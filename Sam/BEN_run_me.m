year_microgrid_load_profile = csvread('JACOB_Load_Use.csv',1,1);

year_grid_import_price_profile = struct2array(load('grid_import_pricing'));
year_grid_import_price_profile = year_grid_import_price_profile';
year_grid_export_price_profile = year_grid_import_price_profile * 0.7;

year_wind_profile = struct2array(load('JACOB_turbine_power_out'));


BESS_capacity = 100;

result = get_total_profit(BESS_capacity, year_microgrid_load_profile, year_wind_profile, year_grid_import_price_profile, year_grid_export_price_profile);


function total_profit = get_total_profit(BESS_capacity, year_microgrid_load_profile, year_wind_profile, year_grid_import_price_profile, year_grid_export_price_profile)
    
    total_profit_array = zeros(365,1);
    for day = 1 : 10
        disp(day)
        total_profit_array(day,1) = compute_24h_profit(BESS_capacity, year_microgrid_load_profile((day*48)-47:day*48), year_wind_profile((day*48)-47:day*48), year_grid_import_price_profile((day*48)-47:day*48), year_grid_export_price_profile((day*48)-47:day*48));
        
    end
    total_profit = sum(total_profit_array);
end 



function day_profit = compute_24h_profit(BESS_capacity, microgrid_load_profile, wind_profile, grid_import_price_profile, grid_export_price_profile)
    
    % !!!!!! Turn visualisation on or off! !!!!!!!
    visualisation = 0;


    % Computes profit for a given 24 hour period
    tic
    % GENERAL
    time_period = 24/length(microgrid_load_profile); %Time window in hours

    % GRID 
    grid_import_limit = 100;
    grid_export_limit = 100;
    peak_shaving_limit = 0; 

    % WTG
    WTG_operating_cost(1:48) = 5;

    % BESS
    BESS_max_discharge_rate = 50*5;
    BESS_max_charge_rate = 10*5;

    %BESS_max_SOC = 180;
    %BESS_min_SOC = 50;
    %BESS_capacity = 200;
    
    BESS_max_SOC = BESS_capacity*0.9;
    BESS_min_SOC = BESS_capacity*0.1;
    
   
    BESS_operating_cost(1:48) = 10;
    BESS_round_trip_efficiency = 0.7; 
    
    
    % GRID
    grid_to_load_power = optimvar('grid_to_load_power', 48,1);
    grid_to_load_power.LowerBound = 0;

    grid_to_BESS_power = optimvar('grid_to_BESS_power', 48,1);
    grid_to_BESS_power.LowerBound = 0;

    % WTG
    WTG_to_load_power = optimvar('WTG_to_load_power', 48,1);
    WTG_to_load_power.LowerBound = 0;

    WTG_to_BESS_power = optimvar('WTG_to_BESS_power', 48,1);
    WTG_to_BESS_power.LowerBound = 0;

    WTG_to_grid_power = optimvar('WTG_to_grid_power', 48,1);
    WTG_to_grid_power.LowerBound = 0;

    % BESS
    BESS_to_load_power = optimvar('BESS_to_load_power', 48,1);
    BESS_to_load_power.LowerBound = 0;

    BESS_to_grid_power = optimvar('BESS_to_grid_power', 48,1);
    BESS_to_grid_power.LowerBound = 0;

    BESS_initial_SOC = optimvar('BESS_initial_SOC');
    BESS_initial_SOC.LowerBound = BESS_min_SOC;
    BESS_initial_SOC.UpperBound = BESS_max_SOC;


    % COMBINED

    WTG_power = WTG_to_load_power + WTG_to_BESS_power + WTG_to_grid_power;

    grid_import_power = grid_to_load_power + grid_to_BESS_power;
    grid_export_power = WTG_to_grid_power + BESS_to_grid_power;

    BESS_charge_power = grid_to_BESS_power + WTG_to_BESS_power;
    BESS_power_loss = ((1/BESS_round_trip_efficiency)-1) * BESS_charge_power;
    BESS_adjusted_charge_power = BESS_charge_power + BESS_power_loss;
    BESS_discharge_power = BESS_to_load_power + BESS_to_grid_power;


    % Optimisation problem

    revenues = grid_export_price_profile * grid_export_power;

    costs = grid_import_price_profile     * grid_import_power...
            + WTG_operating_cost        * WTG_power...
            + BESS_operating_cost       * BESS_discharge_power;

    PROFIT = sum(revenues - costs);

    problem = optimproblem;
    problem.Objective = -PROFIT;

    % Optimisation constraints

    problem.Constraints.c1 = grid_to_load_power ...
                           + WTG_to_load_power ...
                           + BESS_to_load_power ...
                          == microgrid_load_profile;

    problem.Constraints.c2 = WTG_power == wind_profile;

    problem.Constraints.c3 = BESS_discharge_power <= BESS_max_discharge_rate;
    problem.Constraints.c4 = BESS_adjusted_charge_power <= BESS_max_charge_rate;
    problem.Constraints.c5 = sum(BESS_discharge_power) == sum(BESS_charge_power);

    BESS_total_energy_discharged = optimexpr(48);
    BESS_total_energy_charged = optimexpr(48);

    for n = 1:48
        BESS_total_energy_discharged(n) = sum(BESS_discharge_power(1:n,1)) * time_period;
        BESS_total_energy_charged(n)    = sum(BESS_charge_power(1:n,1))    * time_period;
    end
    BESS_SOC = BESS_initial_SOC + BESS_total_energy_charged - BESS_total_energy_discharged;

    problem.Constraints.c6 = BESS_SOC <= BESS_max_SOC;
    problem.Constraints.c7 = BESS_SOC >= BESS_min_SOC;

    problem.Constraints.c8 = grid_import_power <= grid_import_limit;
    problem.Constraints.c9 = grid_export_power <= grid_export_limit;

    problem.Constraints.c10 = BESS_initial_SOC == 50;

    % Solve! 
    toc
    solution = solve(problem);
    toc
    day_profit = evaluate(PROFIT, solution);
    
    

    if visualisation
        % GRID 
        grid_export_power = evaluate(grid_export_power, solution);
        grid_import_power = evaluate(grid_import_power, solution);
        grid_to_BESS_power = solution.grid_to_BESS_power;
        grid_to_load_power = solution.grid_to_load_power;

        % BESS
        BESS_adjusted_charge_power = evaluate(BESS_adjusted_charge_power, solution);
        BESS_charge_power = evaluate(BESS_charge_power, solution);
        BESS_discharge_power = evaluate(BESS_discharge_power, solution);
        BESS_initial_SOC = solution.BESS_initial_SOC;
        BESS_power_loss = evaluate(BESS_power_loss, solution);
        BESS_SOC = evaluate(BESS_SOC, solution);
        BESS_SOC_percentage = (BESS_SOC/BESS_capacity)*100; % percentage over AVAILABLE charge
        BESS_to_grid_power = solution.BESS_to_grid_power;
        BESS_to_load_power = solution.BESS_to_load_power;
        BESS_total_energy_charged = evaluate(BESS_total_energy_charged, solution);
        BESS_total_energy_discharged = evaluate(BESS_total_energy_discharged, solution);

        % WTG 
        WTG_power = evaluate(WTG_power, solution);
        WTG_to_BESS_power = solution.WTG_to_BESS_power;
        WTG_to_grid_power = solution.WTG_to_grid_power;
        WTG_to_load_power = solution.WTG_to_load_power;

        % FINANCIAL 
        PROFIT = evaluate(PROFIT, solution);


        % GRID
        grid_to_load_cost = grid_import_price_profile * grid_to_load_power;
        grid_to_BESS_cost = grid_import_price_profile * grid_to_BESS_power;

        % WTG
        WTG_to_load_cost = WTG_operating_cost * WTG_to_load_power;
        WTG_to_BESS_cost = WTG_operating_cost * WTG_to_BESS_power;
        WTG_to_grid_cost = WTG_operating_cost * WTG_to_grid_power;
        WTG_to_grid_revenue = grid_export_price_profile * WTG_to_grid_power;

        % BESS
        BESS_to_load_cost = BESS_operating_cost * BESS_to_load_power;
        BESS_to_grid_cost = BESS_operating_cost * BESS_to_grid_power;
        BESS_to_grid_revenue = grid_export_price_profile * BESS_to_grid_power;

        %COMBINED
        grid_import_cost = grid_to_load_cost + grid_to_BESS_cost;
        grid_export_revenue = WTG_to_grid_revenue + BESS_to_grid_revenue;
        WTG_cost = WTG_to_load_cost + WTG_to_BESS_cost + WTG_to_grid_cost;
        BESS_discharge_cost = BESS_to_load_cost + BESS_to_grid_cost;

        costs = grid_import_cost + WTG_cost + BESS_discharge_cost;
        revenues = grid_export_revenue;
        PROFIT2 = revenues - costs; % For comparison - to confirm PROFIT2 gives same value as objective function

        grid_only_cost = grid_import_price_profile * microgrid_load_profile;
        SAVING = PROFIT - - grid_only_cost;

        cost_of_charging = grid_import_price_profile * grid_to_BESS_power + WTG_operating_cost * WTG_to_BESS_power;
        cost_of_discharging = grid_export_price_profile * BESS_to_grid_power + grid_import_price_profile * BESS_to_load_power; 
        % Cost of discharge === revenue of sales to grid + savings of load powered, assuming power would otherwise be imported from grid
        ARBITRAGE = cost_of_discharging - cost_of_charging;



        % Energy TO LOAD ONLY
        LOAD_ENERGY_REQUIRED = sum(microgrid_load_profile)*time_period;
        grid_to_load = sum(grid_to_load_power)*time_period;
        WTG_to_load = sum(WTG_to_load_power)*time_period;
        BESS_to_load = sum(BESS_to_load_power)*time_period;

        % State of charge
        initial_SOC_pct = (BESS_initial_SOC/BESS_capacity)*100;
        highest_SOC_pct = max(BESS_SOC_percentage);
        lowest_SOC_pct = min(BESS_SOC_percentage);
        min_SOC_pct = (BESS_min_SOC/BESS_capacity)*100; 
        max_SOC_pct = (BESS_max_SOC/BESS_capacity)*100; 



        figure('units','normalized','outerposition',[0 0 1 1])
        set(gcf, 'color','w')
        sgtitle({'LP METHOD FOR OPTIMISATION OF BESS CHARGE SCHEDULING'; 'BEN COBLEY';}, 'FontWeight', 'bold')
        skipcolour = zeros(48,1);

        global_power_ylim = max([max(wind_profile), grid_import_limit, grid_export_limit, max(BESS_discharge_power), max(microgrid_load_profile)]) +10;
        global_price_ylim = max([max(grid_import_price_profile), max(grid_export_price_profile), WTG_operating_cost, BESS_operating_cost]) + 10;

        % Generation/import/export price [£/kWh]
        subplot(4,3,1);
        plot(grid_import_price_profile, '.-', 'Color', [0 0.4470 0.7410], 'LineWidth', 1.5)
        hold on
        plot(grid_export_price_profile, '.-', 'Color', [0.6350 0.0780 0.1840], 'LineWidth', 1.5)
        plot(WTG_operating_cost, '.-', 'Color', [0.8500 0.3250 0.0980], 'LineWidth', 1.5)
        plot(BESS_operating_cost, '.-', 'Color', [0.9290 0.6940 0.1250], 'LineWidth', 1.5)
        ylim([0,global_price_ylim])
        set(gca,'XTick',(0:12:48))
        title('Generation/import/export price [£/kWh]')

        % WTG power forecast [kW]
        subplot(4,3,2);
        bar(wind_profile, 'FaceColor', [0.8500 0.3250 0.0980])
        ylim([0,global_power_ylim])
        set(gca,'XTick',(0:12:48))
        title('WTG power forecast [kW]')

        % Scheduled grid import [kW]
        subplot(4,3,4);
        yline(peak_shaving_limit, '--', 'Color', [0.66,0.66,0.66], 'LineWidth', 1)
        hold on
        yline(grid_import_limit, '--', 'Color', [0.66,0.66,0.66], 'LineWidth', 1)
        bar([skipcolour, skipcolour, skipcolour, grid_to_BESS_power, skipcolour, grid_to_load_power], 'stacked')
        ylim([0,global_power_ylim])
        set(gca,'XTick',(0:12:48))
        title('Scheduled grid import [kW]')
        yyaxis right
        ylim([0,global_price_ylim])
        p = plot(grid_import_price_profile, '-', 'Color', [0 0.4470 0.7410], 'LineWidth', 1);
        p.Color(4) = 0.25; 
        ax = gca;
        ax.YAxis(1).Color = 'k';
        ax.YAxis(2).Color = [0 0.4470 0.7410];

        % Scheduled grid export [kW]
        subplot(4,3,5);
        bar([skipcolour, WTG_to_grid_power, BESS_to_grid_power], 'stacked')
        hold on
        yline(grid_export_limit, '--', 'Color', [0.66,0.66,0.66], 'LineWidth', 1)
        ylim([0,global_power_ylim])
        set(gca,'XTick',(0:12:48))
        title('Scheduled grid export [kW]')
        yyaxis right
        ylim([0,global_price_ylim])
        p = plot(grid_export_price_profile, '-', 'Color', [0.6350 0.0780 0.1840], 'LineWidth', 1);
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
        set(gca,'XTick',(0:12:48))
        title('Scheduled BESS charge [%]')

        % Scheduled BESS charge/discharge [kW]
        subplot(4,3,8);
        bar([skipcolour,skipcolour,BESS_discharge_power], 'stacked') 
        hold on
        bar([-BESS_charge_power, -BESS_power_loss], 'stacked')
        ylim([-global_power_ylim,global_power_ylim])
        set(gca,'XTick',(0:12:48))
        set(gcf, 'color','w')
        title('Scheduled BESS charge/discharge [kW]')

        % Microgrid load [kW]
        subplot(4,3,10);
        bar(microgrid_load_profile, 'FaceColor', [0.3010 0.7450 0.9330])
        ylim([0,global_power_ylim])
        set(gca,'XTick',(0:12:48))
        title('Microgrid load [kW]')

        % Microgrid load breakdown [kW]
        subplot(4,3,11);
        bar([grid_to_load_power, WTG_to_load_power, BESS_to_load_power], 'stacked')
        ylim([0,global_power_ylim])
        set(gca,'XTick',(0:12:48))
        title('Microgrid load breakdown [kW]')






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

        row_names = {'grid_to_load';'wind_to_load';'BESS_to_load';'MICROGRID_load';};
        kWh = [grid_to_load; WTG_to_load; BESS_to_load; LOAD_ENERGY_REQUIRED; ];



        data_table = table(kWh, 'RowNames',row_names);

        uitable('Data', data_table{:,:}, 'RowName',data_table.Properties.RowNames,'ColumnName',data_table.Properties.VariableNames, 'Units', 'Normalized', 'Position', table_position, 'ColumnWidth', 'auto');
        set(table_subplot, 'Visible', 'Off')
        
        disp('Press enter to continue')
        close all
        input('')

    end



end





