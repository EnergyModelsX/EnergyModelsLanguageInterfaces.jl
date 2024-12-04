# EnergyModelsUtilities.jl

```@docs
EnergyModelsUtilities
```

**EnergyModelsX** is an operational, multi nodal energy system framework, written in Julia.
The model is based on the [`JuMP`](https://jump.dev/JuMP.jl/stable/) optimization framework.
It is a multi carrier energy model, where the definition of the resources are fully up to the user of the model.
One of the primary design goals was to develop a model that can eaily be extended with new functionality without the need to understand and remember every variable and constraint in the model.

EnergyModelsUtilities provides utilities to this framework.

## Manual outline

```@contents
Pages = [
    "manual/philosophy.md",
    "manual/NEWS.md",
]
Depth = 1
```

## How to guides

```@contents
Pages = [
    "how-to/call_python_functions.md",
    "how-to/call_Cpp_functions.md",
]
Depth = 1
```

## Library outline

```@contents
Pages = [
    "library/public.md",
    "library/internals/reference.md",
]
Depth = 1
```
