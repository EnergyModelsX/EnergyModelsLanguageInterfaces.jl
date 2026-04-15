import platform
import pyomo.environ as pyo

def solve_optimization_problem(input_data):
    """
    Solves a simple optimization problem:
        maximize: a * x + b * y + c * z
        subject to: x + 2y + z <= 1
                    x, y, z >= 0
    Returns the optimal values of x, y, and z.
    """
    a, b, c = input_data
    print(f"Python module: Solving optimization problem with a = {a}, b = {b}, c = {c}")
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
    solver = pyo.SolverFactory("appsi_highs")
    solver.solve(model, tee=False)
    # Extract results
    x_value = model.x.value
    y_value = model.y.value
    z_value = model.z.value
    print(f"Python module: Optimal values: x = {x_value}, y = {y_value}, z = {z_value}")
    return [x_value, y_value, z_value]