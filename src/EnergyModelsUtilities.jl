"""
The module `EnergyModelsUtilities` is a package that provides utility functions for the
EnergyModelsX framework.
"""
module EnergyModelsUtilities

using TimeStruct
using EnergyModelsBase

include("datastructures.jl")
include("model.jl")
include("utils.jl")

export call_python_function, call_cpp_function

end # module EnergyModelsUtilities
