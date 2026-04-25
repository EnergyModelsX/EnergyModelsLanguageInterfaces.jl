module EMIExt

using TimeStruct
using EnergyModelsBase
using EnergyModelsInvestments
using EnergyModelsHeat
using EnergyModelsLanguageInterfaces

const TS = TimeStruct
const EMB = EnergyModelsBase
const EMI = EnergyModelsInvestments
const EMH = EnergyModelsHeat
const EMLI = EnergyModelsLanguageInterfaces

"""
    EMLI.BioCHP(
        id::Any,
        cap::TimeProfile,
        cap_init::TimeProfile,
        cap_max_installed::TimeProfile,
        mass_fractions::Dict{<:ResourceBio,<:Real},
        heat_output_ratios::Dict{<:ResourceHeat,<:Real},
        electricity_resource::Resource;
        data::Vector{<:ExtensionData} = ExtensionData[],
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
- **`cap`** is the installed electric capacity used in the CHP submodule for the calculations.
- **`cap_init`** is the initial capacity for the node.
- **`cap_max_installed`** is the maximum installed capacity.
- **`mass_fractions`** is the mass fractions of each input `ResourceBio`.
- **`heat_output_ratios`** is the output heat `ResourceHeat`s with the ratio of installed
  capacity of heat to that of the electricity.
- **`electricity_resource`** is the `Resource` for the electricity.

# Keyword arguments
- **`data::Vector{<:ExtensionData}`** is the additional data (*e.g.*, for investments). The field `data`
  is conditional through usage of a constructor.
- **`libpath`** is the absolute path of the `CHP_modelling` library file.

!!! note ""EmissionsEnergy"
    If `EmissionsEnergy` is not included in the `data` field, it is automatically added.
"""
function EMLI.BioCHP(
    id::Any,
    cap::TimeProfile,
    cap_init::TimeProfile,
    cap_max_installed::TimeProfile,
    mass_fractions::Dict{<:ResourceBio,<:Real},
    heat_output_ratios::Dict{<:ResourceHeat,<:Real},
    electricity_resource::Resource;
    data::Vector{<:ExtensionData} = ExtensionData[],
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
    cap_updated, opex_var, opex_fixed, input_updated, output, data, capex = EMLI.BioCHP(
        cap,
        mass_fractions,
        heat_output_ratios,
        electricity_resource,
        data,
        libpath,
    )

    if !any(isa(d, Investment) for d ∈ data)
        push!(data,
            SingleInvData(
                FixedProfile(capex),  # Capex in EUR/MW
                cap_max_installed,                # Max installed capacity [MW]
                cap_init,
                ContinuousInvestment(FixedProfile(0), cap_updated),
                # Line above: Investment mode with the following arguments:
                # 1. argument: min added capacity per sp [MW]
                # 2. argument: max added capacity per sp [MW]
            ),
        )
    end

    return EMLI.BioCHP(
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

end
