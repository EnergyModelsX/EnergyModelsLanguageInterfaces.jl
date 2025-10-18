using EnergyModelsHeat
using JSON
using Dates

@testset "CSPandPV" begin
    Power = ResourceCarrier("Power", 0.0)
    CSPHeat = ResourceHeat("CSPHeat", 400.0, 390) # CSP heat
    CO2 = ResourceEmit("CO2", 1.0)

    # Creation of the initial problem with the NonDisRES node
    time_start_str = "2019-01-01"
    time_end_str = "2019-01-07"
    op_duration = 1
    op_number = 24 * (Dates.value(Date(time_end_str) - Date(time_start_str)) + 1)
    operational_periods = SimpleTimes(op_number, op_duration)

    sp_duration = [1, 2, 10]
    sp_number = length(sp_duration)
    T = TwoLevel(sp_duration, operational_periods; op_per_strat = 8760.0)

    # Load paths to default Buildings process
    project_path =
        joinpath(pkgdir(EMLI), "submodules", "Tecnalia_Solar-Energy-Model")

    path_to_json_csp_pv = joinpath(project_path, "input.json")
    process_pay_load_csp_pv = JSON.parsefile(path_to_json_csp_pv)

    #process_pay_load_buildings["nutsid"] = "NO04" # Agder and Rogaland

    time_start = DateTime(time_start_str * "T00:00:00")
    time_end = DateTime(time_end_str * "T23:00:00")

    resources_map_csp_cv = Dict(
        "Ppv" => Power,
        "Pthermal" => CSPHeat,
    )
    products = [Power, CSPHeat, CO2]
    𝒫 = [Power, CSPHeat]
    caps = Dict(Power => 100, CSPHeat => 20)
    sinks = [
        RefSink(
            "Sink for " * p.id,
            FixedProfile(caps[p]),
            Dict(:surplus => FixedProfile(1), :deficit => FixedProfile(1e4)),
            Dict(p => 1.0),
        ) for p ∈ 𝒫
    ]
    csp_and_pv_plant = CSPandPV(
        "CSP and PV plant",                     # Node id
        process_pay_load_csp_pv,
        time_start,                    # Start time
        time_end,                      # End time
        resources_map_csp_cv;                 # Map of resource keys to `EMB.Resource`s
        data_location = joinpath(pkgdir(EMLI), "test", "data", "CSPandPV", "NO04"),
        overwrite_saved_data = false,
    )
    nodes = [csp_and_pv_plant, sinks...]
    links = [
        Direct("csp_and_pv_plant-" * node.id, csp_and_pv_plant, node, Linear()) for
        node ∈ sinks
    ]

    case = Case(T, products, [nodes, links], [[get_nodes, get_links]])

    em_limits = Dict(CO2 => FixedProfile(1e4))   # Emission cap for CO₂ in t/year
    em_cost = Dict(CO2 => FixedProfile(71.0))    # Emission price for CO₂ in €/t
    modeltype = OperationalModel(em_limits, em_cost, CO2)

    # Run the model
    m = EMB.run_model(case, modeltype, OPTIMIZER)

    # Extraction of the time structure
    𝒯 = get_time_struct(case)

    # Run of the general tests
    general_tests(m)

    # Test that curtailment is correctly with respect to the profile.
    @test sum(value.(m[:solar_curtailment][csp_and_pv_plant, t, Power]) > 0.0 for t ∈ 𝒯) ==
          102

    # Test constraints from EMB.constraints_capacity
    @test sum(
        value.(m[:solar_cap_use][csp_and_pv_plant, t, p]) ≤
        EMB.capacity(csp_and_pv_plant, t, p) for t ∈ 𝒯, p ∈ 𝒫
    ) == length(𝒯) * length(𝒫)

    @test sum(
        value.(m[:solar_cap_use][csp_and_pv_plant, t, p]) +
        value.(m[:solar_curtailment][csp_and_pv_plant, t, p]) ≈
        EMRP.profile(csp_and_pv_plant, t, p) *
        EMB.capacity(csp_and_pv_plant, t, p) for t ∈ 𝒯, p ∈ 𝒫
    ) == length(𝒯) * length(𝒫)

    @test sum(
        sum(value.(m[:solar_curtailment][csp_and_pv_plant, t, p]) for p ∈ 𝒫) ≈
        value(m[:curtailment][csp_and_pv_plant, t]) for t ∈ 𝒯
    ) == length(𝒯)

    # Test constraints frmo EMB.constraints_flow_out
    @test sum(
        value(m[:flow_out][csp_and_pv_plant, t, p]) ≈
        value(m[:solar_cap_use][csp_and_pv_plant, t, p]) * outputs(csp_and_pv_plant, p) for
        t ∈ 𝒯, p ∈ 𝒫
    ) == length(𝒯) * length(𝒫)

    # Test constraints from EMB.constraints_opex_var
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    @test sum(
        value(m[:opex_var][csp_and_pv_plant, t_inv]) ≈
        sum(
            value(m[:solar_cap_use][csp_and_pv_plant, t, p]) *
            EMB.opex_var(csp_and_pv_plant, t, p) *
            scale_op_sp(t_inv, t) for t ∈ t_inv, p ∈ outputs(csp_and_pv_plant)
        ) for t_inv ∈ 𝒯ᴵⁿᵛ
    ) == length(𝒯ᴵⁿᵛ)

    # Test constraints from EMB.constraints_opex_fixed
    @test sum(
        value(m[:opex_fixed][csp_and_pv_plant, t_inv]) ≈
        sum(
            EMB.opex_fixed(csp_and_pv_plant, t_inv, p) *
            EMB.capacity(csp_and_pv_plant, first(t_inv), p) for
            p ∈ outputs(csp_and_pv_plant)
        ) for t_inv ∈ 𝒯ᴵⁿᵛ
    ) == length(𝒯ᴵⁿᵛ)

    # Test that the EMB function has_capacity is false for the CSPandPV node.
    @test !EMB.has_capacity(csp_and_pv_plant)
end
