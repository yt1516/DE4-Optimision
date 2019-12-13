clc
clear all

WTFout_Combined = matfile('JACOB_11_Profiles.mat');
Pn  = WTFout_Combined.Complete_Pout;
Load_perhouse = csvread('JACOB_Load_Use.csv',1,1);
Turbine_Base = matfile('JACOB_11_Profiles.mat');
Turbine_Base = Turbine_Base.c_out_sam;

[optimal_Cost, wind_turbine_profile, capacity] = SAM_Opt_One_Standalone(Pn, Load_perhouse, Turbine_Base);