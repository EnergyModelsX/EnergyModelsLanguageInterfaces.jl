using Aqua

@testset "Aqua.jl" begin
    Aqua.test_ambiguities(EnergyModelsUtilities)
    Aqua.test_unbound_args(EnergyModelsUtilities)
    Aqua.test_undefined_exports(EnergyModelsUtilities)
    Aqua.test_project_extras(EnergyModelsUtilities)
    Aqua.test_stale_deps(EnergyModelsUtilities)
    Aqua.test_deps_compat(EnergyModelsUtilities)
    Aqua.test_piracies(EnergyModelsUtilities)
    Aqua.test_persistent_tasks(EnergyModelsUtilities)
end
