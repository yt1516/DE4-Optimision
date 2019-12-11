function [Lmax, Profile_1, Profile_2, Profile_3, Profile_4, Profile_5, Profile_6, Profile_7, Profile_8, Profile_9, Profile_10, Profile_11] = SAM_Grouper(power_surplus)

posday = 0;
Lmax = [];              % Empty list for maximum capacity
day_count = 0;          % Ticking count for number of days for first combined period 
shortage = 0;           % Ticking count for the period of shortage or generation
R = 1;                  % Ticking count to iterate through elements of the Total_Shortage list 
Macro_Shortage = 0;   
All_Storage = []; 

% The below for loop and integrate for and while loops are the main part of
% data processing, looking at all 9 power output profiles, comparing them
% to the load requirement and outputting all required data for the
% optimisation
for counter = 1:11
    load_shortages = [];    % List to store the power shortage
    shortage_days = [];     % List containing the number of days for a given period of power shortage 
    current_day = [];       % List to record the last day of a macro period 
    load_shortages2 = [];   % The same but for periods of charging 
    shortage_days2 = [];
    current_day2 = [];
% The following for loop runs through the list power_surplus and groups
% together days where power is lost
    current_surplus = power_surplus(counter,:);
    Total_Shortage = [];
    for day = 1:1:365
        if current_surplus(day) < 0
            day_count = day_count + 1;
            shortage = shortage + current_surplus(day);
        else
            if day_count >=1 
                load_shortages = [load_shortages, shortage];
                shortage_days = [shortage_days, day_count];
                current_day = [current_day, day];
                day_count = 0;   
                shortage = 0;
            end
        end
    end 

    % The following for loop runs through the list power_surplus and groups
    % together days where power is generated 
    for day = 1:1:365
        if current_surplus(day) >= 0
            day_count = day_count + 1;
            shortage = shortage + current_surplus(day);
        else
            if day_count >=1 
                load_shortages2 = [load_shortages2, shortage];
                shortage_days2 = [shortage_days2, day_count];
                current_day2 = [current_day2, day];
                day_count = 0;   
                shortage = 0;
            end
        end
    end

    % Lines 82 to 93 format the data generated in the above two for loops into
    % one usable matrix. 
    a = [current_day,current_day2; shortage_days,shortage_days2; load_shortages,load_shortages2];
    daycheck = sum(shortage_days) + posday;

    Total_Shortage = transpose(a);

    number_of_dataset = size(Total_Shortage);
    R1 = number_of_dataset(1) - 1;

    Shortage_Profile = abs(Total_Shortage(:,3));

    Total_Shortage = sortrows(Total_Shortage);
    Total_Shortage = [Total_Shortage; 0, 0, 0; 0, 0, 0; 0, 0, 0];

    Storage_Bank = Total_Shortage(:,3); 
    % Storing the existing power profiles just in case the individual profiles
    % are greater than the macro profiles 

    % The following while loop runs through the matrix Total_Shortage and
    % changes it to contain 'macro' periods of generation and shortage. Please
    % read the report for more information 
    while R < R1-3
        if Total_Shortage(R,3) < 0
            if Total_Shortage(R+1,3) < abs(Total_Shortage(R,3))
                Macro_Shortage = sum(Total_Shortage(R:R+2,3));
                Macro_Day = sum(Total_Shortage(R:R+2,2));
                Total_Shortage(R,1) = Total_Shortage(R,3);
                Total_Shortage(R,2) = Macro_Day;
                Total_Shortage(R,3) = Macro_Shortage;
                R1 = R1-2;
                Total_Shortage = [Total_Shortage(1:R,:);Total_Shortage(R+3:R1,:)];
            else 
                R = R+2;    %tick over to next macro period 
            end
        else
            R = R+1;        %Tick over to the next value, for negative
        end
    end
    
    if counter == 1
        Profile_1 = Total_Shortage(:,3);
    elseif counter == 2
        Profile_2 = Total_Shortage(:,3);
    elseif counter == 3
        Profile_3 = Total_Shortage(:,3);
    elseif counter == 4
        Profile_4 = Total_Shortage(:,3);
    elseif counter == 5
        Profile_5 = Total_Shortage(:,3);
    elseif counter == 6
        Profile_6 = Total_Shortage(:,3);
    elseif counter == 7
        Profile_7 = Total_Shortage(:,3);
    elseif counter == 8
        Profile_8 = Total_Shortage(:,3);
    elseif counter == 9
        Profile_9 = Total_Shortage(:,3);
    elseif counter == 10
        Profile_10 = Total_Shortage(:,3);
    else
        Profile_11 = Total_Shortage(:,3);
    end
    
   
    plot(Total_Shortage(:,3))
    hold on
    
    Lmax = [Lmax, abs(min(Total_Shortage(:,3)))];
    Total_Shortage = [Total_Shortage; 666, 666, 666];
    All_Storage = [All_Storage; Total_Shortage];
    
    
end
