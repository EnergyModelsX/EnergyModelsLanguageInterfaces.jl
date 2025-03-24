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
