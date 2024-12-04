import pyomo.environ as pyo

def solve_optimization_problem(input_data):
    """
    Solves a simple optimization problem:
        maximize: a * x + b * y + c * z
        subject to: x + 2y + z <= 1
                    x, y, z >= 0
    Returns the optimal values of x, y, and z.
    """
    a = input_data[0]
    b = input_data[1]
    c = input_data[2]
    print(f"Python module: Solving optimization problem with a = %s, b = %s, c = %s" % (a, b, c))
    model = pyo.ConcreteModel()
    # Define variables
    model.x = pyo.Var(within=pyo.PositiveReals)  # x >= 0
    model.y = pyo.Var(within=pyo.PositiveReals)  # y >= 0
    model.z = pyo.Var(within=pyo.PositiveReals)  # z >= 0
    # Define objective function
    model.obj = pyo.Objective(expr=a * model.x + b * model.y + c * model.z, sense=pyo.maximize)
    # Define constraints
    model.constraint = pyo.Constraint(expr=model.x + 2 * model.y + model.z <= 1)
    # Solve the optimization problem
    solver = pyo.SolverFactory("glpk")
    solver.solve(model, tee=False)
    # Extract results
    x_value = model.x.value
    y_value = model.y.value
    z_value = model.z.value
    print(f"Python module: Optimal values: x = {x_value}, y = {y_value}, z = {z_value}")
    return [x_value, y_value, z_value]