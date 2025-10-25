function indices = computeSubsrefIndices(arrds, blockIndex)
%

%   Copyright 2020-2022 The MathWorks, Inc.

    indices = arrds.IndexVector;
    indices{arrds.IterationDimension} = blockIndex;
end
