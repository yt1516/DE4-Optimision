%% Housekeeping
clear
clc
%% Area setting
x = 1.2; % width of the area
y = 1.2; % length of the area
Pctstart=60; % default starting percentile
Pctend=70; % default finishing percentile

%% Step 1: turbine selection
[Power_Output, install_cost, maintain_cost, turbines]=turb_selection(x,y,Pctstart,Pctend);
%% Step 2: turbine placement
load_constraint_index = 5; % A representative wind turbine combination
[Model_Name, Numbers, Installation_Cost, Final_Power_Output, Turbine_Locations, fval] = turb_placement(x,y,load_constraint_index,Power_Output,install_cost,turbines);