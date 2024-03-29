# Model Construction and Subsystem 2
This ReadMe file provides detailed walkthrough of how the datasets output from subsystem one are turned into useful models for subsystem two and then optimised
There are two optimisations. One standalone which completes a quick optimisation for the first stage outlined in the submitted paper, and a second which completes the system optimisation.

## Global Code
These instructions are for both optimisations

### Input Datasets
`JACOB_11_Profiles.mat` and `JACOB_Load_Use.csv`. Place these three files into the same directory as the MATLAB files. 

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
Running either master code will generate the following outputs:

_wind_turbine_profile_: the wind turbine profile which creates the optimal BESS WTG combination

_capacity_: The Capacity, in kWh, which creates the optimal BESS WTG combination

_optimal_Cost_: the cost of installing and maintaining the system over the 20 year period
