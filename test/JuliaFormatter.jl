using JuliaFormatter

@testset "JuliaFormatter.jl" begin
    @test format(joinpath(@__DIR__, "..", "src"))
    @test format(joinpath(@__DIR__, "..", "test"))
    @test format(joinpath(@__DIR__, "..", "ext"))
end
