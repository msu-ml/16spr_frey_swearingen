% script to develop yykmeans function
clear

% Suppress kmeans' 'failed to converge' warning
warning('off', 'stats:kmeans:FailedToConverge');

load('all_data.mat')
%load('visualization.mat')
k = 100;
epsilon = 0.01;
t = k / 10;
%t = 2;
n = size(all_data, 1);
% Array used to track cluster membership for set operations
point_labels = 1:n;

% Get k random initial centers
%old_centers = datasample(all_data, k, 'Replace', false);

% For replication, use first k data points as initial centers
old_centers = all_data(1:k, :);

% Step 1: group initial centers into t groups
[group_idx, group_locations] = kmeans(old_centers, t, 'MaxIter', 5);

% Step 2 part 1: run one iteration of k-means.
[old_assignments, old_locations, ~, old_distances] = kmeans(all_data, k,...
    'MaxIter', 1, 'Start', old_centers);

% Step 2 part 2: run one more so we have new and old assignments and
% locations.
[new_assignments, new_locations, ~, local_filter_distances] = kmeans(all_data, k,...
    'MaxIter', 1, 'Start', old_locations);
distances_to_centroids = dist(all_data, new_locations');

% Step 2 part 3: calculate initial upper bounds
ub = min(distances_to_centroids, [], 2);

% Step 2 part 4: find lower bounds for all points.
lb = zeros(n, t);
for i = 1:n
    this_centroid_group = group_idx(new_assignments(i));
    this_cluster = new_assignments(i);
    % Find the closest center in each group to this point (not counting the
    % center the point is assigned to).
    for j = 1:t
        if this_centroid_group == j
            lb(i, j) = min(distances_to_centroids(i, [1:this_cluster-1 ...
                this_cluster+1:end]));
        else
            lb(i, j) = min(distances_to_centroids(i, :));
        end
    end
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

old_assignments = new_assignments;
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
    
    % Step 3.2 part 1: update bounds
    ub = ub + center_drifts(old_assignments);
    for i = 1:t
        lb(:, i) = lb(:, i) - group_drifts(i);
    end
    
    temp_global_lb = min(lb, [], 2);
    
    % Step 3.2 part 2: find points and groups that need to go to local
    % filtering.
    points_blocked_by_group_filter = zeros(n, t);
    points_through_group_filter = zeros(n, 1);
    for i = 1:n
        if temp_global_lb(i) >= ub(i)
            new_assignments(i) = old_assignments(i);
        else
            % Tighten bounds and re-check
            ub(i) = distances_to_centroids(i, old_assignments(i));
            if temp_global_lb(i) >= ub(i)
                new_assignments(i) = old_assignments(i);
            else
                % Still failed check, pass to local filtering
                for j = 1:t
                    if lb(i, j) < ub(i)
                        points_blocked_by_group_filter(i, j) = j;
                    else
                        points_through_group_filter(i) = i;
                    end
                end
            end
        end
    end
    
    % Remove zero rows from the arrays generated above
    points_blocked_by_group_filter(~any(points_blocked_by_group_filter, 2), :) = [];
    points_through_group_filter(~any(points_through_group_filter, 2), :) = [];
    
    % Step 3.3 part 1: filter remaining candidate centers with the
    % second-closest center found so far.
    centers_through_local_filter = zeros(k, 1);
    points_through_local_filter = zeros(n, 1);
    center_num = 1;
    for i = 1:size(points_blocked_by_group_filter, 1)
        this_centroid = new_assignments(i);
        % Don't count the point's current assignment when looking for the
        % second-closest center.
        [sorted_distances, idx] = sort(distances_to_centroids(i, ...
            [1:this_centroid-1 this_centroid+1:end]));
        if ~any(points_through_group_filter == i)
            for j = 1:t
                if sorted_distances(2) >= lb(i, points_blocked_by_group_filter(i, j)) -...
                        center_drifts(old_assignments(i));
                    centers_through_local_filter(center_num) = idx(2);
                    center_num = center_num + 1;
                    points_through_local_filter(i) = i;
                end
            end
        end
    end
    
    % Remove duplicate center indices.
    centers_through_local_filter = unique(centers_through_local_filter);
    
    % Remove zeros from points_through_local_filter
    points_through_local_filter(~any(points_through_local_filter, 2), :) = [];
    
    % Find new b(x) for any point that failed the local filter check above
    local_filter_distances = dist(all_data(points_through_local_filter(:, 1), :),...
        new_locations(centers_through_local_filter, :)');
    [new_shortest_distances, idx] = min(local_filter_distances, [], 2);
    ub(idx) = new_shortest_distances;
    
    old_assignments = new_assignments;
    numiter = numiter + 1;
end