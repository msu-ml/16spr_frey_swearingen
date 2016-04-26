files = dir('Data*.mat');
for i = 1:size(files)
    all_data = [];
    load(files(i).name);
    for dat = data
        all_data = [all_data; cell2mat(dat)];
    end
    [yy_idx, yy_locs] = yykmeans(all_data, NumClusters, NumClusters, 1000);
    [km_idx, ~, km_locs] = simple_kmeans(all_data, NumClusters, 1000, all_data(1:NumClusters, :));
    plotting
end