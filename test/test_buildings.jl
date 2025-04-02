using EnergyModelsHeat
using JSON
using Dates

@testset "MultipleBuildingTypes" begin
    Power = ResourceCarrier("Power", 0.0)
    HeatHT = ResourceHeat("HeatHT", 80.0, 30.0) # High-temperature heat for demand
    Coal = ResourceCarrier("Coal", 0.35)
    LNG = ResourceCarrier("LNG", 0.2)
    Oil = ResourceCarrier("Oil", 0.3)
    NG = ResourceCarrier("NG", 0.2)
    SolidBiomass = ResourceCarrier("SolidBiomass", 0.1)
    LiquidBiomass = ResourceCarrier("LiquidBiomass", 0.15)
    Biogas = ResourceCarrier("Biogas", 0.05)
    Hydrogen = ResourceCarrier("Hydrogen", 0.0)
    SolarHeat = ResourceCarrier("SolarHeat", 0.0)
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

    # Load paths to default Buildings process and authentication files
    project_path = joinpath(@__DIR__, "..", "Tecnalia")
    if !isdir(project_path)
        project_path = joinpath(@__DIR__, "..", "..", "Tecnalia")
    end
    project_path = joinpath(project_path, "examples", "building_energy_process")
    path_to_auth_file_buildings = joinpath(project_path, "auth.json")
    auth_pay_load_buildings = JSON.parsefile(path_to_auth_file_buildings)

    path_to_json_buildings = joinpath(project_path, "process.json")
    process_pay_load_buildings = JSON.parsefile(path_to_json_buildings)

    #process_pay_load_buildings["nutsid"] = "NO04" # Agder and Rogaland

    time_start = DateTime(time_start_str * "T00:00:00")
    time_end = DateTime(time_end_str * "T23:00:00")

    buildings = ["Apartment Block", "Single family- Terraced houses"]
    resources_map_buildings = Dict(
        "Solids|Coal" => Coal,
        "Liquids|Gas" => LNG,
        "Liquids|Oil" => Oil,
        "Gases|Gas" => NG,
        "Solids|Biomass" => SolidBiomass,
        "Electricity" => Power,
        "Heat" => HeatHT,
        "Liquids|Biomass" => LiquidBiomass,
        "Gases|Biomass" => Biogas,
        "Hydrogen" => Hydrogen,
        "Heat|Solar" => SolarHeat,
    )
    penalty_surplus = Dict{Resource,TimeProfile}(
        resource => FixedProfile(100) for resource ∈ values(resources_map_buildings)
    )
    penalty_deficit = Dict{Resource,TimeProfile}(
        resource => FixedProfile(1e4) for resource ∈ values(resources_map_buildings)
    )
    building_res =
        [
            Power,
            HeatHT,
            Coal,
            LNG,
            Oil,
            NG,
            SolidBiomass,
            LiquidBiomass,
            Biogas,
            Hydrogen,
            SolarHeat,
        ]
    products = [building_res..., CO2]

    sources = [
        RefSource(
            "Source for " * resource.id,
            FixedProfile(150),
            FixedProfile(120),
            FixedProfile(0),
            Dict(resource => 1.0),
        ) for resource ∈ building_res
    ]
    buildings = MultipleBuildingTypes(
        "Buildings",                     # Node id
        auth_pay_load_buildings,                  # Dictionary for the authentication
        process_pay_load_buildings,               # Dictionary for the process
        time_start,                     # Start time
        time_end,                       # End time
        buildings,                 # List of building types to be simulated
        resources_map_buildings,                  # Map of resource keys to `EMB.Resource`s
        T,                            # Time structure
        penalty_surplus, # surplus penalty for the node in €/MWh;
        penalty_deficit, # deficit penalty for the node in €/MWh;
        data = [EmissionsEnergy()],
        overwrite_saved_data = false,
    )
    nodes = [buildings, sources...]
    links = [Direct(node.id * "-Buildings", node, buildings, Linear()) for node ∈ sources]

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

    @test all(
        value.(m[:buildings_surplus][buildings, t, p]) == 0.0 for t ∈ 𝒯, p ∈ building_res
    )
    @test all(
        value.(m[:buildings_deficit][buildings, t, p]) == 0.0 for t ∈ 𝒯, p ∈ building_res
    )
    @test all(value.(m[:emissions_total][t, CO2]) > 0.001 for t ∈ 𝒯)

    # Test that the EMB function has_capacity is false for the MultipleBuildingTypes node.
    @test !EMB.has_capacity(buildings)

    # Test constraints from EMB.constraints_capacity
    @test all(
        value.(m[:flow_in][buildings, t, p]) / inputs(buildings, p) +
        value.(m[:buildings_deficit][buildings, t, p]) ==
        EMB.capacity(buildings, t, p) + value.(m[:buildings_surplus][buildings, t, p])
        for t ∈ 𝒯, p ∈ inputs(buildings)
    )

    @test all(
        sum(value.(m[:buildings_deficit][buildings, t, p]) for p ∈ inputs(buildings)) ==
        value.(m[:sink_deficit][buildings, t])
        for t ∈ 𝒯
    )

    @test all(
        sum(value.(m[:buildings_surplus][buildings, t, p]) for p ∈ inputs(buildings)) ==
        value.(m[:sink_surplus][buildings, t])
        for t ∈ 𝒯
    )

    # Test constraints from EMB.constraints_opex_var
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    @test all(
        value.(m[:opex_var][buildings, t_inv]) ==
        sum(
            (
                value.(m[:buildings_surplus][buildings, t, p]) *
                EMB.surplus_penalty(buildings, t, p) +
                value.(m[:buildings_deficit][buildings, t, p]) *
                EMB.deficit_penalty(buildings, t, p)
            ) * scale_op_sp(t_inv, t) for t ∈ t_inv, p ∈ inputs(buildings)
        )
        for t_inv ∈ 𝒯ᴵⁿᵛ
    )
end
