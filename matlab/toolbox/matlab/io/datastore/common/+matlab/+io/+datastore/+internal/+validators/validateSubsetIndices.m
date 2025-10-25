function indices = validateSubsetIndices(indices, maxSize, callingFcnName, needsUniqueIndices)
%VALIDATESUBSETINDICES Validate the indices provided for subset method.
%   This is a helper function that validates the indices provided to
%   the subset method. Indices
%      - must be a logical or a numerical vector.
%      - must be of size less than or equal to maxSize, if numerical.
%      - must be of size equal to maxSize, if logical.
%
%   See also matlab.io.datastore.ImageDatastore/subset,
%            matlab.io.datastore.DsFileSet/subset

%   Copyright 2018-2022 The MathWorks, Inc.

arguments
    indices
    maxSize (1, 1) double
    callingFcnName (1, 1) string
    needsUniqueIndices (1, 1) logical = true
end

% Allow 0x0 empty too.
is0x0Empty = @(x) ndims(x) == 2 && size(x, 1) == 0 && size(x, 2) == 0;
if isnumeric(indices) && is0x0Empty(indices)
    indices = reshape(indices, [], 1);
end

if maxSize > 0
    if islogical(indices)
        classes = {'logical'};
        attrs = {'vector', 'numel', maxSize};
        validateattributes(indices, classes, attrs, ...
            callingFcnName + ":subset", 'indices');
        indices = find(indices);
        return;
    end
    classes = {'numeric'};
    attrs = {'vector', 'positive', 'integer', '<=', maxSize};
    validateattributes(indices, classes, attrs, ...
        callingFcnName + ":subset", 'indices');

    % check that only unique indices are supplied
    if needsUniqueIndices
        uniqIdx = unique(indices);
        if numel(uniqIdx) ~= numel(indices)
           error(message('MATLAB:datastoreio:splittabledatastore:uniqueIndices'));
        end
    end
else
    if any(indices >= 0)
        error(message('MATLAB:datastoreio:splittabledatastore:zeroSubset', ...
            callingFcnName));
    else
        return;
    end
end
