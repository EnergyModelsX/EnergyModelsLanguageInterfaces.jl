using EnergyModelsHeat
using JSON
using Dates

@testset "CSPandPV" begin
    case, modeltype = simple_graph_csp_pv()

    csp_and_pv_plant = get_node(case, "CSP and PV plant")  # The MultipleBuildingTypes node
    𝒫 = setdiff(get_products(case), [CO2])

    # Run the model
    m = EMB.run_model(case, modeltype, OPTIMIZER)

    # Extraction of the time structure
    𝒯 = get_time_struct(case)

    # Run of the general tests
    general_tests(m)

    # Test that curtailment is correctly with respect to the profile.
    @test sum(value.(m[:solar_curtailment][csp_and_pv_plant, t, Power]) > 0.0 for t ∈ 𝒯) ==
          102

    # Test constraints from EMB.constraints_capacity
    @test sum(
        value.(m[:solar_cap_use][csp_and_pv_plant, t, p]) ≤
        EMB.capacity(csp_and_pv_plant, t, p) for t ∈ 𝒯, p ∈ 𝒫
    ) == length(𝒯) * length(𝒫)

    @test sum(
        value.(m[:solar_cap_use][csp_and_pv_plant, t, p]) +
        value.(m[:solar_curtailment][csp_and_pv_plant, t, p]) ≈
        EMRP.profile(csp_and_pv_plant, t, p) *
        EMB.capacity(csp_and_pv_plant, t, p) for t ∈ 𝒯, p ∈ 𝒫
    ) == length(𝒯) * length(𝒫)

    @test sum(
        sum(value.(m[:solar_curtailment][csp_and_pv_plant, t, p]) for p ∈ 𝒫) ≈
        value(m[:curtailment][csp_and_pv_plant, t]) for t ∈ 𝒯
    ) == length(𝒯)

    # Test constraints frmo EMB.constraints_flow_out
    @test sum(
        value(m[:flow_out][csp_and_pv_plant, t, p]) ≈
        value(m[:solar_cap_use][csp_and_pv_plant, t, p]) * outputs(csp_and_pv_plant, p) for
        t ∈ 𝒯, p ∈ 𝒫
    ) == length(𝒯) * length(𝒫)

    # Test constraints from EMB.constraints_opex_var
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    @test sum(
        value(m[:opex_var][csp_and_pv_plant, t_inv]) ≈
        sum(
            value(m[:solar_cap_use][csp_and_pv_plant, t, p]) *
            EMB.opex_var(csp_and_pv_plant, t, p) *
            scale_op_sp(t_inv, t) for t ∈ t_inv, p ∈ outputs(csp_and_pv_plant)
        ) for t_inv ∈ 𝒯ᴵⁿᵛ
    ) == length(𝒯ᴵⁿᵛ)

    # Test constraints from EMB.constraints_opex_fixed
    @test sum(
        value(m[:opex_fixed][csp_and_pv_plant, t_inv]) ≈
        sum(
            EMB.opex_fixed(csp_and_pv_plant, t_inv, p) *
            EMB.capacity(csp_and_pv_plant, first(t_inv), p) for
            p ∈ outputs(csp_and_pv_plant)
        ) for t_inv ∈ 𝒯ᴵⁿᵛ
    ) == length(𝒯ᴵⁿᵛ)

    # Test that the EMB function has_capacity is false for the CSPandPV node.
    @test !EMB.has_capacity(csp_and_pv_plant)

    # Test the utility functions
    for p ∈ 𝒫
        # Capacity
        @test EMB.capacity(csp_and_pv_plant, p) isa TimeProfile
        @test EMB.capacity(csp_and_pv_plant)[p] == EMB.capacity(csp_and_pv_plant, p)
        @test EMB.capacity(csp_and_pv_plant, first(𝒯), p) ==
              EMB.capacity(csp_and_pv_plant, p)[first(𝒯)]

        # OPEX variable
        @test EMB.opex_var(csp_and_pv_plant, p) isa TimeProfile
        @test EMB.opex_var(csp_and_pv_plant)[p] == EMB.opex_var(csp_and_pv_plant, p)
        @test EMB.opex_var(csp_and_pv_plant, first(𝒯), p) ==
              EMB.opex_var(csp_and_pv_plant, p)[first(𝒯)]

        # OPEX fixed
        @test EMB.opex_fixed(csp_and_pv_plant, p) isa TimeProfile
        @test EMB.opex_fixed(csp_and_pv_plant)[p] == EMB.opex_fixed(csp_and_pv_plant, p)
        @test EMB.opex_fixed(csp_and_pv_plant, first(𝒯ᴵⁿᵛ), p) ==
              EMB.opex_fixed(csp_and_pv_plant, p)[first(𝒯ᴵⁿᵛ)]

        # Profile
        @test EMRP.profile(csp_and_pv_plant, p) isa TimeProfile
        @test EMRP.profile(csp_and_pv_plant)[p] == EMRP.profile(csp_and_pv_plant, p)
        @test EMRP.profile(csp_and_pv_plant, first(𝒯), p) ==
              EMRP.profile(csp_and_pv_plant, p)[first(𝒯)]
    end
end
