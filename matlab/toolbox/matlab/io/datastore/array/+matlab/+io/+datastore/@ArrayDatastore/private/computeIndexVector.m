function indexVector = computeIndexVector(arrds)
%

%   Copyright 2022 The MathWorks, Inc.

    % Account for the possibility that the iteration dimension
    % is higher than the number of dimensions in the input array.
    numIndices = max([ndims(arrds.Data) arrds.IterationDimension]);
    indexVector = repmat({':'}, 1, numIndices);
end