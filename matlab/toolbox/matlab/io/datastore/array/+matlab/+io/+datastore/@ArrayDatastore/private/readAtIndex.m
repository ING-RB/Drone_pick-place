function blockData = readAtIndex(arrds, index)
%readAtIndex   A helper function that reads a block located at a specified
%   index in the ArrayDatastore.
%   Handles OutputType by wrapping the result in a cell, but does not handle
%   ReadSize since this is a block-level function.

%   Copyright 2020 The MathWorks, Inc.

    % Compute the indexing expression for the next block.
    subsrefIndices = arrds.computeSubsrefIndices(index);

    % Get the block's data out of the original array.
    blockData = arrds.Data(subsrefIndices{:});
end
