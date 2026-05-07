using PyCall

"""
    call_python_function(module_name::String, function_name::String; kwargs...)
    call_python_function(module_name::String, function_name::String, args::Vector)

Call an external Python function.

## Arguments
- `module_name` - the name of the Python module to be used.
- `function_name` - the name of the function to be called. Nested names (*e.g.*, due to sub
  modules) must be separated by ".".

This function enables a vector of arguments (args) or keyword arguments (`kwargs`) as
the input to the python function to be called.

!!! note "Arguments"
    The function can be called with either a vector of arguments or keyword arguments, but not both.
    A combination of both arguments and keyword arguments is not possible as Julia does not
    distinguish methods solely based on the presence of keyword arguments.

!!! note "Environments"
    It is assumed that the required packages of the python module is installed in the root
    environment.

    If a specific python environment is required, one can use conda to create the environment
    and then set ENV["PYTHON"] to the path of the python executable in that environment. This
    requires a rebuild of `PyCall` with `Pkg.build("PyCall")` followed by a restart of Julia.

!!! warning "Arguments"
    If kwargs is not used and the function requires arguments, the function will assume all
    arguments are collected in the `Vector` `args`. That is, if you only have one argument
    to the python function which is a Vector, it must be passed as a Vector of the Vector.
"""
function call_python_function(module_name::String, function_name::String; kwargs...)
    # Import the requested function from the python module
    python_function = get_python_function(module_name, function_name)

    # Call the Python function with kwargs as input, and return the result.
    @info "Calling $function_name in the Python module $module_name"
    return python_function(; kwargs...)
end
function call_python_function(module_name::String, function_name::String, args::Vector)
    # Import the requested function from the python module
    python_function = get_python_function(module_name, function_name)

    # Call the Python function with kwargs as input, and return the result.
    @info "Calling $function_name in the Python module $module_name"
    return python_function(args...)
end

"""
    get_python_function(module_name::String, function_name::String)

Import the requested function `function_name` from the python module `module_name`.
"""
function get_python_function(module_name::String, function_name::String)
    # Import the requested function from the python module
    sub_names = split(function_name, ".")
    python_function = pyimport(module_name)
    for name ∈ sub_names
        python_function = python_function[name]
    end
    return python_function
end

"""
    cleanup_libraries()

Close all the C module libraries that have been loaded by `EnergyModelsLanguageInterfaces`.
"""
function cleanup_libraries()
    for (libpath, lib) ∈ LIB_CACHE
        @info "Closing the C module library $libpath"
        Libdl.dlclose(lib)
    end
    empty!(LIB_CACHE)
end

"""
    getfirst(f::Function, a::Vector)

Return the first element of Vector `a` satisfying the requirement of Function `f`.
"""
function getfirst(f::Function, a::Vector)
    index = findfirst(f, a)
    return isnothing(index) ? nothing : a[index]
end

"""
    fetch_element(elements, id)

Fetch the element with the given `id` from the `elements` array.
"""
function fetch_element(elements, id)
    return getfirst(element -> element.id == id, elements)
end

"""
    pvgis_profile(time_start::DateTime, params::PVParameters;
        peakpower::Real=1.0,
        data_path::String = "pvgis_cache",
        filename_hint::String = "",
        normalize::Bool = true,
        no_weather_years::Int = 1,
        remove_leap_day::Bool = true,
    )

Fetches hourly photovoltaic (PV) power output data for a specified start time
(`time_start`), PV system parameters (`params`), and additional options, using the
PVGIS `seriescalc` API. The function caches the results locally in a CSV file to
optimize subsequent calls.

The actual call to the PVGIS API is handled by the helper function `get_pvgis_data`
see [`get_pvgis_data`](@ref) for details.

# Arguments
- **`time_start::DateTime`**: The start of the time range for which the PV output data
  is requested.
- **`params::PVParameters`**: Struct containing PV system and location parameters
  (e.g., latitude, longitude, peak power, technology, etc.).
- **`peakpower::Real=1.0`**: Nominal peak power of the PV system in kilowatts (kW).
- **`data_path::String="pvgis_cache"`**: Directory where the cached CSV file will be
  stored.
- **`filename_hint::String=""`**: Optional string to include in the cache file name for
  identification.
- **`normalize::Bool=true`**: Whether to normalize the power output by the peak power
  (i.e., return values between 0 and 1).
- **`no_weather_years::Int=1`**: Number of years of weather data to fetch.
- **`remove_leap_day::Bool=true`**: Whether to remove February 29th from the results.

# Returns
A `DataFrame` containing the following columns:
- **`:time_utc`**: Timestamps in UTC, rounded to the nearest hour.
- **`:pv`**: PV power output in kilowatts (kW), normalized if requested.
"""
function pvgis_profile(time_start::DateTime, params::PVParameters;
    peakpower::Real = 1.0,
    data_path::String = "pvgis_cache",
    filename_hint::String = "",
    normalize::Bool = true,
    no_weather_years::Int = 1,
    remove_leap_day::Bool = true,
)
    # Ensure the cache directory exists
    isdir(data_path) || mkpath(data_path)

    start_year = year(time_start)

    # If the time range starts at the beginning of the year, we can fetch data for that year only. 
    # Otherwise, we need to fetch data for multiple years to cover the entire range.
    if time_start == DateTime(start_year, 1, 1)
        end_year = start_year + no_weather_years - 1
    else
        end_year = start_year + no_weather_years
    end

    # Create a sanitized file hint for the cache file name
    if isempty(filename_hint)
        filehint = ""
    else
        filehint = "_" * replace(filename_hint, r"[^\w\.-]" => "_")
    end

    csv_path = joinpath(
        data_path,
        "pvgis_$(Dates.format(time_start, "yyyymmdd"))_$(no_weather_years)$(filehint).csv",
    )

    if isfile(csv_path) && filesize(csv_path) > 0
        return CSV.read(csv_path, DataFrame)

    else
        df = get_pvgis_data(start_year, end_year, params; peakpower, normalize)

        if remove_leap_day
            # Remove special case of Feb 29 in non-leap years
            df = filter(r -> !(month(r[:time]) == 2 && day(r[:time]) > 28), df)
        end

        # Keep only the relevant columns (time and power), and rename time.
        select!(df, [:time, :P])

        # Rename time column to be more descriptive.
        rename!(df, :time => :time_utc)
        rename!(df, :P => :pv)

        # Cache the results to CSV for future use.
        CSV.write(csv_path, df)

        return df
    end
end

"""
    get_pvgis_data(start_year::Int64, end_year::Int64, params::PVParameters, peakpower::Real, normalize::Bool)

# Arguments
- **`start_year::Int64`**: The starting year for the PVGIS data request.
- **`end_year::Int64`**: The ending year for the PVGIS data request.
- **`params::PVParameters`**: Struct containing PV system and location parameters
  (e.g., latitude, longitude, technology, etc.).
- **`peakpower::Real = 1.0`**: Nominal peak power of the PV system in kilowatts (kW).
- **`normalize::Bool = true`**: Whether to normalize the power output by the peak power.

Fetches hourly photovoltaic (PV) power output data for the specified years and PV system 
parameters using the PVGIS `seriescalc` API.

# Details
The function queries the PVGIS `seriescalc` API, which provides hourly PV power output
data based on the specified location, system parameters, and meteorological data. The
API calculates the power output using the following inputs:
- Solar radiation data.
- PV system parameters (e.g., peak power, technology, mounting type).
- Meteorological data (e.g., air temperature, wind speed).

The response includes hourly data for the specified years, which is parsed and
processed into a `DataFrame`. The power output is converted from watts (W) to
kilowatts (kW) for better readability. 

# Caching
The results are cached locally in a CSV file to avoid redundant API calls. The cache
file is stored in the specified `data_path` directory, and its name includes the date,
number of years, and an optional `filename_hint`.

!!! note
    The PVGIS API documentation is available at:
    https://joint-research-centre.ec.europa.eu/photovoltaic-geographical-information-system-pvgis/getting-started-pvgis/pvgis-user-manual_en

!!! note
    Due to current limitations on PVGIS, only dates within the years 2005 to 2023 can
    be queried.
"""
function get_pvgis_data(
    start_year::Int64,
    end_year::Int64,
    params::PVParameters;
    peakpower::Real = 1.0,
    normalize::Bool = true,
)
    base = "https://re.jrc.ec.europa.eu/api/seriescalc"

    query = Dict(
        "lat" => string(params.lat),
        "lon" => string(params.lon),
        "startyear" => string(start_year),
        "endyear" => string(end_year),
        "outputformat" => "json",
        "usehorizon" => params.usehorizon ? "1" : "0",
        "pvcalculation" => "1",
        "peakpower" => string(peakpower),
        "pvtechchoice" => params.pvtechchoice,
        "mountingplace" => params.mountingplace,
        "loss" => string(params.loss),
        "trackingtype" => "0",
        "optimalangles" => params.optimalangles ? "1" : "0",
    )

    # Build url
    qs = join(
        [string(k, "=", HTTP.escapeuri(v)) for (k, v) ∈ query],
        "&",
    )
    url = string(base, "?", qs)

    # Make the HTTP request with a custom User-Agent and Accept header to indicate we want JSON.
    @debug "Fetching PVGIS data for lat=$(params.lat), lon=$(params.lon), year=$(start_year) from PVGIS API..."
    resp = try
        HTTP.get(
            url;
            headers = [
                "User-Agent" => "EnergyModelsLanguageInterfaces.jl",
                "Accept" => "application/json",
            ],
        )
    catch e
        if isa(e, HTTP.Exceptions.StatusError)
            # Try to extract error message from response body if available
            body = String(e.response.body)
            msg = try
                parsed = JSON.parse(body)
                haskey(parsed, "message") ? parsed["message"] : body
            catch
                body
            end
            error("PVGIS request failed with status $(e.status): $msg \n URL: $url")
        else
            rethrow(e)
        end
    end

    # Parse the JSON response. We expect a structure with `outputs.hourly` containing the data.
    parsed = JSON.parse(String(resp.body))

    if !haskey(parsed, :outputs) || !haskey(parsed.outputs, :hourly)
        error("Missing `outputs.hourly` in PVGIS response.")
    end

    # Extract the hourly data, which should be an array of records. Each record is expected to have a `time` field and a `P` field for power output, among others.
    hourly = parsed["outputs"]["hourly"]

    rows = Vector{Dict{Symbol,Any}}(undef, length(hourly))
    for (i, rec) ∈ pairs(hourly)
        d = Dict{Symbol,Any}()
        for (k, v) ∈ rec
            if k == "time"
                d[:time] = round(DateTime(v, dateformat"yyyymmdd:HHMM"), Dates.Hour)
            elseif k == "P"
                d[:P] = v / 1000  # Convert power from W to kW
                if normalize
                    d[:P] /= peakpower  # Normalize by peak power if requested
                end
            end
        end
        rows[i] = d
    end

    # Column description available at https://joint-research-centre.ec.europa.eu/photovoltaic-geographical-information-system-pvgis/pvgis-tools/hourly-radiation_en:
    # time [UTC]
    # P [W] - PV power output (if requested)
    # G(i) [W/m2] - Global in-plane irradiance (if radiation components are not requested
    # Gb(i) [W/m2] - Direct in-plane irradiance (if radiation components are requested)
    # Gd(i) [W/m2] - Diffuse in-plane irradiance (if radiation components are requested)
    # Gr(i) [W/m2] - Reflected in-plane irradiance (if radiation components are requested)
    # H_sun [°] - Sun height (elevation)
    # T2m [°C] - Air temperature
    # WS10m [m/s] - Wind speed at 10m
    return DataFrame(rows)
end
