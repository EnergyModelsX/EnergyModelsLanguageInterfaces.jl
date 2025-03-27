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
        data::Vector{Data} = Data[],
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
