function data = indexSlices(data, indices)
%indexSlices Helper function for performing indexing only in the first
%dimension.

% Copyright 2016-2019 The MathWorks, Inc.

[hasComplexFields, complexFields] = matlab.io.datastore.internal.getComplexityInfo(data);
sz = size(data);

% Special case for 2D and 3D to keep them fast
if numel(sz) == 2
    data = data(indices, :);
elseif numel(sz) == 3
    data = data(indices, :, :);
else
    % For high dimensional arrays build the indexing expression
    % programmatically (avoid reshape since it isn't implemented uniformly
    % for all underlying types).
    subs = [{indices}, repmat({':'}, 1, numel(sz)-1)];
    data = subsref(data, substruct('()', subs));
end

if hasComplexFields
    data = matlab.io.datastore.internal.applyComplexityInfo(data, complexFields);
end
end
