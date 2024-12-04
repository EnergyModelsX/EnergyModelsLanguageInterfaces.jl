using PyCall
using Libdl

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
environment (otherwise this can be resolved by, e.g., `using Conda; Conda.add("pyomo")`).

Note that this approach is greatly simplified if the module is available in the root environment.

Also note that installing Python packages for use with PyCall requires the use of the root environment.
"""
function call_python_function(
    module_name::String, function_name::String, input; module_path::String=""
)
    # If the module is provided locally, add the path to the Python sys path
    if !isempty(module_path)
        sys_paths = pyimport("sys")."path"
        if !(module_path in sys_paths)
            push!(sys_paths, module_path)
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
        libpath::String, function_name::String, input; compile::Bool=false, filepath::String = ""
    )

Call the function `function_name` of the module with shared library (e.g., .so-file) at `libpath`.

Note that is assumed that the g++ compiler is installed on the system and available from the
PATH variable.
"""
function call_cpp_function(
    libpath::String, function_name::String, input; compile::Bool=false, filepath::String=""
)
    if compile || !isfile(libpath)
        if !isfile(filepath)
            error("The file $filepath does not exist.")
        end

        # Compile the C++ module
        @info "Compiling the C++ module $libpath"
        run(`g++ -fPIC -shared $filepath -o $libpath`)
    end

    # Load the shared library
    lib = Libdl.dlopen(libpath)

    # Allocate the output variable
    n = length(input)
    output = Vector{Cdouble}(undef, n)

    # Call the function
    @info "Calling the C++ module $libpath"
    @ccall $(@dlsym(lib, function_name))(
        input::Ptr{Cdouble}, n::Cint, output::Ptr{Cdouble}
    )::Cvoid

    # Close the shared library
    @info "Closing the C++ module library $libpath"
    Libdl.dlclose(lib)

    return output
end
