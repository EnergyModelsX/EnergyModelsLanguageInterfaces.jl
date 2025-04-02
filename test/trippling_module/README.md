# Compilation
Compile the `trippling.cpp` program with
```bash
mkdir -p build
cd build
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=C:\Users\user\.julia\dev\libcxxwrap_julia_jll ..
cmake --build . --config Release
cd ..
julia --project=@temp
```
where `user` must be changed with the Windows user name.

# Run compiled function
Run the trippling function by
```julia
using Pkg
Pkg.add("CxxWrap")
using CxxWrap
module CppTrippling
    @wrapmodule(() -> joinpath(@__DIR__, "build", "Release", "tripplinglib.dll"))

    function __init__()
        @initcxx
    end
end
input = [1, 2, 3.0]

# Convert to C++ vector
cpp_input = StdVector{Float64}(input)

# Convert to Julia vector
output = convert(Vector{Float64}, CppTrippling.trippling(cpp_input))

println("Before trippling: $input \nAfter trippling: $output")
```

