clc
clear all

analysed_profiles = 50:5:100; %defining the initial spread of profiles
profile_space = 5;

L = 3;

for i = 1:L
    
    %Jacob, replace the Pn input with your output and Load_perhouse with
    %your input for load
    WTFout_Combined = matfile('JACOB_11_Profiles.mat');
    Pn  = WTFout_Combined.Complete_Pout;
    Load_perhouse = csvread('JACOB_Load_Use.csv',1,1);
    Turbine_Base = matfile('JACOB_11_Profiles.mat');
    Turbine_Base = Turbine_Base.c_out_sam;

    [optimal_Cost, wind_turbine_profile, ratio] = SAM_Opt_One_Profit(Pn, Load_perhouse, Turbine_Base);

    profile_space = profile_space/((i)*11); %shrink the profile space
    
    analysed_profiles = (analysed_profiles(wind_turbine_profile)-(profile_space*11)):profile_space:(analysed_profiles(wind_turbine_profile));
    % The new profile to be investigated
    
end