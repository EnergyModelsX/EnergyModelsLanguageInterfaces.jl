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
        python_function = getproperty(python_function, name)
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

function sanitize_filename_hint(filename_hint::String)
    if isempty(filename_hint)
        filehint = ""
    else
        filehint = "_" * replace(filename_hint, r"[^\w\.-]" => "_")
    end
    return filehint
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
    filehint = sanitize_filename_hint(filename_hint)

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

"""
    heat_demand_profile(
        time_start::DateTime,
        time_end::DateTime,
        lat::Real,
        lon::Real,
        temp_to_demand::Function;
        data_path::String = "metocean_api_data",
        filename_hint::String = "",
        source::String = "NORA3",
        reload_csv::Bool = true,
        save_csv::Bool = true,
        use_cache::Bool = true,
    )

Generates a heat demand profile for a specified location and time period using temperature data 
and a user-provided temperature-to-demand mapping function.

The function retrieves temperature data for the given latitude and longitude from the specified
data source (e.g., "NORA3" or "ERA5") and applies the `temp_to_demand` function to convert
temperature values into heat demand.

The data source is queried using the [`get_met_data`](@ref) function, which handles data retrieval, 
caching, and storage.

# Arguments
- **`time_start::DateTime`** is the start of the time period for the demand profile.
- **`time_end::DateTime`** is the end of the time period for the demand profile.
- **`lat::Real`** is the latitude of the location.
- **`lon::Real`** is the longitude of the location.
- **`temp_to_demand::Function`** is a function mapping temperature in Kelvin to demand.
- **`data_path::String`** is the directory path to store or load temperature data (default: "metocean_api_data").
- **`filename_hint::String`** is an optional hint for naming the data file (default: "").
- **`source::String`** is the data source for temperature (default: "NORA3").
- **`reload_csv::Bool`** is a flag indicating whether to reload CSV data if available (default: true).
- **`save_csv::Bool`** is a flag indicating whether to save the generated profile to a CSV file (default: true).
- **`use_cache::Bool`** is a flag indicating whether to use cached data if available (default: true).
"""
function heat_demand_profile(
    time_start::DateTime,
    time_end::DateTime,
    lat::Real,
    lon::Real,
    temp_to_demand::Function;
    data_path::String = "metocean_api_data",
    filename_hint::String = "",
    source::String = "NORA3",
    reload_csv::Bool = true,
    save_csv::Bool = true,
    use_cache::Bool = true,
)
    if source == "NORA3"
        product = "NORA3_atm_sub"
        variables = ["air_temperature_2m"]
    elseif source == "ERA5"
        product = "ERA5"
        variables = ["2m_temperature"]
    else
        error("Unsupported data source: $source. Use 'NORA3' or 'ERA5'.")
    end
    df = get_met_data(
        time_start,
        time_end,
        lat,
        lon,
        product,
        variables;
        data_path,
        filename_hint,
        reload_csv,
        save_csv,
        use_cache,
    )
    temperature_column = variables[1]
    if !(temperature_column in names(df))
        error("Temperature column $temperature_column not found in meteorological data.")
    end
    df.heat_demand = temp_to_demand.(df[!, temperature_column])
    return df
end

"""
    get_met_data(
        time_start::DateTime, 
        time_end::DateTime, 
        lat::Real, 
        lon::Real, 
        product::String, 
        variables::Vector{String}; 
        data_path::String = "metocean_api_data", 
        filename_hint::String = "", 
        reload_csv::Bool = true, 
        save_csv::Bool = true, 
        use_cache::Bool = true,
    )

Fetches meteorological data for a specified time range and geographic location.

# Arguments
- **`time_start::DateTime`**: Start of the time range for data retrieval.
- **`time_end::DateTime`**: End of the time range for data retrieval.
- **`lat::Real`**: Latitude of the location.
- **`lon::Real`**: Longitude of the location.
- **`product::String`**: Name of the meteorological data product to use.
- **`variables::Vector{String}`**: List of meteorological variables to retrieve.
- **`data_path::String`**: Directory path where data files are stored or will be saved.
- **`filename_hint::String`**: Hint for naming the output file.
- **`reload_csv::Bool`**: If true, reloads CSV data if available (default: true).
- **`save_csv::Bool`**: If `true`, saves the retrieved data as a CSV file (default: true).
- **`use_cache::Bool`**: If `true`, uses cached data if available (default: true).

# Notes
- The function may download data from remote sources if not available locally.
- If `save_csv` is enabled, the data will be saved to a CSV file in the specified `data_path`.
- Caching behavior is controlled by the `use_cache` parameter.

!!! note "Usage of the ERA5 data source"
    For use of the "ERA5" data source, the user needs to register and obtain a CDS API key.
    -  Perform step 1: https://cds.climate.copernicus.eu/how-to-api
"""
function get_met_data(
    time_start::DateTime,
    time_end::DateTime,
    lat::Real,
    lon::Real,
    product::String,
    variables::Vector{String};
    data_path::String = "metocean_api_data",
    filename_hint::String = "",
    reload_csv::Bool = true,
    save_csv::Bool = true,
    use_cache::Bool = true,
)
    # Ensure the cache directory exists
    isdir(data_path) || mkpath(data_path)

    # Create a sanitized file hint for the cache file name
    filehint = sanitize_filename_hint(filename_hint)

    csv_path = joinpath(
        data_path,
        product * "_" * Dates.format(time_start, "yyyymmdd") * "_" *
        Dates.format(time_end, "yyyymmdd") * "_lat" * string(lat) * "_lon" *
        string(lon) * filehint * ".csv",
    )

    if reload_csv && isfile(csv_path) && filesize(csv_path) > 0
        df = CSV.read(
            csv_path,
            DataFrame;
            comment = "#",
            dateformat = "yyyy-mm-dd HH:MM:SS",
            types = Dict(:time => DateTime),
        )
        rename!(df, :time => :time_utc)
        return df
    else
        ts = pyimport("metocean_api.ts")
        ts_data = ts.TimeSeries(
            lon = lon,
            lat = lat,
            start_time = Dates.format(time_start, "yyyy-mm-dd"),
            end_time = Dates.format(time_end, "yyyy-mm-dd"),
            product = product,
            variable = variables,
            datafile = nothing,
        )
        ts_data.datafile = csv_path
        ts_data.import_data(save_csv = save_csv, save_nc = false, use_cache = use_cache)
        idx_np = ts_data.data.index.to_numpy(copy = true)
        time = DateTime(1970, 1, 1) .+ Nanosecond.(idx_np.astype("int64"))
        data = ts_data.data.to_numpy(copy = true)
        colnames = Symbol.(ts_data.data.columns.tolist())
        df = DataFrame([time data], [:time_utc; colnames...])
        # Ensure correct types
        df.time_utc = DateTime.(df.time_utc)
        for col ∈ colnames
            df[!, col] = Float64.(df[!, col])
        end
        
        @info("PyCall python", PyCall.pyversion, PyCall.libpython)
        md = pyimport("importlib.metadata")

        met = pyimport("metocean_api")
        @info("metocean_api version", md.version("metocean-api"))

        return df
    end
end
