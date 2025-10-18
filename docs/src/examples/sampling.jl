# # [Example for sampling](@id exampl-sampl)
#
# The following example shows how the samling routines can be used for, *e.g.*, creating
# profiles that can be used in `EnergyModelsX` nodes.
#
# You first need to install the optimization_module package in the a conda environment in python:
# ```bash
# conda create --name testenv python=3.10
# conda activate testenv
# conda install -c conda-forge poetry
# cd test/python_module
# poetry install
# cd ../..
# ```
# and then in julia:
# ```julia
# ENV["PYTHON"] = joinpath(homedir(), "AppData", "Local", "miniconda3", "envs", "testenv", "python.exe")
# using Pkg
# Pkg.build("PyCall")
# ```
#
# !!! note "Python path on linux"
#     On Linux, the path might look like this:
#     ```julia
#     ENV["PYTHON"] = joinpath(homedir(), "miniconda3", "envs", "testenv", "bin", "python")
#     ```
#
# restart Julia

# It is first required to load the relevant packages for running the model.
using EnergyModelsBase
using JuMP
using HiGHS
using TimeStruct
using EnergyModelsLanguageInterfaces

const EMB = EnergyModelsBase
const EMLI = EnergyModelsLanguageInterfaces

# ## [Utilizing the python routine](@id exampl-sampl-py)
# A python function is called for providing the profile of the PV module (`pv_profile`).
# The variable `module_name` corresponds to the python file, while the variable `function_name`
# corresponds to the function you want to call from the python file. The input Vector
# is the input of the python function.
#
# !!! note "Commented line"
#     It is necessary for building the documentation that we do not use the function from
#     `EnergyModelsLanguageInterfaces` as Literate crashes. The function is however running. Hence,
#     you have to uncomment the line
#
#     `pv_profile = EMLI.call_python_function(module_name, function_name; input_data)`
#
#     and comment the line following it.
python_module_name = "test_python_sampling"
python_function_name = "optimization_module.solve_optimization_problem"
input_data = [1.4, 2.0, 1.2]
#pv_profile = EMLI.call_python_function(python_module_name, python_function_name; input_data)
pv_profile = [1.0, 0.0, 0.0]

# ## [Utilizing the C/C++ routines](@id exampl-sampl-c++)
#
# The C/C++ function is used for calculating the demand profile. You have to specify both the
# path to the library (`libpath`) and the function name. file (`filepath`).
EMLI_path = pkgdir(EnergyModelsLanguageInterfaces)
c_libpath = joinpath(EMLI_path, "test", "doubling_module", "libdoubling.so")
c_filepath = joinpath(EMLI_path, "test", "doubling_module", "doubling.c")
c_function_name = "doubling"
input_cpp::Vector{Cdouble} = [1.4, 2.0, 1.2]
include(joinpath(EMLI_path, "test", "doubling_module", "doubling.jl"))
demand_profile = doubling(c_libpath, c_function_name, input_cpp; filepath = c_filepath)

# ## [Apply the routines in an `EnergyModelsBase` model](@id exampl-sampl-emb)
#
# The simple examples uses two resources, `Power` and `CO2` with their emission intensity in tCO₂/MWh.
Power = ResourceCarrier("Power", 0.0)
CO2 = ResourceEmit("CO2", 1.0)
products = [Power, CO2]

# The operational time structure consists of 3 operational periods (`op_number`) with a
# duration of 1 (`op_duration`) in each of them.
op_duration = 1
op_number = 3
operational_periods = SimpleTimes(op_number, op_duration)

# The multi horizon time structure uses 3 strategic periods (`sp_number`) with increasing
# duration (`sp_duration`). A duration of 1 in a strategic period corresponds to 8760 times
# a duration of 1 in an operational period.
sp_duration = [1, 2, 10]
sp_number = length(sp_duration)
T = TwoLevel(sp_duration, operational_periods; op_per_strat = 8760.0)

# The model is an operational model. The emission cap (`em_limits`) and the price for an
# emission (`em_cost`) is not relevant, as none of the nodes lead to emissions.
# They are however required.
em_limits = Dict(CO2 => FixedProfile(10))   # Emission cap for CO₂ in t/year
em_cost = Dict(CO2 => FixedProfile(0.0))    # Emission price for CO₂ in NOK/t
model = OperationalModel(em_limits, em_cost, CO2)

# Once we have declared the modeltype and the time structure, we can declare the individual
# nodes, the connections, and the case dictionary.
## Create the individual nodes
solar_pv = RefSource(
    "Solar PV",                     # Node id
    OperationalProfile(pv_profile), # Capacity in MW
    FixedProfile(1),                # Variable operational cost in €/MWh
    FixedProfile(0),                # Fixed operational cost in €/MW
    Dict(Power => 1),               # The generated resources with conversion value 1
)
demand = RefSink(
    "Demand",                            # Node id
    OperationalProfile(demand_profile),  # The demand of the ndoe in MW
    Dict(                                # Penalties for surplus or deficit
        :surplus => FixedProfile(0),     # Penalty for surplus in €/MWh
        :deficit => FixedProfile(1e5)    # Penalty for deficit in €/MWh
    ),
    Dict(Power => 1),                    # Energy demand and corresponding ratio
)

## Collect all nodes
nodes = [solar_pv, demand]

## Create links between nodes
links = [Direct("solar_pv-demand", solar_pv, demand, Linear())]

## Create the EMX case
case = Case(T, products, [nodes, links], [[get_nodes, get_links]])

# Subsequently, we can create the model and solve it:

## Construct JuMP model for optimization
m = create_model(case, model)

## Set optimizer for JuMP
set_optimizer(m, HiGHS.Optimizer)

## Solve the optimization problem
optimize!(m)

## Print solution summary
solution_summary(m)
