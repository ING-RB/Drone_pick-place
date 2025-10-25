function indices = computeEmptyCellIndices(arrds)
%

%   Copyright 2020 The MathWorks, Inc.

    % Account for the possibility that the concatenation dimension
    % is higher than the number of dimensions in the input array.
    numIndices = max([ndims(arrds.Data) arrds.ConcatenationDimension]);
    indices = repmat({1}, 1, numIndices);
    indices{arrds.ConcatenationDimension} = 0;
end
