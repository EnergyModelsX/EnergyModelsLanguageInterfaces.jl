# Philosophy

## General design philosophy

One key aim in the development of `EnergyModelsUtilities` is to provide utility functions for 
[EnergyModelsX](https://github.com/EnergyModelsX). This includes

1. an interface for nodes developed in other languages (currently C++ and Python), as well as outside of Julia.
2. an interface with the potential for incorporating piece-wise linear efficiencies or cost functions or alternatively, if the system is convex, the required bounds.