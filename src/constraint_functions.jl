"""
    EMB.constraints_capacity(m, n::MultipleBuildingTypes, 𝒯::TimeStructure, modeltype::EnergyModel)

Function for creating the constraints on the maximum capacity of a
[`MultipleBuildingTypes`](@ref) node.
"""
function EMB.constraints_capacity(
    m,
    n::MultipleBuildingTypes,
    𝒯::TimeStructure,
    ::EnergyModel,
)
    𝒫ⁱⁿ = inputs(n)
    @constraint(m, [t ∈ 𝒯, p ∈ 𝒫ⁱⁿ],
        m[:flow_in][n, t, p] / inputs(n, p) + m[:buildings_deficit][n, t, p] ==
        EMB.capacity(n, t, p) + m[:buildings_surplus][n, t, p]
    )

    # Define sink_deficit and sink_surplus
    @constraint(
        m,
        [t ∈ 𝒯],
        sum(m[:buildings_deficit][n, t, p] for p ∈ 𝒫ⁱⁿ) == m[:sink_deficit][n, t]
    )
    @constraint(
        m,
        [t ∈ 𝒯],
        sum(m[:buildings_surplus][n, t, p] for p ∈ 𝒫ⁱⁿ) == m[:sink_surplus][n, t]
    )
end

"""
    EMB.constraints_capacity(m, n::CSPandPV, 𝒯::TimeStructure, ::EnergyModel)

Function for creating the constraint on the maximum capacity of a [`CSPandPV`](@ref) node.
Also sets the constraint on the curtailment.
"""
function EMB.constraints_capacity(m, n::CSPandPV, 𝒯::TimeStructure, ::EnergyModel)

    # Declaration of the required subsets.
    𝒫 = outputs(n)

    @constraint(m, [t ∈ 𝒯, p ∈ 𝒫],
        m[:solar_cap_use][n, t, p] ≤ EMB.capacity(n, t, p)
    )

    # Non dispatchable renewable energy sources operate at their max
    # capacity with repsect to the current profile (e.g. PV) at every time.
    @constraint(
        m,
        [t ∈ 𝒯, p ∈ 𝒫],
        m[:solar_cap_use][n, t, p] + m[:solar_curtailment][n, t, p] ==
        EMR.profile(n, t, p) * EMB.capacity(n, t, p)
    )

    @constraint(
        m,
        [t ∈ 𝒯],
        sum(m[:solar_curtailment][n, t, p] for p ∈ 𝒫) == m[:curtailment][n, t]
    )
end

"""
    EMB.constraints_flow_in(m, n::MultipleBuildingTypes, 𝒯::TimeStructure, ::EnergyModel)

The constraints on the inlet flow for a [`MultipleBuildingTypes`](@ref) node are implemented
directly in the function `EMB.constraints_capacity`.
"""
function EMB.constraints_flow_in(m, ::MultipleBuildingTypes, ::TimeStructure, ::EnergyModel)
end

"""
    EMB.constraints_flow_out(m, n::CSPandPV, 𝒯::TimeStructure, modeltype::EnergyModel)

Function for creating the constraint on the outlet flow from a [`CSPandPV`](@ref) node.
"""
function EMB.constraints_flow_out(m, n::CSPandPV, 𝒯::TimeStructure, modeltype::EnergyModel)
    # Declaration of the required subsets, excluding CO2, if specified
    𝒫ᵒᵘᵗ = EMB.res_not(outputs(n), co2_instance(modeltype))

    # Constraint for the individual output stream connections
    @constraint(m, [t ∈ 𝒯, p ∈ 𝒫ᵒᵘᵗ],
        m[:flow_out][n, t, p] == m[:solar_cap_use][n, t, p] * outputs(n, p)
    )
end

"""
    EMB.constraints_opex_var(m, n::MultipleBuildingTypes, 𝒯ᴵⁿᵛ, ::EnergyModel)

Function for creating the constraint on the variable OPEX of a [`MultipleBuildingTypes`](@ref)
node.

The variable OPEX is calculate through the penalties for both `surplus` and `deficit` for
each of the individual resource demands.
"""
function EMB.constraints_opex_var(m, n::MultipleBuildingTypes, 𝒯ᴵⁿᵛ, ::EnergyModel)
    @constraint(m, [t_inv ∈ 𝒯ᴵⁿᵛ],
        m[:opex_var][n, t_inv] ==
        sum(
            (
                m[:buildings_surplus][n, t, p] * EMB.surplus_penalty(n, t, p) +
                m[:buildings_deficit][n, t, p] * EMB.deficit_penalty(n, t, p)
            ) * scale_op_sp(t_inv, t) for t ∈ t_inv, p ∈ inputs(n)
        )
    )
end

"""
    EMB.constraints_opex_var(m, n::CSPandPV, 𝒯ᴵⁿᵛ, ::EnergyModel)

Function for creating the constraint on the variable OPEX of a [`CSPandPV`](@ref) node.
"""
function EMB.constraints_opex_var(m, n::CSPandPV, 𝒯ᴵⁿᵛ, ::EnergyModel)
    @constraint(m, [t_inv ∈ 𝒯ᴵⁿᵛ],
        m[:opex_var][n, t_inv] ==
        sum(
            m[:solar_cap_use][n, t, p] * EMB.opex_var(n, t, p) * scale_op_sp(t_inv, t) for
            t ∈ t_inv, p ∈ outputs(n)
        )
    )
end

"""
    EMB.constraints_opex_fixed(m, n::CSPandPV, 𝒯ᴵⁿᵛ, ::EnergyModel)

Function for creating the constraint on the fixed OPEX of a [`CSPandPV`](@ref) node.
"""
function EMB.constraints_opex_fixed(m, n::CSPandPV, 𝒯ᴵⁿᵛ, ::EnergyModel)
    @constraint(m, [t_inv ∈ 𝒯ᴵⁿᵛ],
        m[:opex_fixed][n, t_inv] == sum(
            EMB.opex_fixed(n, t_inv, p) * EMB.capacity(n, first(t_inv), p) for
            p ∈ outputs(n)
        )
    )
end

"""
    EMB.constraints_flow_out(m, n::BioCHP, 𝒯::TimeStructure, modeltype::EnergyModel)

Function for creating the constraint on the outlet flow from a [`BioCHP`](@ref) node.

It differs from a standard `NetworkNode` by not requiring heat production.
"""
function EMB.constraints_flow_out(m, n::BioCHP, 𝒯::TimeStructure, modeltype::EnergyModel)
    # Declaration of the required subsets, excluding CO2, if specified
    𝒫ᵒᵘᵗ = EMB.res_not(outputs(n), co2_instance(modeltype))
    power = electricity_resource(n)
    𝒫ʰᵉᵃᵗ = EMB.res_not(𝒫ᵒᵘᵗ, power)

    # Constraint for the power output stream connections
    @constraint(m, [t ∈ 𝒯],
        m[:flow_out][n, t, power] == m[:cap_use][n, t] * outputs(n, power)
    )

    # Constraint for the heat output stream connections
    @constraint(m, [t ∈ 𝒯, p ∈ 𝒫ʰᵉᵃᵗ],
        m[:flow_out][n, t, p] ≤ m[:cap_use][n, t] * outputs(n, p)
    )
end
