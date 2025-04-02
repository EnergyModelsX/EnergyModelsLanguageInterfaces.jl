# [Quick Start](@id man-quick_start)

1. Install the most recent version of [Julia](https://julialang.org/downloads/)
2. Install the package [`EnergyModelsBase`](https://energymodelsx.github.io/EnergyModelsBase.jl/) and the time package [`TimeStruct`](https://sintefore.github.io/TimeStruct.jl/), by running:

   ```julia
   ] add TimeStruct
   ] add EnergyModelsBase
   ```

   These packages are required as we do not only use them internally, but also for building a model.
3. Install the package [`EnergyModelsLanguageInterfaces`](https://gitlab.sintef.no/idesignres/wp-2/EnergyModelsLanguageInterfaces.jl).
   As the package is not registered, you need to first clone the package to the folder you want to have it using

   ```bash
   git clone git@gitlab.sintef.no:idesignres/wp-2/EnergyModelsLanguageInterfaces.jl.git
   ```

   and subsequently

   ```julia
   ] dev *directory-of-the-package*
   ```
