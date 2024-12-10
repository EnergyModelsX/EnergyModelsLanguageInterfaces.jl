# [Contribute to EnergyModelsUtilities](@id how_to-con)

Contributing to `EnergyModelsUtilities` can be achieved in several different ways.

## [File a bug report](@id how_to-con-bug_rep)

An approach to contributing to `EnergyModelsUtilities` is through filing a bug report as an *[issue](https://gitlab.sintef.no/idesignres/wp-2/energymodelsutilities.jl/-/issues/new)* when unexpected behaviour is occuring.

When filing a bug report, please follow the following guidelines:

1. Be certain that the bug is a bug and originating in `EnergyModelsUtilities`:
    - If the problem is within the results of the optimization problem, please check first that the nodes are correctly linked with each other.
      Frequently, missing links (or wrongly defined links) restrict the transport of energy/mass.
      If you are certain that all links are set correctly, it is most likely a bug in `EnergyModelsUtilities` and should be reported.
    - If the problem occurs in model construction, it is most likely a bug in either `EnergyModelsBase` or `EnergyModelsUtilities` and should be reported in the respective package.
      The error message of Julia should provide you with the failing function and whether the failing function is located in `EnergyModelsBase` or `EnergyModelsUtilities`.
      It can occur, that the last shown failing function is within `JuMP` or `MathOptInterface`.
      In this case, it is best to trace the error to the last called `EnergyModelsBase` or `EnergyModelsUtilities` function.
    - If the problem is only appearing for specific solvers, it is most likely not a bug in `EnergyModelsUtilities`, but instead a problem of the solver wrapper for `MathOptInterface`.
      In this case, please contact the developers of the corresponding solver wrapper.
2. Label the issue as bug, and
3. Provide a minimum working example of a case in which the bug occurs.

## [Feature requests](@id how_to-con-feat_req)

`EnergyModelsUtilities` includes several new potential constraints utilizing developed types that can be utilized for new nodal descriptions.
It is however always possible to think of new subtypes or types for a given nodal description.
In this case, you can contribute through a feature request.

Feature requests for `EnergyModelsUtilities` should follow the guidelines developed for [`EnergyModelsBase`](https://energymodelsx.github.io/EnergyModelsBase.jl/stable/how-to/contribute/).

!!! tip "Development of new types and functionality"
    In general, new types or functionality are best tested by implementing them in a package in which they are required.
    In this case, if you believe that these new types or functionality may be relevant for several other packages, we ask you to create an *[issue](https://gitlab.sintef.no/idesignres/wp-2/energymodelsutilities.jl/-/issues/new)* with

    1. a link to the implementation,
    2. a description of its benefits, and
    3. ideas regarding the implementation.

    It is crucial that provided tests work without having to load a different package.
    This can be achieved through types that are only introduced in the testsets.
