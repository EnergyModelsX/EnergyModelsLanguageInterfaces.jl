module EMIExt

using TimeStruct
using EnergyModelsBase
using EnergyModelsInvestments
using EnergyModelsHeat
using EnergyModelsLanguageInterfaces
using Libdl

const TS = TimeStruct
const EMB = EnergyModelsBase
const EMI = EnergyModelsInvestments
const EMH = EnergyModelsHeat
const EMLI = EnergyModelsLanguageInterfaces

"""
    EMLI.BioCHP(
        id::Any,
        cap::TimeProfile,
        mass_fractions::Dict{<:ResourceBio,<:Real},
        heat_output_ratios::Dict{<:ResourceHeat,<:Real},
        electricity_resource::Resource;
        data::Vector{Data} = Data[],
        libpath::String = joinpath(
            @__DIR__,
            "..",
            "..",
            "CHP_modelling",
            "build",
            "lib",
            "libbioCHP_wrapper.so",
        ),
    )

Constructs a [`BioCHP`](@ref) instance where the power and heat production profiles are
sampled from the `bioCHP_plant_c` function in the C++ library `CHP_modelling` with shared
library file located at `libpath`. The BioCHP has electricity production of the resource
`electricity_resource` and heat production of the resources in `heat_output_ratios`
(which can be different `ResourceHeat`s at different temperature levels).

# Arguments
- **`id`** is the name or identifier of the node.
- **`cap`** is the installed electric capacity.
- **`mass_fractions`** is the mass fractions of each input `ResourceBio`.
- **`heat_output_ratios`** is the output heat `ResourceHeat`s with the ratio of installed
  capacity of heat to that of the electricity.
- **`electricity_resource`** is the `Resource` for the electricity.

# Keyword arguments
- **`data::Vector{Data}`** is the additional data (*e.g.*, for investments). The field `data`
  is conditional through usage of a constructor.
- **`libpath`** is the absolute path of the `CHP_modelling` library file.
- **`cap_init`** is the initial capacity of the `BioCHP`-node.

!!! note ""EmissionsEnergy"
    If `EmissionsEnergy` is not included in the `data` field, it is automatically added.
"""
function EMLI.BioCHP(
    id::Any,
    cap::TimeProfile,
    mass_fractions::Dict{<:ResourceBio,<:Real},
    heat_output_ratios::Dict{<:ResourceHeat,<:Real},
    electricity_resource::Resource;
    data::Vector{Data} = Data[],
    libpath::String = joinpath(
        @__DIR__,
        "..",
        "..",
        "CHP_modelling",
        "build",
        "lib",
        "libbioCHP_wrapper.so",
    ),
    cap_init::TimeProfile = FixedProfile(0),
)

    # Get the capacity
    el_capacity = cap.val

    # fuel_def: name of each biomass feedstock
    bio_resources::Vector{ResourceBio} = collect(keys(mass_fractions))
    fuel_def_strings = [EMLI.bio_type(res) for res ∈ bio_resources]

    # Create pointers
    fuel_def_buffers = [Vector{UInt8}(string(s, '\0')) for s ∈ fuel_def_strings]
    fuel_def_ptrs = [pointer(buf) for buf ∈ fuel_def_buffers]
    fuel_def_ptr_array = pointer(fuel_def_ptrs)

    # Create mass fractions from input that sum up to 1
    normalization = sum(mass_fractions[res] for res ∈ bio_resources)
    normalized_mass_fractions = Dict{ResourceBio,Float64}(
        res => mass_fractions[res] / normalization for res ∈ bio_resources
    )

    # Yj: mass fraction of each biomass feedstock
    # W_el: electric power output (MW_el)
    # Qk: heat demand (MW)
    # Tk_in: Return temperature for each heat demand (district heating)
    # Tk_in: Supply temperature for each heat demand (district heating)
    heat_resources::Vector{ResourceHeat} = collect(keys(heat_output_ratios))
    Qk_dict::Dict{Resource,Real} = Dict{Resource,Real}(
        res => heat_output_ratios[res] * el_capacity for res ∈ heat_resources
    )
    Yj::Vector{Cdouble} = [normalized_mass_fractions[res] for res ∈ bio_resources]
    YH2Oj::Vector{Cdouble} = EMLI.moisture.(bio_resources)
    W_el::Cdouble = el_capacity
    Qk::Vector{Cdouble} = []
    Tk_in::Vector{Cdouble} = []
    Tk_out::Vector{Cdouble} = []
    for res ∈ heat_resources
        # Get the heat demand
        push!(Qk, Qk_dict[res])

        # Get the supply temperature
        supply_heat_profile = EMH.t_supply(res)
        if !isa(supply_heat_profile, FixedProfile)
            @error "Current implementation require the supply heat profile to be fixed."
        else
            push!(Tk_in, supply_heat_profile.val)
        end

        # Get the return temperature
        return_heat_profile = EMH.t_return(res)
        if !isa(return_heat_profile, FixedProfile)
            @error "Current implementation require the return heat profile to be fixed."
        else
            push!(Tk_out, return_heat_profile.val)
        end
    end

    # Preallocate output variables
    # Mj: Required mass flow of each biomass feedstock
    # C_inv: Investment cost
    # C_op: Variable operating cost
    Mj::Vector{Cdouble} = zeros(length(Yj))   # Output vector
    Q_prod::Ref{Cdouble} = Ref{Cdouble}(0.0)  # Output double
    W_el_prod::Ref{Cdouble} = Ref{Cdouble}(0.0)  # Output double
    C_inv::Ref{Cdouble} = Ref{Cdouble}(0.0)  # Output double
    C_op::Ref{Cdouble} = Ref{Cdouble}(0.0)   # Output double
    C_op_var::Ref{Cdouble} = Ref{Cdouble}(0.0)   # Output double

    # Get lengths of the vectors
    len_Yj::Cint = length(Yj)
    len_YH2Oj::Cint = length(YH2Oj)
    len_Qk::Cint = length(Qk)
    len_Tk_in::Cint = length(Tk_in)
    len_Tk_out::Cint = length(Tk_out)
    len_Mj::Cint = length(Mj)
    len_fuel_def_ptrs::Cint = length(fuel_def_ptrs)

    # Load the library if it's not already cached
    if !haskey(EMLI.LIB_CACHE, libpath)
        @info "Loading the C module $libpath"
        EMLI.LIB_CACHE[libpath] = Libdl.dlopen(libpath)
    end
    lib = EMLI.LIB_CACHE[libpath]
    lib = Libdl.dlopen(libpath)

    # Call the shared C function from the loaded library
    err_ref = Ref{Cstring}()
    ret = @ccall $(EMLI.@dlsym(lib, :bioCHP_plant_c))(
        fuel_def_ptr_array::Ptr{Cstring}, len_fuel_def_ptrs::Cint,
        Yj::Ptr{Cdouble}, len_Yj::Cint,
        YH2Oj::Ptr{Cdouble}, len_YH2Oj::Cint,
        W_el::Cdouble,
        Qk::Ptr{Cdouble}, len_Qk::Cint,
        Tk_in::Ptr{Cdouble}, len_Tk_in::Cint,
        Tk_out::Ptr{Cdouble}, len_Tk_out::Cint,
        Mj::Ptr{Cdouble}, len_Mj::Cint,
        Q_prod::Ref{Cdouble},
        W_el_prod::Ref{Cdouble},
        C_inv::Ref{Cdouble},
        C_op::Ref{Cdouble},
        C_op_var::Ref{Cdouble},
        err_ref::Ref{Cstring},
    )::Cint
    if ret != 0
        msg = err_ref[] == C_NULL ? "unknown error" : unsafe_string(err_ref[])
        if err_ref[] != C_NULL
            ccall(:free, Cvoid, (Ptr{Cvoid},), Ptr{Cvoid}(err_ref[]))
        end
        error("CHP_modelling library failed: $msg")
    end

    input_updated = Dict{ResourceBio,Real}(
        res => Mj[i] / W_el_prod[] for (i, res) ∈ enumerate(bio_resources)
    )
    cap_updated = FixedProfile(Float64(W_el_prod[]))

    tot_opex = C_op[]
    fixed_opex = tot_opex - C_op_var[]
    var_opex = C_op_var[] / 8760
    opex_fixed = FixedProfile(Float64(fixed_opex))
    opex_var = FixedProfile(Float64(var_opex))

    output = Dict{Resource,Real}(
        resource => val / W_el_prod[] for (resource, val) ∈ Qk_dict
    )
    output[electricity_resource] = 1.0

    if !(EmissionsEnergy ∈ typeof.(data))
        push!(data, EmissionsEnergy())
    end
    if !any(isa(d, Investment) for d ∈ data)
        push!(data,
            SingleInvData(
                FixedProfile(Float64(C_inv[]/W_el_prod[])),  # Capex in EUR/MW
                cap_updated,                # Max installed capacity [MW]
                ContinuousInvestment(FixedProfile(0), cap_updated),
                # Line above: Investment mode with the following arguments:
                # 1. argument: min added capacity per sp [MW]
                # 2. argument: max added capacity per sp [MW]
            ),
        )
    end

    return EMLI.BioCHP(
        id,
        cap_init,
        electricity_resource,
        opex_var,
        opex_fixed,
        input_updated,
        output,
        data,
    )
end

end
