# [Public interface](@id lib-pub)

## [New resource types](@id lib-pub-resource_types)

```@docs
EnergyModelsLanguageInterfaces.ResourceBio
```

## [New parameter types](@id lib-pub-parameter_types)

```@docs
EnergyModelsLanguageInterfaces.PVParameters
```

## [New nodal types](@id lib-pub-nodal_types)

```@docs
EnergyModelsLanguageInterfaces.WindPower
EnergyModelsLanguageInterfaces.PV
EnergyModelsLanguageInterfaces.CSPandPV
EnergyModelsLanguageInterfaces.MultipleBuildingTypes
EnergyModelsLanguageInterfaces.BioCHP
```

## [Sampling constructors](@id lib-pub-sampling_constructors)

```@docs
EnergyModelsLanguageInterfaces.WindPower(
    ::Any,
    ::TimeStruct.TimeProfile,
    ::Dict,
    ::String,
    ::String,
    ::TimeStruct.TimeProfile,
    ::TimeStruct.TimeProfile,
    ::Dict{<:EnergyModelsBase.Resource,<:Real},
)
EnergyModelsLanguageInterfaces.PV(
    ::Any,
    ::TimeProfile,
    ::DateTime,
    ::DateTime,
    ::TimeProfile,
    ::TimeProfile,
    ::Dict{<:Resource,<:Real},
    ::PVParameters;
    data::Vector{<:Data} = Data[],
    data_path::String = "pvgis_cache",
    filename_hint::String = "",
)
EnergyModelsLanguageInterfaces.CSPandPV(
    ::Any,
    ::Dict,
    ::DateTime,
    ::DateTime,
    ::Dict{String,<:EnergyModelsBase.Resource};
    data::Vector{<:Data} = Data[],
    method::String = "Ninja",
    data_path::String = "",
    source::String = "NORA3",
)
EnergyModelsLanguageInterfaces.MultipleBuildingTypes(
    ::Any,
    ::Dict,
    ::DateTime,
    ::DateTime,
    ::Vector{String},
    ::Dict{String,<:EnergyModelsBase.Resource},
    ::TimeStruct.TimeStructure,
    ::Dict{<:EnergyModelsBase.Resource,<:TimeStruct.TimeProfile},
    ::Dict{<:EnergyModelsBase.Resource,<:TimeStruct.TimeProfile};
    data::Vector{<:EnergyModelsBase.Data} = EnergyModelsBase.Data[],
    data_location::String = joinpath(tempdir(), "buildings"),
    overwrite_saved_data::Bool = false,
)
EnergyModelsLanguageInterfaces.BioCHP(
    ::Any,
    ::TimeStruct.TimeProfile,
    ::Dict{<:EnergyModelsLanguageInterfaces.ResourceBio,<:Real},
    ::Dict{<:EnergyModelsHeat.ResourceHeat,<:Real},
    ::EnergyModelsBase.Resource;
    data::Vector{<:EnergyModelsBase.Data} = EnergyModelsBase.Data[],
    libpath::String = joinpath(@__DIR__, "..", "..", "CHP_modelling", "build", "lib", "libbioCHP_wrapper.so"),
)
```

## [Utility functions](@id lib-pub-util_fun)

```@docs
EnergyModelsLanguageInterfaces.call_python_function
EnergyModelsLanguageInterfaces.fetch_element
```
