# Dataset Organisation and Subsystem 1
This guide provides detailed walkthrough of how the datasets used in the system and subsystem 1 are retrieved and organised.

## Python Libraries
Please install the following libraries if they have not been installed previously.

Numpy: `pip install numpy`
Pandas: `pip install pandas`
Matplotlib: `pip install matplotlib`
Windpowerlib: `pip install windpowerlib`

## Datasets
Hourly wind speed data of the area of one year: **weather.csv**

Electricity usage data of the area of one year: **oneYearPower.csv**

Wind turbine models power data: **WT_valid.csv**

Wind turbine models specifications: **model_height.csv**

## Outputs
After running the Python code, the following files should be created:

**WT_Pout.csv**: Contains power output of all wind turbine models at all time stamps of the wind speed data of the whole year. Very large dataset.

**price.csv**: Contains wind turbine models specifications and the arbitrary prices. 
