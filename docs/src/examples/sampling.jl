# # [Example for sampling](@id exampl-sampl)
#
# The following example shows how the samling routines can be used for, *e.g.*, creating
# profiles that can be used in `EnergyModelsX` nodes.
#
# !!! warning
#     The example require that you have G++ as C++ compiler installed.
#     It is however also possible to use a different compiler as outlined in [`call_cpp_function`](@ref).
#
# It is first required to load the relevant packages for running the model.
using EnergyModelsBase
using JuMP
using HiGHS
using TimeStruct
using EnergyModelsUtilities
using Conda

const EMB = EnergyModelsBase
const EMU = EnergyModelsUtilities

# ## [Utilizing the python routine](@id exampl-sampl-py)
#
# The chosen python function includes a Pyomo optimization model. It is hence necessary to
# add both Pyomo and GLPK to the environment. These will be added in the root environment.
# If they are already installed, they are not installed again.
Conda.add("pyomo")
Conda.add("glpk")

# A python function is called for providing the profile of the PV module (`pv_profile`).
# The variable `module_name` corresponds to the python file, while the variable `function_name`
# corresponds to the function you want to call from the python file. The input Vector
# is the input of the python function.
#
# !!! note "Commented line"
#     It is necessary for building the documentation that we do not use the function from
#     `EnergyModelsUtilities` as Literate crashes. The function is however running. Hence,
#     you have to uncomment the line
#
#     `pv_profile = EMU.call_python_function(module_name, function_name, input; module_path)`
#
#     and comment the line following it.
EMU_path = pkgdir(EnergyModelsUtilities)
module_path = joinpath(EMU_path, "test", "python_module")
module_name = "optimization_module"
function_name = "solve_optimization_problem"
input::Vector{Float64} = [1.4, 2.0, 1.2]
#pv_profile = EMU.call_python_function(module_name, function_name, input; module_path)
pv_profile = [1.0, 0.0, 0.0]

# ## [Utilizing the C++ routines](@id exampl-sampl-c++)
#
# The C++ function is used for calculating the demand profile. You have to specify both the
# path to the library (`libpath`) and the function name. file (`filepath`).
libpath = joinpath(EMU_path, "test", "cpp_module", "libdoubling.so")
filepath = joinpath(EMU_path, "test", "cpp_module", "doubling.cpp")
cpp_function_name = "doubling"
input_cpp::Vector{Cdouble} = [1.4, 2.0, 1.2]
demand_profile = EMU.call_cpp_function(libpath, cpp_function_name, input_cpp; filepath)

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

## Create the EMX case dictionary
case = Dict(
    :nodes => Array{EMB.Node}(nodes),
    :links => Array{Link}(links),
    :products => products,
    :T => T,
)

# Subsequently, we can create the model and solve it:

## Construct JuMP model for optimization
m = EMB.create_model(case, model)

## Set optimizer for JuMP
set_optimizer(m, HiGHS.Optimizer)

## Solve the optimization problem
optimize!(m)

## Print solution summary
solution_summary(m)
