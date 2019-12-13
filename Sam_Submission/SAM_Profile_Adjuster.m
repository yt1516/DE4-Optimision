function [Shortage_Matrix, tick] = SAM_Profile_Adjuster(Profile, ratio, tick, Shortage_Matrix)
Adjusted = [];
Shortage_List = [];
Shortage_Moment = [];

% The for loop below adjusts the profiles to the diferent ratios to work
% out the amount of power that would need to be purchased from the grid
% annually, in order to optimise.
for count = 1:20
    size_check = size(Profile);
    if size_check(1) > 2
        Adjusted = [Adjusted, Profile + ratio(count,tick)];
    else
        Adjusted = 0;
    end
end 
tick = tick + 1;

for count = 1:20
    size_check = size(Adjusted);
    if size_check(1) > 1
        for length = 1:size_check(1)
            if Adjusted(length,count) < 0 
                Shortage_Moment = [Shortage_Moment, abs(Adjusted(length,count))];
            end
            if length == size_check(1)
                Shortage_List = [Shortage_List, sum(Shortage_Moment)];
            end 
        end
    else
        Shortage_List =  1.0e+10*ones(1,20);
    end
end
Shortage_Matrix = [Shortage_Matrix; Shortage_List];
end