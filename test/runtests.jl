using EnergyModelsUtilities
using Test
using TimeStruct

const EMU = EnergyModelsUtilities
const TS = TimeStruct

const TEST_ATOL = 1e-6

@testset "EnergyModelsUtilities" begin
    # Run all Aqua tests
    include("Aqua.jl")

    # Check if there is need for formatting
    include("JuliaFormatter.jl")

    # Test sampling routines
    include("test_sampling_routines.jl")
end
