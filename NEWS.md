# Release notes

## Version 0.1.0 (2025-04-xx)

### Improve documentation (2026-01-06)

* Added documentation for the node and a `how-to` section for the sampling constructors of these nodes.
* Added CI test runs for windows

### Adjust for updates in submodules and update descriptive names for the EMGUI extension (2025-10-17)

* Adjust for updates in submodules
* Add more descriptive names to the EMGUI extension
* Assume submodules are now stable enough not to need local result files in `test/data` 

### Initial version of the package

* Provide sampling routines for C++ and Python for incorporation into `EnergyModelsX` models
* Utilize the sampling routines for sampling from:
  * C++: `BioCHP` node
  * Python: `MultipleBuildingTypes`, `CSPandPV`, and `WindPower` nodes.
* Incorporation of a `BioResource` for `BiOCHP` plant
* Individual nodes to be moved after registration
