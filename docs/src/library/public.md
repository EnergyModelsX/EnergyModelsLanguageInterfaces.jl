# [Public interface](@id lib-pub)

## [New resource types](@id lib-pub-resource_types)

```@docs
EMLI.ResourceBio
```

## [New parameter types](@id lib-pub-parameter_types)

```@docs
EMLI.PVParameters
EMLI.WindFarmParameters
```

## [New nodal types](@id lib-pub-nodal_types)

```@docs
EMLI.WindPower
EMLI.PV
EMLI.CSPandPV
EMLI.Building
EMLI.MultipleBuildingTypes
EMLI.BioCHP
```

## [Sampling constructors](@id lib-pub-sampling_constructors)

```@docs
EMLI.WindPower(
    ::Any,
    ::TimeStruct.TimeProfile,
    ::TimeStruct.TimeProfile,
    ::TimeStruct.TimeProfile,
    ::Dict{<:EnergyModelsBase.Resource,<:Real},
    ::DateTime,
    ::DateTime,
    ::WindFarmParameters,
)
EMLI.PV(
    ::Any,
    ::TimeProfile,
    ::TimeProfile,
    ::TimeProfile,
    ::Dict{<:Resource,<:Real},
    ::DateTime,
    ::DateTime,
    ::PVParameters;
    data::Vector{<:ExtensionData} = ExtensionData[],
    data_path::String = "pvgis_cache",
    filename_hint::String = "",
)
EMLI.CSPandPV(
    ::Any,
    ::Dict,
    ::DateTime,
    ::DateTime,
    ::Dict{String,<:EnergyModelsBase.Resource};
    data::Vector{<:ExtensionData} = ExtensionData[],
    method::String = "Ninja",
    data_path::String = "",
    source::String = "NORA3",
)
EMLI.Building(
    ::Any,
    ::Dict{<:Resource,<:TimeProfile},
    ::Dict{<:Resource,<:TimeProfile},
    ::Dict{<:Resource,<:TimeProfile},
    ::Dict{<:Resource,<:Real},
    ::DateTime,
    ::DateTime,
    ::Real,
    ::Real,
    ::Resource,
    ::Function;
    data::Vector{<:ExtensionData} = ExtensionData[],
    data_path::String = joinpath(tempdir(), "building"),
    source::String = "NORA3",
    reload_csv::Bool = true,
    save_csv::Bool = true,
)
EMLI.MultipleBuildingTypes(
    ::Any,
    ::Dict,
    ::DateTime,
    ::DateTime,
    ::Vector{String},
    ::Dict{String,<:EnergyModelsBase.Resource},
    ::TimeStruct.TimeStructure,
    ::Dict{<:EnergyModelsBase.Resource,<:TimeStruct.TimeProfile},
    ::Dict{<:EnergyModelsBase.Resource,<:TimeStruct.TimeProfile};
    data::Vector{<:ExtensionData} = ExtensionData[],
    data_location::String = joinpath(tempdir(), "buildings"),
    overwrite_saved_data::Bool = false,
)
EMLI.BioCHP(
    ::Any,
    ::TimeStruct.TimeProfile,
    ::Dict{<:EMLI.ResourceBio,<:Real},
    ::Dict{<:EnergyModelsHeat.ResourceHeat,<:Real},
    ::EnergyModelsBase.Resource;
    data::Vector{<:ExtensionData} = ExtensionData[],
    libpath::String = joinpath(@__DIR__, "..", "..", "CHP_modelling", "build", "lib", "libbioCHP_wrapper.so"),
)
```

## [Utility functions](@id lib-pub-util_fun)

```@docs
EMLI.call_python_function
EMLI.fetch_element
EMLI.to_dict
```
