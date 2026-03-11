"""
The module `EnergyModelsLanguageInterfaces` is a package that provides utility functions for the
EnergyModelsX framework.
"""
module EnergyModelsLanguageInterfaces

using JuMP
using TimeStruct
using EnergyModelsBase
using EnergyModelsRenewableProducers
using EnergyModelsHeat
using Dates
using Libdl
using YAML

# The following packages are needed for PVGIS
using HTTP
using JSON3
using CSV
using DataFrames
using Printf

const EMB = EnergyModelsBase
const EMR = EnergyModelsRenewableProducers
const EMH = EnergyModelsHeat

# Keep a global reference to the loaded library
const LIB_CACHE = Dict{String,Ptr{Cvoid}}()
include("macros.jl")

include("datastructures.jl")
include("model.jl")
include("checks.jl")
include("constraint_functions.jl")
include("utils.jl")

export call_python_function, fetch_element
export WindPower, CSPandPV, MultipleBuildingTypes
export ResourceBio, BioCHP
export PV, PVParameters

end # module EnergyModelsLanguageInterfaces
