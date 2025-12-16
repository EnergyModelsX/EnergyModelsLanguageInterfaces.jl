using EnergyModelsHeat

@testset "BioCHP" begin
    case, modeltype = simple_graph_biochp()

    bio_chp = get_node(case, "Bio CHP plant")  # The MultipleBuildingTypes node
    sinks = [get_node(case, "Sink for " * p.id) for p ∈ [Heat1, Heat2, Power]]

    # Run the model
    m = EMB.run_model(case, modeltype, OPTIMIZER)

    # Extraction of the time structure
    𝒯 = get_time_struct(case)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    # Run of the general tests
    general_tests(m)
    sp1 = 𝒯ᴵⁿᵛ[1]
    sp2 = 𝒯ᴵⁿᵛ[2]
    sp3 = 𝒯ᴵⁿᵛ[3]

    @test value(m[:emissions_strategic][sp1, CO2]) ≈ 18111.756783644374
    @test value(m[:emissions_strategic][sp2, CO2]) ≈ 1471.5853754583773
    @test value(m[:emissions_strategic][sp3, CO2]) ≈ 0.0

    # Check that the values of the deficits are correct.
    @test sum(value.(m[:sink_deficit][sinks[1], t]) > 0.0 for t ∈ 𝒯) == 407
    @test sum(value.(m[:sink_deficit][sinks[2], t]) > 0.0 for t ∈ 𝒯) == 168
    @test sum(value.(m[:sink_deficit][sinks[3], t]) > 0.0 for t ∈ 𝒯) == 469

    # Check that the values of the surplus are correct.
    @test all(value.(m[:sink_surplus][sinks[1], t]) ≈ 0.0 for t ∈ 𝒯)
    @test all(value.(m[:sink_surplus][sinks[2], t]) ≈ 0.0 for t ∈ 𝒯)
    @test all(value.(m[:sink_surplus][sinks[3], t]) ≈ 0.0 for t ∈ 𝒯)

    # Test constraints frmo EMB.constraints_flow_out
    @test sum(
        value(m[:flow_out][bio_chp, t, Power]) ≈
        value(m[:cap_use][bio_chp, t]) * outputs(bio_chp, Power) for
        t ∈ 𝒯
    ) == length(𝒯)

    @test sum(
        value(m[:flow_out][bio_chp, t, p]) ⪅
        value(m[:cap_use][bio_chp, t]) * outputs(bio_chp, p) for
        t ∈ 𝒯, p ∈ keys(heat_resources)
    ) == length(𝒯) * length(heat_resources)

    # Test the `bio_type` function
    @test EMLI.bio_type(BioSpruceStem) == "spruce_stem"
    @test EMLI.bio_type(BioSpruceBark) == "spruce_bark"
    @test EMLI.bio_type(BioBirchStem) == "birch_stem"
    @test EMLI.bio_type(BioSpruceTB) == "spruce_TandB"

    # Test the `moisture` function
    @test EMLI.moisture(BioSpruceStem) ≈ 0.4
    @test EMLI.moisture(BioSpruceBark) ≈ 0.5
    @test EMLI.moisture(BioBirchStem) ≈ 0.35
    @test EMLI.moisture(BioSpruceTB) ≈ 0.45

    # Test the `electricity_resource` function
    @test EMLI.electricity_resource(bio_chp) == Power
end

EMLI.cleanup_libraries()
