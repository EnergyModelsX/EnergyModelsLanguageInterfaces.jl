# [Contribute to EnergyModelsLanguageInterfaces](@id how_to-con)

Contributing to `EnergyModelsLanguageInterfaces` can be achieved in several different ways.

## [File a bug report](@id how_to-con-bug_rep)

An approach to contributing to `EnergyModelsLanguageInterfaces` is through filing a bug report as an *[issue](https://github.com/EnergyModelsX/EnergyModelsLanguageInterfaces.jl/issues/new)* when unexpected behaviour is occuring.

When filing a bug report, please follow the following guidelines:

1. Be certain that the bug is a bug and originating in `EnergyModelsLanguageInterfaces`:
    - If the problem is within the results of the optimization problem, please check first that the nodes are correctly linked with each other.
      Frequently, missing links (or wrongly defined links) restrict the transport of energy/mass.
      If you are certain that all links are set correctly, it is most likely a bug in `EnergyModelsLanguageInterfaces` and should be reported.
    - If the problem occurs in model construction, it is most likely a bug in either `EnergyModelsBase` or `EnergyModelsLanguageInterfaces` and should be reported in the respective package.
      The error message of Julia should provide you with the failing function and whether the failing function is located in `EnergyModelsBase` or `EnergyModelsLanguageInterfaces`.
      It can occur, that the last shown failing function is within `JuMP` or `MathOptInterface`.
      In this case, it is best to trace the error to the last called `EnergyModelsBase` or `EnergyModelsLanguageInterfaces` function.
    - If the problem is only appearing for specific solvers, it is most likely not a bug in `EnergyModelsLanguageInterfaces`, but instead a problem of the solver wrapper for `MathOptInterface`.
      In this case, please contact the developers of the corresponding solver wrapper.
2. Label the issue as bug, and
3. Provide a minimum working example of a case in which the bug occurs.

## [Feature requests](@id how_to-con-feat_req)

`EnergyModelsLanguageInterfaces` includes sampling functionanility for both models written in Python and C++.
This functionality is specific for the given package and we thrive to include all potential interfaces to other languages within a single package.
Hence, if you think changes to the interfaces are beneficial, or would like to provide new interfaces, please file an *[issue](https://github.com/EnergyModelsX/EnergyModelsLanguageInterfaces.jl/issues/new)*.

Feature requests for `EnergyModelsLanguageInterfaces` should follow the guidelines developed for [`EnergyModelsBase`](https://energymodelsx.github.io/EnergyModelsBase.jl/stable/how-to/contribute/).
