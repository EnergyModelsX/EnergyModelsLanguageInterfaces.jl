using EnergyModelsLanguageInterfaces
using Test
using TimeStruct
using EnergyModelsBase
using EnergyModelsRenewableProducers
using HiGHS
using JuMP

const EMLI = EnergyModelsLanguageInterfaces
const EMB = EnergyModelsBase
const EMRP = EnergyModelsRenewableProducers
const TS = TimeStruct

const TEST_ATOL = 1e-6

include("utils.jl")

@testset "EnergyModelsLanguageInterfaces" begin
    ## Run all Aqua tests
    include("Aqua.jl")

    ## Check if there is need for formatting
    include("JuliaFormatter.jl")

    ## Test sampling routines
    include("test_sampling_routines.jl")

    ## Test nodes
    include("test_windpower.jl")
    include("test_buildings.jl")
    include("test_CSPandPV.jl")
    include("test_bioCHP.jl")
end
