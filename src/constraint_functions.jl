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
