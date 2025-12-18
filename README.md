# EnergyModelsLanguageInterfaces.jl

[![DOI](https://joss.theoj.org/papers/10.21105/joss.06619/status.svg)](https://doi.org/10.21105/joss.06619)
[![Build Status](https://github.com/EnergyModelsX/EnergyModelsLanguageInterfaces.jl/workflows/CI/badge.svg)](https://github.com/EnergyModelsX/EnergyModelsLanguageInterfaces.jl/actions?query=workflow%3ACI)
[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://energymodelsx.github.io/EnergyModelsLanguageInterfaces.jl/stable/)
[![In Development](https://img.shields.io/badge/docs-dev-blue.svg)](https://energymodelsx.github.io/EnergyModelsLanguageInterfaces.jl/dev/)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/JuliaDiff/BlueStyle)

This package is an extension to the [`EnergyModelsX`](https://github.com/EnergyModelsX) (EMX) framework.
The aim of this package is to provide functions for interacting with other models written in C++ and Python.
This is exemplified with multiple new nodal descriptions from different models.

## Usage

The usage of the package is best illustrated through the commented examples in the documentation.
The examples are minimum working examples highlighting how to use the receding horizon framework.
In addition, they provide a user with an overview regarding potential adjustments to their elements.

> [!CAUTION]
> The node `MultipleBuildingTypes` is currently under development.
> It may contain incorrect implementations with respect to the calculation of the variable OPEX.
> We hence recommendto not use this node in its current stage.

> [!WARNING]
> The package is not yet registered.
> It is hence necessary to first clone the package and manually add the package to the example environment through:
>
> ```julia
> ] dev ..
> ```

## Cite

If you find `EnergyModelsLanguageInterfaces` useful in your work, we kindly request that you cite the following [publication](https://doi.org/10.21105/joss.06619):

```bibtex
@article{hellemo2024energymodelsx,
  title = {EnergyModelsX: Flexible Energy Systems Modelling with Multiple Dispatch},
  author = {Hellemo, Lars and B{\o}dal, Espen Flo and Holm, Sigmund Eggen and Pinel, Dimitri and Straus, Julian},
  journal = {Journal of Open Source Software},
  volume = {9},
  number = {97},
  pages = {6619},
  year = {2024},
  doi = {https://doi.org/10.21105/joss.06619},
}
```

## Project Funding

The development of `EnergyModelsLanguageInterfaces` was funded by the European Union’s Horizon Europe research and innovation programme in the project [iDesignRES](https://idesignres.eu/) under grant agreement [101095849](https://doi.org/10.3030/101095849).
