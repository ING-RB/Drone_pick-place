function [dsIndex, granularFileIndex] = getDSIndexAndGranularFileIndex(numFilesPerDS, partitionIndex)
% Find the underlying datastore index and the corresponding
% granularFileIndex from files list per underlying datastore for an input
% partitionIndex/ fileIndex.

%   Copyright 2022 The MathWorks, Inc.

dsIndex = 1;
currentFileIndex = 0;
while(true)
    currentFileIndex = currentFileIndex + numFilesPerDS(dsIndex);
    if partitionIndex > currentFileIndex
        dsIndex = dsIndex + 1;
    else
        fileIndexTillPreviousDS = currentFileIndex - numFilesPerDS(dsIndex);
        granularFileIndex = partitionIndex - fileIndexTillPreviousDS;
        break;
    end
end