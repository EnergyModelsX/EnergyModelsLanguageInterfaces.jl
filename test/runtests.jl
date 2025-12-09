using EnergyModelsLanguageInterfaces
using Test
using TimeStruct
using EnergyModelsBase
using EnergyModelsRenewableProducers
using EnergyModelsHeat
using Dates
using JSON
using HiGHS
using JuMP

const EMLI = EnergyModelsLanguageInterfaces
const EMB = EnergyModelsBase
const EMRP = EnergyModelsRenewableProducers
const TS = TimeStruct

pkg_dir = pkgdir(EnergyModelsLanguageInterfaces)
testdir = joinpath(pkg_dir, "test")

include(joinpath(testdir, "utils.jl"))

@testset "EnergyModelsLanguageInterfaces" begin
    ## Run all Aqua tests
    include("Aqua.jl")

    ## Check if there is need for formatting
    include("JuliaFormatter.jl")

    ## Test sampling routines
    include("test_sampling_routines.jl")

    ## Test checks
    include("test_checks.jl")

    ## Test nodes
    include("test_windpower.jl")
    include("test_buildings.jl")
    include("test_CSPandPV.jl")
    include("test_bioCHP.jl")
end
