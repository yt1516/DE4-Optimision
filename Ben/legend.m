for i = 1:7, X{i} = rand(10-i, 10)*2^i; end
 
 
figure

clear h



hi = bar(X{1}, 'FaceColor', [0, 0.4470, 0.7410])
h(1) = hi(1)
hold on
hi = bar(X{2}, 'FaceColor', [0.6350, 0.0780, 0.1840])
h(2) = hi(2)
hi = bar(X{3}, 'FaceColor', [0.8500, 0.3250, 0.0980])
h(3) = hi(3)
hi = bar(X{4}, 'FaceColor', [0.9290, 0.6940, 0.1250])
h(4) = hi(4)
hi = bar(X{5}, 'FaceColor', [0.4940, 0.1840, 0.5560])
h(5) = hi(5)
hi = bar(X{6}, 'FaceColor', [0.3010, 0.7450, 0.9330])
h(6) = hi(6)
hi = bar(X{7}, 'FaceColor',  [0.4660, 0.6740, 0.1880])
h(7) = hi(7)


lgd = legend(h, {'Grid (Import)' 'Grid (Export)' 'WTG' 'BESS (Discharge)' 'BESS (Charge)' 'Load' 'Power loss'})


lgd.FontSize = 20;