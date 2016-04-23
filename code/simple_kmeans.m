function [ new_assignments, numiter, timer ] = simple_kmeans( data, k, maxiter )
%SIMPLE_KMEANS does the classic kmeans with no fancy tricks or
%  optimizations.

n = size(data, 1);
old_centers = data(1:k, :);
old_assignments = zeros(n, 1);
%old_centers = datasample(data, k, 'Replace', false);
timer = [];
tic
distances = pdist2(data, old_centers);
[~, new_assignments] = min(distances, [], 2);

new_centers = zeros(size(old_centers));
for i = 1:k
    new_centers(i, :) = 1/sum(new_assignments == i) .* sum(data(new_assignments == i, :));
end
timer = [timer; toc];
numiter = 1;
while sum(new_assignments == old_assignments) < n && numiter <= maxiter
    tic
    old_assignments = new_assignments;
    old_centers = new_centers;
    distances = pdist2(data, old_centers);
    [~, new_assignments] = min(distances, [], 2);
    
    for i = 1:k
        new_centers(i, :) = 1/sum(new_assignments == i) .* sum(data(new_assignments == i, :));
    end
    numiter = numiter + 1;
    timer = [timer; toc];
end