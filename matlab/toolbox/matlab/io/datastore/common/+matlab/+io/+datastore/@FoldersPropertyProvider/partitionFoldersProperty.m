function partitionFoldersProperty(ds, partitionStrategy, partitionIndex)
%partitionFoldersProperty   a helper method that slices the folders
%   property using the new indices provided in the partitionStrategy
%   and partitionIndex.
%
%   If partitionStrategy is numeric and equal to partitionIndex,
%   with a value of 1 then a trivial partition is assumed. In this case the
%   Folders property is not recalculated, it is just copied.

%   Copyright 2019 The MathWorks, Inc.

    % Figure out if a numeric partitioning strategy is being used.
    isNumericPartitionStrategy = isnumeric(partitionStrategy) ... 
                              && isnumeric(partitionIndex);

    % Is this a trivial partition?
    isTrivialPartition = isNumericPartitionStrategy ... 
                      && isequal(partitionStrategy, 1) ... 
                      && isequal(partitionIndex, 1); 

    % Ensure that the Folders property is only recomputed when
    % necessary.
    if ~isTrivialPartition
        % A non-trivial partition is being generated, ensure that
        % the Folders property is recomputed on the next get.Folders.
        ds.RecalculateFolders = true;
    end 
end
