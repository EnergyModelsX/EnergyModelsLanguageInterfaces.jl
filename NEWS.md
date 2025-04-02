# Release notes

## Version 0.1.0 (2025-03-30)

### Adjustment

* Removed the `call_cpp_function` function (breaking change) and related content as this approach was not generalizable to an arbitrary number of input/output arguments and types.
  This must instead be done locally in node constructors.

### Enhancement

* Added the `MultipleBuildingTypes` (as sinks for different building types) and `CSPandPV` (as a source node for concentrated solar power and photovoltaic power).
* Added the `BioCHP` node (as a NetworkNode to model Compbined Heat and Power plant based on biomass combustion).

## Version 0.1.0 (2025-03-07)

### Adjustment

* Adjusted python sampling routine to use a conda environment and enabled keyword arguments.

### Enhancement

* Added the WindPower node using the wind_power_timeseries at https://gitlab.sintef.no/harald.svendsen/timeseries/

## Version 0.1.0 (2024-12-04)

### Added sampling routines

### Enhancement

* Added first version of functions to evaluate functions in C++ and Python.

## Version 0.1.0 (2024-12-02)

### Initial (skeleton) version

* Provides an initial skeleton version with the required files.
* Includes dependency for `TimeStruct`.
