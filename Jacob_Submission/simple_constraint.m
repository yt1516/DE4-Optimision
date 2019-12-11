function [c, ceq] = simple_constraint(x)
load('storage.mat');
%d= 2*max(rr)/1000;
c = [];
idx = 1;
   for i = 1:1:N/2
       for j = idx:1:N/2-1
           c(end+1,:)=0.3-sqrt((x(2*j+2)-x(2*i))^2+(x(2*j+1)-x(2*i-1))^2); %0.3 default
       end
       idx = idx + 1;
   end
   ceq = [];