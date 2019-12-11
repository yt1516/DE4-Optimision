# Dataset Organisation and Subsystem 1
This guide provides detailed walkthrough of how the datasets used in the system and subsystem 1 are retrieved and organised.

## Python Code
### Libraries
Please install the following libraries if they have not been installed previously.

Numpy: `pip install numpy`
Pandas: `pip install pandas`
Matplotlib: `pip install matplotlib`
Windpowerlib: `pip install windpowerlib`

### Datasets
Hourly wind speed data of the area of one year: `weather.csv`

Electricity usage data of the area of one year: `oneYearPower.csv`

Wind turbine models power data: `WT_valid.csv`

Wind turbine models specifications: `model_height.csv`

### Function
`Wind Turbine Power Output Generation.ipynb`: Computes the yearly power output of 166 wind turbine models based on the wind speed profile data and the arbitrary price of the wind turbine models.

### Outputs
After running the Python code, the following files should be created:

`WT_Pout.csv` Contains power output of all wind turbine models at all time stamps of the wind speed data of the whole year. Very large dataset.

`price.csv` Contains wind turbine models specifications and the arbitrary prices. 

## Matlab Code
### Libraries
Go to Add-Ons and install Global Optimization Toolbox

### Input Datasets
`WT_Pout.csv` `oneYearPower.csv` and `price.csv` Place these three files into the same directory as the MATLAB files. 

### Functions
`Demo.m`: Generate a wind turbine farm for an area of 2 km by 2 km with electricity load profile from `oneYearPower.csv`.

`turb_selection.m`: Uses Linear Programming to select the turbine models and the number of them for a build area and a load requirement profile. 

`turb_placement.m`: Uses Pattern Search to place the selected turbine models into the given build area to maximise the power output of the wind turbine farm.

