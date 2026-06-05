@testset "WindFarmParameters" begin
    @testset "Constructor" begin
        params1 = WindFarmParameters(
            "wf1",
            52.0,
            5.0,
            100.0;
            orientation = 180,
            shape = 2.0,
            method = "Ninja",
            source = "NORA3",
            turbine_power_curve = nothing,
            sigma = nothing,
            wakeloss = nothing,
        )

        params2 = WindFarmParameters(
            "wf1",
            52.0,
            5.0,
            100.0,
            180,
            2.0,
            "Ninja",
            "NORA3",
            nothing,
            nothing,
            nothing,
        )

        for params ∈ (params1, params2)
            @test params.id == "wf1"
            @test params.lat == 52.0
            @test params.lon == 5.0
            @test params.turbine_height == 100.0
            @test params.orientation == 180
            @test params.shape == 2.0
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

        @test_throws ArgumentError WindFarmParameters(
            "wf1", 52.0, 5.0, 100.0;
            turbine_power_curve = "invalid",
        )
        @test_throws ArgumentError WindFarmParameters(
            "wf1", 52.0, 5.0, 100.0;
            turbine_power_curve = DataFrame(invalid = [0.0, 3.0]),
        )
        @test_throws ArgumentError WindFarmParameters(
            "wf1", 52.0, 5.0, 100.0;
            turbine_power_curve = DataFrame(
                wind_speed = [0.0, 3.0],
                power_curve = [0.0, -0.5],
            ),
        )
        @test_throws ArgumentError WindFarmParameters(
            "wf1", 52.0, 5.0, 100.0;
            turbine_power_curve = DataFrame(
                wind_speed = [0.0, -3.0],
                power_curve = [0.0, 0.5],
            ),
        )

        # invalid sigma
        @test_throws ArgumentError WindFarmParameters(
            "wf1", 52.0, 5.0, 100.0;
            sigma = -0.1,
        )

        # invalid wakeloss
        @test_throws ArgumentError WindFarmParameters(
            "wf1", 52.0, 5.0, 100.0;
            wakeloss = -0.1,
        )
        @test_throws ArgumentError WindFarmParameters(
            "wf1", 52.0, 5.0, 100.0;
            wakeloss = 1.1,
        )
    end
end

@testset "WindPower" begin
    @testset "Utilities" begin
        # Create the general data for the activation cost node
        𝒯 = TwoLevel(2, 1, SimpleTimes(4, 1))
        power = ResourceCarrier("Power", 0.0)
        wind_node = WindPower(
            "Windfarm",
            FixedProfile(50),
            OperationalProfile([1, 2, 3, 5]),
            FixedProfile(1),
            FixedProfile(2),
            Dict(power => 2),
        )

        # Test the EMB utility functions
        @test capacity(wind_node) == FixedProfile(50)
        @test opex_var(wind_node) == FixedProfile(1)
        @test opex_fixed(wind_node) == FixedProfile(2)
        @test all(
            EMRP.profile(wind_node, t) == OperationalProfile([1, 2, 3, 5])[t] for t ∈ 𝒯
        )
        @test all(
            EMRP.profile(wind_node)[t] == OperationalProfile([1, 2, 3, 5])[t] for t ∈ 𝒯
        )
        @test outputs(wind_node) == [power]
        @test node_data(wind_node) == ExtensionData[]
    end

    @testset "Mathematical formulation" begin
        for _ ∈ 1:2 # Run the test two times to also test running from stored files (from first run)
            case, modeltype = simple_graph_wind()
            wind = get_node(case, "Windfarm")  # The WindPower node

            # Run the model
            m = EMB.run_model(case, modeltype, OPTIMIZER)

            # Extraction of the time structure
            𝒯 = get_time_struct(case)

            # Run of the general tests
            general_tests(m)

            ref_values = OperationalProfile(
                [
                    0.05392155871086372
                    0.06593995234130348
                    0.10709543333338498 # <- leading to curtailment
                    0.05602965048633869
                    0.04120640299099798
                    0.06871412996829987
                    0.0567443917628802
                    0.010421408219884402
                    0.0024146808530687916
                    0.01026380514282864
                    0.02149572164305347
                    0.02496252052948427
                    0.0289288257505998
                    0.025383268189000156
                    0.024929140168785634
                    0.026437806889332234
                    0.061005199466452116
                    0.045339748171755824
                    0.050099956532362384
                    0.06672067031250274
                    0.06878357668493178
                    0.050558812511585796
                    0.020751829278872737
                    0.008541570639539572
                ],
            )
            curtailment = 100 * 0.10709543333338498 - 8 # wind.cap * profile - 8 * sink.cap

            @test all(
                isapprox(EMRP.profile(wind, t), ref_values[t]; atol = TEST_ATOL) for
                t ∈ 𝒯
            )

            # Test that cap_use is correctly with respect to the profile.
            # - EMB.constraints_capacity(m, n::NonDisRES, 𝒯::TimeStructure, modeltype::EnergyModel)
            #   - 4, as we have one operational period per strategic period with curtailment
            @test sum(value.(m[:curtailment][wind, t]) > 0.0 for t ∈ 𝒯) == 4
            @test isapprox(
                sum(value.(m[:curtailment][wind, t]) for t ∈ 𝒯),
                4 * curtailment;
                atol = TEST_ATOL,
            )
            @test sum(
                isapprox(
                    value.(m[:cap_use][wind, t]) + value.(m[:curtailment][wind, t]),
                    EMRP.profile(wind, t) * value.(m[:cap_inst][wind, t]);
                    atol = TEST_ATOL,
                ) for t ∈ 𝒯
            ) == length(𝒯)
        end

        max_wind_speed = 25.0
        wind_speed = collect(range(0, max_wind_speed; length = 2)) # m/s
        power_fun(u) = (u / max_wind_speed) .^ 3
        power_curve = power_fun.(wind_speed)
        df = DataFrame(wind_speed = wind_speed, power_curve = power_curve)
        case, modeltype =
            simple_graph_wind(; turbine_power_curve = df, sigma = 0.0, wakeloss = 0.0)
        wind = get_node(case, "Windfarm")  # The WindPower node

        # Run the model
        m = EMB.run_model(case, modeltype, OPTIMIZER)

        # Extraction of the time structure
        𝒯 = get_time_struct(case)

        # Run of the general tests
        general_tests(m)

        wind_speed_100m = [
            4.56
            4.94
            5.79
            4.81
            4.21
            4.88
            4.44
            2.7
            1.74
            3.09
            3.76
            3.93
            4.09
            3.96
            3.92
            4.02
            5.04
            4.64
            4.62
            4.9
            5.09
            5.0
            3.98
            3.19
        ]
        wind_speed_250m = [
            5.29
            5.43
            6.08
            5.06
            4.98
            5.67
            5.64
            4.14
            3.29
            3.47
            3.98
            4.08
            4.24
            4.08
            4.09
            4.1
            5.03
            4.68
            4.99
            5.53
            5.38
            4.54
            3.64
            3.01
        ]

        function interp1d(x)
            if x <= wind_speed[1] || x >= wind_speed[end]
                return 0.0
            end
            i = searchsortedlast(wind_speed, x)
            x1, x2 = wind_speed[i], wind_speed[i+1]
            y1, y2 = power_curve[i], power_curve[i+1]
            return y1 + (y2 - y1) * (x - x1) / (x2 - x1)
        end

        # Get nora3 heights from height = 150
        turbine_height = 150
        z = turbine_height
        z1, z2 = 100, 250

        u1 = wind_speed_100m
        u2 = wind_speed_250m
        alpha = log.(u2 ./ u1) ./ log.(z2 ./ z1)
        windspeed_at_hub = u1 .* (z / z1) .^ alpha
        ref_values = interp1d.(windspeed_at_hub)
        ref_values_profile = OperationalProfile(ref_values)

        @test all(
            isapprox(EMRP.profile(wind, t), ref_values_profile[t]; atol = TEST_ATOL) for
            t ∈ 𝒯
        )
    end
end
