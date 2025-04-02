# [Quick Start](@id man-quick_start)

1. Install the most recent version of [Julia](https://julialang.org/downloads/)
2. Install the package [`EnergyModelsLanguageInterfaces`](https://github.com/EnergyModelsX/EnergyModelsLanguageInterfaces.jl) by running:

   ```julia
   ] add EnergyModelsLanguageInterfaces
   ```

3. If you plan to create new element descriptions from the sampled data, you also must install the package [`EnergyModelsBase`](https://energymodelsx.github.io/EnergyModelsBase.jl/) and the time package [`TimeStruct`](https://sintefore.github.io/TimeStruct.jl/) by running:

   ```julia
   ] add EnergyModelsBase
   ] add TimeStruct
   ```

!!! note
    If you receive the error that `EnergyModelsLanguageInterfaces` is not yet registered, you have to add the package using the GitHub repositories through `] add https://github.com/EnergyModelsX/EnergyModelsLanguageInterfaces.jl`.
    Once the package is registered, this is not required.
