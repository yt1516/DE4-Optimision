function vel = calculate_velocity(j,location,counter,rotor_radius,z)
global wind_farm;
count = counter;
alpha = 0.5/(log10(z/0.3));
a = 0.326795;
velr1 = 0;
for lo = 1:1:count-1
    for ii=1:1:counter-1 % Loop for checking turbine 1 by 1, see if in multiple wakes
        for jj = ii+1 : 1 : counter
            y1 = location(ii); % previous in wake
            y2 = location(jj); % current in wake
            ydistance = abs(wind_farm(y1,2) - wind_farm(y2,2));
            radius = rotor_radius + (alpha * ydistance);
            xmin = wind_farm(y1,1) - radius;
            xmax = wind_farm(y1,1) + radius;
            if (xmin < wind_farm(y2,1)) && (xmax > wind_farm(y2,1))
                % Eliminate turbine at ii, in the wake
                
                location(ii) = [];
                
                counter = counter - 1;
                
                break;
            end
        end
    end
end
for ii=1:1:counter
    y1 = location(ii);
    ydistance = wind_farm(j,2) - wind_farm(y1,2);
    denominator = ((alpha * ydistance / rotor_radius) + 1) ^ 2;
    velr = (1 - (2 * a / denominator));
    velr1 = velr1 + ((1 - velr)^2); % wind velocity after multiple wakes.
end
vel = 1 - (velr1 ^ 0.5);