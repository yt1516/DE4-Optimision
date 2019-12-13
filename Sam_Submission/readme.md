# Model Construction and Subsystem 2
This guide provides detailed walkthrough of how the datasets output from subsystem one are turned into useful models for subsystem two and then optimised
There are two optimisations. One standalone which completes a quick optimisation for the first stage outlined in the submitted paper, and a second which completes the system optimisation.

## Global Code
These instructions are for both optimisations

### Input Datasets
`Power_Output` `oneYearPower.csv` and `price` Place these three files into the same directory as the MATLAB files. 

### Functions
`SAM_List_Simplify.m`: Takes in `oneYearPower.csv` and `Power_Output` and creates a new usable dataset, `power_surplus`.

`SAM_Grouper.m`: groups the negative and positive values of `power_surplus` together before creating the macro period profiles.

`SAM_Profile_Adjuster.m`: Uses a capacity distribution called `ratio` to adjust the profile lists and generate the capacity shortage after the BESS is installed over the time period.

`BEN_BESS_Profit.m`: An imported function from subsystem three which calculates the profits for each battery capacity.

`SAM_Opt_One_Standalone.m`: A standalone function for subsystem 2 for a simple 'cheapest option' optimisation. Does not consider the output from `BEN_BESS_Profit.m` or the payback period.

`SAM_Opt_One_Profit.m`: The system level optimisation which considers payback period and outputs the cheapest option, which returns the investment in 20 years.

## Master_Code_Standalone
As mentioned above, this master code is used to generate the cheapest option over 20 years. This is the optimiation to use if a local community is supporting itselfas they are paying for it.

## Master_Code_Looped
This master code should be used if looking for outside investment as it also considers returning their money, and profits, to them, whilst giving the community free sustainable energy

### Outputs
Running `Demo.m` will generate the following outputs:

_Model_Name_: names of the selected turbine models.

_Numbers_: the number of each selected turbine models. 

_Installation_Cost_: the cost of purchasing the selected turbine models. 

_Final_Power_Output_: a one-year power output from the selected turbine models.

_Turbine_Locations_: the locations of each selected turbine model in the given build area
