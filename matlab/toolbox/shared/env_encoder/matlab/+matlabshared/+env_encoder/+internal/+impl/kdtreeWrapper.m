function [index, dist] = kdtreeWrapper(environment, bps)
% This function is for internal use only. It may be removed in the future.

% kdtreeWrapper create a kdtree object, find the nearest neighbor in 
% environment from bps points

%   Copyright 2023 The MathWorks, Inc.

%#codegen

tree = matlabshared.env_encoder.internal.Kdtree('double');
tree.index(environment);
[index, dist] = tree.knnSearch(bps, 1);

end
