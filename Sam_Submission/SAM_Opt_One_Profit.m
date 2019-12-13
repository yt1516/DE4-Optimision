function [opt_cost_2, wind_turbine_profile, ratio] = SAM_Opt_One_Profit(Pn, Load_perhouse)

% A file to show the concept of taking half hourly turbine power outputs
% and the microgrid half hourly loads and defining the power surplus per
% day over a year period

Load = Load_perhouse; 
Load = Load';
%The .csv file is in kilowatts per household. considering 1000 households 
%and converting from kilowatts to megawatts. Pn in watts so 
%converted to megawatts.

Years_Total = 20;
ratio_profile = [];

% The below profile outlines the four battery technology's important
% properties. These are elaberated on in the report
Battery_Profiles = [[0.83, 0.89, 0.79, 0.72]; 
    [7, 20, 16, 2];
    [0.5, 0.85, 0.8, 1];
    [0.9, 0.9, 0.9, 0.9];
    [546, 270, 494, 460];
    [18.5, 11, 21.5, 25.2];
    [381, 142, 169, 145]];
  
rateoreturn = 0.92;     % rate of return for the discount multiplier 
Cbc_Pre = [];
Cbm_Pre = [];

Price_UK = 1.437; % Electricity Price UK
Temp_Cost = [];

% This establishes a value for summing periods of generation or shortage
% together to investegate if there is a macro period of power shortage.
% Look into the report for more 

% Function to process imported data
power_surplus = SAM_List_Simplify(Pn, Load);

% Function to seperate data into individual matrices for each turbine
% profile 
[Lmax, Profile_1, Profile_2, Profile_3, Profile_4, Profile_5, Profile_6, Profile_7, Profile_8, Profile_9, Profile_10, Profile_11] = SAM_Grouper(power_surplus);

% The below nested for loops create the maintenenace and capital costs for 
% the BESS at different ratios of total required capacity for the
% optimisation task.
for battery = 1:4
    Cbc_List = [];
    Cbm_List = [];
    for list_index = 1:11
        Cbc_raw = [];           % Empty list for values 
        Cbm_raw = [];
        for year = 1:Years_Total
            Cbc_raw = [Cbc_raw, (Battery_Profiles(5,battery)/Years_Total)*Lmax(1,list_index)*rateoreturn^year];
            % Cbc_raw is a list of the capital cost over the 20 years
            Cbm_raw = [Cbm_raw, (Battery_Profiles(6,battery)/Years_Total)*(Lmax(1,list_index)/24)*rateoreturn^year];
            % Cbm_raw is a list of the maintenence cost over the 20 years
        end
        Cbc_List = [Cbc_List, sum(Cbc_raw)];
        Cbm_List = [Cbm_List, sum(Cbm_raw)];
    end 
    Cbc_Pre = [Cbc_Pre, Cbc_List];
    Cbm_Pre = [Cbm_Pre, Cbm_List];
end

% Iterate through years as well as the cost to reimburse the storqage lost
% from the ratio section

Cbc_Battery = [Cbc_Pre(1:11);
    Cbc_Pre(12:22);
    Cbc_Pre(23:33);
    Cbc_Pre(34:44)];
Cbm_Battery = [Cbm_Pre(1:11);
    Cbm_Pre(12:22);
    Cbm_Pre(23:33);
    Cbm_Pre(34:44)];

Cbc_Final = [];
Cbm_Final = [];

depth = 1;

% The below for loop looks at the different ratios of cost for power
% storages.
for ratio = 0.05:0.05:1
    Cbc_Final(:,:,depth) = ratio*Cbc_Battery;
    Cbm_Final(:,:,depth) = ratio*Cbm_Battery;
    ratio_profile(depth,:) = (1-ratio+0.05)*Lmax; % inverse of the ratio plus 0.05 to create a profile for max capacity from batteries 
    depth = depth + 1;
end

% the below are lists for individual profiles for analysis later. This done
% instead of dynamically changing list name to reduce run time

Shortage_Matrix = [];   % list to store all profile shortages
tick = 1;   % tick to change the ratio being looked at 
[Shortage_Matrix, tick] = SAM_Profile_Adjuster(Profile_1, ratio_profile, tick, Shortage_Matrix);
[Shortage_Matrix, tick] = SAM_Profile_Adjuster(Profile_2, ratio_profile, tick, Shortage_Matrix);
[Shortage_Matrix, tick] = SAM_Profile_Adjuster(Profile_3, ratio_profile, tick, Shortage_Matrix);
[Shortage_Matrix, tick] = SAM_Profile_Adjuster(Profile_4, ratio_profile, tick, Shortage_Matrix);
[Shortage_Matrix, tick] = SAM_Profile_Adjuster(Profile_5, ratio_profile, tick, Shortage_Matrix);
[Shortage_Matrix, tick] = SAM_Profile_Adjuster(Profile_6, ratio_profile, tick, Shortage_Matrix);
[Shortage_Matrix, tick] = SAM_Profile_Adjuster(Profile_7, ratio_profile, tick, Shortage_Matrix);
[Shortage_Matrix, tick] = SAM_Profile_Adjuster(Profile_8, ratio_profile, tick, Shortage_Matrix);
[Shortage_Matrix, tick] = SAM_Profile_Adjuster(Profile_9, ratio_profile, tick, Shortage_Matrix);
[Shortage_Matrix, tick] = SAM_Profile_Adjuster(Profile_10, ratio_profile, tick, Shortage_Matrix);
[Shortage_Matrix, tick] = SAM_Profile_Adjuster(Profile_11, ratio_profile, tick, Shortage_Matrix);

Shortage_Costs = Price_UK*Shortage_Matrix;

for x = 1:11
    for y = 1:20
        for year = 1:Years_Total
            Temp_Cost = [Temp_Cost, Shortage_Costs(x,y)*rateoreturn^year];
        end   
        Shortage_Costs(x,y) = sum(Temp_Cost);
        Temp_Cost = [];
    end
end 
    
% At this stage there are Three matrices which consider cost. Cbc_final,
% Cbm_Final and Shortage_Costs. These cover annualised capital costs,
% annualised maintenence and replacement costs and the annualised cost to
% purchase power from the grid if required at different capacity ratios.
% The final result will balence the cost of the grid and the cost to
% maintain power.
    
Cbess_Final = Cbc_Final;        % Removed Maintenence since considered in Ben's 

Cbess_Final = permute(Cbess_Final, [2 3 1]);

Shortage_Costs = fliplr(Shortage_Costs);
Final_Cost = [];
for n = 1:4
    Final_Cost(:,:,n) = [Shortage_Costs + Cbess_Final(:,:,n)];
end 

Turbine_Base = matfile('JACOB_11_Profiles.mat');
Turbine_Base = Turbine_Base.c_out_sam;
Turbine_Cost = ones(11,20,4);

for n = 1:11
    Turbine_Cost(n,:,:) = Turbine_Base(n);
end 

Final_Cost = Final_Cost + Turbine_Cost;

[v,loc] = min(Final_Cost(:));
[ii,jj,k] = ind2sub(size(Final_Cost),loc);

Minimum_Coordinates_1 = [ii, jj, k];

opt_cost_1 = Final_Cost(Minimum_Coordinates_1(1), Minimum_Coordinates_1(2), Minimum_Coordinates_1(3));

Year_Profit_perProfile = [];
Year_Profit = [];


% For loop to use Ben's Code 
for profile = 1:11
    for ratio = 1:20
        Profit = BEN_BESS_profit(Pn(profile,:), ratio_profile(ratio,profile));
        Year_Profit_perProfile = [Year_Profit_perProfile, Profit];
    end
    Year_Profit = [Year_Profit; Year_Profit_perProfile];
    Year_Profit_perProfile = [];
end

% Year_Profit = matfile('Year_Profit.mat'); % Import Example ben's code to shorten running time 
% Year_Profit = Year_Profit.Year_Profit;

profit_sum = [];
profit_ratio = [];
profit_20years = [];


% For loop to process Ben's Calculations 
for profile = 1:11
    for ratio = 1:20
        for year = 0:(Years_Total - 1)
            profit_sum = [profit_sum, Year_Profit(1, ratio)/(rateoreturn^year)];
        end
        profit_ratio = [profit_ratio, sum(profit_sum)];
        profit_sum = [];
    end
    profit_20years = [profit_20years; profit_ratio];
    profit_ratio = [];
end

for n = 1:4
    Final_Profit(:,:,n) = [Final_Cost(:,:,n) - profit_20years];
end 

for a = 1:11
    for b = 1:20
        for c = 1:4 
            if Final_Profit(a,b,c) > 0
                Final_Profit(a,b,c) = 1000000000000000; % more money than on the planet therefore always invalid 
            end 
        end 
    end 
end 
            
[v,loc] = min(Final_Profit(:));
[ii,jj,k] = ind2sub(size(Final_Cost),loc);

Minimum_Coordinates_2 = [ii, jj, k];

opt_cost_2 = Final_Cost(Minimum_Coordinates_2(1), Minimum_Coordinates_2(2), Minimum_Coordinates_2(3));

wind_turbine_profile = ii;

ratio = (20-jj+1)/20;

end
