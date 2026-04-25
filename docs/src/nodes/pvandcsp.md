# [PV and CSP source node](@id nodes-CSPandPV)

PV and CSP source nodes can generate multiple different resources simultaneously.
The standard approach would be to include electricity and heat from solar power, both *via* solar PV and concentrated solar power.
The implementation of the node is hence similar to that of [`NonDisRES`](@extref EnergyModelsRenewableProducers nodes-nondisres) but uses dictionaries for the fields `cap`, `profile`, `opex_var` and `opex_fixed` to facilitate multiple [`Resource`](@extref EnergyModelsBase.Resource)s (both electricity and heat outputs).
The type is also used to enable a specialized constructor that samples the [Tecnalia_Solar-Energy-Model](https://github.com/iDesignRES/Tecnalia_Solar-Energy-Model) module.

!!! note "Sampling Tecnalia_Solar-Energy-Model module"
    To use the [constructor](@ref lib-pub-sampling_constructors) for [`CSPandPV`](@ref) that samples the [Tecnalia_Solar-Energy-Model](https://github.com/iDesignRES/Tecnalia_Solar-Energy-Model) module, follow the installation in the [Use nodes](@ref how_to-utilize-use_nodes) section.

!!! danger
    Investments are currently not available for this node.

## [Introduced type and its field](@id nodes-CSPandPV-fields)

The [`CSPandPV`](@ref) is a subtype of [`AbstractNonDisRES`](@extref EnergyModelsRenewableProducers.AbstractNonDisRES) (the same is the case for [NonDisRES](@extref EnergyModelsRenewableProducers nodes-nondisres)) and is thus implemented as equivalent to a [`RefSource`](@extref EnergyModelsBase.RefSource).
Hence, it utilizes the same functions declared in `EnergyModelsBase`.

### [Standard fields](@id nodes-CSPandPV-fields-stand)

Standard fields (of an [`AbstractNonDisRES`](@extref EnergyModelsRenewableProducers.AbstractNonDisRES)) being reused are given as:

- **`id`**:\
  The field `id` is only used for providing a name to the node.
  This is similar to the approach utilized in `EnergyModelsBase`.
- **`output::Dict{<:Resource, <:Real}`**:\
  The field `output` includes [`Resource`](@extref EnergyModelsBase.Resource)s with their corresponding conversion factors as dictionaries.
  In the case of a PV and CSP energy source, `output` should always include your *electricity* resource and a *heat* resource. In practice, you should use a value of 1.\
  All values have to be non-negative.
- **`data::Vector{<:ExtensionData}`**:\
  An entry for providing additional data to the model.
  In the current version, it is not applicable. We intend to change this in future releases to enable investments.

  !!! note "Constructor for `CSPandPV`"
      The field `data` is not required as we include a constructor when the value is excluded.

### [Additional fields](@id nodes-CSPandPV-fields-new)

[`CSPandPV`](@ref) nodes alter the types of some fields compared to a [`AbstractNonDisRES`](@extref EnergyModelsRenewableProducers.AbstractNonDisRES):

- **`cap::Dict{<:Resource,<:TimeProfile}`**:\
  The installed capacity corresponds to the nominal capacity of the node for each of the produced resources.\
  If the node should contain investments through the application of [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/stable/), it is important to note that you can only use `FixedProfile` or `StrategicProfile` for the capacity, but not `RepresentativeProfile` or `OperationalProfile`.
  In addition, all values have to be non-negative.
- **`profile::Dict{<:Resource,<:TimeProfile}`**:\
  The profiles are used as a multiplier to the installed capacity to represent the maximum actual capacity in each operational period for each of the produced resources.
  The profiles should be provided as `OperationalProfile` or at least as `RepresentativeProfile`.
  In addition, all values should be in the range ``[0, 1]``.
- **`opex_var::Dict{<:Resource,<:TimeProfile}`**:\
  The variable operating expenses are based on the capacity utilization through the variable [`:cap_use`](@extref EnergyModelsBase man-opt_var-cap) for each of the produced resources.
  Hence, it is directly related to the specified `output` ratios.
  The variable operating expenses can be provided as `OperationalProfile` as well.
- **`opex_fixed::Dict{<:Resource,<:TimeProfile}`**:\
  The fixed operating expenses are relative to the installed capacity (through the field `cap`) for each of the produced resources and the chosen duration of a strategic period as outlined on *[Utilize `TimeStruct`](@extref EnergyModelsBase how_to-utilize_TS)*.\
  It is important to note that you can only use `FixedProfile` or `StrategicProfile` for the fixed OPEX, but not `RepresentativeProfile` or `OperationalProfile`.
  In addition, all values have to be non-negative.

## [Mathematical description](@id nodes-CSPandPV-math)

In the following mathematical equations, we use the name for variables and functions used in the model.
Variables are in general represented as

``\texttt{var\_example}[index_1, index_2]``

with square brackets, while functions are represented as

``func\_example(index_1, index_2)``

with parantheses.

### [Variables](@id nodes-CSPandPV-math-var)

#### [Standard variables](@id nodes-CSPandPV-math-var-stand)

The PV and CSP source node types utilize all standard variables from the [`AbstractNonDisRES`](@extref EnergyModelsRenewableProducers.AbstractNonDisRES) node type.
The variables include:

- [``\texttt{opex\_var}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{opex\_fixed}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{cap\_inst}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{flow\_out}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{emissions\_node}``](@extref EnergyModelsBase man-opt_var-emissions) if `EmissionsData` is added to the field `data`.
- [``\texttt{curtailment}[n, t]``](@extref EnergyModelsRenewableProducers nodes-nondisres-math-add): For [`CSPandPV`](@ref), this variable is the sum of curtailed energy (as rate) of source ``n`` in operational period ``t``.\

!!! note
    Non-dispatchable renewable energy source nodes are not compatible with `CaptureData`.
    Hence, you can only provide [`EmissionsProcess`](@extref EnergyModelsBase.EmissionsProcess) to the node.
    It is our aim to include the potential for construction emissions in a latter stage

#### [Additional variables](@id nodes-CSPandPV-math-add)

[`CSPandPV`](@ref) replaces the variables [``\texttt{cap\_use}``](@extref EnergyModelsBase man-opt_var-cap) and [``\texttt{curtailment}``](@extref EnergyModelsRenewableProducers nodes-nondisres-math-add) variables with the following variables

- ``\texttt{solar\_cap\_use}[n, t, p]``: The capacity usage of source ``n`` in operational period ``t`` for resource ``p``.
- ``\texttt{solar\_curtailment}[n, t, p]``: Curtailed capacity of source ``n`` in operational period ``t`` for resource ``p`` with a typical unit of MW.\
  The curtailed resources specifies the unused generation capacity of sources.
  It is currently only used in the calculation, but not with a cost.

### [Constraints](@id nodes-CSPandPV-math-con)

The following sections omit the direct inclusion of the vector of PV and CSP source nodes.
Instead, it is implicitly assumed that the constraints are valid ``\forall n ∈ N^{\text{CSPandPV}\_source}`` for all [`CSPandPV`](@ref) types if not stated differently.
In addition, all constraints are valid ``\forall t \in T`` (that is in all operational periods) or ``\forall t_{inv} \in T^{Inv}`` (that is in all strategic periods).
Finally, all constraints are valid ``\forall p \in outputs(n)`` (that is in all output resources).

#### [Standard constraints](@id nodes-CSPandPV-math-con-stand)

[`CSPandPV`](@ref) nodes utilize specialized constraint functions that extend the standard approach to accommodate multiple resources with per-resource tracking.
These constraints are:

- `constraints_capacity`:

  ```math
  \texttt{solar\_cap\_use}[n, t, p] \leq capacity(n, t, p)
  ```

  ```math
  \texttt{solar\_cap\_use}[n, t, p] + \texttt{solar\_curtailment}[n, t, p] =
  profile(n, t, p) \times capacity(n, t, p)
  \qquad \forall p \in outputs(n)
  ```

  ```math
  \sum_{p \in outputs(n)} \texttt{solar\_curtailment}[n, t, p] = \texttt{curtailment}[n, t]
  ```

  !!! note "constraints_capacity_installed"
      The function `constraints_capacity_installed` is not used and the node thus currently does not support investments.

- `constraints_flow_out`:

  ```math
  \texttt{flow\_out}[n, t, p] =
  \texttt{solar\_cap\_use}[n, t, p] \times outputs(n, p)
  \qquad \forall p \in outputs(n) \setminus \{\text{CO}_2\}
  ```

- `constraints_opex_fixed`:

  ```math
  \texttt{opex\_fixed}[n, t_{inv}] = \sum_{p \in outputs(n)} opex\_fixed(n, t_{inv}, p) \times capacity(n, first(t_{inv}), p)
  ```

- `constraints_opex_var`:

  ```math
  \texttt{opex\_var}[n, t_{inv}] = \sum_{t \in t_{inv},\, p \in outputs(n)} \texttt{solar\_cap\_use}[n, t, p] \times opex\_var(n, t, p) \times scale\_op\_sp(t_{inv}, t)
  ```

- `constraints_data`:\
  This function is only called for specified data of the node, see above.

#### [Additional constraints](@id nodes-CSPandPV-math-con-add)

[`CSPandPV`](@ref) nodes do not add additional constraints.
