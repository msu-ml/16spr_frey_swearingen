clear
maxiter = 1000;
files = dir('Data*.mat');
for file = files
    name = file.name;
    load(name);
    c_locations = strfind(name, 'c');
    k = str2num(name(6:c_locations(1) - 1));
    [yy_idx, yy_numiter, yy_timer] = yykmeans(alldata, k, k/10, maxiter);
    [km_idx, km_numiter, ~, ~, km_timer ] = simple_kmeans(alldata, k, maxiter, alldata(1:k, :));
    save(strcat('results_', name, '.mat'), 'yy_idx', 'yy_numiter', 'yy_timer',...
        'km_idx', 'km_numiter', 'km_timer');
end