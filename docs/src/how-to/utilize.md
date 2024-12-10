# [Utilize the concepts of `EnergyModelsUtilities`](@id how_to-utilize)

## [Call external functions](@id how_to-utilize-ext_fun)

### [Call Python functions](@id how_to-utilize-ext_fun-Python)

To evaluate a python function (with input argument `input`) called `my_func` which 
is available in the file `my_python_file.py` located at `filepath`, you can do the following

```julia
output = EMU.call_python_function("my_python_file", "my_func", input; "filepath")
```

!!! note
    All python package dependencies must be available in the root environment. 
    You can add packages with, *e.g.*, `using Conda; Conda.add("pyomo")`.

To evaluate a C++ function (with input argument `input`) called `my_func` which 
is available in the library `libpath` which can be compiled by a `cpp` file located at `filepath`, you can do the following

### [Call C++ functions](@id how_to-utilize-ext_fun-Cpp)

```julia
output = EMU.call_cpp_function(libpath, "my_func", input; filepath)
```

!!! note
    If the `.so`-file already exist for the shared library it will not be recompiled (unless you set the key word argument `compile` to `true`).
    If compilation is required, make sure to have the `g++`-compiler available. 

    Also note that the C++-library is kept open to enable fast multiple evaluations of the `call_cpp_function`, but this reduces permissions on the `.so`-file.
    In order to close the usage of the library, simply call `EMU.cleanup_libraries()` in Julia.