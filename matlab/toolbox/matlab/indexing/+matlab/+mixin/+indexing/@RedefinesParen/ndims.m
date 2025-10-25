%NDIMS  Number of dimensions
%   NDIMS(obj) returns numel(size(obj)).

%   Copyright 2020-2021 The MathWorks, Inc.

function N = ndims(obj)
    N = numel(size(obj));
end
