function numRowGroups = computeNumRowGroups(fds, ~, ~)
%computeNumRowGroups   Returns the NumRowGroups for every Parquet file
%   in the input FileDatastore.
%
%   Used by RepeatedDatastore to optimize the numpartitions calculation for
%   ParquetDatastore.

%   Copyright 2022 The MathWorks, Inc.

    files = string(fds.Files);

    import matlab.io.datastore.internal.ParquetDatastore.defaultNumRowGroupsMode
    useSync = defaultNumRowGroupsMode();

    import matlab.io.parquet.internal.getNumRowGroups
    numRowGroups = getNumRowGroups(files, useSync);
end