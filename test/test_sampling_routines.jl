@testset "call_python_function tests" begin
    # Define paths to python module
    module_name = "test_python_sampling"
    function_name = "optimization_module.solve_optimization_problem"

    # Call the Python function
    input_data = [1.4, 2.0, 1.2]
    pv_profile = EMLI.call_python_function(module_name, function_name; input_data)

    @test pv_profile[1] == 1.0
    @test pv_profile[2] == 0.0
    @test pv_profile[3] == 0.0
end
