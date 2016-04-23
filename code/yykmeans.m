function [ assignments, numiter ] = yykmeans( data, k, maxiter )
%YYKMEANS implements Yinyang kmeans as described in Y. Ding, Y. Zhao, 
% X. Shen, M. Musuvathi, and T. Mytkowicz. Yinyang k-means: A drop-in
% replacement of the classic k-means with consistent speedup.

% Suppress kmeans' 'failed to converge' warning
warning('off', 'stats:kmeans:FailedToConverge');

%t = k / 10;
t = 2;
n = size(data, 1);

% For replication, use first k data points as initial centers
old_centers = data(1:k, :);
%old_centers = datasample(data, k, 'Replace', false);

% Step 1: group initial centers into t groups
[group_idx, ~] = kmeans(old_centers, t, 'MaxIter', 5);

% Step 2 part 1: run one iteration of k-means.
[old_assignments, old_locations] = kmeans(data, k,...
    'MaxIter', 1, 'Start', old_centers);

% Step 2 part 2: run one more so we have new and old assignments and
% locations.
[new_assignments, new_locations, ~, distances_to_centroids] = kmeans(data, k,...
    'MaxIter', 1, 'Start', old_locations, 'EmptyAction', 'error');

% Step 2 part 3: calculate initial upper bounds
ub = min(distances_to_centroids, [], 2);

% Step 2 part 4: find lower bounds for all points.
lb = zeros(n, t);
for i = 1:n
    this_cluster = new_assignments(i);
    this_centroid_group = group_idx(this_cluster);
    % Find the closest center in each group to this point (not counting the
    % center the point is assigned to).
    for j = 1:t
        if this_centroid_group == j
            lb(i, j) = min(distances_to_centroids(i, [1:this_cluster-1 ...
                this_cluster+1:end]));
        else
            lb(i, j) = ub(i);
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

numiter = 0;
while sum(new_assignments == old_assignments) < n && numiter <= maxiter
    old_assignments = new_assignments;
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
            - sum(data(old_only, :)) + sum(data(new_only, :))) / ...
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
    %points_through_group_filter(~any(points_through_group_filter, 2), :) = [];
    
    % Step 3.3 part 1: filter remaining candidate centers with the
    % second-closest center found so far.
    centers_through_local_filter = zeros(k, 1);
    points_through_local_filter = zeros(n, 1);
    center_num = 1;
    for i = 1:size(points_blocked_by_group_filter, 1)
        % Don't do anything for points that weren't caught by the group
        % filter
        if points_through_group_filter(i) == 0
            this_centroid = new_assignments(i);
            % Don't count the point's current assignment when looking for the
            % second-closest center.
            [sorted_distances, idx] = sort(distances_to_centroids(i, ...
                [1:this_centroid-1 this_centroid+1:end]));
            for j = 1:t
                if points_blocked_by_group_filter(i, j) ~= 0
                    if sorted_distances(2) >= lb(i, points_blocked_by_group_filter(i, j)) -...
                            center_drifts(old_assignments(i));
                        centers_through_local_filter(center_num) = idx(2);
                        center_num = center_num + 1;
                        points_through_local_filter(i) = i;
                    end
                end
            end
        end
    end
    
    % Remove duplicate center indices.
    centers_through_local_filter = unique(centers_through_local_filter);
    
    % Remove zeros from points_through_local_filter
    points_through_local_filter(~any(points_through_local_filter, 2), :) = [];
    
    % Find new b(x) for any point that failed the local filter check above
    local_filter_distances = dist(data(points_through_local_filter, :),...
        new_locations(centers_through_local_filter, :)');
    [new_shortest_distances, idx] = min(local_filter_distances, [], 2);
    ub(idx) = new_shortest_distances;
    new_assignments(points_through_local_filter) = idx;
    
    numiter = numiter + 1;
end
assignments = new_assignments;
end