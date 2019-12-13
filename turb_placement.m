function [Model_Name, Numbers, Installation_Cost, Final_Power_Output, Turbine_Locations, fval] = turb_placement(x,y,load_constraint_index,Power_Output,install_cost,turbines)
%% Load datasets and inputs 
Final_Power_Output = Power_Output(load_constraint_index,:);
Installation_Cost = install_cost(load_constraint_index);

wt_models = readtable('price.csv');
name = string(wt_models.ModelName);
turb_numbs=[];
combo_idx=[];
rotor_radius=[];
heights=[];
Model_Name=strings;

sel=turbines(:,load_constraint_index); % use the chosen constraint by the system

for i=1:1:length(sel)   % set up indices for the iterative objective function.
    if sel(i) ~= 0
        turb_numbs(end+1)=uint8(sel(i));
        combo_idx(end+1)=i;
        Model_Name=[Model_Name name(i)];
    end
end

Model_Name=Model_Name(2:end);

for i=1:1:length(combo_idx)
    rotor_radius(end+1)=wt_models.rotor_diameter(combo_idx(i))/2;
    heights(end+1)=wt_models.ModelHeight(combo_idx(i));
    Model_Name(i)=Model_Name(i)+'-'+string(wt_models.ModelHeight(combo_idx(i)));
end

rr=repelem(rotor_radius,turb_numbs);
hh=repelem(heights,turb_numbs);

N = 2*sum(turb_numbs);

save('storage.mat','turb_numbs','rr','hh','N') % Store these variabels for other functions to use
%% Genetic Algorithm
% ConstraintFunction = @simple_constraint;
% options = optimoptions('ga','PlotFcn',@GAfun); % Animate the placing process
% [coord_out,fval] = ga(@Analyse_Grid,N,[],[],[],[],LowerBound(N),UpperBound(N,sqrt(0.9)*x,sqrt(0.9)*y),ConstraintFunction,options);
%% Pattern Search 
ConstraintFunction = @simple_constraint;
x0 = [];
n = sqrt(N/2);
n = floor(n);
X = linspace(0,x,n);
Y = linspace(0,y,n); % Spread out the turbines as much as possible
for j=1:1:length(X)
    for k=1:1:length(Y)
        x0(end+1) = X(j);
        x0(end+1) = Y(k);
    end
end

for i=1:1:(N-length(x0))/2
    x0(end+1) = randi([1,x*100],1)/100;
    x0(end+1) = randi([1,y*100],1)/100; % Randomly place the extra turbines
end

%x0 =x+randi([x,y*10],1,N)/10; % Randomly generate all starting points

options = optimoptions('patternsearch','PlotFcn',@PSfun,'MeshTolerance',1e-12); % Aniimate the placing process
[coord_out,fval]=patternsearch(@Analyse_Grid,x0,[],[],[],[],LowerBound(N),UpperBound(N,sqrt(0.9)*x,sqrt(0.9)*y),ConstraintFunction,options);
%% Producing outputs
Numbers = turb_numbs;
Turbine_Locations = coord_out;
%% Plot the placement of turbines
x_coord=[];
y_coord=[];
for i=1:1:N/2
    n = (2 * i) - 1;
    x_coord(end+1)=coord_out(n);
    y_coord(end+1)=coord_out(n+1);
end
x_coord = x_coord*1000;
y_coord = y_coord*1000;
r_list = repelem(rotor_radius,turb_numbs);
for i = 1:1:N/2
    circle(x_coord(i),y_coord(i),r_list(i));
end
title('Wind Turbine Placements')
xlabel('Width (m)') 
ylabel('Length (m)') 