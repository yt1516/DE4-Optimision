clear
x=2;
y=2;
loop = 1;
start = 50;

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
% model_avg = mean(power_time,2); % calculate the average power output of all turbine models
% load_avg = [];
% for i=40:5:80
%     load_avg(end+1)=prctile(load_time,i); % compute 40 to 80 percentile of load as this is most probable region
% end
%%
if loop == 1
    incre=5;
elseif loop == 2
        incre=1;
elseif loop == 3
        incre = 0.2;
end

model_avg = mean(power_time,2); % calculate the average power output of all turbine models
load_avg = [];
for i=start:incre:start+10
    load_avg(end+1)=prctile(load_time,i); % compute 65 to 73 percentile of load as this is most probable region
end
%%
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
%%
for i=1:1:length(load_avg)
    A = [-model_avg'
        area'];
    b = [-load_avg(i)*1.2
        build_area];
    [selected,~] = intlinprog(f,intcon,A,b,Aeq,beq,lb);
    x_res(:,end+1)=selected;
end
c_list = cost.*x_res;
c_out=[];
%%
for i=1:1:length(c_list(1,:))
    c_out(end+1)=sum(c_list(:,i));
end
%%
selected = wt_models.ModelName;
selected_radius = num2cell(wt_models.rotor_diameter);
x_idx = num2cell(x_res(:,7));
selected = [selected,selected_radius];
selected = [selected,x_idx];
models = [selected, num2cell(wt_models.ModelHeight)];
%%
Complete_Pout = zeros(length(x_res(1,:)),length(Pout_MW));
for ii=1:1:length(x_res(1,:))
    for i=1:1:length(x_res(:,1))
        Complete_Pout(ii,:)=Complete_Pout(ii,:) + x_res(i,ii)*Pout_MW(i,:);
    end
end

%%
fianl_out=[c_out' Complete_Pout];
%%
c_out_sam=c_out';