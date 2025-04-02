# EnergyModelsLanguageInterfaces

```@docs
EnergyModelsLanguageInterfaces
```

This Julia package implements additional utilities that can be used in combination with [`EnergyModelsX`](https://energymodelsx.github.io).

These utilities do not directly incorporate new technology descriptions.
They can be instead added to your technology type and included in a [`create_node`](@extref EnergyModelsBase.create_node) method for your new types.
You can also use the utility functions in both pre-processing and model building.

## Manual outline

```@contents
Pages = [
    "manual/quick-start.md",
    "manual/simple-example.md",
    "manual/NEWS.md",
]
Depth = 1
```

## Description of the new types

```@contents
Pages = [
    "types/reference.md",
]
Depth = 1
```

## Utility functions

```@contents
Pages = [
    "util-fun/reference.md",
]
Depth = 1
```

## How to guides

```@contents
Pages = [
    "how-to/contribute.md",
    "how-to/utilize.md",
]
Depth = 1
```

## Library outline

```@contents
Pages = [
    "library/public.md",
    "library/internals/types-EMLI.md",
    "library/internals/methods-fields.md",
    "library/internals/methods-EMLI.md",
    "library/internals/methods-EMB.md",
]
Depth = 1
```
