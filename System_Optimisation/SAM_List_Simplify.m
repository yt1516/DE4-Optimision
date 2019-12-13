function [power_surplus] = SAM_List_Simplify(Power_Out, Load_Required)

    ones_mat = ones(11,48);     % Basic matrix of ones to create load profiles for every test 
    n = 1;                      % Variable to combine the half hour profiles to days 
    power_surplus = [];         % Empty list to create 365 days of data 
    
% The below while loop takes in the half hourly data for load requirements
% and power generation and simplifies them into a single list where each
% value is the surplus or loss for one day 
    while n < 365*48
        day_output = Power_Out(:,n:n+47);
        day_load = Load_Required(n:n+47).*ones_mat;
        day_surplus = [sum(day_output(1,:)) - sum(day_load(1,:));
            sum(day_output(2,:)) - sum(day_load(2,:));
            sum(day_output(3,:)) - sum(day_load(3,:));
            sum(day_output(4,:)) - sum(day_load(4,:));
            sum(day_output(5,:)) - sum(day_load(5,:));
            sum(day_output(6,:)) - sum(day_load(6,:));
            sum(day_output(7,:)) - sum(day_load(7,:));
            sum(day_output(8,:)) - sum(day_load(8,:));
            sum(day_output(9,:)) - sum(day_load(9,:));
            sum(day_output(10,:)) - sum(day_load(10,:));
            sum(day_output(11,:)) - sum(day_load(11,:))];
        power_surplus = [power_surplus, day_surplus];
        n = n + 48;
    end
end