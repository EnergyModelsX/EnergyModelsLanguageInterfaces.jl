"""
The module `EnergyModelsUtilities` is a package that provides utility functions for the
EnergyModelsX framework.
"""
module EnergyModelsUtilities

using JuMP
using TimeStruct
using EnergyModelsBase
using EnergyModelsRenewableProducers
using Dates
using YAML

const EMB = EnergyModelsBase
const EMR = EnergyModelsRenewableProducers

include("datastructures.jl")
include("model.jl")
include("checks.jl")
include("constraint_functions.jl")
include("utils.jl")

export call_python_function, call_cpp_function, fetch_element
export WindPower, CSPandPV

end # module EnergyModelsUtilities
