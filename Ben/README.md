#  LP Method for the Optimisation of BESS Charge Scheduling


*Note, there is an error in this version*  `subsystem_III.m` *a line was omitted.* 

*This was submitted correctly in the version of the file in Subsystem II* `BEN_BESS_profit.m`

`result = total_profit_array` *Was added back to the final line of the outer loop of the function in versions submitted since 5PM to correct. *

### Functions
`subsystem_III.m`: The sub-system code called by the system-level code. It takes in the following variables:
*See error notice above*

`portal.m`: The 'portal' that might be viewed by a Renewable System Manager for running a site. 

![alt text](https://github.com/yt1516/DE4-Optimision/blob/master/Ben/bigportal.png)


`legend.m`: For generating the legend - did not fit on subplot

![alt text](https://github.com/yt1516/DE4-Optimision/blob/master/Ben/legend.png)

### Input Datasets
`microgrid_load.mat` and `grid_import_pricing.mat` and `turbine_power_out.mat`. are example versions of the datasets that might be run through the scheduler at a system level. Place these three files into the same directory when running `subsystem_III.m`. 

### Input Variables
`time_interval` : Time interval length (hours)

`resolution` : Skip to only run every * resolution * days

`BESS_capacity`: BESS capacity (kWh) from Subsystem 2

`year_microgrid_demand_profile`: Demand from microgrid load 

`year_grid_import_cost_profile`: Cost of import from supplier

`year_grid_export_income_profile`: Profit from energy sale (assumed 70% of purchase price) 

`year_wind_profile`: Wind energy supply (kWh) from Subsystem 1

`BESS_max_discharge_rate`: Limit for discharge rate from BESS (kW)

`BESS_max_charge_rate` : Limit for discharge rate to BESS (kW)

`BESS_max_SOC_pct` : Maximum State of Charge limit (% of capacity)

`BESS_min_SOC_pct `: Minimum State of Charge limit (% of capacity)

`BESS_operating_cost`: Operational cost of BESS discharged (£/kwh)

`BESS_round_trip_efficiency`: Round trip efficiency - the ratio of energy charged to energy retrieved, for a transaction of equal amounts of energy in and out of an Energy Storage System

`WTG_operating_cost`: Operational cost supplied from WTG (£/kwh)

`grid_import_limit`: Limit for import rate from grid (kW)

`grid_export_limit`: Limit for export rate to grid (kW)


