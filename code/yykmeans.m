function [ assignments ] = yykmeans( data, k )
%YYKMEANS implements Yinyang kmeans as described in Y. Ding, Y. Zhao, 
% X. Shen, M. Musuvathi, and T. Mytkowicz. Yinyang k-means: A drop-in
% replacement of the classic k-means with consistent speedup.

t = k / 10;

% Get k random initial centers
centers = datasample(data, k, 'Replace', true);
idx = kmeans(centers, t, 'MaxIter', 5);


end