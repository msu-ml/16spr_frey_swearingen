clear
maxiter = 1000;
files = dir('Data*.mat');
for i = 1:size(files)
    name = files(i).name;
    load(name);
    c_locations = strfind(name, 'c');
    k = str2num(name(6:c_locations(1) - 1));
    [yy_idx, yy_locations, yy_numiter, yy_timer] = yykmeans(alldata, k, k/10, maxiter);
    [km_idx, km_numiter, km_locations, ~, km_timer ] = simple_kmeans(alldata, k, maxiter, alldata(1:k, :));
    save(strcat('results_', name, '.mat'), 'yy_idx', 'yy_numiter', 'yy_timer', yy_locations,...
        'km_idx', 'km_numiter', 'km_timer, km_locations');
end