# Set the global to true to suppress the error message
EMB.TEST_ENV = true

@testset "Test checks - WindPower" begin
    # Test that a wrong capacity is caught by the checks
    @test_throws AssertionError simple_graph_wind(; cap = FixedProfile(-25))

    # Test that a wrong profile is caught by the checks
    @test_throws AssertionError simple_graph_wind(; profile = FixedProfile(-0.5))
    @test_throws AssertionError simple_graph_wind(; profile = FixedProfile(1.5))

    # Test that a wrong fixed OPEX is caught by the checks
    @test_throws AssertionError simple_graph_wind(; opex_fixed = FixedProfile(-5))

    # Test that a wrong output dictionary is caught
    @test_throws AssertionError simple_graph_wind(; output = Dict(Power => -0.9))
end

@testset "Test checks - PV" begin
    # Test that a wrong capacity is caught by the checks
    @test_throws AssertionError simple_graph_pv(; cap = FixedProfile(-25))

    # Test that a wrong profile is caught by the checks
    @test_throws AssertionError simple_graph_pv(; profile = FixedProfile(-0.5))
    @test_throws AssertionError simple_graph_pv(; profile = FixedProfile(1.5))

    # Test that a wrong fixed OPEX is caught by the checks
    @test_throws AssertionError simple_graph_pv(; opex_fixed = FixedProfile(-5))

    # Test that a wrong output dictionary is caught
    @test_throws AssertionError simple_graph_pv(; output = Dict(Power => -0.9))
end

@testset "Test checks - MultipleBuildingTypes" begin
    # Test missing resource in cap
    @test_throws AssertionError simple_graph_buildings(;
        cap_p = Dict(HeatHT=>FixedProfile(10.0)),
        input = Dict(HeatHT=>1.0, Power=>2.0),
    )

    # Test missing resource in penalty_surplus
    @test_throws AssertionError simple_graph_buildings(;
        cap_p = Dict(HeatHT=>FixedProfile(10.0), Power=>FixedProfile(5.0)),
        penalty_surplus = Dict(HeatHT=>FixedProfile(0.5)),
        input = Dict(HeatHT=>1.0, Power=>2.0),
    )

    # Test missing resource in penalty_deficit
    @test_throws AssertionError simple_graph_buildings(;
        cap_p = Dict(HeatHT=>FixedProfile(10.0), Power=>FixedProfile(5.0)),
        penalty_deficit = Dict(Power=>FixedProfile(0.5)),
        input = Dict(HeatHT=>1.0, Power=>2.0),
    )

    # Test negative capacity
    @test_throws AssertionError simple_graph_buildings(;
        cap_p = Dict(HeatHT=>FixedProfile(-10.0), Power=>FixedProfile(5.0)),
    )

    # Test negative input value
    @test_throws AssertionError simple_graph_buildings(;
        cap_p = Dict(HeatHT=>FixedProfile(10.0), Power=>FixedProfile(5.0)),
        input = Dict(HeatHT=>-1.0, Power=>2.0),
    )

    # Test infeasible penalty combination (sum negative)
    @test_throws AssertionError simple_graph_buildings(;
        cap_p = Dict(HeatHT=>FixedProfile(10.0), Power=>FixedProfile(5.0)),
        penalty_surplus = Dict(HeatHT=>FixedProfile(-2.0), Power=>FixedProfile(0.5)),
        penalty_deficit = Dict(HeatHT=>FixedProfile(-1.0), Power=>FixedProfile(0.5)),
    )
end

@testset "Test checks - CSPandPV" begin
    # Test missing resource in cap
    @test_throws AssertionError simple_graph_csp_pv(;
        cap_p = Dict(Power=>FixedProfile(10.0)),
    )

    # Test missing resource in opex_fixed
    @test_throws AssertionError simple_graph_csp_pv(;
        cap_p = Dict(Power=>FixedProfile(10.0), CSPHeat=>FixedProfile(5.0)),
        opex_fixed_p = Dict(Power=>FixedProfile(5.0)),
    )

    # Test missing resource in opex_var
    @test_throws AssertionError simple_graph_csp_pv(;
        cap_p = Dict(Power=>FixedProfile(10.0), CSPHeat=>FixedProfile(5.0)),
        opex_var_p = Dict(Power=>FixedProfile(0.1)),
    )

    # Test missing resource in profile
    @test_throws AssertionError simple_graph_csp_pv(;
        cap_p = Dict(Power=>FixedProfile(10.0), CSPHeat=>FixedProfile(5.0)),
        profile = Dict(Power=>FixedProfile(0.8)),
    )

    # Test that a wrong capacity is caught by the checks
    @test_throws AssertionError simple_graph_csp_pv(;
        cap_p = Dict(Power=>FixedProfile(-10.0), CSPHeat=>FixedProfile(5.0)),
    )

    # Test negative opex_fixed value
    @test_throws AssertionError simple_graph_csp_pv(;
        cap_p = Dict(Power=>FixedProfile(10.0), CSPHeat=>FixedProfile(5.0)),
        opex_fixed_p = Dict(Power=>FixedProfile(-5.0), CSPHeat=>FixedProfile(2.0)),
    )

    # Test that a wrong profile is caught by the checks
    @test_throws AssertionError simple_graph_csp_pv(;
        cap_p = Dict(Power=>FixedProfile(10.0), CSPHeat=>FixedProfile(5.0)),
        profile = Dict(Power=>FixedProfile(-0.2), CSPHeat=>FixedProfile(0.7)),
    )
    @test_throws AssertionError simple_graph_csp_pv(;
        cap_p = Dict(Power=>FixedProfile(10.0), CSPHeat=>FixedProfile(5.0)),
        profile = Dict(Power=>FixedProfile(1.2), CSPHeat=>FixedProfile(0.7)),
    )

    # Test that a wrong fixed OPEX is caught by the checks
    @test_throws AssertionError simple_graph_csp_pv(;
        cap_p = Dict(Power=>FixedProfile(10.0), CSPHeat=>FixedProfile(5.0)),
        opex_fixed_p = Dict(
            Power=>FixedProfile(5.0),
            CSPHeat=>FixedProfile(-5),
        ),
    )

    # Test that a wrong output dictionary is caught
    @test_throws AssertionError simple_graph_csp_pv(;
        cap_p = Dict(Power=>FixedProfile(10.0), CSPHeat=>FixedProfile(5.0)),
        output = Dict(CSPHeat=>-1.0, Power=>1.0),
    )
end

@testset "Test checks - BioCHP" begin
    # Test that missing electricity_resource in outputs is caught
    @test_throws AssertionError simple_graph_biochp(; output = Dict(Heat1=>1.0, Heat2=>1.0))
end
