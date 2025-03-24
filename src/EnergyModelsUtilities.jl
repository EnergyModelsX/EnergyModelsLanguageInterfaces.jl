"""
The module `EnergyModelsUtilities` is a package that provides utility functions for the
EnergyModelsX framework.
"""
module EnergyModelsUtilities

using TimeStruct
using EnergyModelsBase
using EnergyModelsRenewableProducers

const EMB = EnergyModelsBase
const EMR = EnergyModelsRenewableProducers

include("datastructures.jl")
include("model.jl")
include("checks.jl")
include("utils.jl")

export call_python_function, call_cpp_function, fetch_element
export WindPower

end # module EnergyModelsUtilities
