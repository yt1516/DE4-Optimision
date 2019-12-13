function UB = UpperBound(N,x,y)
UB = zeros(1,N); 
idxx = 1:2:N;
idxy = 2:2:N;
for i=1:1:length(idxx)
    UB(idxx(i)) = x; 
    UB(idxy(i)) = y; 
end