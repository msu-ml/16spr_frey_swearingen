close all; clear; clc;

ClusterSizes = [1e2 1e3 1e4 1e5 1e6];
FeatureSizes = [1e2 1e3 1e4];
SampleSizes = [1e2 1e3 1e4 1e5];

for NumClusters = ClusterSizes
    for NumSamples = SampleSizes
        for NumFeatures = FeatureSizes
            AvgClusterDistance = NumFeatures * 1000;
            
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