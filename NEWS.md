# Release notes

## Version 0.1.0 (2026-06-05)

### Extended WindFarmParameters

* Extended `WindFarmParameters` to include an optional `turbine_power_curve` argument, which allows users to specify a custom power curve for the wind turbine.
  The `turbine_power_curve` is expected to be a `DataFrame` with columns `wind_speed` and `power_curve`, where `wind_speed` represents the wind speed values (in m/s) and `power_curve` represents the corresponding power output of the turbine at those wind speeds.
* The parameters `sigma` and `wakeloss` were also added to `WindFarmParameters` to enable all options of the `wind_power_timeseries` repository.
* The `shape` parameter was corrected from a string to a float.

### Added WindFarmParameters

* Introduces `WindFarmParameters` more in line with `PVParameters` and also made the corresponding nodes more consistent.

### Add Building node

* Added a `Building` node to the package, which provides sampling routines for building heat demand profiles based on temperature data.
  A function `heat_demand_profile` is included to generate the heat demand profile from temperature data downloaded using hindcast data.
  A function `get_met_data` is included to handle data retrieval, caching, and storage (using the python [`metocean_api`](https://metocean-api.readthedocs.io/en/latest/) library) for the meteorological data used in the `heat_demand_profile` function.
  This function enables implementation of meteorological data dependent nodes.

### Add PV node

* Added a `PV` node to the package, which provides sampling routines for photovoltaic power generation which is more in line with the WindPower node requiring lat-lon coordinates.

### Initial version of the package

* Provide sampling routines for C++ and Python for incorporation into `EnergyModelsX` models.
* Utilize the sampling routines for sampling from:
  * C++: `BioCHP` node.
  * Python: `MultipleBuildingTypes`, `CSPandPV`, and `WindPower` nodes.
* Incorporation of a `BioResource` for `BiOCHP` plant.
* Individual nodes to be moved after registration.
