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

Call the function `function_name` of `module_name` located at `module_path`.
It is assumed that the required packages of the python module is installed in the root
environment (otherwise this can be resolved by, *e.g.*, `using Conda; Conda.add("pyomo")`).

!!! note "Note on environments"
    This approach is greatly simplified if the module is available in the root environment.

    Also note that installing Python packages for use with PyCall requires the use of the root environment.
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
        input;
        filepath::String="",
        compile::Bool=false,
        compiler::String="g++",
        flags::String="-fPIC -shared",
    )

Call the function `function_name` of the module with shared library (*e.g.*, .so-file) at `libpath`.

The `flags` argument is used to specify the flags to be passed to the compiler. They must be
compatible with the chosen `compiler` and create a shared library.

!!! note "Compiler"
    It is assumed that the chosen compiler is installed on the system. The full path to
    the compiler may be provided in the `compiler` argument, otherwise it must be available in PATH.
"""
function call_cpp_function(
    libpath::String,
    function_name::String,
    input;
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
