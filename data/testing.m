clear
maxiter = 1000;
files = dir('Data*.mat');
yy_iterations = [];
yy_times_means = [];
km_iterations = [];
km_times_means = [];
for file = files
    name = file.name;
    load(name);
    c_locations = strfind(name, 'c');
    k = str2num(name(6:c_locations(1) - 1));
    [yy_idx, yy_numiter, yy_timer] = yykmeans(alldata, k, k/10, maxiter);
    [km_idx, km_numiter, ~, ~, km_timer ] = simple_kmeans(alldata, k, maxiter, alldata(1:k, :));
    yy_iterations = [yy_iterations; yy_numiter];
    yy_times_means = [yy_times_means; mean(yy_timer)];
    km_iterations = [km_iterations; km_numiter];
    km_times_means = [km_times_means; mean(km_timer)];
end

