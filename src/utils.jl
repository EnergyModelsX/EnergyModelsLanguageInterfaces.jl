using PyCall

"""
    call_python_function(module_name::String, function_name::String; kwargs...)
    call_python_function(module_name::String, function_name::String, args::Vector)

Call an external Python function.

## Arguments
- `module_name` - the name of the Python module to be used.
- `function_name` - the name of the function to be called. Nested names (e.g., due to sub modules)
  must be separated by ".".

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
