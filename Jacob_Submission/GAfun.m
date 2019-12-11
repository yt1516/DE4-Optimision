function state = GAfun(~, state, ~)
[~,loc] = min(state.Score);
coord_out = state.Population(loc,:);
x_coord=[];
y_coord=[];
N = length(coord_out);
for i=1:1:N/2
    n = (2 * i) - 1;
    x_coord(end+1)=coord_out(n);
    y_coord(end+1)=coord_out(n+1);
end
x_coord = x_coord*1000;
y_coord = y_coord*1000;
clf;
for i = 1:1:N/2
    scatter(x_coord(i),y_coord(i),'filled');
    grid on;
    hold on;
end
end