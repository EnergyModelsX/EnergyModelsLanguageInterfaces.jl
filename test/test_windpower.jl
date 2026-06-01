@testset "WindFarmParameters" begin
    @testset "Constructor" begin
        params1 = WindFarmParameters(
            "wf1",
            52.0,
            5.0,
            100.0;
            orientation = 180,
            shape = "circular",
            method = "Ninja",
            source = "NORA3",
        )

        params2 = WindFarmParameters(
            "wf1",
            52.0,
            5.0,
            100.0,
            180,
            "circular",
            "Ninja",
            "NORA3",
        )

        for params ∈ (params1, params2)
            @test params.id == "wf1"
            @test params.lat == 52.0
            @test params.lon == 5.0
            @test params.turbine_height == 100.0
            @test params.orientation == 180
            @test params.shape == "circular"
            @test params.method == "Ninja"
            @test params.source == "NORA3"
        end
    end

    @testset "Invalid parameters" begin
        # lat/lon validation
        @test_throws ArgumentError WindFarmParameters("wf1", -91.0, 5.0, 100.0)
        @test_throws ArgumentError WindFarmParameters("wf1", 91.0, 5.0, 100.0)
        @test_throws ArgumentError WindFarmParameters("wf1", 52.0, -181.0, 100.0)
        @test_throws ArgumentError WindFarmParameters("wf1", 52.0, 181.0, 100.0)

        # turbine height
        @test_throws ArgumentError WindFarmParameters("wf1", 52.0, 5.0, 0.0)
        @test_throws ArgumentError WindFarmParameters("wf1", 52.0, 5.0, -10.0)

        # invalid method
        @test_throws ArgumentError WindFarmParameters(
            "wf1", 52.0, 5.0, 100.0;
            method = "invalid",
        )

        # invalid source
        @test_throws ArgumentError WindFarmParameters(
            "wf1", 52.0, 5.0, 100.0;
            source = "invalid",
        )
    end
end

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
