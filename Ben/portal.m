
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
BESS_max_discharge_rate = 50;
BESS_max_charge_rate = 25;

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
    test = isequal (length(year_microgrid_demand_profile), length(year_wind_profile), length(year_grid_import_cost_profile), length(year_grid_export_income_profile));
        if test == 1
           number_of_days = (length(year_microgrid_demand_profile)/n);
        else
            error("Consistency errors in data")
        end
     total_profit_array = zeros(number_of_days,1);
    
    
    for day = 1:resolution:number_of_days

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

        [solution,fval,exitflag,output] = solve(problem);
       
        disp(day)
        total_profit_array(day,1) = fval;
        tic

 
    
        %% Evaluate

        % GRID 
        grid_export_energy = evaluate(grid_export_energy, solution);
        grid_import_energy = evaluate(grid_import_energy, solution);
        grid_to_BESS_energy = solution.grid_to_BESS_energy;
        grid_to_demand_energy = solution.grid_to_demand_energy;

        % BESS
        BESS_charge_energy = evaluate(BESS_charge_energy, solution);
        BESS_discharge_energy = evaluate(BESS_discharge_energy, solution);
        BESS_initial_SOC = solution.BESS_initial_SOC;
        BESS_energy_loss = BESS_charge_energy - BESS_round_trip_efficiency*BESS_charge_energy;
        BESS_SOC = evaluate(BESS_SOC, solution);
        BESS_SOC_percentage = (BESS_SOC/BESS_capacity)*100; % percentage over AVAILABLE charge
        BESS_to_grid_energy = solution.BESS_to_grid_energy;
        BESS_to_demand_energy = solution.BESS_to_demand_energy;
        BESS_cumulative_energy_charged = evaluate(BESS_cumulative_energy_charged, solution);
        BESS_cumulative_energy_discharged = evaluate(BESS_cumulative_energy_discharged, solution);

        % WTG 
        WTG_energy = evaluate(WTG_energy, solution);
        WTG_to_BESS_energy = solution.WTG_to_BESS_energy;
        WTG_to_grid_energy = solution.WTG_to_grid_energy;
        WTG_to_demand_energy = solution.WTG_to_demand_energy;

        % FINANCIAL 
        PROFIT = evaluate(PROFIT, solution);

        %% CALCULATE FINANCIAL BREAKDOWN 

        % GRID
        grid_to_demand_cost = grid_import_cost_profile * grid_to_demand_energy;
        grid_to_BESS_cost = grid_import_cost_profile * grid_to_BESS_energy;

        % WTG
        WTG_to_demand_cost = sum(WTG_operating_cost * WTG_to_demand_energy);
        WTG_to_BESS_cost = sum(WTG_operating_cost * WTG_to_BESS_energy);
        WTG_to_grid_cost = sum(WTG_operating_cost * WTG_to_grid_energy);
        WTG_to_grid_revenue = sum(grid_export_income_profile * WTG_to_grid_energy);

        % BESS
        BESS_to_demand_cost = sum(BESS_operating_cost * BESS_to_demand_energy);
        BESS_to_grid_cost = sum(BESS_operating_cost * BESS_to_grid_energy);
        BESS_to_grid_revenue = sum(grid_export_income_profile * BESS_to_grid_energy);

        %COMBINED
        grid_import_cost = grid_to_demand_cost + grid_to_BESS_cost;
        grid_export_revenue = WTG_to_grid_revenue + BESS_to_grid_revenue;
        WTG_cost = WTG_to_demand_cost + WTG_to_BESS_cost + WTG_to_grid_cost;
        BESS_discharge_cost = BESS_to_demand_cost + BESS_to_grid_cost;

        costs = grid_import_cost + WTG_cost + BESS_discharge_cost;
        revenues = grid_export_revenue;
        PROFIT2 = revenues - costs; % For validation - to confirm PROFIT2 gives same value as objective function

        grid_only_cost = grid_import_cost_profile * microgrid_demand_profile;
        SAVING = PROFIT - - grid_only_cost;

        cost_of_charging = grid_import_cost_profile * grid_to_BESS_energy + WTG_operating_cost * WTG_to_BESS_energy;
        cost_of_discharging = sum(grid_export_income_profile * BESS_to_grid_energy + grid_import_cost_profile * BESS_to_demand_energy); 
        % Cost of discharge === revenue of sales to grid + savings of demand powered, assuming energy would otherwise be imported from grid
        ARBITRAGE = cost_of_discharging - cost_of_charging;


        %% CALCULATE ENERGY USE

        % Energy TO demand ONLY
        demand_ENERGY_REQUIRED = sum(microgrid_demand_profile);
        grid_to_demand = sum(grid_to_demand_energy);
        WTG_to_demand = sum(WTG_to_demand_energy);
        BESS_to_demand = sum(BESS_to_demand_energy);

        % State of charge
        initial_SOC_pct = (BESS_initial_SOC/BESS_capacity)*100;
        highest_SOC_pct = max(BESS_SOC_percentage);
        lowest_SOC_pct = min(BESS_SOC_percentage);
        min_SOC_pct = (BESS_min_SOC/BESS_capacity)*100; 
        max_SOC_pct = (BESS_max_SOC/BESS_capacity)*100; 


        %% Convert and plot data

        figure('units','normalized','outerposition',[0 0 1 1])
        set(gcf, 'color','w')
        sgtitle({'LP METHOD FOR OPTIMISATION OF BESS CHARGE SCHEDULING'; 'BEN COBLEY';}, 'FontWeight', 'bold')
        skipcolour = zeros(n,1);

        % Convert power limit to energy limit
        global_energy_ylim = max([max(wind_profile), max(BESS_discharge_energy), max(microgrid_demand_profile)]) +10;

        global_cost_ylim = max([max(grid_import_cost_profile), max(grid_export_income_profile), WTG_operating_cost, BESS_operating_cost]) + 10;


        % Generation/import/export price [£/kWh]
        subplot(4,3,1);
        plot(grid_import_cost_profile, '.-', 'Color', [0 0.4470 0.7410], 'LineWidth', 1.5)
        hold on
        plot(grid_export_income_profile, '.-', 'Color', [0.6350 0.0780 0.1840], 'LineWidth', 1.5)
        plot(WTG_operating_cost, '.-', 'Color', [0.8500 0.3250 0.0980], 'LineWidth', 1.5)
        plot(BESS_operating_cost, '.-', 'Color', [0.9290 0.6940 0.1250], 'LineWidth', 1.5)
        ylim([0,global_cost_ylim])
        set(gca,'XTick',(0:12:n))
        title('Generation/import/export price [£/kWh]')

        % WTG energy supply forecast [kWh]
        subplot(4,3,2);
        bar(wind_profile, 'FaceColor', [0.8500 0.3250 0.0980])
        ylim([0,global_energy_ylim])
        set(gca,'XTick',(0:12:n))
        title('WTG energy supply forecast [kWh]')

        % Scheduled grid import [kWh]
        subplot(4,3,4);
        hold on
        yline(grid_import_limit * time_interval, '--', 'Color', [0.66,0.66,0.66], 'LineWidth', 1) % Convert power limit to energy limit
        bar([skipcolour, skipcolour, skipcolour, grid_to_BESS_energy, skipcolour, grid_to_demand_energy], 'stacked')
        ylim([0,global_energy_ylim])
        set(gca,'XTick',(0:12:n))
        title('Scheduled grid import [kWh]')
        yyaxis right
        ylim([0,global_cost_ylim])
        p = plot(grid_import_cost_profile, '-', 'Color', [0 0.4470 0.7410], 'LineWidth', 1);
        p.Color(4) = 0.25; 
        ax = gca;
        ax.YAxis(1).Color = 'k';
        ax.YAxis(2).Color = [0 0.4470 0.7410];

        % Scheduled grid export [kWh]
        subplot(4,3,5);
        bar([skipcolour, WTG_to_grid_energy, BESS_to_grid_energy], 'stacked')
        hold on
        yline(grid_export_limit * time_interval, '--', 'Color', [0.66,0.66,0.66], 'LineWidth', 1) % Convert power limit to energy limit
        ylim([0,global_energy_ylim])
        set(gca,'XTick',(0:12:n))
        title('Scheduled grid export [kWh]')
        yyaxis right
        ylim([0,global_cost_ylim])
        p = plot(grid_export_income_profile, '-', 'Color', [0.6350 0.0780 0.1840], 'LineWidth', 1);
        p.Color(4) = 0.25; 
        ax = gca;
        ax.YAxis(1).Color = 'k';
        ax.YAxis(2).Color = [0.6350 0.0780 0.1840];

        % Scheduled BESS charge [%]
        subplot(4,3,7);
        plot(BESS_SOC_percentage, '.-', 'Color', [0.9290 0.6940 0.1250], 'LineWidth', 2)
        ylim([0, 100])
        yline(0, 'k')
        yline((BESS_max_SOC/BESS_capacity)*100,  '--', 'Color', [0.66,0.66,0.66], 'LineWidth', 1)
        yline((BESS_min_SOC/BESS_capacity)*100, '--', 'Color', [0.66,0.66,0.66], 'LineWidth', 1)
        set(gca,'XTick',(0:12:n))
        title('Scheduled BESS charge [%]')

        % Scheduled BESS charge/discharge [kWh]
        subplot(4,3,8);
        bar([skipcolour,skipcolour,BESS_discharge_energy], 'stacked') 
        hold on
        bar([-BESS_charge_energy, -BESS_energy_loss], 'stacked')
        ylim([-global_energy_ylim,global_energy_ylim])
        set(gca,'XTick',(0:12:n))
        set(gcf, 'color','w')
        title('Scheduled BESS charge/discharge [kWh]')

        % Microgrid demand [kWh]
        subplot(4,3,10);
        bar(microgrid_demand_profile, 'FaceColor', [0.3010 0.7450 0.9330])
        ylim([0,global_energy_ylim])
        set(gca,'XTick',(0:12:n))
        title('Microgrid demand [kWh]')

        % Microgrid demand breakdown [kWh]
        subplot(4,3,11);
        bar([grid_to_demand_energy, WTG_to_demand_energy, BESS_to_demand_energy], 'stacked')
        ylim([0,global_energy_ylim])
        set(gca,'XTick',(0:12:n))
        title('Microgrid demand breakdown [kWh]')





        %% TABLES

        A = 1;
        B = {'2.5223523452'};

        % TABLE 1 
        table_subplot = subplot(4,3,3);
        table_position = get(table_subplot, 'Position');

        row_names = {'grid_only_cost';'SAVING'; 'cost_of_charging'; 'cost_of_discharging'; 'ARBITRAGE';};
        GBP = [grid_only_cost; SAVING; cost_of_charging; cost_of_discharging; ARBITRAGE;];

        data_table = table(GBP,'RowNames',row_names);
        uitable('Data', data_table{:,:}, 'RowName',data_table.Properties.RowNames,'ColumnName',data_table.Properties.VariableNames, 'Units', 'Normalized', 'Position', table_position, 'ColumnWidth', 'auto');
        set(table_subplot, 'Visible', 'Off')     

        % TABLE 2
        table_subplot = subplot(4,3,6);
        table_position = get(table_subplot, 'Position');

        row_names = {'grid_import_cost'; 'WTG_cost'; 'BESS_discharge_cost'; 'grid_export_revenue'; 'PROFIT';};
        GBP = [-grid_import_cost; -WTG_cost; -BESS_discharge_cost; grid_export_revenue; PROFIT;];

        data_table = table(GBP,'RowNames',row_names);
        uitable('Data', data_table{:,:}, 'RowName',data_table.Properties.RowNames,'ColumnName',data_table.Properties.VariableNames, 'Units', 'Normalized', 'Position', table_position, 'ColumnWidth', 'auto');
        set(table_subplot, 'Visible', 'Off')     

        % TABLE 3
        table_subplot = subplot(4,3,9);
        table_position = get(table_subplot, 'Position');

        row_names = {'min_SOC_pct'; 'lowest_SOC_pct'; 'initial_SOC_pct'; 'highest_SOC_pct'; 'max_SOC_pct'};
        pct = [min_SOC_pct; lowest_SOC_pct; initial_SOC_pct; highest_SOC_pct;  max_SOC_pct;];

        data_table = table(pct,'RowNames',row_names);
        uitable('Data', data_table{:,:}, 'RowName',data_table.Properties.RowNames,'ColumnName',data_table.Properties.VariableNames, 'Units', 'Normalized', 'Position', table_position, 'ColumnWidth', 'auto');
        set(table_subplot, 'Visible', 'Off')     

        % TABLE 4
        table_subplot = subplot(4,3,12);
        table_position = get(table_subplot, 'Position');

        row_names = {'grid_to_demand';'wind_to_demand';'BESS_to_demand';'MICROGRID_demand';};
        kWh = [grid_to_demand; WTG_to_demand; BESS_to_demand; demand_ENERGY_REQUIRED; ];



        data_table = table(kWh, 'RowNames',row_names);

        uitable('Data', data_table{:,:}, 'RowName',data_table.Properties.RowNames,'ColumnName',data_table.Properties.VariableNames, 'Units', 'Normalized', 'Position', table_position, 'ColumnWidth', 'auto');
        set(table_subplot, 'Visible', 'Off')
        
        
        disp('Press enter to continue')
        input('')
        close all
        
        

    end
        
end
