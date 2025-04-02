using Aqua

@testset "Aqua.jl" begin
    Aqua.test_ambiguities(EnergyModelsLanguageInterfaces)
    Aqua.test_unbound_args(EnergyModelsLanguageInterfaces)
    Aqua.test_undefined_exports(EnergyModelsLanguageInterfaces)
    Aqua.test_project_extras(EnergyModelsLanguageInterfaces)
    Aqua.test_stale_deps(EnergyModelsLanguageInterfaces)
    Aqua.test_deps_compat(EnergyModelsLanguageInterfaces)
    Aqua.test_piracies(EnergyModelsLanguageInterfaces)
    Aqua.test_persistent_tasks(EnergyModelsLanguageInterfaces)
end
