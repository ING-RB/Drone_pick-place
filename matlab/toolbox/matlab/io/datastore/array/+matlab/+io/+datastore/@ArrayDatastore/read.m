function [data, info] = read(arrds)
%READ   Return the next block of data from the ArrayDatastore.
%
%   DATA = READ(ARRDS) reads the next block of data from the ArrayDatastore.
%
%       DATA will be a cell array if "OutputType" is set to "cell".
%
%       DATA will have one row, unless "ReadSize" has been set to a value greater than 1.
%
%   [DATA, INFO] = READ(ARRDS) also returns a struct containing additional information
%   about DATA. The fields of INFO are:
%       - BlockIndex - Indices of the blocks read.
%
%   See also: arrayDatastore, matlab.io.datastore.ArrayDatastore/hasdata

%   Copyright 2020-2022 The MathWorks, Inc.

    if ~arrds.hasdata()
        msgid = "MATLAB:io:datastore:array:read:NoMoreData";
        error(message(msgid));
    end

    % Compute the range of block indices for the next read.
    startBlockIndex = arrds.NumBlocksRead + 1;

    % Account for the possibility that the last read doesn't have all ReadSize blocks.
    endBlockIndex = min(arrds.NumBlocksRead + arrds.ReadSize, arrds.TotalNumBlocks);

    if arrds.OutputType == "same" && arrds.ConcatenationDimension == arrds.IterationDimension
        % Use range-based indexing to get all the data in one indexing
        % expression.
        data = arrds.readAtIndex(startBlockIndex:endBlockIndex);

    else
        data = cell(endBlockIndex-startBlockIndex+1, 1);

        if arrds.OutputType == "same"
            for blockIndex = startBlockIndex:endBlockIndex
                % Get the data for this next block.
                data{blockIndex-startBlockIndex+1} = arrds.readAtIndex(blockIndex);
            end
        else
            for blockIndex = startBlockIndex:endBlockIndex
                % Get the data for this next block.
                data{blockIndex-startBlockIndex+1} = {arrds.readAtIndex(blockIndex)};
            end
        end
        data = cat(arrds.ConcatenationDimension, data{:});
    end

    if nargout > 1
        % Only populate info struct when necessary.
        info = struct("BlockIndex", num2cell(startBlockIndex:endBlockIndex));
    end

    % Increment NumBlocksRead *after* the indexing operations, to ensure
    % consistent behavior on read failure.
    arrds.NumBlocksRead = endBlockIndex;
end
