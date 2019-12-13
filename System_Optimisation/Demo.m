

x = 1.2; % width of the area
y = 1.2; % length of the area
Pctstart=0.6; % default starting percentile
Pctend=07.; % default finishing percentile


[Power_Output, install_cost, maintain_cost, turbines]=turb_selection(x,y,Pctstart,Pctend);

load_constraint_index = 5; % A representative wind turbine combination
[Model_Name, Numbers, Installation_Cost, Final_Power_Output, Turbine_Locations, fval] = turb_placement(x,y,load_constraint_index,Power_Output,install_cost,turbines);
