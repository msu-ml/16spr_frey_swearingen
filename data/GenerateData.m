close all; clear; clc;

ClusterSizes = [1e2 1e3 1e4];
FeatureSizes = [1e2 5e2 1e3];
SampleSizes = [1e2 5e2 1e3];
AvgClusterDistances = [1e2 5e2 1e3];
MaxIter = 100000;

for NumClusters = ClusterSizes
    for NumSamples = SampleSizes
        for NumFeatures = FeatureSizes
        	for AvgClusterDistance = AvgClusterDistances
				fprintf('Generating Data with NumCluster=%g, NumSamples=%g, NumFeatures=%g, and AvgClusterDistance = %g\n', NumClusters, NumSamples, NumFeatures, AvgClusterDistance);
			
				clustermeans = GenerateMeans(NumClusters, NumFeatures, AvgClusterDistance, AvgClusterDistance, MaxIter);
			
			
				for cluster = 1:NumClusters
					clustercov{cluster} = 0.45*rand(NumFeatures);
					clustercov{cluster} = clustercov{cluster}' * clustercov{cluster}; %make psd

					data{cluster} = mvnrnd(clustermeans(cluster,:)', clustercov{cluster}, NumSamples);
				end
			
				fname = sprintf('Data_%gclusters_%gsamples_%gfeatures_%gclustdist.mat', NumClusters, NumSamples, NumFeatures, AvgClusterDistance);
				save(fname,'data', 'clustercov', 'clustermeans', 'NumClusters', 'NumSamples', 'NumFeatures', '-v7.3');
            end
        end
    end
end