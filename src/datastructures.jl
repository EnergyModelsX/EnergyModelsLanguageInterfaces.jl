"""
    WindPower <: AbstractNonDisRES

A wind power source. It extends the existing `AbstractNonDisRES` node through allowing for
sampling the profile from a Python code through a constructor.

# Fields
- **`id`** is the name/identifyer of the node.
- **`cap::TimeProfile`** is the installed capacity.
- **`profile::TimeProfile`** is the power production in each operational period as a ratio
  of the installed capacity at that time.
- **`opex_var::TimeProfile`** is the variable operating expense per energy unit produced.
- **`opex_fixed::TimeProfile`** is the fixed operating expense.
- **`output::Dict{Resource, Real}`** are the generated `Resource`s, normally Power.
- **`data::Vector{Data}`** is the additional data (e.g. for investments). The field `data`
  is conditional through usage of a constructor.
"""
struct WindPower <: AbstractNonDisRES
    id::Any
    cap::TimeProfile
    profile::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    output::Dict{<:Resource,<:Real}
    data::Vector{Data}
end
function WindPower(
    id::Any,
    cap::TimeProfile,
    profile::TimeProfile,
    opex_var::TimeProfile,
    opex_fixed::TimeProfile,
    output::Dict{<:Resource,<:Real},
)
    return WindPower(id, cap, profile, opex_var, opex_fixed, output, Data[])
end

"""
    WindPower(
        id::Any,
        cap::TimeProfile,
        windfarm::Dict,
        time_start::String,
        time_end::String,
        opex_var::TimeProfile,
        opex_fixed::TimeProfile,
        output::Dict{<:Resource,<:Real};
        data::Vector{Data} = Data[],
        method::String = "Ninja",
        data_path::String = ""
    )

Constructs a [`WindPower`](@ref) instance where the power production profile is sampled from
a Python function.

# Arguments
- **`id`** is the name or identifier of the node.
- **`cap`** is the installed capacity.
- **`windfarm`** is a dictionary containing the wind farm parameters. An example dictionary
  is given by:

  ```julia
    windfarm = Dict(
        "id" => "windfarm_1",       # The identifier of the windfarm
        "lat" => 56.8233,           # The latitude coordinates of the windfarm
        "lon" => 4.3467,            # The longitude of the wind farm
        "orientation" => missing,   # The orientation
        "shape" => missing,
        "turbine_height" => 150,    # The turbine height
    )
  ```
- **`time_start`** is the starting time (as a string) for the wind power time series sampling.
  The format is "YYYY-MM-DD".
- **`time_end`** is the end time (as a string) for the wind power time series sampling.
  The format is "YYYY-MM-DD".
- **`opex_var`** is the variable operating expense per energy unit produced.
- **`opex_fixed`** is the fixed operating expense.
- **`output`** are the generated `Resource`s, normally Power, with conversion value `Real`.

# Keyword arguments
- **`data`** is the additional data (*e.g.*, for investments). The default value is no `data`.
- **`method`** is the chosen method for data retrieval. The user can choose between the
  strings "Ninja", "Tradewind_offshore", "Tradewind_upland",  and "Tradewind_lowland".
  The default value is "Ninja".
- **`data_path`** is an optional file path for already downloaded data. The default value is
  an empty datapath.
"""
function WindPower(
    id::Any,
    cap::TimeProfile,
    windfarm::Dict,
    time_start::String,
    time_end::String,
    opex_var::TimeProfile,
    opex_fixed::TimeProfile,
    output::Dict{<:Resource,<:Real};
    data::Vector{Data} = Data[],
    method::String = "Ninja",
    data_path::String = "",
)
    power = call_python_function(
        "wind_power_timeseries",
        "sample.wind_power";
        windfarm = windfarm,
        time_start = time_start,
        time_end = time_end,
        method = method,
        data_path = data_path,
    )
    profile = OperationalProfile(power)

    return WindPower(id, cap, profile, opex_var, opex_fixed, output, data)
end

"""
    CSPandPV <: AbstractNonDisRES

A combined CSP and PV source producing both power and heat. It extends the existing
`AbstractNonDisRES` to multiple production profiles. The profiles can have variations on
the strategic level.

# Fields
- **`id`** is the name/identifyer of the node.
- **`cap::Dict{<:Resource,<:TimeProfile}`** is the installed capacity (for all resources in a Dict).
- **`profile::Dict{<:Resource,<:TimeProfile}`** is the production profile in each operational
  period as a ratio of the installed capacity at that time (for all resources in a Dict).
- **`opex_var::Dict{<:Resource,<:TimeProfile}`** is the variable operating expense per
  energy unit produced (for all resources in a Dict).
- **`opex_fixed::Dict{<:Resource,<:TimeProfile}`** is the fixed operating expense (for all
  resources in a Dict).
- **`output::Dict{Resource, Real}`** are the generated `Resource`s, normally Power.
- **`data::Vector{Data}`** is the additional data (e.g. for investments). The field `data`
  is conditional through usage of a constructor.

!!! danger
    Investments are not available for this node.
"""
struct CSPandPV <: AbstractNonDisRES
    id::Any
    cap::Dict{<:Resource,<:TimeProfile}
    profile::Dict{<:Resource,<:TimeProfile}
    opex_var::Dict{<:Resource,<:TimeProfile}
    opex_fixed::Dict{<:Resource,<:TimeProfile}
    output::Dict{<:Resource,<:Real}
    data::Vector{Data}
end
function CSPandPV(
    id::Any,
    cap::Dict{<:Resource,<:TimeProfile},
    profile::Dict{<:Resource,<:TimeProfile},
    opex_var::Dict{<:Resource,<:TimeProfile},
    opex_fixed::Dict{<:Resource,<:TimeProfile},
    output::Dict{<:Resource,<:Real},
)
    return CSPandPV(id, cap, profile, opex_var, opex_fixed, output, Data[])
end

"""
    CSPandPV(
        id::Any,
        process_pay_load::Dict,
        time_start::DateTime,
        time_end::DateTime,
        resources_map::Dict{String,<:Resource};
        data::Vector{Data} = Data[],
        data_location::String = joinpath(tempdir(), "CSPandPV"),
        overwrite_saved_data::Bool = false,
    )

Constructs a `CSPandPV` instance where the power and heat production profiles are sampled from
the `executeSolarEnergyModelProcess` function in the `solar_power_plants` python project.

# Arguments
- **`id`** is the name or identifier of the node in EMX.
- **`process_pay_load`** is the process dictionary for the Python function.
- **`time_start`** is the start time for the sampling.
- **`time_end`** is the end time for the sampling.
- **`resources_map`** is a map of resource keys to `EMB.Resource`s, *e.g.*, the dictionary

  ```julia
  Power = ResourceCarrier("Power", 0.0)
  Heat = ResourceCarrier("Heat", 0.0)

  resources_map = Dict(
      "Ppv" => Power,
      "Pthermal" => Heat,
  )
  ```

  It must contain the keys "Ppv" and "Pthermal" with their equivalent in EMX as values.

# Keyword arguments
- **`data`** is the additional data (*e.g.*, for investments). The default value is no `data`.
- **`data_location`** is the location where the data is saved. The default value is in the
  temporary directory.
- **`overwrite_saved_data`** is a boolean that determines if the stored data should be
  overwritten (in which case the building_energy_process is called). The default value is
  `false`.

!!! note
    The argument `process_pay_load` is a dictionary that contains the process information 
    for the Python function. The defaults can be achieved through

    ```julia
    using JSON
    process_pay_load = JSON.parsefile(path_to_pv_power_plants/input.json)
    ```
"""
function CSPandPV(
    id::Any,
    process_pay_load::Dict,
    time_start::DateTime,
    time_end::DateTime,
    resources_map::Dict{String,<:Resource};
    data::Vector{Data} = Data[],
    data_location::String = joinpath(tempdir(), "CSPandPV"),
    overwrite_saved_data::Bool = false,
)
    time_start_str = Dates.format(time_start, "yyyy-mm-dd\\THH:MM:SS")
    time_end_str = Dates.format(time_end, "yyyy-mm-dd\\THH:MM:SS")
    data_path = joinpath(data_location, "CSPandPV.yml")
    resources = values(resources_map)
    if isfile(data_path) && !overwrite_saved_data
        power_outputs = YAML.load(open(data_path))
    else
        csp_and_pv_dict = call_python_function(
            "solar_power_plants",
            "executeSolarEnergyModelProcess",
            [process_pay_load, time_start_str, time_end_str],
        )

        if !isdir(data_location)
            mkpath(data_location)
        end

        # Extract power_outputs from the dictionary
        power_outputs = Dict(
            key => csp_and_pv_dict[key] for
            key ∈ keys(csp_and_pv_dict) if key != "time(UTC)"
        )
        open(data_path, "w") do io
            YAML.write(io, power_outputs)
        end
    end

    # Find the maximum power output for each resource
    max_power =
        Dict{String,Real}(key => maximum(power_outputs[key]) for key ∈ keys(power_outputs))

    # Construct capacity profiles
    cap = Dict{Resource,TimeProfile}(
        resources_map[key] => FixedProfile(max_power[key]) for
        key ∈ keys(power_outputs)
    )

    # Construct normalized power profiles
    profile = Dict{Resource,TimeProfile}(
        resources_map[key] => OperationalProfile(power_outputs[key] / max_power[key])
        for
        key ∈ keys(power_outputs)
    )

    # Set the fixed OPEX to the values in the process_pay_load
    opex_fixed = Dict{Resource,TimeProfile}(
        resources_map[key] => FixedProfile(process_pay_load["opex_"*key[2:end]]) for
        key ∈ keys(power_outputs)
    )

    # Set the variable OPEX to 0
    opex_var = Dict{Resource,TimeProfile}(
        resource => FixedProfile(0) for resource ∈ resources
    )

    output = Dict{Resource,Real}(resource => 1.0 for resource ∈ resources)

    return CSPandPV(id, cap, profile, opex_var, opex_fixed, output, data)
end

"""
    EMB.capacity(n::CSPandPV)
    EMB.capacity(n::CSPandPV, p::Resource)
    EMB.capacity(n::CSPandPV, t, p::Resource)

Returns the capacity of a CSPandPV `n` as a `Dictionary` or of resource `p` as `TimeProfile`
or in operational period `t`.
"""
EMB.capacity(n::CSPandPV) = n.cap
EMB.capacity(n::CSPandPV, p::Resource) = n.cap[p]
EMB.capacity(n::CSPandPV, t, p::Resource) = n.cap[p][t]

"""
    EMB.has_capacity(n::CSPandPV)

A CSPandPV has capacity for all its resources but not in a EMB sense.
"""
EMB.has_capacity(n::CSPandPV) = false

"""
    EMB.opex_var(n::CSPandPV)
    EMB.opex_var(n::CSPandPV, p::Resource)
    EMB.opex_var(n::CSPandPV, t, p::Resource)

Returns the variable OPEX of a CSPandPV `n` as a `Dictionary` or of resource `p` as `TimeProfile`
or in operational period `t`.
"""
EMB.opex_var(n::CSPandPV) = n.opex_var
EMB.opex_var(n::CSPandPV, p::Resource) = n.opex_var[p]
EMB.opex_var(n::CSPandPV, t, p::Resource) = n.opex_var[p][t]

"""
    EMB.opex_fixed(n::CSPandPV)
    EMB.opex_fixed(n::CSPandPV, p::Resource)
    EMB.opex_fixed(n::CSPandPV, t_inv, p::Resource)

Returns the fixed OPEX of a CSPandPV `n` as a `Dictionary` or of resource `p` as `TimeProfile`
or in operational period `t`.
"""
EMB.opex_fixed(n::CSPandPV) = n.opex_fixed
EMB.opex_fixed(n::CSPandPV, p::Resource) = n.opex_fixed[p]
EMB.opex_fixed(n::CSPandPV, t_inv, p::Resource) = n.opex_fixed[p][t_inv]

"""
    EMR.profile(n::CSPandPV)
    EMR.profile(n::CSPandPV, p::Resource)
    EMR.profile(n::CSPandPV, t, p::Resource)

Returns the profile of a CSPandPV `n` as a `Dictionary` or of resource `p` as `TimeProfile`
or in operational period `t`.
"""
EMR.profile(n::CSPandPV) = n.profile
EMR.profile(n::CSPandPV, p::Resource) = n.profile[p]
EMR.profile(n::CSPandPV, t, p::Resource) = n.profile[p][t]

"""
    struct MultipleBuildingTypes <: EMB.Sink

A [`MultipleBuildingTypes`](@ref) node that creates sinks for all demand resources. The
demand for each resources has a penalty for both surplus and deficit.
The penalties introduced in the field `penalty` affect the variable OPEX for both a surplus
and deficit.

# Fields
- **`id`** is the name/identifier of the node.
- **`cap::Dict{<:Resource,<:TimeProfile}`** is the demand.
- **`penalty_surplus::Dict{<:Resource,<:TimeProfile}`** are the penalties for surplus.
- **`penalty_deficit::Dict{<:Resource,<:TimeProfile}`** are the penalties for deficit.
- **`input::Dict{<:Resource,<:Real}`** are the input 
  [`Resource`](@extref EnergyModelsBase.Resource)s with conversion value `Real`.
- **`data::Vector{<:Data}`** is the additional data (*e.g.*, for investments). The field `data`
  is conditional through usage of a constructor.

!!! danger
    Investments are not available for this node.
"""
struct MultipleBuildingTypes <: EMB.Sink
    id::Any
    cap::Dict{<:Resource,<:TimeProfile}
    penalty_surplus::Dict{<:Resource,<:TimeProfile}
    penalty_deficit::Dict{<:Resource,<:TimeProfile}
    input::Dict{<:Resource,<:Real}
    data::Vector{<:Data}
end
function MultipleBuildingTypes(
    id::Any,
    cap::Dict{<:Resource,<:TimeProfile},
    penalty_surplus::Dict{<:Resource,<:TimeProfile},
    penalty_deficit::Dict{<:Resource,<:TimeProfile},
    input::Dict{<:Resource,<:Real},
)
    return MultipleBuildingTypes(id, cap, penalty_surplus, penalty_deficit, input, Data[])
end

"""
    MultipleBuildingTypes(
        id::Any,
        process_pay_load::Dict,
        time_start::DateTime,
        time_end::DateTime,
        buildings::Vector{String},
        resources_map::Dict{String,<:Resource},
        T::TimeStructure,
        penalty_surplus::Dict{<:Resource,<:TimeProfile},
        penalty_deficit::Dict{<:Resource,<:TimeProfile};
        data::Vector{<:Data} = Data[],
        data_location::String = joinpath(tempdir(), "buildings"),
        overwrite_saved_data::Bool = false,
    )

Constructs a `MultipleBuildingTypes` instance where the demand profiles are sampled from the
`executeBuildingEnergySimulationProcess` function in the `building_energy_process` python project.

# Arguments
- **`id`** is the name or identifier of the node.
- **`process_pay_load`** is the process dictionary for the Python function.
- **`time_start`** is the starting time for the sampling.
- **`time_end`** is the ending time for the sampling.
- **`buildings`** is a vector of the buildings to be considered. Any combination of the following building types is allowed:
  - "Apartment Block"
  - "Single family- Terraced houses"
  - "Hotels and Restaurants"
  - "Health"
  - "Education"
  - "Offices"
  - "Trade"
  - "Other non-residential buildings"
  - "Sport"
- **`resources_map`** is a map of resource keys to `EMB.Resource`s. E.g., the dictionary

  ```julia
  Coal = ResourceCarrier("Coal", 0.35)
  LNG = ResourceCarrier("LNG", 0.2)
  Oil = ResourceCarrier("Oil", 0.3)
  NG = ResourceCarrier("NG", 0.2)
  SolidBiomass = ResourceCarrier("SolidBiomass", 0.1)
  Power = ResourceCarrier("Power", 0.0)
  Heat = ResourceCarrier("Heat", 0.0)
  LiquidBiomass = ResourceCarrier("LiquidBiomass", 0.15)
  Biogas = ResourceCarrier("Biogas", 0.05)
  Hydrogen = ResourceCarrier("Hydrogen", 0.0)
  SolarHeat = ResourceCarrier("SolarHeat", 0.0)

  resources_map = Dict(
      "Solids|Coal" => Coal,
      "Liquids|Gas" => LNG,
      "Liquids|Oil" => Oil,
      "Gases|Gas" => NG,
      "Solids|Biomass" => SolidBiomass,
      "Electricity" => Power,
      "Heat" => Heat,
      "Liquids|Biomass" => LiquidBiomass,
      "Gases|Biomass" => Biogas,
      "Hydrogen" => Hydrogen,
      "Heat|Solar" => SolarHeat,
  )
  ```
- **`T`** is the TimeStructure used in the model.
- **`penalty_surplus::Dict{<:Resource,<:TimeProfile}`** is the penalties for surplus.
- **`penalty_deficit::Dict{<:Resource,<:TimeProfile}`** is the penalties for deficit.

# Keyword arguments
- **`data`** is the additional data (*e.g.*, for investments). The default value is no `data`.
- **`data_location`** is the location where the data is saved. The default value is in the
  temporary directory.
- **`overwrite_saved_data`** is a boolean that determines if the stored data should be
  overwritten (in which case the building_energy_process is called). The default value is
  `false`.

!!! note
    The "Variable cost [€/KWh]" and "Emissions [KgCO2/KWh]" from the `building_energy_process`
    model is currently not used. Both of these are incorporated indirectly through the usage
    of the energy carriers.

!!! note
    The argument `process_pay_load` is a dictionary that contains the process information 
    for the Python function. The defaults can be achieved through

    ```julia
    using JSON
    process_pay_load = JSON.parsefile(path_to_building_energy_process/input.json)
    ```

!!! note
    If you want to incorporate unique penalities for each building type, you must create A
    `MultipleBuildingTypes` node for each building type.
"""
function MultipleBuildingTypes(
    id::Any,
    process_pay_load::Dict,
    time_start::DateTime,
    time_end::DateTime,
    buildings::Vector{String},
    resources_map::Dict{String,<:Resource},
    T::TimeStructure,
    penalty_surplus::Dict{<:Resource,<:TimeProfile},
    penalty_deficit::Dict{<:Resource,<:TimeProfile};
    data::Vector{<:Data} = Data[],
    data_location::String = joinpath(tempdir(), "buildings"),
    overwrite_saved_data::Bool = false,
)
    time_start_str = Dates.format(time_start, "yyyy-mm-dd\\THH:MM:SS")
    time_end_str = Dates.format(time_end, "yyyy-mm-dd\\THH:MM:SS")
    oper_length = length(T.operational[1]) # Assume the length to be the same in all Strategic periods
    resources = values(resources_map)
    cap_vector =
        Dict{Resource,Vector}(resource => zeros(oper_length) for resource ∈ resources)
    for building ∈ buildings
        # The keys of demands is
        data_path = joinpath(data_location, building * ".yml")
        if isfile(data_path) && !overwrite_saved_data
            demands = YAML.load(open(data_path))
        else
            demands = call_python_function(
                "building_energy_process",
                "executeBuildingEnergySimulationProcess",
                [process_pay_load, time_start_str, time_end_str, building],
            )

            if !isdir(data_location)
                mkpath(data_location)
            end

            # Scale power_outputs to MW
            for key ∈ keys(demands)
                if !(key in ["Datetime", "Variable cost [€/KWh]", "Emissions [KgCO2/KWh]"])
                    demands[key] /= 1e6
                end
            end
            open(data_path, "w") do io
                YAML.write(io, demands)
            end
        end
        for (key, demand) ∈ demands
            # Skip fields not used
            if key in ["Datetime", "Variable cost [€/KWh]", "Emissions [KgCO2/KWh]"]
                continue
            end

            # Add the demand to the corresponding resource
            cap_vector[resources_map[key]] += demand
        end
    end
    # Convert to OperationalProfile
    cap = Dict{Resource,TimeProfile}(
        resource => OperationalProfile(cap_vector[resource]) for
        resource ∈ resources
    )

    input = Dict{Resource,Real}(resource => 1.0 for resource ∈ resources)
    return MultipleBuildingTypes(id, cap, penalty_surplus, penalty_deficit, input, data)
end

"""
    EMB.capacity(n::MultipleBuildingTypes)
    EMB.capacity(n::MultipleBuildingTypes, p::Resource)
    EMB.capacity(n::MultipleBuildingTypes, t, p::Resource)

Returns the capacity of a MultipleBuildingTypes `n` as a `Dictionary` or of resource `p` as `TimeProfile`
or in operational period `t`.
"""
EMB.capacity(n::MultipleBuildingTypes) = n.cap
EMB.capacity(n::MultipleBuildingTypes, p::Resource) = n.cap[p]
EMB.capacity(n::MultipleBuildingTypes, t, p::Resource) = n.cap[p][t]

"""
    EMB.has_capacity(n::MultipleBuildingTypes)

A MultipleBuildingTypes has capacity for all its resources but not in a EMB sense.
"""
EMB.has_capacity(n::MultipleBuildingTypes) = false

"""
    EMB.surplus_penalty(n::MultipleBuildingTypes)
    EMB.surplus_penalty(n::MultipleBuildingTypes, p::Resource)
    EMB.surplus_penalty(n::MultipleBuildingTypes, t, p::Resource)

Returns the surplus penalty of MultipleBuildingTypes `n` as a `Dictionary` or of resource `p` as `TimeProfile`
or in operational period `t`.
"""
EMB.surplus_penalty(n::MultipleBuildingTypes) = n.penalty_surplus
EMB.surplus_penalty(n::MultipleBuildingTypes, p::Resource) = n.penalty_surplus[p]
EMB.surplus_penalty(n::MultipleBuildingTypes, t, p::Resource) = n.penalty_surplus[p][t]

"""
    EMB.deficit_penalty(n::MultipleBuildingTypes)
    EMB.deficit_penalty(n::MultipleBuildingTypes, p::Resource)
    EMB.deficit_penalty(n::MultipleBuildingTypes, t, p::Resource)

Returns the deficit penalty of MultipleBuildingTypes `n` as a `Dictionary` or of resource `p` as `TimeProfile`
or in operational period `t`.
"""
EMB.deficit_penalty(n::MultipleBuildingTypes) = n.penalty_deficit
EMB.deficit_penalty(n::MultipleBuildingTypes, p::Resource) = n.penalty_deficit[p]
EMB.deficit_penalty(n::MultipleBuildingTypes, t, p::Resource) = n.penalty_deficit[p][t]

"""
    ResourceBio{T<:Real} <: Resource

Resources that can be transported and converted.
These resources **cannot** be included as resources that are emitted, *e.g*, in the variable
[`emissions_strategic`](@extref EnergyModelsBase man-opt_var-emissions). Compared to a `ResourceCarrier`, the
`ResourceBio` `Resource` includes additionally the fuel definition (a string identifier of
the biomass) and the moisture content of the biomass (as a mass fraction).

# Fields
- **`id`** is the name/identifyer of the resource.
- **`bio_type::String`** is the type of biomass, *e.g.*, "spruce_stem", "spruce_bark",
  "spruce_T&B", or "birch_stem".
- **`moisture::Float64`** is the moisture content of the biomass resource as a mass fraction.
- **`co2_int::T`** is the CO₂ intensity, *e.g.*, t/MWh.
"""
struct ResourceBio{T<:Real} <: Resource
    id::Any
    bio_type::String
    moisture::Float64
    co2_int::T
end

"""
    bio_type(p::ResourceBio)

Returns the biomass type of a [`ResourceBio`](@ref) `p`.
"""
bio_type(p::ResourceBio) = p.bio_type

"""
    bio_type(p::ResourceBio)

Returns the moisture content of a [`ResourceBio`](@ref) `p`.
"""
moisture(p::ResourceBio) = p.moisture

"""
    BioCHP <: NetworkNode

A [`BioCHP`](@ref) node that samples the CHP model at https://github.com/iDesignRES/CHP_modelling.git.
The `BioCHP` utilizes a linear, time independent conversion rate of the `input`
[`Resource`](@extref EnergyModelsBase.Resource)s to the output [`Resource`](@extref EnergyModelsBase.Resource)s, subject to the available capacity.
The capacity is hereby normalized to a conversion value of 1 in the fields `input` and
`output`.

# Fields
- **`id`** is the name/identifier of the node.
- **`cap::TimeProfile`** is the installed capacity.
- **`electricity_resource::Resource`** is the electric power resource.
- **`opex_var::TimeProfile`** is the variable operating expense per per capacity usage
  through the variable `:cap_use`.
- **`opex_fixed::TimeProfile`** is the fixed operating expense per installed capacity
  through the variable `:cap_inst`.
- **`input::Dict{<:Resource,<:Real}`** are the input [`Resource`](@extref EnergyModelsBase.Resource)s with conversion
  value `Real`.
- **`output::Dict{<:Resource,<:Real}`** are the generated [`Resource`](@extref EnergyModelsBase.Resource)s with
  conversion value `Real`.
- **`data::Vector{Data}`** is the additional data (*e.g.*, for investments). The field `data`
  is conditional through usage of a constructor.
"""
struct BioCHP <: NetworkNode
    id::Any
    cap::TimeProfile
    electricity_resource::Resource
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    input::Dict{<:ResourceBio,<:Real}
    output::Dict{<:Resource,<:Real}
    data::Vector{<:Data}
end
function BioCHP(
    id,
    cap::TimeProfile,
    electricity_resource::Resource,
    opex_var::TimeProfile,
    opex_fixed::TimeProfile,
    input::Dict{<:ResourceBio,<:Real},
    output::Dict{<:Resource,<:Real},
)
    return BioCHP(
        id,
        cap,
        electricity_resource,
        opex_var,
        opex_fixed,
        input,
        output,
        [EmissionsEnergy()],
    )
end

"""
    BioCHP(
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

!!! note ""EmissionsEnergy"
    If `EmissionsEnergy` is not included in the `data` field, it is automatically added.
"""
function BioCHP(
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

    # Get the capacity
    el_capacity = cap.val

    # fuel_def: name of each biomass feedstock
    bio_resources::Vector{ResourceBio} = collect(keys(mass_fractions))
    fuel_def_strings = [bio_type(res) for res ∈ bio_resources]

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
    YH2Oj::Vector{Cdouble} = moisture.(bio_resources)
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
    if !haskey(LIB_CACHE, libpath)
        @info "Loading the C module $libpath"
        LIB_CACHE[libpath] = Libdl.dlopen(libpath)
    end
    lib = LIB_CACHE[libpath]
    lib = Libdl.dlopen(libpath)

    # Call the shared C function from the loaded library
    @ccall $(@dlsym(lib, :bioCHP_plant_c))(
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
    )::Bool

    input_updated = Dict{ResourceBio,Real}(
        res => Mj[i] / W_el_prod[] for (i, res) ∈ enumerate(bio_resources)
    )
    cap_updated = FixedProfile(Float64(W_el_prod[]))

    opex_fixed = FixedProfile(Float64(C_op[]))
    opex_var = FixedProfile(Float64(C_op_var[] / 8760))

    output = Dict{Resource,Real}(
        resource => val / W_el_prod[] for (resource, val) ∈ Qk_dict
    )
    output[electricity_resource] = 1.0

    if !(EmissionsEnergy ∈ typeof.(data))
        push!(data, EmissionsEnergy())
    end

    return BioCHP(
        id,
        cap_updated,
        electricity_resource,
        opex_var,
        opex_fixed,
        input_updated,
        output,
        data,
    )
end

"""
    electricity_resource(n::BioCHP)

Returns the electricity resource of [`BioCHP`](@ref) node `n`.
"""
electricity_resource(n::BioCHP) = n.electricity_resource
