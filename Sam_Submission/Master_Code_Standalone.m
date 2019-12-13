clc
clear all

WTFout_Combined = matfile('JACOB_11_Profiles.mat');
Pn  = WTFout_Combined.Complete_Pout;
Load_perhouse = csvread('JACOB_Load_Use.csv',1,1);

[optimal_Cost, wind_turbine_profile, ratio] = SAM_Opt_One_Standalone(Pn, Load_perhouse);