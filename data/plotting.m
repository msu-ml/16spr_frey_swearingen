point_types = {'rd', 'y^', 'gs', 'bo', 'kv'};
figure
subplot(1, 2, 1);
hold on
for i = 1:5
    scatter(all_data(yy_idx == i, 1), all_data(yy_idx == i, 2),...
        point_types{i});
end
scatter(yy_locs(:, 1), yy_locs(:, 2), 'ms', 'filled');
title('Yinyang K-means');
set(gca, 'xtick', []);
set(gca, 'ytick', []);
axis square
hold off

subplot(1, 2, 2);
hold on
for i = 1:5
    scatter(all_data(km_idx == i, 1), all_data(km_idx == i, 2),...
        point_types{i});
end
scatter(km_locs(:, 1), km_locs(:, 2), 'ms', 'filled');
title('Classic K-means');
set(gca, 'xtick', []);
set(gca, 'ytick', []);
axis square
hold off