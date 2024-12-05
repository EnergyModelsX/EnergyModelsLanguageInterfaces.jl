module EMIExt

using EnergyModelsBase
using EnergyModelsUtilities
using EnergyModelsInvestments
using JuMP
using TimeStruct

const EMB = EnergyModelsBase
const EMU = EnergyModelsUtilities
const EMI = EnergyModelsInvestments
const TS = TimeStruct

include("checks.jl")
include("model.jl")
include("constraint_functions.jl")
include("utils.jl")

end
