function [names,turb_numbs,t_cost,P_out,coord_out,models] = Subsystem_Optimisation(x,y)
close all
load = readtable('oneYearPower.csv');
wt_power = readtable('WT_Pout.csv');
wt_models = readtable('price.csv');
load_time = load.KWH_hh_perHalfHour_;
l = 4:1:8763;
T2 = mergevars(wt_power,l);
power_time = T2.Var4;
power_time = kron(power_time,ones(1,2)); % duplicate wind power output to half-hour timestamp
load_time = load_time(1:17520); % match load timestamp to the power output timestamp
load_time = load_time * 1e3 / 1e3; % assume 1000 households in the area then convert to MW
Pout_MW = power_time/1e6; % convert wind turbine outputs to MW
%% Comparing model average to different percentiles of load
model_avg = mean(power_time,2); % calculate the average power output of all turbine models
load_avg = [];
for i=50:5:100
    load_avg(end+1)=prctile(load_time,i); % compute from 50 to 100 percentile of load as constraints (11 in total)
end

cost = wt_models.cost;
model_avg = model_avg/1000000; % output in MW
name = string(wt_models.ModelName);
area = wt_models.area;
build_area = x*1000*y*1000*0.9;
lb = zeros(length(cost),1);
Aeq = [];
beq = [];
x_res=[];
f = cost';
intcon = 1:1:length(cost);
%% Wind turbine model selection optimisation
for i=1:1:length(load_avg)
    A = [-model_avg'
        area'];
    b = [-load_avg(i)
        build_area];
    [selected,~] = intlinprog(f,intcon,A,b,Aeq,beq,lb);
    x_res(:,end+1)=selected; % x_res contains picked model list and amounts for the 11 different load constraints
end
%%
turb_numbs=[];
combo_idx=[];
rotor_radius=[];
heights=[];
names=strings;
t_cost=0;
sel=x_res(:,4); % use the 4th output, this value is affected by the system. 

for i=1:1:length(sel)   % set up indices for the iterative objective function.
    if sel(i) ~= 0
        turb_numbs(end+1)=uint8(sel(i));
        combo_idx(end+1)=i;
        names=[names name(i)];
    end
end
names=names(2:end);
for i=1:1:length(combo_idx)
    rotor_radius(end+1)=wt_models.rotor_diameter(combo_idx(i))/2;
    t_cost=t_cost+cost(combo_idx(i))*turb_numbs(i);
    heights(end+1)=wt_models.ModelHeight(combo_idx(i));
    names(i)=names(i)+'-'+string(wt_models.ModelHeight(combo_idx(i)));
end

rr=repelem(rotor_radius,turb_numbs);
hh=repelem(heights,turb_numbs);

N = 2*sum(turb_numbs);
%%
save('storage.mat','turb_numbs','rr','hh','N') % Store these variabels for other functions to use
%% Genetic Algorithm
% ConstraintFunction = @simple_constraint;
% [coord_out,fval] = ga(@Analyse_Grid,N,[],[],[],[],LowerBound(N),UpperBound(N,x,y),ConstraintFunction);
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
[coord_out,fval]=patternsearch(@Analyse_Grid,x0,[],[],[],[],LowerBound(N),UpperBound(N,sqrt(0.9)*x,sqrt(0.9)*y),ConstraintFunction);
% %%
% wind_speed_avg=3.737;
% P_efficiency=((1/fval)/(wind_speed_avg*N/2))^3; % power is proportional to speed^3
%%
selected = wt_models.ModelName;
selected_radius = num2cell(wt_models.rotor_diameter);
x_idx = num2cell(sel);
selected = [selected,selected_radius];
selected = [selected,x_idx];
models = [selected, num2cell(wt_models.ModelHeight)];
%%
Complete_Pout = zeros(1,length(Pout_MW));
for ii=1:1:length(sel)
    Complete_Pout=Complete_Pout + sel(ii)*Pout_MW(ii,:);
end

P_out=Complete_Pout;%*P_efficiency;
%%
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
end