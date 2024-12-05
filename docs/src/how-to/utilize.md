# [Utilize the concepts of `EnergyModelsUtilities`](@id how_to-utilize)

## Call external functions

To evaluate a python function (with input argument `input`) called `my_func` which 
is available in the file `my_python_file.py` located at `filepath`, you can do the following

```julia
output = EMU.call_python_function("my_python_file", "my_func", input; "filepath")
```

!!! note
    All python package dependencies must be available in the root environment. You can add packages with, e.g., `using Conda; Conda.add("pyomo")`.

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

A full example of how this could be utilized in EMX is as follows

```julia
using EnergyModelsBase
using JuMP
using HiGHS
using TimeStruct
using EnergyModelsUtilities
using Conda

const EMB = EnergyModelsBase
const EMU = EnergyModelsUtilities

# Install the dependencies of the external module
using Conda
Conda.add("pyomo")
Conda.add("glpk")

function read_data()
    # Define the different resources and their emission intensity in tCO₂/MWh
    Power = ResourceCarrier("Power", 0.0)
    CO2 = ResourceEmit("CO2", 1.0)
    products = [Power, CO2]

    # Variables for the individual entries of the time structure
    op_duration = 1  # Each operational period has a duration of one hour
    op_number = 3   # There are in total 24 operational periods (one for each hour in a day)

    operational_periods = SimpleTimes(op_number, op_duration)

    # Creation of the time structure
    dur = [1, 2, 10] # Duration of the strategic periods

    T = TwoLevel(dur, operational_periods; op_per_strat=8760)

    noSP = length(dur)     # Number of strategic periods

    # Create operational model (global data)
    em_limits = Dict(CO2 => StrategicProfile(1e6 * ones(noSP)))   # Emission cap for CO₂ in t/year
    em_cost = Dict(CO2 => FixedProfile(0.0))  # Emission price for CO₂ in NOK/t
    model = OperationalModel(em_limits, em_cost, CO2)

    # Call python module
    EMU_path = dirname(pathof(EnergyModelsUtilities))
    module_path = joinpath(EMU_path, "..", "test", "python_module")
    module_name = "optimization_module"
    function_name = "solve_optimization_problem"
    input = [1.4, 2.0, 1.2]
    pv_profile = EMU.call_python_function(module_name, function_name, input; module_path)

    # Call C++ module
    libpath = joinpath(EMU_path, "..", "test", "cpp_module", "libdoubling.so")
    filepath = joinpath(EMU_path, "..", "test", "cpp_module", "doubling.cpp")
    cpp_function_name = "doubling"
    input_cpp::Vector{Cdouble} = [1.4, 2.0, 1.2]
    demand_profile = EMU.call_cpp_function(libpath, cpp_function_name, input_cpp; filepath)

    av = GenAvailability("av", [Power])
    solar_pv = RefSource(
        "Solar PV",                     # Node id
        OperationalProfile(pv_profile), # cap
        FixedProfile(1),                # Variable operational cost per unit produced
        FixedProfile(0),                # Fixed operational cost per unit produced
        Dict(Power => 1),               # The generated resources with conversion value 1
    )
    demand = RefSink(
        "Demand",                            # Node id
        OperationalProfile(demand_profile),  # demand: the demand
        Dict(                                # penality: penalties for surplus or deficits
            :surplus => FixedProfile(0),     # Penalty for surplus
            :deficit => FixedProfile(1e5),   # Penalty for deficit
        ),
        Dict(Power => 1),                    # input `Resource`s with conversion value `Real`
    )
    nodes = [av, solar_pv, demand]

    # Create links between nodes
    links = [
        Direct("solar_pv-av", solar_pv, av, Linear()),
        Direct("av-demand", av, demand, Linear()),
    ]

    case = Dict(
        :nodes => Array{EMB.Node}(nodes),
        :links => Array{Link}(links),
        :products => products,
        :T => T,
    )
    return case, model
end

# Get case and model data
case, model = read_data()

# Construct JuMP model for optimization
m = EMB.create_model(case, model)

# Set optimizer for JuMP
set_optimizer(m, HiGHS.Optimizer)

# Solve the optimization problem
optimize!(m)

# Print solution summary
solution_summary(m)

```
