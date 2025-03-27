using PyCall
using Libdl

# Keep a global reference to the loaded library
const LIB_CACHE = Dict{String,Ptr{Cvoid}}()

"""
    @dlsym(lib, func)

This macro uses `dlsym` to load a function from a shared library specified by `lib` and `func`.
It caches the result in a `Ref` to avoid repeated lookups. If the symbol is already loaded,
it returns the cached pointer. Otherwise, it loads the symbol, caches it, and then returns the pointer.
"""
macro dlsym(lib, func)
    z = Ref{Ptr{Cvoid}}(C_NULL)
    quote
        let zlocal = $z[]
            if zlocal == C_NULL
                zlocal = dlsym($(esc(lib))::Ptr{Cvoid}, $(esc(func)))::Ptr{Cvoid}
                $z[] = zlocal
            end
            zlocal
        end
    end
end

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
    environment (otherwise this can be resolved by, *e.g.*, `using Conda; Conda.add("pyomo")`).

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
    call_cpp_function(
        libpath::String,
        function_name::String,
        input::Vector{Cdouble};
        filepath::String="",
        compile::Bool=false,
        compiler::String="g++",
        flags::String="-fPIC -shared",
    )

Call an external C/C++ function.

## Arguments
- `libpath` - the path of the shared library (*e.g.*, .so-file) to be used (or the destination
  at which the compiled shared library should be placed).
- `function_name` - the name of the function to be called.
- `input` - a `Vector` of `Cdouble`s passed as input to the function to be called.

## Keyword Arguments
- `filepath` - the path to the .c or .cpp file to be compiled (if the .so file is not available
  or must be recompiled).
- `compile` - a boolean to control if recompilation is desired.
- `compiler` - a string of the compiler command (if it exist in PATH) or the path to the compiler.
- `flags` - the optional arguments is used to specify the flags to be passed to the compiler.
  They must be compatible with the chosen `compiler` and create a shared library.

!!! note "Compiler"
    It is assumed that the chosen compiler is installed on the system. The full path to
    the compiler may be provided in the `compiler` argument, otherwise it must be available in PATH.
"""
function call_cpp_function(
    libpath::String,
    function_name::String,
    input::Vector{Cdouble};
    filepath::String = "",
    compile::Bool = false,
    compiler::String = "g++",
    flags::String = "-fPIC -shared",
)
    if compile || !isfile(libpath)
        if !isfile(filepath)
            error("The file $filepath does not exist.")
        end

        # Compile the C++ module
        @info "Compiling the C/C++ module $libpath"
        cmd::Vector{String} = [compiler, split(flags, ' ')..., filepath, "-o", libpath]
        run(Cmd(cmd))
    end

    # Load the library if it's not already cached
    if !haskey(LIB_CACHE, libpath)
        @info "Loading the C/C++ module $libpath"
        LIB_CACHE[libpath] = Libdl.dlopen(libpath)
    end
    lib = LIB_CACHE[libpath]

    # Allocate the output variable
    n = length(input)
    output = Vector{Cdouble}(undef, n)

    # Call the function
    @info "Calling the C/C++ module $libpath"
    @ccall $(@dlsym(lib, function_name))(
        input::Ptr{Cdouble}, n::Cint, output::Ptr{Cdouble},
    )::Cvoid

    return output
end

"""
    cleanup_libraries()

Close all the C++ module libraries that have been loaded by `EnergyModelsUtilities`.
"""
function cleanup_libraries()
    for (libpath, lib) ∈ LIB_CACHE
        @info "Closing the C++ module library $libpath"
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
