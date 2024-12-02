"""
Main module for `EnergyModelsUtilities` a package that extends that provides interfaces for nodes
developed in other languages, as well as outside of Julia.

The aim of the pacakge is to provide a user with the potential for incorporating piece-wise
linear efficiencies or cost functions or alternatively, if the system is convex, the
required bounds.
"""
module EnergyModelsUtilities

using TimeStruct

include("datastructures.jl")
include("model.jl")
include("utils.jl")

end # module EnergyModelsUtilities
