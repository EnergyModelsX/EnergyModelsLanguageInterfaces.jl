# [ResourceBio](@id resources-ResourceBio)

Biomass fuels have characteristics that go beyond a pure energy carrier, such as the specific fuel type and the moisture content of the material.
These properties can significantly affect conversion efficiency and emissions, and are therefore explicitly represented.
[`ResourceBio`](@ref), which is a [`Resource`](@extref EnergyModelsBase.Resource) for transporting and converting biomass fuels, is introduced to enable consistent modeling of biomass-based energy technologies in [`EnergyModelsX`](https://github.com/EnergyModelsX).

Compared to a [`ResourceCarrier`](@extref EnergyModelsBase.ResourceCarrier), [`ResourceBio`](@ref) includes additional information on the biomass fuel type and its moisture content.
Resources of type [`ResourceBio`](@ref) are intended to be *consumed* by technologies (*e.g.*, biomass boilers or CHP plants).
The properties are included in the detailed submodule for the calculation of efficiencies of the the `BioCHP` type.

## [Introduced type and its fields](@id resources-ResourceBio-fields)

[`ResourceBio`](@ref) extends the abstract type
[`Resource`](https://github.com/EnergyModelsX/EnergyModelsBase.jl/blob/main/src/structures/resource.jl)
from [EnergyModelsBase](https://github.com/EnergyModelsX/EnergyModelsBase.jl/tree/main),
with additional fields describing biomass-specific properties.

- **`id`** :\
    The field `id` is used to provide a name to the resource.

- **`bio_type::String`** :\
    The type of biomass fuel, *e.g.*, `"spruce_stem"`, `"spruce_bark"`, `"spruce_T&B"`, or `"birch_stem"`.

- **`moisture::Float64`** :\
    Moisture content of the biomass resource as a mass fraction.
    Typical values range from around ``0.1`` for dry pellets to more than ``0.5`` for wet wood chips.

- **`co2_int::T`** :\
    CO₂ intensity of the biomass resource (with `T <: Real`), *e.g.*, in t/MWh.
    This value can be used by emissions-accounting extensions when biomass is converted or consumed.
