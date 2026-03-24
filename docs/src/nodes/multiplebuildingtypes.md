# [Multiple building types sink node](@id nodes-MultipleBuildingTypes)

The [`MultipleBuildingTypes`](@ref) node creates sinks for all demand resources with penalties for both surplus and deficit.
The implementation uses `Dict` structures for the fields `cap`, `penalty_surplus`, and `penalty_deficit` to facilitate multiple [Resource](@extref EnergyModelsBase.Resource)s.
This approach allows modeling building demands with flexible penalty mechanisms for over- and under-supply.
The type is also used to enable a specialized constructor that samples the [`Tecnalia_Building-Stock-Energy-Model`](https://github.com/iDesignRES/Tecnalia_Building-Stock-Energy-Model) module.

!!! note "Sampling Tecnalia_Building-Stock-Energy-Model module"
    To use the [constructor](@ref lib-pub-sampling_constructors) for [`MultipleBuildingTypes`](@ref) that samples the [`Tecnalia_Building-Stock-Energy-Model`](https://github.com/iDesignRES/Tecnalia_Building-Stock-Energy-Model) module, follow the installation in the [Use nodes](@ref how_to-utilize-use_nodes) section.

!!! danger
    Investments are currently not available for this node.

## [Introduced type and its field](@id nodes-MultipleBuildingTypes-fields)

The [`MultipleBuildingTypes`](@ref) is a subtype of [`Sink`](@extref EnergyModelsBase.Sink) and is implemented as a specialized sink node.
Hence, it utilizes the same functions declared in `EnergyModelsBase`.

### [Standard fields](@id nodes-MultipleBuildingTypes-fields-stand)

Standard fields of a [`MultipleBuildingTypes`](@ref) node are given as:

- **`id`**:\
  The field `id` is only used for providing a name to the node.
  This is similar to the approach utilized in `EnergyModelsBase`.
- **`input::Dict{<:Resource, <:Real}`**:\
  The field `input` includes [`Resource`](@extref EnergyModelsBase.Resource)s with their corresponding conversion factors as dictionaries.
  All values have to be non-negative.
- **`data::Vector{Data}`**:\
  An entry for providing additional data to the model.
  In the current version, it is not applicable. We intend to change this in future releases to enable investments.

  !!! note "Constructor for `MultipleBuildingTypes`"
      The field `data` is not required as we include a constructor when the value is excluded.

  !!! danger "Using `CaptureData`"
      As a `Sink` node does not have any output, it is not possible to utilize `CaptureData`.
      If you still plan to specify it, you will receive an error in the model building.

### [Additional fields](@id nodes-MultipleBuildingTypes-fields-new)

[`MultipleBuildingTypes`](@ref) nodes introduce additional fields for demand and penalty specifications:

- **`cap::Dict{<:Resource,<:TimeProfile}`**:\
  The demand capacity for each of the input resources.
  All values have to be non-negative.
- **`penalty_surplus::Dict{<:Resource,<:TimeProfile}`**:\
  The penalties applied for surplus (over-supply) for each of the input resources.
  These penalties are added to the variable operating expenses.
  All values have to be non-negative.
- **`penalty_deficit::Dict{<:Resource,<:TimeProfile}`**:\
  The penalties applied for deficit (under-supply) for each of the input resources.
  These penalties are added to the variable operating expenses.
  All values have to be non-negative.

## [Mathematical description](@id nodes-MultipleBuildingTypes-math)

In the following mathematical equations, we use the name for variables and functions used in the model.
Variables are in general represented as

``\texttt{var\_example}[index_1, index_2]``

with square brackets, while functions are represented as

``func\_example(index_1, index_2)``

with parantheses.

### [Variables](@id nodes-MultipleBuildingTypes-math-var)

#### [Standard variables](@id nodes-MultipleBuildingTypes-math-var-stand)

The [`MultipleBuildingTypes`](@ref) node type utilizes standard variables from the [`Sink`](@extref EnergyModelsBase.Sink) node type and includes:

- [``\texttt{opex\_var}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{opex\_fixed}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{flow\_in}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{sink\_surplus}``](@extref EnergyModelsBase man-opt_var-sink): Declared as the total surplus aggregated across all resources.
- [``\texttt{sink\_deficit}``](@extref EnergyModelsBase man-opt_var-sink): Declared as the total surplus aggregated across all resources.
- [``\texttt{emissions\_node}``](@extref EnergyModelsBase man-opt_var-emissions) if `EmissionsData` is added to the field `data`

!!! note "cap\_use and cap\_inst"
    A `MultipleBuildingTypes` has an individual capacity for all its resources, that is each `Resource` has its own capacity which must be satisfied.
    As a consequence, the standard variables [``\texttt{cap\_use}``](@extref EnergyModelsBase man-opt_var-cap) and  [``\texttt{cap\_use}``](@extref EnergyModelsBase man-opt_var-cap) are not defined for [`MultipleBuildingTypes`](@ref) nodes through a new method for the function [`has_capacity`](@ref EnergyModelsBase.capacity).

#### [Additional variables](@id nodes-MultipleBuildingTypes-math-add)

[`MultipleBuildingTypes`](@ref) introduces the following variables:

- ``\texttt{buildings\_surplus}[n, t, p]``: Surplus (over-supply) for node ``n`` in operational period ``t`` for resource ``p``.
- ``\texttt{buildings\_deficit}[n, t, p]``: Deficit (under-supply) for node ``n`` in operational period ``t`` for resource ``p``.
- ``\texttt{sink\_surplus}[n, t]``: Total surplus aggregated across all resources.
- ``\texttt{sink\_deficit}[n, t]``: Total deficit aggregated across all resources.

### [Constraints](@id nodes-MultipleBuildingTypes-math-con)

The following sections omit the direct inclusion of the vector of [`MultipleBuildingTypes`](@ref) nodes.
Instead, it is implicitly assumed that the constraints are valid ``\forall n ∈ N^{\text{MultipleBuildingTypes}}`` if not stated differently.
In addition, all constraints are valid ``\forall t \in T`` (that is in all operational periods) or ``\forall t_{inv} \in T^{Inv}`` (that is in all strategic periods).
Finally, all constraints are valid ``\forall p \in inputs(n)`` (that is in all input resources).

#### [Standard constraints](@id nodes-MultipleBuildingTypes-math-con-stand)

[`MultipleBuildingTypes`](@ref) nodes utilize the following standard constraint functions:

- `constraints_opex_fixed`:\
  The current implementation fixes the fixed operating expenses of a sink to 0.

  ```math
  \texttt{opex\_fixed}[n, t_{inv}] = 0
  ```

- `constraints_ext_data`:\
  This function is only called for specified additional data, see above.

The function `constraints_capacity` is extended with a new method to account for the multiple inputs that must be satisfied within this `Sink` node:

```math
\frac{\texttt{flow\_in}[n, t, p]}{inputs(n, p)} + \texttt{buildings\_deficit}[n, t, p] =
capacity(n, t, p) + \texttt{buildings\_surplus}[n, t, p]
\qquad \forall p \in inputs(n)
```

```math
\texttt{sink\_deficit}[n, t] = \texttt{buildings\_deficit}[n, t, p]
```

```math
\texttt{sink\_surplus}[n, t] = \texttt{buildings\_surplus}[n, t, p]
```

The function `constraints_flow_in` is extended with a new method that does not add any constraint.

The function `constraints_capacity_installed` is not called within `constraints_capacity`.
Thus, the node does not support investments.

The function `constraints_opex_var` is extended with a new method to allow for individual penalties for the different demands.

```math
\texttt{opex\_var}[n, t_{inv}] = \sum_{t \in t_{inv},\, p \in inputs(n)}
\left(
\texttt{buildings\_surplus}[n, t, p] \times penalty\_surplus(n, t, p) +
\texttt{buildings\_deficit}[n, t, p] \times penalty\_deficit(n, t, p)
\right) \times scale\_op\_sp(t_{inv}, t)
```

!!! tip "The function `scale_op_sp`"
    The function [``scale\_op\_sp(t_{inv}, t)``](@extref EnergyModelsBase.scale_op_sp) calculates the scaling factor between operational and strategic periods.
    It also takes into account potential operational scenarios and their probability as well as representative periods.


#### [Additional constraints](@id nodes-MultipleBuildingTypes-math-con-add)

[`MultipleBuildingTypes`](@ref) nodes do not add additional constraints.
