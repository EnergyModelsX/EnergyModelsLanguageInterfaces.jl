"""
    EMB.variables_node(m, 𝒩::Vector{MultipleBuildingTypes}, 𝒯, ::EnergyModel)

For a [`MultipleBuildingTypes`](@ref) node, the following variables are created:
- `buildings_surplus[n, t, p]` is the surplus of node `n` with resource `p` in operational period `t`.
- `buildings_deficit[n, t, p]` is the surplus of node `n` with resource `p` in operational period `t`.
"""
function EMB.variables_node(m, 𝒩::Vector{MultipleBuildingTypes}, 𝒯, ::EnergyModel)

    # Declaration of the required subsets.
    𝒫 = unique([p for n ∈ 𝒩 for p ∈ inputs(n)])

    @variable(m, buildings_surplus[𝒩, 𝒯, 𝒫] >= 0)
    @variable(m, buildings_deficit[𝒩, 𝒯, 𝒫] >= 0)
end

"""
    EMB.variables_node(m, 𝒩::Vector{CSPandPV}, 𝒯, ::EnergyModel)

For a [`CSPandPV`](@ref) node, the following variables are created:
    - `solar_curtailment[n, t, p]` is the curtailment of node `n` with resource `p` in operational period `t`.
    - `solar_cap_use[n, t, p]` is the capacity utilization of node `n` with resource `p` in operational period `t`.
    - `solar_cap_inst[n, t, p]` is the installed capacity of node `n` with resource `p` in operational period `t`.
"""
function EMB.variables_node(m, 𝒩::Vector{CSPandPV}, 𝒯, ::EnergyModel)

    # Declaration of the required subsets.
    𝒫 = unique([p for n ∈ 𝒩 for p ∈ outputs(n)])

    @variable(m, solar_curtailment[𝒩, 𝒯, 𝒫] ≥ 0)
    @variable(m, solar_cap_use[𝒩, 𝒯, 𝒫] ≥ 0)
end
