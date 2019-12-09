clear all
tic
fval_store=[];
for i=1:1:10
    [names,turb_numbs,t_cost,P_out,coord_out,models,fval]=Subsystem_Optimisation(3,3);
    fval_store(end+1)=fval;
end
toc