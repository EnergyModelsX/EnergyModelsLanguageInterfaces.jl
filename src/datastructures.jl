"""
    WindPower <: AbstractNonDisRES

A wind power source. It extends the existing `AbstractNonDisRES` node through allowing for
sampling the profile from a Python code through a constructor.

# Fields
- **`id`** is the name/identifyer of the node.
- **`cap::TimeProfile`** is the installed capacity.
- **`profile::TimeProfile`** is the power production in each operational period as a ratio
  of the installed capacity at that time.
- **`opex_var::TimeProfile`** is the variable operating expense per energy unit produced.
- **`opex_fixed::TimeProfile`** is the fixed operating expense.
- **`output::Dict{Resource, Real}`** are the generated `Resource`s, normally Power.
- **`data::Vector{Data}`** is the additional data (e.g. for investments). The field `data`
  is conditional through usage of a constructor.
"""
struct WindPower <: AbstractNonDisRES
    id::Any
    cap::TimeProfile
    profile::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    output::Dict{<:Resource,<:Real}
    data::Vector{Data}
end
function WindPower(
    id::Any,
    cap::TimeProfile,
    profile::TimeProfile,
    opex_var::TimeProfile,
    opex_fixed::TimeProfile,
    output::Dict{<:Resource,<:Real},
)
    return WindPower(id, cap, profile, opex_var, opex_fixed, output, Data[])
end

"""
    WindPower(
        id::Any,
        cap::TimeProfile,
        windfarm::Dict,
        time_start::String,
        time_end::String,
        opex_var::TimeProfile,
        opex_fixed::TimeProfile,
        output::Dict{<:Resource,<:Real};
        data::Vector{Data} = Data[],
        method::String = "Ninja",
        data_path::String = ""
    )

Constructs a [`WindPower`](@ref) instance where the power production profile is sampled from
a Python function.

# Arguments
- **`id`** is the name or identifier of the node.
- **`cap`** is the installed capacity.
- **`windfarm`** is a dictionary containing the wind farm parameters. An example dictionary
  is given by:

  ```julia
    windfarm = Dict(
        "id" => "windfarm_1",       # The identifier of the windfarm
        "lat" => 56.8233,           # The latitude coordinates of the windfarm
        "lon" => 4.3467,            # The longitude of the wind farm
        "orientation" => missing,   # The orientation
        "shape" => missing,
        "turbine_height" => 150,    # The turbine height
    )
  ```
- **`time_start`** is the starting time (as a string) for the wind power time series sampling.
  The format is "YYYY-MM-DD".
- **`time_end`** is the end time (as a string) for the wind power time series sampling.
  The format is "YYYY-MM-DD".
- **`opex_var`** is the variable operating expense per energy unit produced.
- **`opex_fixed`** is the fixed operating expense.
- **`output`** are the generated `Resource`s, normally Power, with conversion value `Real`.

# Keyword arguments
- **`data`** is the additional data (*e.g.*, for investments). The default value is no `data`.
- **`method`** is the chosen method for data retrieval. The user can choose between the
  strings "Ninja", "Tradewind_offshore", "Tradewind_upland",  and "Tradewind_lowland".
  The default value is "Ninja".
- **`data_path`** is an optional file path for already downloaded data. The default value is
  an empty datapath.
"""
function WindPower(
    id::Any,
    cap::TimeProfile,
    windfarm::Dict,
    time_start::String,
    time_end::String,
    opex_var::TimeProfile,
    opex_fixed::TimeProfile,
    output::Dict{<:Resource,<:Real};
    data::Vector{Data} = Data[],
    method::String = "Ninja",
    data_path::String = "",
)
    power = call_python_function(
        "wind_power_timeseries",
        "sample.wind_power";
        windfarm = windfarm,
        time_start = time_start,
        time_end = time_end,
        method = method,
        data_path = data_path,
    )
    profile = OperationalProfile(power)

    return WindPower(id, cap, profile, opex_var, opex_fixed, output, data)
end

"""
    CSPandPV <: AbstractNonDisRES

A combined CSP and PV source producing both power and heat. It extends the existing
`AbstractNonDisRES` to multiple production profiles. The profiles can have variations on
the strategic level.

# Fields
- **`id`** is the name/identifyer of the node.
- **`cap::Dict{<:Resource,<:TimeProfile}`** is the installed capacity (for all resources in a Dict).
- **`profile::Dict{<:Resource,<:TimeProfile}`** is the production profile in each operational
  period as a ratio of the installed capacity at that time (for all resources in a Dict).
- **`opex_var::Dict{<:Resource,<:TimeProfile}`** is the variable operating expense per
  energy unit produced (for all resources in a Dict).
- **`opex_fixed::Dict{<:Resource,<:TimeProfile}`** is the fixed operating expense (for all
  resources in a Dict).
- **`output::Dict{Resource, Real}`** are the generated `Resource`s, normally Power.
- **`data::Vector{Data}`** is the additional data (e.g. for investments). The field `data`
  is conditional through usage of a constructor.

!!! danger
    Investments are not available for this node.
"""
struct CSPandPV <: AbstractNonDisRES
    id::Any
    cap::Dict{<:Resource,<:TimeProfile}
    profile::Dict{<:Resource,<:TimeProfile}
    opex_var::Dict{<:Resource,<:TimeProfile}
    opex_fixed::Dict{<:Resource,<:TimeProfile}
    output::Dict{<:Resource,<:Real}
    data::Vector{Data}
end
function CSPandPV(
    id::Any,
    cap::Dict{<:Resource,<:TimeProfile},
    profile::Dict{<:Resource,<:TimeProfile},
    opex_var::Dict{<:Resource,<:TimeProfile},
    opex_fixed::Dict{<:Resource,<:TimeProfile},
    output::Dict{<:Resource,<:Real},
)
    return CSPandPV(id, cap, profile, opex_var, opex_fixed, output, Data[])
end

"""
    CSPandPV(
        id::Any,
        auth_pay_load::Dict,
        process_pay_load::Dict,
        time_start::DateTime,
        time_end::DateTime,
        resources_map::Dict{String,<:Resource};
        data::Vector{Data} = Data[],
        data_location::String = joinpath(tempdir(), "CSPandPV"),
        overwrite_saved_data::Bool = false,
    )

Constructs a `CSPandPV` instance where the power and heat production profiles are sampled from
the `executePVPowerPlantsProcess` function in the `pv_power_plants` python project.

# Arguments
- **`id`** is the name or identifier of the node in EMX.
- **`auth_pay_load`** is the authentication dictionary for the Python function.
- **`process_pay_load`** is the process dictionary for the Python function.
- **`time_start`** is the start time for the sampling.
- **`time_end`** is the end time for the sampling.
- **`resources_map`** is a map of resource keys to `EMB.Resource`s, *e.g.*, the dictionary

  ```julia
  Power = ResourceCarrier("Power", 0.0)
  Heat = ResourceCarrier("Heat", 0.0)

  resources_map = Dict(
      "Ppv" => Power,
      "Pthermal" => Heat,
  )
  ```

  It must contain the keys "Ppv" and "Pthermal" with their equivalent in EMX as values.

# Keyword arguments
- **`data`** is the additional data (*e.g.*, for investments). The default value is no `data`.
- **`data_location`** is the location where the data is saved. The default value is in the
  temporary directory.
- **`overwrite_saved_data`** is a boolean that determines if the stored data should be
  overwritten (in which case the building_energy_process is called). The default value is
  `false`.

!!! note
    The arguments `aut_pay_load` and `process_pay_load` are dictionaries that contain the
    authentication and process information for the Python function. The defaults can be
    achieved through

    ```julia
    using JSON
    auth_pay_load = JSON.parsefile(path_to_pv_power_plants/auth.json)
    process_pay_load = JSON.parsefile(path_to_pv_power_plants/process.json)
    ```
"""
function CSPandPV(
    id::Any,
    auth_pay_load::Dict,
    process_pay_load::Dict,
    time_start::DateTime,
    time_end::DateTime,
    resources_map::Dict{String,<:Resource};
    data::Vector{Data} = Data[],
    data_location::String = joinpath(tempdir(), "CSPandPV"),
    overwrite_saved_data::Bool = false,
)
    time_start_str = Dates.format(time_start, "yyyy-mm-dd\\THH:MM:SS")
    time_end_str = Dates.format(time_end, "yyyy-mm-dd\\THH:MM:SS")
    data_path = joinpath(data_location, "CSPandPV.yml")
    resources = values(resources_map)
    if isfile(data_path) && !overwrite_saved_data
        power_outputs = YAML.load(open(data_path))
    else
        csp_and_pv_dict = call_python_function(
            "pv_power_plants",
            "executePVPowerPlantsProcess",
            [auth_pay_load, process_pay_load, time_start_str, time_end_str],
        )

        if !isdir(data_location)
            mkpath(data_location)
        end

        # Extract power_outputs from the dictionary
        power_outputs = Dict(
            key => csp_and_pv_dict[key] for
            key ∈ keys(csp_and_pv_dict) if key != "time(UTC)"
        )
        open(data_path, "w") do io
            YAML.write(io, power_outputs)
        end
    end

    # Find the maximum power output for each resource
    max_power =
        Dict{String,Real}(key => maximum(power_outputs[key]) for key ∈ keys(power_outputs))

    # Construct capacity profiles
    cap = Dict{Resource,TimeProfile}(
        resources_map[key] => FixedProfile(max_power[key]) for
        key ∈ keys(power_outputs)
    )

    # Construct normalized power profiles
    profile = Dict{Resource,TimeProfile}(
        resources_map[key] => OperationalProfile(power_outputs[key] / max_power[key])
        for
        key ∈ keys(power_outputs)
    )

    # Set the fixed OPEX to the values in the process_pay_load
    opex_fixed = Dict{Resource,TimeProfile}(
        resources_map[key] => FixedProfile(process_pay_load["opex_"*key[2:end]]) for
        key ∈ keys(power_outputs)
    )

    # Set the variable OPEX to 0
    opex_var = Dict{Resource,TimeProfile}(
        resource => FixedProfile(0) for resource ∈ resources
    )

    output = Dict{Resource,Real}(resource => 1.0 for resource ∈ resources)

    return CSPandPV(id, cap, profile, opex_var, opex_fixed, output, data)
end

"""
    EMB.capacity(n::CSPandPV)
    EMB.capacity(n::CSPandPV, p::Resource)
    EMB.capacity(n::CSPandPV, t, p::Resource)

Returns the capacity of a CSPandPV `n` as a `Dictionary` or of resource `p` as `TimeProfile`
or in operational period `t`.
"""
EMB.capacity(n::CSPandPV) = n.cap
EMB.capacity(n::CSPandPV, p::Resource) = n.cap[p]
EMB.capacity(n::CSPandPV, t, p::Resource) = n.cap[p][t]

"""
    EMB.has_capacity(n::CSPandPV)

A CSPandPV has capacity for all its resources but not in a EMB sense.
"""
EMB.has_capacity(n::CSPandPV) = false

"""
    EMB.opex_var(n::CSPandPV)
    EMB.opex_var(n::CSPandPV, p::Resource)
    EMB.opex_var(n::CSPandPV, t, p::Resource)

Returns the variable OPEX of a CSPandPV `n` as a `Dictionary` or of resource `p` as `TimeProfile`
or in operational period `t`.
"""
EMB.opex_var(n::CSPandPV) = n.opex_var
EMB.opex_var(n::CSPandPV, p::Resource) = n.opex_var[p]
EMB.opex_var(n::CSPandPV, t, p::Resource) = n.opex_var[p][t]

"""
    EMB.opex_fixed(n::CSPandPV)
    EMB.opex_fixed(n::CSPandPV, p::Resource)
    EMB.opex_fixed(n::CSPandPV, t_inv, p::Resource)

Returns the fixed OPEX of a CSPandPV `n` as a `Dictionary` or of resource `p` as `TimeProfile`
or in operational period `t`.
"""
EMB.opex_fixed(n::CSPandPV) = n.opex_fixed
EMB.opex_fixed(n::CSPandPV, p::Resource) = n.opex_fixed[p]
EMB.opex_fixed(n::CSPandPV, t_inv, p::Resource) = n.opex_fixed[p][t_inv]

"""
    EMR.profile(n::CSPandPV)
    EMR.profile(n::CSPandPV, p::Resource)
    EMR.profile(n::CSPandPV, t, p::Resource)

Returns the profile of a CSPandPV `n` as a `Dictionary` or of resource `p` as `TimeProfile`
or in operational period `t`.
"""
EMR.profile(n::CSPandPV) = n.profile
EMR.profile(n::CSPandPV, p::Resource) = n.profile[p]
EMR.profile(n::CSPandPV, t, p::Resource) = n.profile[p][t]

"""
    struct MultipleBuildingTypes <: EMB.Sink

A [`MultipleBuildingTypes`](@ref) node that creates sinks for all demand resources. The
demand for each resources has a penalty for both surplus and deficit.
The penalties introduced in the field `penalty` affect the variable OPEX for both a surplus
and deficit.

# Fields
- **`id`** is the name/identifier of the node.
- **`cap::Dict{<:Resource,<:TimeProfile}`** is the demand.
- **`penalty_surplus::Dict{<:Resource,<:TimeProfile}`** are the penalties for surplus.
- **`penalty_deficit::Dict{<:Resource,<:TimeProfile}`** are the penalties for deficit.
- **`input::Dict{<:Resource,<:Real}`** are the input [`Resource`](@ref)s with conversion
  value `Real`.
- **`data::Vector{<:Data}`** is the additional data (*e.g.*, for investments). The field `data`
  is conditional through usage of a constructor.

!!! danger
    Investments are not available for this node.
"""
struct MultipleBuildingTypes <: EMB.Sink
    id::Any
    cap::Dict{<:Resource,<:TimeProfile}
    penalty_surplus::Dict{<:Resource,<:TimeProfile}
    penalty_deficit::Dict{<:Resource,<:TimeProfile}
    input::Dict{<:Resource,<:Real}
    data::Vector{<:Data}
end
function MultipleBuildingTypes(
    id::Any,
    cap::Dict{<:Resource,<:TimeProfile},
    penalty_surplus::Dict{<:Resource,<:TimeProfile},
    penalty_deficit::Dict{<:Resource,<:TimeProfile},
    input::Dict{<:Resource,<:Real},
)
    return MultipleBuildingTypes(id, cap, penalty_surplus, penalty_deficit, input, Data[])
end

"""
    MultipleBuildingTypes(
        id::Any,
        auth_pay_load::Dict,
        process_pay_load::Dict,
        time_start::DateTime,
        time_end::DateTime,
        buildings::Vector{String},
        resources_map::Dict{String,<:Resource},
        T::TimeStructure,
        penalty_surplus::Dict{<:Resource,<:TimeProfile},
        penalty_deficit::Dict{<:Resource,<:TimeProfile};
        data::Vector{<:Data} = Data[],
        data_location::String = joinpath(tempdir(), "buildings"),
        overwrite_saved_data::Bool = false,
    )

Constructs a `MultipleBuildingTypes` instance where the demand profiles are sampled from the
`executeBuildingEnergySimulationProcess` function in the `building_energy_process` python project.

# Arguments
- **`id`** is the name or identifier of the node.
- **`auth_pay_load`** is the authentication dictionary for the Python function.
- **`process_pay_load`** is the process dictionary for the Python function.
- **`time_start`** is the starting time for the sampling.
- **`time_end`** is the ending time for the sampling.
- **`buildings`** is a vector of the buildings to be considered. Any combination of the following building types is allowed:
  - "Apartment Block"
  - "Single family- Terraced houses"
  - "Hotels and Restaurants"
  - "Health"
  - "Education"
  - "Offices"
  - "Trade"
  - "Other non-residential buildings"
  - "Sport"
- **`resources_map`** is a map of resource keys to `EMB.Resource`s. E.g., the dictionary

  ```julia
  Coal = ResourceCarrier("Coal", 0.35)
  LNG = ResourceCarrier("LNG", 0.2)
  Oil = ResourceCarrier("Oil", 0.3)
  NG = ResourceCarrier("NG", 0.2)
  SolidBiomass = ResourceCarrier("SolidBiomass", 0.1)
  Power = ResourceCarrier("Power", 0.0)
  Heat = ResourceCarrier("Heat", 0.0)
  LiquidBiomass = ResourceCarrier("LiquidBiomass", 0.15)
  Biogas = ResourceCarrier("Biogas", 0.05)
  Hydrogen = ResourceCarrier("Hydrogen", 0.0)
  SolarHeat = ResourceCarrier("SolarHeat", 0.0)

  resources_map = Dict(
      "Solids|Coal" => Coal,
      "Liquids|Gas" => LNG,
      "Liquids|Oil" => Oil,
      "Gases|Gas" => NG,
      "Solids|Biomass" => SolidBiomass,
      "Electricity" => Power,
      "Heat" => Heat,
      "Liquids|Biomass" => LiquidBiomass,
      "Gases|Biomass" => Biogas,
      "Hydrogen" => Hydrogen,
      "Heat|Solar" => SolarHeat,
  )
  ```
- **`T`** is the TimeStructure used in the model.
- **`penalty_surplus::Dict{<:Resource,<:TimeProfile}`** is the penalties for surplus.
- **`penalty_deficit::Dict{<:Resource,<:TimeProfile}`** is the penalties for deficit.

# Keyword arguments
- **`data`** is the additional data (*e.g.*, for investments). The default value is no `data`.
- **`data_location`** is the location where the data is saved. The default value is in the
  temporary directory.
- **`overwrite_saved_data`** is a boolean that determines if the stored data should be
  overwritten (in which case the building_energy_process is called). The default value is
  `false`.

!!! note
    The "Variable cost [€/KWh]" and "Emissions [KgCO2/KWh]" from the `building_energy_process`
    model is currently not used. Both of these are incorporated indirectly through the usage
    of the energy carriers.

!!! note
    The arguments `aut_pay_load` and `process_pay_load` are dictionaries that contain the
    authentication and process information for the Python function. The defaults can be
    achieved through

    ```julia
    using JSON
    auth_pay_load = JSON.parsefile(path_to_building_energy_process/auth.json)
    process_pay_load = JSON.parsefile(path_to_building_energy_process/process.json)
    ```

!!! note
    If you want to incorporate unique penalities for each building type, you must create A
    `MultipleBuildingTypes` node for each building type.
"""
function MultipleBuildingTypes(
    id::Any,
    auth_pay_load::Dict,
    process_pay_load::Dict,
    time_start::DateTime,
    time_end::DateTime,
    buildings::Vector{String},
    resources_map::Dict{String,<:Resource},
    T::TimeStructure,
    penalty_surplus::Dict{<:Resource,<:TimeProfile},
    penalty_deficit::Dict{<:Resource,<:TimeProfile};
    data::Vector{<:Data} = Data[],
    data_location::String = joinpath(tempdir(), "buildings"),
    overwrite_saved_data::Bool = false,
)
    time_start_str = Dates.format(time_start, "yyyy-mm-dd\\THH:MM:SS")
    time_end_str = Dates.format(time_end, "yyyy-mm-dd\\THH:MM:SS")
    oper_length = length(T.operational[1]) # Assume the length to be the same in all Strategic periods
    resources = values(resources_map)
    cap_vector =
        Dict{Resource,Vector}(resource => zeros(oper_length) for resource ∈ resources)
    for building ∈ buildings
        # The keys of demands is
        data_path = joinpath(data_location, building * ".yml")
        if isfile(data_path) && !overwrite_saved_data
            demands = YAML.load(open(data_path))
        else
            demands = call_python_function(
                "building_energy_process",
                "executeBuildingEnergySimulationProcess",
                [auth_pay_load, process_pay_load, time_start_str, time_end_str, building],
            )

            if !isdir(data_location)
                mkpath(data_location)
            end

            # Scale power_outputs to MW
            for key ∈ keys(demands)
                if !(key in ["Datetime", "Variable cost [€/KWh]", "Emissions [KgCO2/KWh]"])
                    demands[key] /= 1e6
                end
            end
            open(data_path, "w") do io
                YAML.write(io, demands)
            end
        end
        for (key, demand) ∈ demands
            # Skip fields not used
            if key in ["Datetime", "Variable cost [€/KWh]", "Emissions [KgCO2/KWh]"]
                continue
            end

            # Add the demand to the corresponding resource
            cap_vector[resources_map[key]] += demand
        end
    end
    # Convert to OperationalProfile
    cap = Dict{Resource,TimeProfile}(
        resource => OperationalProfile(cap_vector[resource]) for
        resource ∈ resources
    )

    input = Dict{Resource,Real}(resource => 1.0 for resource ∈ resources)
    return MultipleBuildingTypes(id, cap, penalty_surplus, penalty_deficit, input, data)
end

"""
    EMB.capacity(n::MultipleBuildingTypes)
    EMB.capacity(n::MultipleBuildingTypes, p::Resource)
    EMB.capacity(n::MultipleBuildingTypes, t, p::Resource)

Returns the capacity of a MultipleBuildingTypes `n` as a `Dictionary` or of resource `p` as `TimeProfile`
or in operational period `t`.
"""
EMB.capacity(n::MultipleBuildingTypes) = n.cap
EMB.capacity(n::MultipleBuildingTypes, p::Resource) = n.cap[p]
EMB.capacity(n::MultipleBuildingTypes, t, p::Resource) = n.cap[p][t]

"""
    EMB.has_capacity(n::MultipleBuildingTypes)

A MultipleBuildingTypes has capacity for all its resources but not in a EMB sense.
"""
EMB.has_capacity(n::MultipleBuildingTypes) = false

"""
    EMB.surplus_penalty(n::MultipleBuildingTypes)
    EMB.surplus_penalty(n::MultipleBuildingTypes, p::Resource)
    EMB.surplus_penalty(n::MultipleBuildingTypes, t, p::Resource)

Returns the surplus penalty of MultipleBuildingTypes `n` as a `Dictionary` or of resource `p` as `TimeProfile`
or in operational period `t`.
"""
EMB.surplus_penalty(n::MultipleBuildingTypes) = n.penalty_surplus
EMB.surplus_penalty(n::MultipleBuildingTypes, p::Resource) = n.penalty_surplus[p]
EMB.surplus_penalty(n::MultipleBuildingTypes, t, p::Resource) = n.penalty_surplus[p][t]

"""
    EMB.deficit_penalty(n::MultipleBuildingTypes)
    EMB.deficit_penalty(n::MultipleBuildingTypes, p::Resource)
    EMB.deficit_penalty(n::MultipleBuildingTypes, t, p::Resource)

Returns the deficit penalty of MultipleBuildingTypes `n` as a `Dictionary` or of resource `p` as `TimeProfile`
or in operational period `t`.
"""
EMB.deficit_penalty(n::MultipleBuildingTypes) = n.penalty_deficit
EMB.deficit_penalty(n::MultipleBuildingTypes, p::Resource) = n.penalty_deficit[p]
EMB.deficit_penalty(n::MultipleBuildingTypes, t, p::Resource) = n.penalty_deficit[p][t]
