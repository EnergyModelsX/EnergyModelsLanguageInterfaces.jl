using JuliaFormatter

@testset "JuliaFormatter.jl" begin
    @test format(joinpath(testdir, "..", "src"))
    @test format(joinpath(testdir, "..", "test"))
    @test format(joinpath(testdir, "..", "ext"))
end
