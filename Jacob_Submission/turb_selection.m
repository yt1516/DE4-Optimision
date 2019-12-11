function [Power_Output, install_cost, maintain_cost, turbines]=turb_selection(x,y,Pctstart,Pctend)
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
incre = (Pctend-Pctstart)/10;
for i=Pctstart:incre:Pctstart+10*incre
    load_avg(end+1)=prctile(load_time,i); % compute load constraints for a range of percentiles based on system optimisation.
end
%%
cost = wt_models.cost;
model_avg = model_avg/1000000; % output in MW
area = wt_models.area;
build_area = x*1000*y*1000*0.9;
lb = zeros(length(cost),1);
Aeq = [];
beq = [];
turbines=[];
f = cost';
intcon = 1:1:length(cost);
%%
for i=1:1:length(load_avg)
    A = [-model_avg'
        area'];
    b = [-load_avg(i)*1.2
        build_area];
    [selected,~] = intlinprog(f,intcon,A,b,Aeq,beq,lb);
    turbines(:,end+1)=selected;
end
c_list = cost.*turbines;
install_cost=[];
maintain_cost=[];
%%
for i=1:1:length(c_list(1,:))
    c_current=sum(c_list(:,i));
    install_cost(end+1)=c_current;
    maintain_cost(end+1)=c_current*0.17;
end
%%
Power_Output = zeros(length(turbines(1,:)),length(Pout_MW));
for ii=1:1:length(turbines(1,:))
    for i=1:1:length(turbines(:,1))
        Power_Output(ii,:)=Power_Output(ii,:) + turbines(i,ii)*Pout_MW(i,:);
    end
end
install_cost=install_cost';
maintain_cost=maintain_cost';
end