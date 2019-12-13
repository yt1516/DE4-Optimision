clc
clear all

analysed_profiles = 50:5:100; %defining the initial spread of profiles
profile_space = 5;
Load_perhouse = csvread('oneYearPower.csv',1,1);
L = 3;

for i = 1:L
    
    x = 1.2; % width of the area
    y = 1.2; % length of the area
    Pctstart=analysed_profiles(1); % default starting percentile
    Pctend=analysed_profiles(11); % default finishing percentile

    [Power_Output, install_cost, maintain_cost, turbines]=turb_selection(x,y,Pctstart,Pctend);
    
    Turbine_Cost = install_cost + maintain_cost;
    
    [optimal_Cost, wind_turbine_profile, ratio] = SAM_Opt_One_Profit(Power_Output, Load_perhouse, Turbine_Cost);

    profile_space = profile_space/((i)*11); %shrink the profile space
    
    analysed_profiles = (analysed_profiles(wind_turbine_profile)-(profile_space*11)):profile_space:(analysed_profiles(wind_turbine_profile));
    % The new profile to be investigated
    
end