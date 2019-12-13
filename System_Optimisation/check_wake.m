function f = check_wake(x,y,j,rotor_radius,z) % row i x=column 1, y=column 2.
global wind_farm;
u0 = 3.737; % average wind speed
alpha = 0.5/(log(z/0.3)); % entrainment constant, how fast/slow wake expands

chk = 0; % chk = 0 No wake------ chk = 1 Wake
counter = 0;

for i = 1:1:j-1
    ydistance = abs(y - wind_farm(i,2)); % check distance from previous
    
    radius = rotor_radius + (alpha * ydistance);
    xmin = wind_farm(i,1) - radius;
    xmax = wind_farm(i,1) + radius;
    
    if (xmin < x) && (x < xmax) % Checking for wake by radius
        % Turbine in wake
        chk = 1;
        counter = counter + 1;
        location(counter) = i;
        
    else
        % Turbine outside of wake
        chk = 0;
    end
end % returns 

if chk == 0 % if outside of wake, wind velocity unchange
    f = u0;
else
    % Call calculate velocity
    velocity = calculate_velocity(j,location,counter,rotor_radius,z);
    f = velocity * u0;
end

