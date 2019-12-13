# Model Construction and Subsystem 2
This guide provides detailed walkthrough of how the datasets output from subsystem one are turned into useful models for subsystem two and then optimised
There are two optimisations. One standalone which completes a quick optimisation for the first stage outlined in the submitted paper, and a second which completes the system optimisation.

## Global Code
These instructions are for both optimisations

### Input Datasets
`Power_Output` `oneYearPower.csv` and `price` Place these three files into the same directory as the MATLAB files. 

### Functions
`SAM_Grouper.m`: Generate a wind turbine farm for an area of 2 km by 2 km with electricity load profile from `oneYearPower.csv`.

`SAM_List_Simplify.m`: Uses Linear Programming to select the turbine models and the number of them for a build area and a load requirement profile. 

`SAM_Profile_Adjuster.m`: Uses Pattern Search to place the selected turbine models into the given build area to maximise the power output of the wind turbine farm.

'BEN_BESS_Profit':

'SAM_Opt_One_Standalone':

'SAM_Opt_One_Profit':

## Master_Code_Standalone
These instructions are for both optimisations

## Master_Code_Looped
These instructions are for both optimisations

### Outputs
Running `Demo.m` will generate the following outputs:

_Model_Name_: names of the selected turbine models.

_Numbers_: the number of each selected turbine models. 

_Installation_Cost_: the cost of purchasing the selected turbine models. 

_Final_Power_Output_: a one-year power output from the selected turbine models.

_Turbine_Locations_: the locations of each selected turbine model in the given build area
