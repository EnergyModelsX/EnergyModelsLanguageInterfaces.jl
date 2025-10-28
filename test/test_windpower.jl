
@testset "WindPower" begin
    case, modeltype = simple_graph_wind()
    wind = get_node(case, "Windfarm")  # The WindPower node

    # Run the model
    m = EMB.run_model(case, modeltype, OPTIMIZER)

    # Extraction of the time structure
    𝒯 = get_time_struct(case)

    # Run of the general tests
    general_tests(m)

    # Test that cap_use is correctly with respect to the profile.
    # - EMB.constraints_capacity(m, n::NonDisRES, 𝒯::TimeStructure, modeltype::EnergyModel)
    #   - 28 as we have 28 operational periods per strategic period and a single strategic
    #     period with curtailment
    @test sum(value.(m[:curtailment][wind, t]) > 0.0 for t ∈ 𝒯) == 28
    @test sum(
        value.(m[:cap_use][wind, t]) + value.(m[:curtailment][wind, t]) ≈
        EMRP.profile(wind, t) * value.(m[:cap_inst][wind, t]) for t ∈ 𝒯, atol ∈ TEST_ATOL
    ) == length(𝒯)
end
