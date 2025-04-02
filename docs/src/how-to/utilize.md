# [Utilize the concepts of `EnergyModelsLanguageInterfaces`](@id how_to-utilize)

## [Call external functions](@id how_to-utilize-ext_fun)

### [Call Python functions](@id how_to-utilize-ext_fun-Python)

To evaluate a python function (with input argument `input`) called `my_func` which
is available in the `my_python_package`, you can do the following

```julia
output = EMLI.call_python_function("my_python_package", "my_func"; input)
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

### [Call C/C++ functions](@id how_to-utilize-ext_fun-Cpp)

There is no generic way of implementing a function for compiling, loading and running C/C++ code as it is for python while maintaining generality in the number of input/output arguments (and their types).
Instead, one can create specialized function to obtain this using the `@ccall`-macro as outlined in [doubling.jl](https://gitlab.sintef.no/idesignres/wp-2/EnergyModelsLanguageInterfaces.jl/-/blob/main/test/doubling_module/doubling.jl).
Such a function can be made in your Julia framework, or its coding lines can be directly incorporated where you want to call your C/C++ function.
For the doubling example, one is able to call the C++ function with

```julia
using EnergyModelsLanguageInterfaces
EMLI_path = pkgdir(EnergyModelsLanguageInterfaces)
libpath = joinpath(EMLI_path, "test", "doubling_module", "libdoubling.so")
filepath = joinpath(EMLI_path, "test", "doubling_module", "doubling.cpp")
cpp_function_name = "doubling"
input_cpp::Vector{Cdouble} = [1.4, 2.0, 1.2]
include(joinpath(EMLI_path, "test", "doubling_module", "doubling.jl"))
demand_profile = doubling(libpath, cpp_function_name, input_cpp; filepath)
```

Calling C++ functions that cannot be wrapped in a C environment requires more manual work.
One must use [CxxWrap](https://github.com/JuliaInterop/CxxWrap.jl).
This package builds on [libcxxwrap](https://github.com/JuliaInterop/libcxxwrap-julia/tree/main) which must be installed first.
Start by cloning this repository

```bash
git clone https://github.com/JuliaInterop/libcxxwrap-julia.git
git checkout v0.13.4
```

In VS Code open a new Julia session and navigate to the folder containing the `libcxxwrap-julia`-repository cloned above.
Check out

```julia
] develop libcxxwrap_julia_jll
```

Next, import the package and call the `dev_jll` function:

```julia
import libcxxwrap_julia_jll
libcxxwrap_julia_jll.dev_jll()
```

In a terminal compile the `libcxxwrap` with

```bash
cd /home/user/.julia/dev/libcxxwrap_julia_jll/override
rm -rf *
cmake -DJulia_PREFIX="C:/Users/user/.julia/juliaup/julia-1.11.3+0.x64.w64.mingw32" "C:/Users/user/kode/iDesignRES/libcxxwrap-julia"
cmake --build . --config Release
```

where the `JULIA_PREFIX` above must be updated to the executable of your julia installation and the location of the `libcxxwrap-julia`-repository cloned above.

In Julia you can now activate your project and add `CxxWrap` through

```julia
using CxxWrap
CxxWrap.prefix_path()
```
which should return `"/home/user/.julia/dev/libcxxwrap_julia_jll/override"`.

!!! note
    If this instead returns `"/home/user/.julia/artifacts/5016ccec96368c99a5a678ab3319d1da7bb9a2c7"`, create a n`Overrides.toml` file at `/home/user/.julia/artifacts` with  the following content

    ```toml
    [3eaa8342-bff7-56a5-9981-c04077f7cee7]
    libcxxwrap_julia = "C:/Users/user/.julia/dev/libcxxwrap_julia_jll/override"
    ```

    to point to your `libcxxwrap` build.

!!! note
    If you get the error `ERROR: InitError: This version of CxxWrap requires a libcxxwrap-julia in the range (v"0.13.0", v"0.14.0"), but version 0.14.0 was found`, it might be related to that the main branch is set to `version 0.14.0+0` in its `binarybuilder/Manifest.toml`-file in accordance.
    You can try to clone `CxxWrap`, change the toml file to `libcxxwrap_julia_jll = "0.13.4"` (instead of `0.14.0` which is not available yet), and `develop` `CxxWrap` in your environment.

An example is given by the *[trippling_module example](https://gitlab.sintef.no/idesignres/wp-2/EnergyModelsLanguageInterfaces.jl/-/blob/main/test/trippling_module/)*.
