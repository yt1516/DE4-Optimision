% Used in the Limitations and Challenges section of the report to compare the runtime between GA and PS 
clear
clc
x = 2; % width of the area
y = 2; % length of the area
Pctstart=50; % default starting percentile
Pctend=60; % default finishing percentile
[Power_Output, install_cost, maintain_cost, turbines]=turb_selection(x,y,Pctstart,Pctend);
%% clear all
load_constraint_index = 4; % A representative wind turbine combination
tic
fval_store=[];
for i=1:1:10
    [Model_Name, Numbers, Installation_Cost, Final_Power_Output, Turbine_Locations, fval] = turb_placement(x,y,load_constraint_index,Power_Output,install_cost,turbines);
    fval_store(end+1)=fval;
end
toc
%%
mean(fval_store) % average fval 