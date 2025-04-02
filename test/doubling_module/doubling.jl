using Libdl

# Keep a global reference to the loaded library
const LIB_CACHE = Dict{String,Ptr{Cvoid}}()

include(joinpath(@__DIR__, "..", "..", "src", "macros.jl"))

"""
    doubling(
        libpath::String,
        function_name::String,
        input::Vector{Cdouble};
        filepath::String="",
        compile::Bool=false,
        compiler::String="g++",
        flags::String="-fPIC -shared",
    )

Example function showing how to call a C function from Julia (or a C++ function with a C interface).

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

function doubling(
    libpath::String,
    function_name::String,
    input::Vector{Cdouble};
    filepath::String = "",
    compile::Bool = false,
    compiler::String = "gcc",
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
        LIB_CACHE[libpath] = Libdl.dlopen(string(libpath))
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
    # Ensure the input and output arrays are passed correctly
    #ccall(
    #    (function_name, lib),
    #    Cvoid,
    #    (Ptr{Cdouble}, Cint, Ptr{Cdouble}),
    #    input, n, output
    #)
    return output
end
