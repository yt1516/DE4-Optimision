function e = circle(x,y,r)
grid on
th = 0:pi/50:2*pi;
xunit = r * cos(th) + x;
yunit = r * sin(th) + y;
hold on
e = plot(xunit, yunit,'k','LineWidth',1);
hold off
end