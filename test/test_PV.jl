@testset "Utilities" begin
    # Create the general data for the activation cost node
    𝒯 = TwoLevel(2, 1, SimpleTimes(4, 1))
    power = ResourceCarrier("Power", 0.0)
    pv_node = PV(
        "PV plant",
        FixedProfile(50),
        OperationalProfile([1, 2, 3, 5]),
        FixedProfile(1),
        FixedProfile(2),
        Dict(power => 2),
    )

    # Test the EMB utility functions
    @test capacity(pv_node) == FixedProfile(50)
    @test opex_var(pv_node) == FixedProfile(1)
    @test opex_fixed(pv_node) == FixedProfile(2)
    @test all(EMRP.profile(pv_node, t) == OperationalProfile([1, 2, 3, 5])[t] for t ∈ 𝒯)
    @test all(EMRP.profile(pv_node)[t] == OperationalProfile([1, 2, 3, 5])[t] for t ∈ 𝒯)
    @test outputs(pv_node) == [power]
    @test node_data(pv_node) == ExtensionData[]
end

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

        # Test that the source data is the same
        temp = zeros(24)
        temp[9:17] .=
            [0.04232, 0.17286, 0.28464, 0.35291, 0.37037, 0.34113, 0.259, 0.13508, 0.01448]
        ref_values = OperationalProfile(temp)

        @test all(
            isapprox(EMRP.profile(pv_plant, t), ref_values[t]; atol = TEST_ATOL) for t ∈ 𝒯
        )

        # Test that curtailment is correctly with respect to the profile.
        @test sum(
            value.(m[:curtailment][pv_plant, t]) > 0.0 for t ∈ 𝒯
        ) == 9

        # Test that deficit is correctly with respect to the profile.
        @test sum(
            value.(m[:sink_deficit][sink, t]) > 0.0 for t ∈ 𝒯
        ) == 63
    end
end
