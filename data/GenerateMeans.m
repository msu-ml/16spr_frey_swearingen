function [ means ] = GenerateMeans( N, D, AvgEucDistance, tol, NumIter )
%GENERATEMEANS Generate a set of mean that are within the specified
%properties.
%   N = how many means to generate
%   D = dimension of each mean
%   AvgEucDistance = Avg allowed euclidean distnace between all means
%   tol = error tolerance for AvgEucDistance
%   NumIter = number of iterations before quiting
%
%   means = N x D matrix with means with the desired properties

    WholeSampleSize = N * 1000;
    
    WholeSet = randn(WholeSampleSize, D);
    
    for i = 1:NumIter
        Subset = datasample(WholeSet, N, 'Replace', false);
        
        if(abs(mean(pdist(Subset)) - AvgEucDistance) <= tol)
            means = Subset;
            return;
        end
    end
    
    error('No Means with speicified properties found.');
end

