function obj = Analyse_Grid(wf)
global wind_farm;
load('storage.mat');
N = sum(turb_numbs);
wind_farm = zeros(N,2); % Initialise wind_farm grid for [x1,y1;x2,y2...] format

wf = wf(1:end);
wf = wf * 1000; % location
wf = round(wf);

for a = 1:1:N        % slplit the list of x1, y1, x2, y2 into a Nx2 list of x1,x2,x3...xn; y1,y2,y3...ym
    b = (2 * a) - 1; 
    wind_farm(a,1) = wf(b);
    wind_farm(a,2) = wf(b + 1);
end

total_speed = 0;
wind_farm = sortrows(wind_farm,[2 1]);      % sort rows by y coordinate, assuming wind blowing towards +ve y-axis.

for j=1:1:length(turb_numbs)
    for i = 1:1:turb_numbs(j)
        x = wind_farm(i,1); 
        y = wind_farm(i,2);
        z = hh(j);
        velocity = check_wake(x,y,i,rr(j),z); % row i, return wind velocity 
                                            %affected by wake.
        total_speed = total_speed + velocity; % total power
    end
end
%obj = 100*((u0*N/2)-total_speed)/(u0*N/2);
%obj = abs(1-(total_speed/(u0*N/2)))*100;
obj = 1/total_speed;

