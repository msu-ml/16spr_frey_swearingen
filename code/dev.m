% script to develop yykmeans function
%clear

% Suppress kmeans' 'failed to converge' warning
warning('off', 'stats:kmeans:FailedToConverge');

%load('all_data.mat')
k = 5;
epsilon = 0.01;
%t = k / 10;
t = 2;
% Array used to track cluster membership for set operations
point_labels = 1:size(all_data, 1);

% Get k random initial centers
%old_centers = datasample(all_data, k, 'Replace', false);

% For replication, use first k data points as initial centers
old_centers = all_data(1:k, :);

% Step 1: group initial centers into t groups
[group_idx, group_locations] = kmeans(old_centers, t, 'MaxIter', 5);

% Step 2 part 1: run one iteration of k-means.
[old_assignments, old_locations, ~, old_distances] = kmeans(all_data, k,...
    'MaxIter', 1);

% Step 2 part 2: run one more so we have new and old assignments and
% locations.
[new_assignments, new_locations, ~, new_distances] = kmeans(all_data, k,...
    'MaxIter', 1, 'Start', old_locations);
distances_to_all = dist(all_data, group_locations');

% Step 2 part 3: calculate initial upper bounds
ub = min(distances_to_all, [], 2);

% Step 2 part 4: find lower bounds for all points.
lb = repmat(realmax, size(all_data, 1), 1);
for i = 1:size(all_data, 1)
    this_centroid_group = group_idx(new_assignments(i));
    % Find where the next-closest group center is.
    lb(i) = min(distances_to_all(i, [1:this_centroid_group-1 ...
        this_centroid_group+1:end]));
end

% Count number of points in each cluster
old_clusters = cell(k, 1);
for i = 1:k
    [old_clusters{i, 1}, ~] = find(old_assignments == i);
end

new_clusters = cell(k, 1);
for i = 1:k
    [new_clusters{i, 1}, ~] = find(new_assignments == i);
end

numiter = 1;
while max(max(abs(new_locations - old_locations), [], 2)) > epsilon
    % Step 3.1 part 1: update centers
    center_drifts = zeros(k, 1);
    for i = 1:k
        % find OV, the intersection between new and old clusters; V - OV,
        % the points only in the old cluster, and V' - OV, the points only
        % in the new cluster
        OV = intersect(old_clusters{i}, new_clusters{i});
        old_only = setdiff(old_clusters{i}, OV);
        new_only = setdiff(OV, old_clusters{i});
        new_locations(i, :) = (old_locations(i, :) * numel(old_clusters{i})...
            - sum(all_data(old_only, :)) + sum(all_data(new_only, :))) / ...
            numel(new_clusters{i});
        center_drifts(i) = norm(new_locations(i) - old_locations(i));
    end
    
    % Step 3.1 part 2: update group centers and find largest centroid drift
    % per group
    group_drifts = zeros(t, 1);
    for i = 1:t
        this_group_members = find(group_idx == i);
        %new_group_locations(i, :) = mean(new_locations(this_group_members, :), 1);
        difference_vecs = new_locations(this_group_members, :) - ...
            old_locations(this_group_members, :);
        group_drifts(i) = max(sqrt(sum(difference_vecs.^2, 2)));
    end
    
    % Step 3.2: update bounds
    ub = ub + center_drifts(new_assignments);
    lb = lb - group_drifts(group_idx(new_assignments));
    
    temp_global_lb = min(lb);
    numiter = numiter + 1;
    if numiter > 1000
        break
    end
end