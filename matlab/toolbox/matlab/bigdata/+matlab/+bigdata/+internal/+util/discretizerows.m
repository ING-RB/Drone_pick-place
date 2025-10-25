function keys = discretizerows(keys, boundaries, sortFcn)
% A version of discretize for use with partitioning data based on partition
% boundaries.
%
% This has three important differences from discretize:
%  1. Logic will be applied per row. A row vector input will be treated as
%     a single entry.
%  2. This supports all data types supported by sortrows. This include
%     tables, as well as N-D arrays of a given type types.
%  3. All data outside the range of boundaries will be included. Keys will
%     have value:
%      * 0 for data before the first boundary.
%      * n for data that exists after the nth boundary.

%   Copyright 2018 The MathWorks, Inc.

if nargin < 3 && isnumeric(keys) && iscolumn(keys)
    keys = discretize(keys, [-inf; boundaries; inf]);
else
    if nargin < 3
        sortFcn = @matlab.bigdata.internal.util.quickSortrows;
    end
    % This works by using sort to shuffle the boundaries into the keys,
    % keeping track of where they end up.
    numKeys = size(keys, 1);
    numBoundaries = size(boundaries, 1);
    [~, sourceIndices] = sortFcn([boundaries; keys]);
    
    % Anything <= numBoundary came from the boundaries instead of the data.
    % These offsets are relative to the (non-captured) sorted output of
    % boundaries + keys.
    boundaryOffsets = find(sourceIndices <= numBoundaries);
    sortedKeys = discretize((1 : numKeys + size(boundaries, 1))', [-inf; boundaryOffsets; Inf]);
    % Now to use subsasgn to return to the original order. Note that, the
    % original order is [boundaries; keys]. We need to drop boundaries
    % because they weren't part of the data.
    keys = zeros(numBoundaries + numKeys, 1);
    keys(sourceIndices, :) = sortedKeys;
    keys(1:numBoundaries, :) = [];
end
% Need to subtract 1 from the keys because discretizerows includes all
% values prior to the first boundary as it's own group.
keys = keys - 1;
