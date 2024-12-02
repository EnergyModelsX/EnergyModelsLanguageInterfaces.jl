using EnergyModelsUtilities
using Test
using TimeStruct

const EMU = EnergyModelsUtilities
const TS = TimeStruct

const TEST_ATOL = 1e-6

@testset "EnergyModelsUtilities" begin
    include("test_general.jl")
end
