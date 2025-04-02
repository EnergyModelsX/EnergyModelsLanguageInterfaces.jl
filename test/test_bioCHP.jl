using EnergyModelsHeat

@testset "BioCHP" begin
    Power = ResourceCarrier("Power", 0.0)
    Heat1 = ResourceHeat("Heat1", 70.0, 90.0) # High-temperature heat for demand 1
    Heat2 = ResourceHeat("Heat2", 50.0, 80.0) # High-temperature heat for demand 2

    BioSpruceStem = ResourceBio("BioSpruceStem", "spruce_stem", 0.4, 0.1)
    BioSpruceBark = ResourceBio("BioSpruceBark", "spruce_bark", 0.5, 0.12)
    BioBirchStem = ResourceBio("BioBirchStem", "birch_stem", 0.35, 0.08)
    BioSpruceTB = ResourceBio("BioSpruceTB", "spruce_T&B", 0.45, 0.11)

    CO2 = ResourceEmit("CO2", 1.0)

    # Creation of the initial problem with the NonDisRES node
    op_duration = 1
    op_number = 24 * 7
    operational_periods = SimpleTimes(op_number, op_duration)

    sp_duration = [1, 10, 10]
    sp_number = length(sp_duration)
    T = TwoLevel(sp_duration, operational_periods; op_per_strat = 8760.0)

    bio_products = [BioSpruceStem, BioSpruceBark, BioBirchStem, BioSpruceTB]
    heat_resources = Dict(Heat1 => 0.30, Heat2 => 0.40)
    products = [Power, Heat1, Heat2, bio_products..., CO2]

    sources = [
        RefSource(
            "Source for " * resource.id,
            FixedProfile(150),
            FixedProfile(120),
            FixedProfile(0),
            Dict(resource => 1.0),
        ) for resource ∈ bio_products
    ]
    mass_fractions = Dict(
        BioSpruceStem => 0.1,
        BioSpruceBark => 0.2,
        BioBirchStem => 0.3,
        BioSpruceTB => 0.4,
    )
    libpath = joinpath(@__DIR__, "..", "CHP_modelling")
    if !isdir(libpath)
        libpath = joinpath(@__DIR__, "..", "..", "CHP_modelling")
    end
    libpath = joinpath(libpath, "build", "lib", "libbioCHP_wrapper.so")

    bio_chp = BioCHP(
        "Bio CHP plant",
        FixedProfile(100.0),
        mass_fractions,
        heat_resources,
        Power;
        libpath,
    )
    caps = Dict(
        Power => OperationalProfile(50 * (1 .+ sin.((1:op_number) * pi / 24) .^ 2)),
        Heat1 => OperationalProfile(10 * (1 .+ cos.((1:op_number) * pi / 24) .^ 2)),
        Heat2 => OperationalProfile(1 .+ cos.((1:op_number) * pi / 24) .^ 2),
    )
    deficits = Dict(
        Power => FixedProfile(30),
        Heat1 => FixedProfile(10),
        Heat2 => FixedProfile(5),
    )
    sinks = [
        RefSink(
            "Sink for " * p.id,
            caps[p],
            Dict(:surplus => FixedProfile(1), :deficit => deficits[p]),
            Dict(p => 1.0),
        ) for p ∈ [Heat1, Heat2, Power]
    ]

    nodes = [bio_chp, sources..., sinks...]
    links = [Direct(node.id * "-Bio CHP plant", node, bio_chp, Linear()) for node ∈ sources]
    append!(
        links,
        [Direct("Bio CHP plant - " * node.id, bio_chp, node, Linear()) for node ∈ sinks],
    )

    case = Case(T, products, [nodes, links], [[get_nodes, get_links]])

    em_limits = Dict(CO2 => FixedProfile(1e5))   # Emission cap for CO₂ in t/year
    em_cost = Dict(CO2 => StrategicProfile([71.0, 100, 500]))    # Emission price for CO₂ in €/t
    modeltype = OperationalModel(em_limits, em_cost, CO2)

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

    @test value(m[:emissions_strategic][sp1, CO2]) ≈ 10383.783224461205
    @test value(m[:emissions_strategic][sp2, CO2]) ≈ 822.44841399
    @test value(m[:emissions_strategic][sp3, CO2]) ≈ 0.0

    # Check that the values of the deficits are correct.
    @test sum(value.(m[:sink_deficit][sinks[1], t]) > 0.0 for t ∈ 𝒯) == 385
    @test sum(value.(m[:sink_deficit][sinks[2], t]) > 0.0 for t ∈ 𝒯) == 168
    @test sum(value.(m[:sink_deficit][sinks[3], t]) > 0.0 for t ∈ 𝒯) == 455

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
    @test EMLI.bio_type(BioSpruceTB) == "spruce_T&B"

    # Test the `moisture` function
    @test EMLI.moisture(BioSpruceStem) ≈ 0.4
    @test EMLI.moisture(BioSpruceBark) ≈ 0.5
    @test EMLI.moisture(BioBirchStem) ≈ 0.35
    @test EMLI.moisture(BioSpruceTB) ≈ 0.45

    # Test the `electricity_resource` function
    @test EMLI.electricity_resource(bio_chp) == Power
end

EMLI.cleanup_libraries()
