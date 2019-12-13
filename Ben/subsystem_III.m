
%% Charge

clear
close all



% GENERAL

time_interval = 0.5; %Time window in hours

resolution = 5; % Skip to only run every *resolution* days


%% GENERATE EXAMPLE DATA

n = 24/time_interval;
% GRID 
grid_import_limit = 0; % These are ignored, see below 
grid_export_limit = 0; % These are ignored, see below

% WTG
WTG_operating_cost(1:n) = 0;

% BESS
BESS_max_discharge_rate = 4000;
BESS_max_charge_rate = 2000;

BESS_max_SOC_pct = 0.9;
BESS_min_SOC_pct = 0.1;
BESS_capacity = 200;
BESS_operating_cost(1:n) = 0;
BESS_round_trip_efficiency = 0.7; 

year_microgrid_demand_profile = struct2array(load('microgrid_load'));

year_grid_import_cost_profile = struct2array(load('grid_import_pricing'));
year_grid_import_cost_profile = year_grid_import_cost_profile';
year_grid_export_income_profile = year_grid_import_cost_profile * 0.7;

year_wind_profile = struct2array(load('turbine_power_out'))*2;


%% RUN FUNCTION


year_profit_array = run_scheduling_optimiser(time_interval, ...
                                            resolution, ...
                                            BESS_capacity, ...
                                            year_microgrid_demand_profile, ...
                                            year_grid_import_cost_profile, ...
                                            year_grid_export_income_profile, ...
                                            year_wind_profile, ...
                                            BESS_max_discharge_rate, ...
                                            BESS_max_charge_rate, ...
                                            BESS_max_SOC_pct, ...
                                            BESS_min_SOC_pct , ...
                                            BESS_operating_cost, ...
                                            BESS_round_trip_efficiency, ...
                                            WTG_operating_cost, ...
                                            grid_import_limit, ...
                                            grid_export_limit);
                                        
year_profit = sum(year_profit_array);


figure 
set(gcf, 'color','w')
plot (year_profit_array)
xlabel('Day') 
ylabel('Profit (£)') 
title('Annual daily profit/loss data')
yline(0, 'k')
set(gca,'XTick',(0:365))



%% Function 

function result = run_scheduling_optimiser( time_interval, ...
                                            resolution, ...
                                            BESS_capacity, ...
                                            year_microgrid_demand_profile, ...
                                            year_grid_import_cost_profile, ...
                                            year_grid_export_income_profile, ...
                                            year_wind_profile, ...
                                            BESS_max_discharge_rate, ...
                                            BESS_max_charge_rate, ...
                                            BESS_max_SOC_pct, ...
                                            BESS_min_SOC_pct , ...
                                            BESS_operating_cost, ...
                                            BESS_round_trip_efficiency, ...
                                            WTG_operating_cost, ...
                                            grid_import_limit, ...
                                            grid_export_limit)


    n = 24/time_interval;
    BESS_max_SOC = BESS_capacity*BESS_max_SOC_pct;
    BESS_min_SOC = BESS_capacity*BESS_min_SOC_pct;           
    
    grid_to_demand_energy = optimvar('grid_to_demand_energy', n,1);
    grid_to_demand_energy.LowerBound = 0;

    grid_to_BESS_energy = optimvar('grid_to_BESS_energy', n,1);
    grid_to_BESS_energy.LowerBound = 0;

    % WTG
    WTG_to_demand_energy = optimvar('WTG_to_demand_energy', n,1);
    WTG_to_demand_energy.LowerBound = 0;

    WTG_to_BESS_energy = optimvar('WTG_to_BESS_energy', n,1);
    WTG_to_BESS_energy.LowerBound = 0;

    WTG_to_grid_energy = optimvar('WTG_to_grid_energy', n,1);
    WTG_to_grid_energy.LowerBound = 0;

    % BESS
    BESS_to_demand_energy = optimvar('BESS_to_demand_energy', n,1);
    BESS_to_demand_energy.LowerBound = 0;

    BESS_to_grid_energy = optimvar('BESS_to_grid_energy', n,1);
    BESS_to_grid_energy.LowerBound = 0;

    BESS_initial_SOC = optimvar('BESS_initial_SOC');
    BESS_initial_SOC.LowerBound = BESS_min_SOC;
    BESS_initial_SOC.UpperBound = BESS_max_SOC;


    % COMBINED

    WTG_energy = WTG_to_demand_energy + WTG_to_BESS_energy + WTG_to_grid_energy;

    grid_import_energy = grid_to_demand_energy + grid_to_BESS_energy;
    grid_export_energy = WTG_to_grid_energy + BESS_to_grid_energy;

    BESS_charge_energy = grid_to_BESS_energy + WTG_to_BESS_energy;
    BESS_discharge_energy = BESS_to_demand_energy + BESS_to_grid_energy;

    test = isequal (length(year_microgrid_demand_profile), length(year_wind_profile), length(year_grid_import_cost_profile), length(year_grid_export_income_profile));
    if test == 1
       number_of_days = (length(year_microgrid_demand_profile)/n);
    else
        error("Consistency errors in data")
    end


    
    total_profit_array = zeros(number_of_days,1);

    for day = 1:resolution:number_of_days
        
        % Take individual days data
        
        microgrid_demand_profile = year_microgrid_demand_profile((day*n)-(n-1):day*n);
        wind_profile = year_wind_profile((day*n)-(n-1):day*n);
        grid_import_cost_profile = year_grid_import_cost_profile((day*n)-(n-1):day*n);
        grid_export_income_profile = year_grid_export_income_profile((day*n)-(n-1):day*n);
        
        
        % OPTIMISATION PROBLEM
       
        revenues = grid_export_income_profile * grid_export_energy;

        costs = grid_import_cost_profile * grid_import_energy...
                + WTG_operating_cost     * WTG_energy...
                + BESS_operating_cost    * BESS_discharge_energy;

        PROFIT = sum(revenues - costs);

        problem = optimproblem;
        problem.Objective = -PROFIT;

        
        % OPTIMISATION CONSTRAINTS
        
        %The energy sources must meet the microgrid demand
        problem.Constraints.c1 = grid_to_demand_energy ...
                               + WTG_to_demand_energy ...
                               + BESS_to_demand_energy ...
                              == microgrid_demand_profile;

        problem.Constraints.c2 = WTG_energy == wind_profile;

        problem.Constraints.c3 = BESS_discharge_energy <= BESS_max_discharge_rate * time_interval;
        problem.Constraints.c4 = BESS_charge_energy <= BESS_max_charge_rate * time_interval;
        problem.Constraints.c5 = sum(BESS_discharge_energy) == sum(BESS_charge_energy)/BESS_round_trip_efficiency;

        BESS_cumulative_energy_discharged = optimexpr(n);
        BESS_cumulative_energy_charged = optimexpr(n);

        for n = 1:n
            BESS_cumulative_energy_discharged(n) = sum(BESS_discharge_energy(1:n,1));
            BESS_cumulative_energy_charged(n)    = (sum(BESS_charge_energy(1:n,1))/BESS_round_trip_efficiency);
        end
        BESS_SOC = BESS_initial_SOC + BESS_cumulative_energy_charged - BESS_cumulative_energy_discharged;

        problem.Constraints.c6 = BESS_SOC <= BESS_max_SOC;
        problem.Constraints.c7 = BESS_SOC >= BESS_min_SOC; 

        %problem.Constraints.c8 = grid_import_energy <= grid_import_limit * time_interval;
        %problem.Constraints.c9 = grid_export_energy <= grid_export_limit * time_interval; 
        
        %   For the purposes of this example presented below, the majority of power is expected to be 
        %   generated and consumed within the microgrid, so RmaxGimport and  RmaxGexportare ignored. 
        %   However in a highly power-hungry or power-producing scenario, this should be considered.


        % SOLVE
        
        struct_prob = prob2struct(problem);
        struct_prob.options = optimoptions('linprog','Algorithm','dual-simplex', 'Display', 'iter');
        
        [solution,fval,exitflag,output] = linprog(struct_prob)
       
        disp(day)
        total_profit_array(day,1) = fval;
        tic

        
        
        
    end
    
end
