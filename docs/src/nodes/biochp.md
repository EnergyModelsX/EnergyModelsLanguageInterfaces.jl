# [BioCHP](@id nodes-BioCHP)

The [`BioCHP`](@ref) node represents a biomass-fired combined heat and power (CHP) plant.

!!! note "Sampling CHP_modelling module"
    To use the constructor that samples the [CHP_modelling](https://github.com/iDesignRES/CHP_modelling) module, follow the installation in the [Use nodes](@ref how_to-utilize-use_nodes) section.

The `BioCHP` utilizes linear, time-independent conversion rates from the `input` [`Resource`](@extref EnergyModelsBase.Resource)s to the `output` [`Resource`](@extref EnergyModelsBase.Resource)s, subject to the available capacity.
The capacity is normalized such that a conversion value of 1 corresponds to the nominal capacity in the fields `input` and `output`.

Compared to a standard [`NetworkNode`](@extref EnergyModelsBase.NetworkNode), `BioCHP` differs in its outlet-flow constraints:
the produced heat does not have to be used (e.g., heat outputs are allowed to be zero), while electric output is enforced according to the given conversion factor.

## [Introduced types and their fields](@id nodes-BioCHP-fields)

The [`BioCHP`](@ref) is a subtype of the [`NetworkNode`](@extref EnergyModelsBase.NetworkNode).
It uses the standard `NetworkNode` functions from `EnergyModelsBase`.

### [Standard fields](@id nodes-BioCHP-fields-stand)

- **`id`**:\
  The field `id` is only used for providing a name to the node.
  This is similar to the approach utilized in `EnergyModelsBase`.

- **`cap::TimeProfile`**:\
  Specifies the installed capacity, that is the heat the heat pump can deliver.\
  If the node should contain investments through the application of [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/stable/), it is important to note that you can only use `FixedProfile` or `StrategicProfile` for the capacity, but not `RepresentativeProfile` or `OperationalProfile`.\
  In addition, all values have to be non-negative.

- **`opex_var::TimeProfile`**:\
  The variable operational expenses are based on the capacity utilization through the variable [`:cap_use`](@extref EnergyModelsBase man-opt_var-cap).
  Hence, it is directly related to the specified `output` ratios.
  The variable operating expenses can be provided as `OperationalProfile` as well.

- **`opex_fixed::TimeProfile`**:\
  The fixed operating expenses are relative to the installed capacity (through the field `cap`) and the chosen duration of a strategic period as outlined on *[Utilize `TimeStruct`](@extref EnergyModelsBase how_to-utilize_TS)*.\
  It is important to note that you can only use `FixedProfile` or `StrategicProfile` for the fixed OPEX, but not `RepresentativeProfile` or `OperationalProfile`.
  In addition, all values have to be non-negative.

- **`output::Dict{<:Resource, <:Real}`**:\
  The field `output` includes the output [`Resource`](@extref EnergyModelsBase.Resource)s with their corresponding conversion factors as dictionaries.
  It is also possible to include other resources which are produced with a given correlation with the heat.\
  All values have to be non-negative.

- **`data::Vector{<:ExtensionData}`**:\
  An entry for providing additional data to the model.
  In the current version, it is only relevant for additional investment data when [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/) is used or for additional emission data through [`EmissionsProcess`](@extref EnergyModelsBase.EmissionsProcess).
  The latter would correspond to uncaptured CO₂ that should be included in the analyses.
  !!! note
      The field `data` is not required as we include a constructor when the value is excluded.

### [New fields](@id nodes-BioCHP-fields-new)

- **`electricity_resource::Resource`**:\
  The electric power resource produced by the CHP plant.
  This field is used to distinguish electricity from (potential) heat outputs in the outlet-flow constraints.

- **`input::Dict{<:ResourceBio, <:Real}`**:\
  The biomass input resources (of type [`ResourceBio`](@ref)) and their conversion factors.
  These conversion factors are normalized to the capacity definition of the node.

!!! note "Default `data` constructor"
    The provided constructor assigns `data = [EmissionsEnergy()]` by default.
    This means the node includes energy-based emission accounting unless overwritten by explicitly constructing `BioCHP` with a custom `data` vector.

## [Mathematical description](@id nodes-BioCHP-math)

In the following mathematical equations, we use the names for variables and functions used in the model.
Variables are in general represented as

``\texttt{var\_example}[index_1, index_2]``

with square brackets, while functions are represented as

``func\_example(index_1, index_2)``

with paranthesis.

### [Variables](@id nodes-BioCHP-math-var)

The [`BioCHP`](@ref) node uses standard `NetworkNode` variables, as described on the page *[Optimization variables](@extref EnergyModelsBase man-opt_var)*.
The variables include:

- [``\texttt{opex\_var}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{opex\_fixed}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{cap\_use}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{cap\_inst}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{flow\_in}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{flow\_out}``](@extref EnergyModelsBase man-opt_var-flow)

### [Constraints](@id nodes-BioCHP-math-con)

The following sections omit the direct inclusion of the vector of heat pump nodes.
Instead, it is implicitly assumed that the constraints are valid ``\forall n ∈ N^{BioCHP}`` for all [`BioCHP`](@ref) types if not stated differently.
In addition, all constraints are valid ``\forall t \in T`` (that is in all operational periods) or ``\forall t_{inv} \in T^{Inv}`` (that is in all strategic periods).

#### [Standard constraints](@id nodes-BioCHP-math-con-stand)

`BioCHP` nodes utilize in general the standard constraints described on
*[Constraint functions](@extref EnergyModelsBase man-con)* for `NetworkNode`s.
These standard constraints are:

- `constraints_capacity`:

  ```math
  \texttt{cap\_use}[n, t] \leq \texttt{cap\_inst}[n, t]
  ```

- `constraints_capacity_installed`:

  ```math
  \texttt{cap\_inst}[n, t] = capacity(n, t)
  ```

  !!! tip "Using investments"
      The function `constraints_capacity_installed` is also used in [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/) to incorporate the potential for investment.
      Nodes with investments are then no longer constrained by the parameter capacity.

- `constraints_flow_out`:

  ```math
  \texttt{flow\_out}[n, t, p] =
  outputs(n, p) \times \texttt{cap\_use}[n, t]
  \qquad \forall p \in outputs(n) \setminus \{\text{CO}_2\}
  ```

- `constraints_opex_fixed`:

  ```math
  \texttt{opex\_fixed}[n, t_{inv}] = opex\_fixed(n, t_{inv}) \times \texttt{cap\_inst}[n, first(t_{inv})]
  ```

  !!! tip "Why do we use `first()`"
      The variable ``\texttt{cap\_inst}`` is declared over all operational periods (see the section on *[Capacity variables](@extref EnergyModelsBase man-opt_var-cap)* for further explanations).
      Hence, we use the function ``first(t_{inv})`` to retrieve the installed capacity in the first operational period of a given strategic period ``t_{inv}`` in the function `constraints_opex_fixed`.

- `constraints_opex_var`:

  ```math
  \texttt{opex\_var}[n, t_{inv}] = \sum_{t \in t_{inv}} opex\_var(n, t) \times \texttt{cap\_use}[n, t] \times scale\_op\_sp(t_{inv}, t)
  ```

  !!! tip "The function `scale_op_sp`"
      The function [``scale\_op\_sp(t_{inv}, t)``](@extref EnergyModelsBase.scale_op_sp) calculates the scaling factor between operational and strategic periods.
      It also takes into account potential operational scenarios and their probability as well as representative periods.

- `constraints_ext_data`:\
  This function is only called for specified data of the storage node, see above.

The function `constraints_flow_out` is extended with a new method for BioCHP nodes such that the outputs are flexible with respect to output resources not being the `electricity_resource`.

Let ``\mathcal{P}^{out}(n)`` denote the set of output resources of node ``n`` excluding CO₂ and `electricity_resource`. The implemented constraint is

```math
\texttt{flow\_out}[n, t, p] = outputs(n, p) \times \texttt{cap\_use}[n, t] \qquad \forall p \in \mathcal{P}^{out}(n)
```

For the `electricity_resource` we still have

```math
\texttt{flow\_out}[n, t, electricity_resource(n)] = outputs(n, electricity_resource(n)) \times \texttt{cap\_use}[n, t]
```

#### [Additional constraints](@id nodes-BioCHP-math-con-add)

[`BioCHP`](@ref) nodes do not add additional constraint functions or constraints in the `create_node` function.
