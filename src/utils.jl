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
    call_python_function(module_name::String, function_name::String, input; module_path::String = "")

Call an external Python function.

## Arguments
- `module_name` - the name of the Python module to be used.
- `function_name` - the name of the function to be called.
- `input` - the input to the function to be called. Multiple input arguments is currently not supported.

## Keyword Arguments
- `module_path` - optional argument for the directory of the module. If not specified,
  it is assumed that the module is available in the root environment.

!!! note "Environments"
    It is assumed that the required packages of the python module is installed in the root
    environment (otherwise this can be resolved by, *e.g.*, `using Conda; Conda.add("pyomo")`).

    This approach is greatly simplified if the module is available in the root environment.

    Installing Python packages for use with PyCall requires the use of the root environment.
"""
function call_python_function(
    module_name::String, function_name::String, input; module_path::String = "",
)
    # If the module is provided locally, add the path to the Python sys path
    if !isempty(module_path)
        sys_paths = pyimport("sys")."path"
        if !(module_path in collect(sys_paths))
            sys_paths.append(module_path)
        end
    end

    # Import the requested function from the python module
    python_function = pyimport(module_name)[function_name]

    # Call the Python function with inputs a, b and c, and return the result.
    @info "Calling the Python module $module_name"
    return python_function(input)
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
