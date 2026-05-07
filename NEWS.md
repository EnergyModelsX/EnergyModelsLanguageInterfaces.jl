# Release notes

## Version 0.1.0 (2026-04-15)

### Add PV node

* Added a `PV` node to the package, which provides sampling routines for photovoltaic power generation which is more in line with the WindPower node requiring lat-lon coordinates.

### Initial version of the package

* Provide sampling routines for C++ and Python for incorporation into `EnergyModelsX` models.
* Utilize the sampling routines for sampling from:.
  * C++: `BioCHP` node.
  * Python: `MultipleBuildingTypes`, `CSPandPV`, and `WindPower` nodes.
* Incorporation of a `BioResource` for `BiOCHP` plant.
* Individual nodes to be moved after registration.
