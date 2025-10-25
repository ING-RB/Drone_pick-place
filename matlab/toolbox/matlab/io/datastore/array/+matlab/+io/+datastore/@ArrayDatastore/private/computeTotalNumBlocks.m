function totalNumBlocks = computeTotalNumBlocks(arrds)
%

%   Copyright 2022 The MathWorks, Inc.

    % Account for the possibility that the IterationDimension is greater than
    % the number of dimensions in the input datatype.
    sz = size(arrds.Data);

    if numel(sz) < arrds.IterationDimension
        totalNumBlocks = 1;
    else
        totalNumBlocks = sz(arrds.IterationDimension);
    end
end