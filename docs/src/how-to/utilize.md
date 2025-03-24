# [Utilize the concepts of `EnergyModelsUtilities`](@id how_to-utilize)

## [Call external functions](@id how_to-utilize-ext_fun)

### [Call Python functions](@id how_to-utilize-ext_fun-Python)

To evaluate a python function (with input argument `input`) called `my_func` which 
is available in the `my_python_package`, you can do the following

```julia
output = EMU.call_python_function("my_python_package", "my_func"; input)
```

!!! note
    All python package dependencies must be available in the root environment. 

    If you want to install non-standard python packages and/or you want to sample
    a local package you must create a conda environment (using a conda installation),
    or an other environment management system (not tested yet), and install required 
    packages there. E.g.,
    ```bash
    conda create --name testenv python=3.10
    conda activate testenv
    conda install -c conda-forge poetry
    cd path_to_your_python_project
    poetry install
    ```
    You must then (in Julia) set (it is here assumed you use miniconda on Windows)
    ```julia
    using Pkg
    Pkg.add("PyCall")
    ENV["PYTHON"] = joinpath(homedir(), "AppData", "Local", "miniconda3", "envs", "testenv", "python.exe")
    Pkg.build("PyCall")
    ```
    and restart Julia.

### [Call C++ functions](@id how_to-utilize-ext_fun-Cpp)

To evaluate a C++ function (with input argument `input`) called `my_func` which 
is available in the library `libpath` which can be compiled by a `cpp` file located at `filepath`, you can do the following

```julia
output = EMU.call_cpp_function(libpath, "my_func", input; filepath)
```

!!! note
    If the `.so`-file already exist for the shared library it will not be recompiled (unless you set the key word argument `compile` to `true`).
    If compilation is required, make sure to have the `g++`-compiler available. 

    Also note that the C++-library is kept open to enable fast multiple evaluations of the `call_cpp_function`, but this reduces permissions on the `.so`-file.
    In order to close the usage of the library, simply call `EMU.cleanup_libraries()` in Julia.