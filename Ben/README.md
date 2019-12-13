#  LP Method for the Optimisation of BESS Charge Scheduling


### Functions
`subsystem_III.m`: The sub-system code called by the system-level code. It takes in the following variables:

`portal.m`: The 'portal' that might be viewed by a Renewable System Manager for running a site. 

![alt text](https://github.com/yt1516/DE4-Optimision/blob/master/Ben/bigportal.png)


`legend.m`: For generating the legend - did not fit on subplot

![alt text](https://github.com/yt1516/DE4-Optimision/blob/master/Ben/legend.png)

### Input Datasets
`microgrid_load.mat` and `grid_import_pricing.mat` and `turbine_power_out.mat`. are example versions of the datasets that might be run through the scheduler at a system level. Place these three files into the same directory when running `subsystem_III.m`. 

### Input Variables
`time_interval` : Time interval length (hours)

`resolution` : Skip to only run every *resolution* days

`BESS_capacity`: BESS capacity (kWh) from Subsystem 2

`year_microgrid_demand_profile`: Demand from microgrid load 

`year_grid_import_cost_profile`: Cost of import from supplier

`year_grid_export_income_profile`: Profit from energy sale (assumed 70% of purchase price) 

`year_wind_profile`

`BESS_max_discharge_rate`

`BESS_max_charge_rate`

`BESS_max_SOC_pct`

`BESS_min_SOC_pct `

`BESS_operating_cost`

`BESS_round_trip_efficiency`

`WTG_operating_cost`

`grid_import_limit`

`grid_export_limit`


