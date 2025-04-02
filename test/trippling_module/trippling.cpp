#include <vector>
#include "jlcxx/jlcxx.hpp"

std::vector<double> trippling(const std::vector<double>& input) {
  std::vector<double> output(input.size());
  for (std::size_t i = 0; i < input.size(); ++i) {
    output[i] = 3.0 * input[i];
  }
  return output;
}

JLCXX_MODULE define_julia_module(jlcxx::Module& mod)
{
  mod.method("trippling", &trippling);
}