using JuliaFormatter

@testset "JuliaFormatter.jl" begin
    @test begin
        format(joinpath(@__DIR__, "..", "src"))
        format(joinpath(@__DIR__, "..", "test"))
        format(joinpath(@__DIR__, "..", "ext"))
    end
end
