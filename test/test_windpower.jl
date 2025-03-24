
@testset "WindPower" begin
    # Creation of the initial problem with the NonDisRES node
    time_start = "2022-05-01"
    time_end = "2022-05-03"
    windfarm = Dict(
        "id" => "windfarm_1",
        "lat" => 55,
        "lon" => 9,
        "orientation" => missing,
        "shape" => missing,
        "turbine_height" => 150,
    )
    data_path = mkpath(joinpath(@__DIR__, "downloaded_nora3"))
    wind = WindPower(
        "Windfarm",                     # Node id
        FixedProfile(100),              # Capacity in MW
        windfarm,                       # Windfarm data
        time_start,                     # Start time for the data
        time_end,                       # End time for the data
        FixedProfile(0),                # Variable operational cost in €/MWh
        FixedProfile(50e3),             # Fixed operational cost in €/MW/year
        Dict(Power => 1);               # The generated resources with conversion value 1
        data_path,                      # Path to the data
    )
    case, modeltype = small_graph(source = wind, ops = SimpleTimes(72, 1))

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
