using EnergyModelsLanguageInterfaces
using Test
using TimeStruct
using EnergyModelsBase
using EnergyModelsRenewableProducers
using EnergyModelsInvestments
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
    # Run all Aqua tests
    include(joinpath(testdir, "Aqua.jl"))

    # Check if there is need for formatting
    include(joinpath(testdir, "JuliaFormatter.jl"))

    # Test sampling routines
    include(joinpath(testdir, "test_sampling_routines.jl"))

    # Test checks
    include(joinpath(testdir, "test_checks.jl"))

    # Test nodes
    include(joinpath(testdir, "test_windpower.jl"))
    include(joinpath(testdir, "test_PV.jl"))
    include(joinpath(testdir, "test_buildings.jl"))
    include(joinpath(testdir, "test_CSPandPV.jl"))
    include(joinpath(testdir, "test_bioCHP.jl"))
end
