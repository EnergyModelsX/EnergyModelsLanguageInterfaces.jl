@testset "PV" begin
    for _ ∈ 1:2 # Run the test two times to also test running from stored files (from first run)
        case, modeltype, m = simple_graph_pv()

        # Run the model
        m = EMB.run_model(case, modeltype, OPTIMIZER)

        pv_plant = get_node(case, "PV plant")
        sink = get_node(case, "Sink for Power")
        𝒫 = setdiff(get_products(case), [CO2])

        # Extraction of the time structure
        𝒯 = get_time_struct(case)

        # Run of the general tests
        general_tests(m)

        # Test that curtailment is correctly with respect to the profile.
        @test sum(
            value.(m[:curtailment][pv_plant, t]) > 0.0 for t ∈ 𝒯
        ) == 63

        # Test that deficit is correctly with respect to the profile.
        @test sum(
            value.(m[:sink_deficit][sink, t]) > 0.0 for t ∈ 𝒯
        ) == 441
    end
end
