using Conda

@testset "call_python_function tests" begin
    # Install the required package
    Conda.add("pyomo")

    # Define paths to python module
    module_path = joinpath(@__DIR__, "python_module")
    module_name = "optimization_module"
    function_name = "solve_optimization_problem"

    # Call the Python function
    input = [1.4, 2.0, 1.2]
    pv_profile = EMU.call_python_function(module_name, function_name, input; module_path)

    @test pv_profile[1] == 1.0
    @test pv_profile[2] == 0.0
    @test pv_profile[3] == 0.0
end

@testset "call_cpp_function tests" begin
    # Define paths to the C++ test module
    libpath = joinpath(@__DIR__, "cpp_module", "libdoubling.so")
    filepath = joinpath(@__DIR__, "cpp_module", "doubling.cpp")

    # Call the C++ function
    function_name = "doubling"
    demand_profile = EMU.call_cpp_function(
        libpath, function_name, [1.4, 2.0, 1.2]; filepath
    )

    @test demand_profile == [2.8, 4.0, 2.4]
end
