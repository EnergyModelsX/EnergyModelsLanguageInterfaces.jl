# Definition of resources
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

CSPHeat = ResourceHeat("CSPHeat", 400.0, 390)

Heat1 = ResourceHeat("Heat1", 70.0, 90.0) # High-temperature heat for demand 1
Heat2 = ResourceHeat("Heat2", 50.0, 80.0) # High-temperature heat for demand 2
BioSpruceStem = ResourceBio("BioSpruceStem", "spruce_stem", 0.4, 0.1)
BioSpruceBark = ResourceBio("BioSpruceBark", "spruce_bark", 0.5, 0.12)
BioBirchStem = ResourceBio("BioBirchStem", "birch_stem", 0.35, 0.08)
BioSpruceTB = ResourceBio("BioSpruceTB", "spruce_TandB", 0.45, 0.11)
heat_resources = Dict(Heat1 => 0.30, Heat2 => 0.40)

const TEST_ATOL = 1e-6
const OPTIMIZER = optimizer_with_attributes(HiGHS.Optimizer, MOI.Silent() => true)

function small_graph(; source = nothing, sink = nothing, ops = SimpleTimes(24, 2))
    products = [Power, CO2]
    # Creation of the source and sink module as well as the arrays used for nodes and links
    if isnothing(source)
        source = RefSource(
            2,
            FixedProfile(20),
            FixedProfile(30),
            FixedProfile(10),
            Dict(Power => 1),
        )
    end
    if isnothing(sink)
        sink = RefSink(
            3,
            FixedProfile(20),
            Dict(:surplus => FixedProfile(1e3), :deficit => FixedProfile(1e6)),
            Dict(Power => 1),
        )
    end

    nodes = [GenAvailability(1, products), source, sink]
    links = [
        Direct(21, nodes[2], nodes[1], Linear())
        Direct(13, nodes[1], nodes[3], Linear())
    ]

    # Creation of the time structure and the used global data
    T = TwoLevel(4, 1, ops)
    modeltype = OperationalModel(
        Dict(CO2 => StrategicProfile([450, 400, 350, 300])),
        Dict(CO2 => FixedProfile(0)),
        CO2,
    )

    # Input data structure
    case = Case(T, products, [nodes, links], [[get_nodes, get_links]])
    return case, modeltype, create_model(case, modeltype)
end
function simple_graph_wind(;
    cap = FixedProfile(100),
    opex_var = FixedProfile(0),
    opex_fixed = FixedProfile(50e3),
    output = Dict(Power => 1.0),
    profile = nothing,
)
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
    if isnothing(profile)
        wind = WindPower(
            "Windfarm",                     # Node id
            cap,                            # Capacity in MW
            windfarm,                       # Windfarm data
            time_start,                     # Start time for the data
            time_end,                       # End time for the data
            opex_var,                       # Variable operational cost in €/MWh
            opex_fixed,                     # Fixed operational cost in €/MW/year
            output;                         # The generated resources with conversion value 1
            data_path,                      # Path to the data
        )
    else
        wind = WindPower(
            "Windfarm",
            cap,
            profile,
            opex_var,
            opex_fixed,
            output,
        )
    end
    return small_graph(source = wind, ops = SimpleTimes(72, 1))
end

function simple_graph_buildings(; cap_p = nothing,
    penalty_surplus = Dict(HeatHT=>FixedProfile(0.5), Power=>FixedProfile(0.5)),
    penalty_deficit = Dict(HeatHT=>FixedProfile(0.5), Power=>FixedProfile(0.5)),
    input = Dict(HeatHT=>1.0, Power=>1.0))
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
    project_path = joinpath(
        pkgdir(EMLI),
        "submodules",
        "Tecnalia_Building-Stock-Energy-Model",
    )
    path_to_json_buildings = joinpath(project_path, "input.json")
    process_pay_load_buildings = Dict(JSON.parsefile(path_to_json_buildings))

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
            FixedProfile(150e6),
            FixedProfile(120),
            FixedProfile(0),
            Dict(resource => 1.0),
        ) for resource ∈ building_res
    ]
    if isnothing(cap_p)
        penalty_surplus = Dict{Resource,TimeProfile}(
            resource => FixedProfile(100) for resource ∈ values(resources_map_buildings)
        )
        penalty_deficit = Dict{Resource,TimeProfile}(
            resource => FixedProfile(1e4) for resource ∈ values(resources_map_buildings)
        )
        buildings = MultipleBuildingTypes(
            "Buildings",                     # Node id
            process_pay_load_buildings,               # Dictionary for the process
            time_start,                     # Start time
            time_end,                       # End time
            buildings,                 # List of building types to be simulated
            resources_map_buildings,                  # Map of resource keys to `EMB.Resource`s
            T,                            # Time structure
            penalty_surplus, # surplus penalty for the node in €/MWh;
            penalty_deficit, # deficit penalty for the node in €/MWh;
            data = [EmissionsEnergy()],
            data_location = joinpath(pkgdir(EMLI), "test", "data", "buildings"),
            overwrite_saved_data = false,
        )
    else
        buildings = MultipleBuildingTypes(
            "Buildings",
            cap_p,
            penalty_surplus,
            penalty_deficit,
            input,
        )
    end

    nodes = [buildings, sources...]
    links = [Direct(node.id * "-Buildings", node, buildings, Linear()) for node ∈ sources]

    case = Case(T, products, [nodes, links], [[get_nodes, get_links]])

    em_limits = Dict(CO2 => FixedProfile(1e10))   # Emission cap for CO₂ in t/year
    em_cost = Dict(CO2 => FixedProfile(71.0))    # Emission price for CO₂ in €/t
    modeltype = OperationalModel(em_limits, em_cost, CO2)
    return case, modeltype, create_model(case, modeltype)
end

function simple_graph_building(; cap_p = nothing,
    penalty_surplus = Dict(HeatHT=>FixedProfile(100), Power=>FixedProfile(100)),
    penalty_deficit = Dict(HeatHT=>FixedProfile(1e4), Power=>FixedProfile(1e4)),
    input = Dict(HeatHT=>1.0, Power=>1.0))
    # Creation of the initial problem with the NonDisRES node
    time_start_str = "2019-01-01"
    time_end_str = "2019-01-01"
    op_duration = 1
    op_number = 24 * (Dates.value(Date(time_end_str) - Date(time_start_str)) + 1)
    operational_periods = SimpleTimes(op_number, op_duration)

    sp_duration = [1, 2, 10]
    T = TwoLevel(sp_duration, operational_periods; op_per_strat = 8760.0)

    time_start = DateTime(time_start_str * "T00:00:00")
    time_end = DateTime(time_end_str * "T23:00:00")

    building_res = [Power, HeatHT]
    products = [building_res..., CO2]

    sources = [
        RefSource(
            "Source for " * resource.id,
            FixedProfile(150e6),
            FixedProfile(120),
            FixedProfile(0),
            Dict(resource => 1.0),
        ) for resource ∈ building_res
    ]
    if isnothing(cap_p)
        # Example temp_to_demand function (replace with your actual function)
        temp_to_demand(temp) = max(0, 20 - (temp - 273.15))
        # Example location (replace with actual values or make it an argument)
        lat, lon = 59.91, 10.75  # Oslo coordinates as example
        cap = Dict(
            resource => FixedProfile(120) for resource ∈ building_res if resource != HeatHT
        )
        building = Building(
            "Building",
            cap,
            penalty_surplus,
            penalty_deficit,
            input,
            time_start,
            time_end,
            lat,
            lon,
            HeatHT,
            temp_to_demand;
            data_path = joinpath(pkgdir(EMLI), "test", "data", "building"),
            source = "NORA3",
            reload = true,
            save_csv = true,
            use_cache = true,
        )
    else
        building = Building(
            "Buildings",
            cap_p,
            penalty_surplus,
            penalty_deficit,
            input,
        )
    end

    nodes = [building, sources...]
    links = [Direct(node.id * "-Buildings", node, building, Linear()) for node ∈ sources]

    case = Case(T, products, [nodes, links], [[get_nodes, get_links]])

    em_limits = Dict(CO2 => FixedProfile(1e10))   # Emission cap for CO₂ in t/year
    em_cost = Dict(CO2 => FixedProfile(71.0))    # Emission price for CO₂ in €/t
    modeltype = OperationalModel(em_limits, em_cost, CO2)
    return case, modeltype, create_model(case, modeltype)
end

function simple_graph_csp_pv(; cap_p = nothing,
    profile = Dict(Power=>FixedProfile(0.8), CSPHeat=>FixedProfile(0.7)),
    opex_var_p = Dict(Power=>FixedProfile(0.1), CSPHeat=>FixedProfile(0.2)),
    opex_fixed_p = Dict(Power=>FixedProfile(5.0), CSPHeat=>FixedProfile(2.0)),
    output = Dict(CSPHeat=>1.0, Power=>1.0),
)
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
    process_pay_load_csp_pv = Dict(JSON.parsefile(path_to_json_csp_pv))

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
    if isnothing(cap_p)
        csp_and_pv_plant = CSPandPV(
            "CSP and PV plant",                     # Node id
            process_pay_load_csp_pv,
            time_start,                    # Start time
            time_end,                      # End time
            resources_map_csp_cv;                 # Map of resource keys to `EMB.Resource`s
            data_location = joinpath(pkgdir(EMLI), "test", "data", "CSPandPV", "NO04"),
            overwrite_saved_data = false,
        )
    else
        csp_and_pv_plant = CSPandPV(
            "CSP and PV plant",
            cap_p,
            profile,
            opex_var_p,
            opex_fixed_p,
            output,
        )
    end
    nodes = [csp_and_pv_plant, sinks...]
    links = [
        Direct("csp_and_pv_plant-" * node.id, csp_and_pv_plant, node, Linear()) for
        node ∈ sinks
    ]

    case = Case(T, products, [nodes, links], [[get_nodes, get_links]])

    em_limits = Dict(CO2 => FixedProfile(1e4))   # Emission cap for CO₂ in t/year
    em_cost = Dict(CO2 => FixedProfile(71.0))    # Emission price for CO₂ in €/t
    modeltype = OperationalModel(em_limits, em_cost, CO2)
    return case, modeltype, create_model(case, modeltype)
end

function simple_graph_pv(;
    cap = FixedProfile(100),
    profile = nothing,
    opex_var = FixedProfile(0.1),
    opex_fixed = FixedProfile(5.0),
    output = Dict(Power => 1.0),
    pv_params = nothing,
)
    # Creation of the initial problem with the NonDisRES node
    time_start_str = "2019-01-01"
    time_end_str = "2019-01-01"
    op_duration = 1
    op_number = 24 * (Dates.value(Date(time_end_str) - Date(time_start_str)) + 1)
    operational_periods = SimpleTimes(op_number, op_duration)

    sp_duration = [1, 2, 10]
    T = TwoLevel(sp_duration, operational_periods; op_per_strat = 8760.0)

    products = [Power, CO2]
    sink = RefSink(
        "Sink for Power",
        FixedProfile(30),
        Dict(:surplus => FixedProfile(1), :deficit => FixedProfile(1e4)),
        Dict(Power => 1.0),
    )

    time_start = DateTime(time_start_str * "T00:00:00")

    if isnothing(profile)
        # Use default PVParameters if not provided
        if isnothing(pv_params)
            pv_params = PVParameters(
                40.0,    # lat
                0.0;     # lon
                loss = 14.0,
                pvtechchoice = "crystSi",
                mountingplace = "free",
                optimalangles = false,
                usehorizon = false,
            )
        end
        pv_plant = PV(
            "PV plant",
            cap,
            opex_var,
            opex_fixed,
            output,
            time_start,
            time_start + Hour(op_number - 1),
            pv_params;
            data_path = joinpath(pkgdir(EMLI), "test", "data", "PV"),
            filename_hint = "",
        )
    else
        pv_plant = PV(
            "PV plant",
            cap,
            profile,
            opex_var,
            opex_fixed,
            output,
        )
    end

    nodes = [pv_plant, sink]
    links = [
        Direct("pv_plant-sink", pv_plant, sink, Linear()),
    ]

    case = Case(T, products, [nodes, links], [[get_nodes, get_links]])

    em_limits = Dict(CO2 => FixedProfile(1e4))   # Emission cap for CO₂ in t/year
    em_cost = Dict(CO2 => FixedProfile(71.0))    # Emission price for CO₂ in €/t
    modeltype = OperationalModel(em_limits, em_cost, CO2)
    return case, modeltype, create_model(case, modeltype)
end

function simple_graph_biochp(; output = nothing)
    # Creation of the initial problem with the NonDisRES node
    op_duration = 1
    op_number = 24 * 7
    operational_periods = SimpleTimes(op_number, op_duration)

    sp_duration = [1, 10, 10]
    sp_number = length(sp_duration)
    T = TwoLevel(sp_duration, operational_periods; op_per_strat = 8760.0)

    bio_products = [BioSpruceStem, BioSpruceBark, BioBirchStem, BioSpruceTB]
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
    libpath::String = if Sys.iswindows()
        joinpath(
            pkgdir(EMLI),
            "submodules",
            "CHP_modelling",
            "build",
            "Release",
            "bioCHP_wrapper.dll",
        )
    else
        joinpath(
            pkgdir(EMLI),
            "submodules",
            "CHP_modelling",
            "build",
            "lib",
            "libbioCHP_wrapper.so",
        )
    end

    if isnothing(output)
        bio_chp = BioCHP(
            "Bio CHP plant",
            FixedProfile(100.0),
            mass_fractions,
            heat_resources,
            Power;
            libpath,
        )
    else
        bio_chp = BioCHP(
            "Bio CHP plant",
            FixedProfile(100.0),
            Power,
            FixedProfile(0.0),
            FixedProfile(0.0),
            mass_fractions,
            output,
        )
    end
    caps = Dict(
        Power => OperationalProfile(50 * (1 .+ sin.((1:op_number) * pi / 24) .^ 2)),
        Heat1 => OperationalProfile(10 * (1 .+ cos.((1:op_number) * pi / 24) .^ 2)),
        Heat2 => OperationalProfile(1 .+ cos.((1:op_number) * pi / 24) .^ 2),
    )
    deficits = Dict(
        Power => FixedProfile(52),
        Heat1 => FixedProfile(15),
        Heat2 => FixedProfile(10),
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
    discount_rate = 0.07                         # Discount rate for investments
    modeltype = InvestmentModel(em_limits, em_cost, CO2, discount_rate)
    return case, modeltype, create_model(case, modeltype)
end

function general_tests(m)
    # Check if the solution is optimal.
    @testset "optimal solution" begin
        @test termination_status(m) == MOI.OPTIMAL

        if termination_status(m) != MOI.OPTIMAL
            @show termination_status(m)
        end
    end
end

⪆(x, y) = x > y || isapprox(x, y; atol = TEST_ATOL)
⪅(x, y) = x < y || isapprox(x, y; atol = TEST_ATOL)

function get_node(case::Case, id)
    elements = get_nodes(case)
    return EMLI.fetch_element(elements, id)
end
