close all; clear; clc;

ClusterSizes = [2, 3, 4, 5];
FeatureSizes = [2];
SampleSizes = [100];

for NumClusters = ClusterSizes
    for NumSamples = SampleSizes
        for NumFeatures = FeatureSizes
            AvgClusterDistance = NumClusters * 100;
            
            clustermeans = GenerateMeans(NumClusters, NumFeatures, AvgClusterDistance, AvgClusterDistance, 10000);
            
            
            for cluster = 1:NumClusters
                clustercov{cluster} = 0.45*rand(NumFeatures);
                clustercov{cluster} = clustercov{cluster}' * clustercov{cluster}; %make psd

                data{cluster} = mvnrnd(clustermeans(cluster,:)', clustercov{cluster}, NumSamples);
            end
            
            fname = sprintf('Data_%gclusters_%gsamples_%gfeatures.mat', NumClusters, NumSamples, NumFeatures);
            save(fname,'data', 'clustercov', 'clustermeans', 'NumClusters', 'NumSamples', 'NumFeatures');
        end
    end
end

clear;

files = dir('Data*.mat');

for i = 1:length(files)
    load(files(i).name);
    
    Data = [];
    Colors = [];
    
    for j = 1:NumClusters
        Data = [ Data; data{j} ];
        
        switch j
            case 1
                colortemp = repmat([1 0 0],length(data{j}),1);
            case 2
                colortemp = repmat([0 1 0],length(data{j}),1);
            case 3
                colortemp = repmat([0 0 1],length(data{j}),1);
            case 4
                colortemp = repmat([0 1 1],length(data{j}),1);
            case 5
                colortemp = repmat([1 0 1],length(data{j}),1);
            otherwise
                error('Unknown color (%g)', j);
        end
        
        Colors = [Colors; colortemp];
    end
    
    scatter(Data(:,1), Data(:,2), 36, Colors, 'filled');
end