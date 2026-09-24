# Set the global to true to suppress the error message
EMB.TEST_ENV = true

@testset "Test checks - PV" begin
    # Test that a wrong capacity is caught by the checks
    profile = FixedProfile(-0.5)
    @test_throws AssertionError simple_graph_pv(; profile, cap = FixedProfile(-25))

    # Test that a wrong profile is caught by the checks
    @test_throws AssertionError simple_graph_pv(; profile = FixedProfile(-0.5))
    @test_throws AssertionError simple_graph_pv(; profile = FixedProfile(1.5))

    # Test that a wrong fixed OPEX is caught by the checks
    @test_throws AssertionError simple_graph_pv(; profile, opex_fixed = FixedProfile(-5))

    # Test that a wrong output dictionary is caught
    @test_throws AssertionError simple_graph_pv(; profile, output = Dict(Power => -0.9))
end

@testset "Test checks - Building" begin
    # Test missing resource in cap
    @test_throws AssertionError simple_graph_building(;
        cap_p = Dict(HeatHT => FixedProfile(10.0)),
        input = Dict(HeatHT => 1.0, Power => 2.0),
    )

    # Test missing resource in penalty_surplus
    @test_throws AssertionError simple_graph_building(;
        cap_p = Dict(HeatHT => FixedProfile(10.0), Power => FixedProfile(5.0)),
        penalty_surplus = Dict(HeatHT => FixedProfile(0.5)),
        input = Dict(HeatHT => 1.0, Power => 2.0),
    )

    # Test missing resource in penalty_deficit
    @test_throws AssertionError simple_graph_building(;
        cap_p = Dict(HeatHT => FixedProfile(10.0), Power => FixedProfile(5.0)),
        penalty_deficit = Dict(Power => FixedProfile(0.5)),
        input = Dict(HeatHT => 1.0, Power => 2.0),
    )

    # Test negative capacity
    @test_throws AssertionError simple_graph_building(;
        cap_p = Dict(HeatHT => FixedProfile(-10.0), Power => FixedProfile(5.0)),
    )

    # Test negative input value
    @test_throws AssertionError simple_graph_building(;
        cap_p = Dict(HeatHT => FixedProfile(10.0), Power => FixedProfile(5.0)),
        input = Dict(HeatHT => -1.0, Power => 2.0),
    )

    # Test infeasible penalty combination (sum negative)
    @test_throws AssertionError simple_graph_building(;
        cap_p = Dict(HeatHT => FixedProfile(10.0), Power => FixedProfile(5.0)),
        penalty_surplus = Dict(HeatHT => FixedProfile(-2.0), Power => FixedProfile(0.5)),
        penalty_deficit = Dict(HeatHT => FixedProfile(-1.0), Power => FixedProfile(0.5)),
    )

    # Test that a unsupported source is caught by the checks
    @test_throws ArgumentError simple_graph_building(; source = "unsupported_source")
end
