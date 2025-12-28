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
Instead, one can create specialized function to obtain this using the `@ccall`-macro as outlined in [doubling.jl](https://github.com/EnergyModelsX/EnergyModelsLanguageInterfaces.jl/tree/main/test/doubling_module/doubling.jl).
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
    If this instead returns `"/home/user/.julia/artifacts/5016ccec96368c99a5a678ab3319d1da7bb9a2c7"`, create an `Overrides.toml` file at `/home/user/.julia/artifacts` with  the following content

    ```toml
    [3eaa8342-bff7-56a5-9981-c04077f7cee7]
    libcxxwrap_julia = "C:/Users/user/.julia/dev/libcxxwrap_julia_jll/override"
    ```

    to point to your `libcxxwrap` build.

!!! note
    If you get the error `ERROR: InitError: This version of CxxWrap requires a libcxxwrap-julia in the range (v"0.13.0", v"0.14.0"), but version 0.14.0 was found`, it might be related to that the main branch is set to `version 0.14.0+0` in its `binarybuilder/Manifest.toml`-file in accordance.
    You can try to clone `CxxWrap`, change the toml file to `libcxxwrap_julia_jll = "0.13.4"` (instead of `0.14.0` which is not available yet), and `develop` `CxxWrap` in your environment.

An example is given by the *[trippling_module example](https://github.com/EnergyModelsX/EnergyModelsLanguageInterfaces.jl/tree/main/test/trippling_module/)*.

## [Use implemented nodes](@id how_to-utilize-use_nodes)

The nodes [`WindPower`](@ref WindPower), [`CSPandPV`](@ref CSPandPV) and [`MultipleBuildingTypes`](@ref MultipleBuildingTypes) have [constructors](@ref lib-pub-sampling_constructors) that samples [`wind_power_timeseries`](https://gitlab.sintef.no/harald.svendsen/wind_power_timeseries), [`Tecnalia_Solar-Energy-Model`](https://github.com/iDesignRES/Tecnalia_Solar-Energy-Model) and [`Tecnalia_Building-Stock-Energy-Model`](https://github.com/iDesignRES/Tecnalia_Building-Stock-Energy-Model), respectively. These modules are python based and the usage of these [constructors](@ref lib-pub-sampling_constructors) requires installation of these as documented [below](@ref how_to-utilize-use_nodes-python_modules).

Additionally, the node [`BioCHP`](@ref BioCHP) have a [constructor](@ref lib-pub-sampling_constructors) that samples the [CHP_modelling](https://github.com/iDesignRES/CHP_modelling) module. This module is `C++` based and the [constructor](@ref lib-pub-sampling_constructors) then requires compilation and build before usage as described further [below](@ref how_to-utilize-use_nodes-cpp_modules).

The following installation guides will show how to install the modules to enable usage of these [constructors](@ref lib-pub-sampling_constructors) for both Windows and Linux. 

### [Clone repositories](@id how_to-utilize-use_nodes-clone_repos)

Navigate to a folder in which you want to download required repositories and run

```PowerShell
git clone --recurse-submodules git@github.com:EnergyModelsX/EnergyModelsLanguageInterfaces.jl.git
```

You should now be enabled to enter the main folder in which the other modules are located (under the submodules folder)

```PowerShell
cd EnergyModelsLanguageInterfaces.jl
```

!!! note "Install git"
    If you do not have git available in your PowerShell, make sure to [download](https://git-scm.com/install/windows) and install it properly (make sure to enable adjustment of the PATH environment).


### [Install python modules](@id how_to-utilize-use_nodes-python_modules)

The following installs the modules using [`poetry`](https://pypi.org/project/poetry/) in a PowerShell in [VS code](https://code.visualstudio.com/). 

!!! note "Python installation"
    You must have a python installation available in the terminal in VS code.
    Python can be downloaded from [here](https://www.python.org/downloads/windows/) and installed by launching the downloaded installer (remember to "Add Python to PATH"). You must restart VS Code (and possibly any other open PowerShell windows) to have python available in the embedded VS code terminal. Check that you have python installed correctly with

    ```PowerShell
    python --version
    ```

    which should return something like `Python 3.11.9`.

Start by installing `poetry` using `pip` (which should be included in the python installation)

```PowerShell
pip install poetry
```

Navigate to the submodule you want to install and run `poetry install`. If you want all python modules installed run the following

```PowerShell
cd submodules/wind_power_timeseries
poetry install
cd ../..
cd submodules/Tecnalia_Solar-Energy-Model
poetry install
cd ../..
cd submodules/Tecnalia_Building-Stock-Energy-Model
poetry install
cd ../..
```

If you want to be able to run the tests of the main repository later (see [Test modules](@ref how_to-utilize-use_nodes-test)), make sure to install the `python_module` (located in the `test/python_module` folder)

```PowerShell
pip install highspy
cd test/python_module
poetry install
cd ../..
```

!!! note "Environments"
    If you are a developer, you probably want to install the python modules in a separate environment which can be done with, e.g., [miniconda](https://www.anaconda.com/docs/getting-started/miniconda/install).

Enable these by starting a julia session in the main folder

```PowerShell
julia --project=.
```

and run the following

```julia
using Pkg
Pkg.instantiate()
ENV["PYTHON"] = joinpath(homedir(), "AppData", "Local", "Programs", "Python", "Python311", "python.exe")
Pkg.build("PyCall")
```

followed by restarting Julia.

!!! note "Path to Python executable"
    The path in the previous commands must be adjusted to the path of your python executable which can be found with

    ```PowerShell
    (Get-Command python).Source
    ```

### [Install C++ modules](@id how_to-utilize-use_nodes-cpp_modules)

Start by installing [`conan`](https://pypi.org/project/conan/)

```PowerShell
pip install conan
conan profile detect
```

Navigate to the `CHP_modelling` folder, build and install the module with the following

```PowerShell
cd submodules/CHP_modelling
mkdir build
cd build
conan install .. --output-folder=. --build=missing -s compiler.cppstd=17 -s arch=x86_64
cmake .. -DCMAKE_TOOLCHAIN_FILE="${PWD}/conan_toolchain.cmake" -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release
cd ../../..
```

### [Install modules on linux](@id how_to-utilize-use_nodes-linux)

To perform the same installation above on linux you can navigate to a folder in which you want to download required repositories and run

```bash
sudo apt-get update -qq
sudo apt-get install -y git glpk-utils g++ cmake wget curl python3-pip
pip install conan
conan profile detect
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/miniconda
echo "$HOME/miniconda/bin" >> $GITHUB_PATH
source "$HOME/miniconda/etc/profile.d/conda.sh"

conda create --name testenv python=3.11 -y
conda activate testenv
conda install -c conda-forge poetry -y

git clone --recurse-submodules git@github.com:EnergyModelsX/EnergyModelsLanguageInterfaces.jl.git
cd "test/python_module"
poetry install
cd "../.."

cd "submodules/wind_power_timeseries"
poetry install
cd "../.."

cd "submodules/Tecnalia_Solar-Energy-Model"
poetry install
cd "../.."
cd "submodules/Tecnalia_Building-Stock-Energy-Model"
poetry install
cd "../.."

cd "submodules/CHP_modelling"
mkdir build
cd build
conan install .. --output-folder=. --build=missing -s compiler.cppstd=17 -s arch=x86_64
cmake .. -DCMAKE_TOOLCHAIN_FILE="${PWD}/conan_toolchain.cmake" -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release
cd "../../.."
```

Enable the python modules by starting a julia session in the main folder

```PowerShell
julia --project=.
```

and run the following

```julia
using Pkg;
Pkg.instantiate()
ENV["PYTHON"] = joinpath(ENV["HOME"], "miniconda", "envs", "testenv", "bin", "python");
Pkg.build("PyCall");
```

followed by restarting Julia.

### [Test modules](@id how_to-utilize-use_nodes-test)

All the mentioned [constructors](@ref lib-pub-sampling_constructors) have been included in the tests of the repository and you may therefore check if everyting is properly setup by running these in julia.

!!! note "Requirements"
    The tests assumes that all modules listed in the [Install python modules](@ref how_to-utilize-use_nodes-python_modules) section and the [Install C++ modules](@ref how_to-utilize-use_nodes-cpp_modules) section has been installed.

Start a new Julia session with

```PowerShell
julia --project=.
```

and run the tests

```julia
using Pkg
Pkg.test()
```

### [Utilize constructors](@id how_to-utilize-constructors)

For detailed information on how to use the [constructors](@ref lib-pub-sampling_constructors), refer to the [test/utils.jl](https://github.com/EnergyModelsX/EnergyModelsLanguageInterfaces.jl/blob/main/test/utils.jl) file, which contains minimum working examples for both sampling the models and using saved sampled data.