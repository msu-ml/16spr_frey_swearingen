point_types = {'rd', 'y^', 'gs', 'bo', 'kv'};
figure
hold on
for i = 1:5
    scatter(all_data(yy_idx == i, 1), all_data(yy_idx == i, 2),...
        point_types{i}, 'filled');
end
hold off

figure
hold on
for i = 1:5
    scatter(all_data(km_idx == i, 1), all_data(km_idx == i, 2),...
        point_types{i}, 'filled');
end
hold off