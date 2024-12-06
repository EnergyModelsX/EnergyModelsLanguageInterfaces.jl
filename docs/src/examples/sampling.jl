using EnergyModelsBase
using JuMP
using HiGHS
using TimeStruct
using EnergyModelsUtilities
using Conda

const EMB = EnergyModelsBase
const EMU = EnergyModelsUtilities

# Install the dependencies of the external Python module
Conda.add("pyomo")
Conda.add("glpk")

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
input::Vector{Float64} = [1.4, 2.0, 1.2]
#pv_profile = EMU.call_python_function(module_name, function_name, input; module_path)
pv_profile = [1.0, 0.0, 0.0]

# Call C++ module
libpath = joinpath(EMU_path, "..", "test", "cpp_module", "libdoubling.so")
filepath = joinpath(EMU_path, "..", "test", "cpp_module", "doubling.cpp")
cpp_function_name = "doubling"
input_cpp::Vector{Cdouble} = [1.4, 2.0, 1.2]
demand_profile = EMU.call_cpp_function(libpath, cpp_function_name, input_cpp; filepath)

# Define EMX nodes
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

# Collect all nodes
nodes = [av, solar_pv, demand]

# Create links between nodes
links = [
    Direct("solar_pv-av", solar_pv, av, Linear()), Direct("av-demand", av, demand, Linear())
]

# Create the EMX case
case = Dict(
    :nodes => Array{EMB.Node}(nodes),
    :links => Array{Link}(links),
    :products => products,
    :T => T,
)

# Construct JuMP model for optimization
m = EMB.create_model(case, model)

# Set optimizer for JuMP
set_optimizer(m, HiGHS.Optimizer)

# Solve the optimization problem
optimize!(m)

# Print solution summary
solution_summary(m)
