function partds = partition(pds, N, ii)
%partition   Divide the input ParquetDatastore into partitions.

%   Copyright 2022-2023 The MathWorks, Inc.

% The Files strategy is required for writeall to work on a parallel pool.
    import matlab.io.datastore.internal.validators.validatePartitionFilesStrategy;
    import matlab.io.datastore.internal.ParquetDatastore.makeDatastoreFromReadSize;

    fs = pds.UnderlyingDatastore.FileSet;
    [isFilesStrategy, ii] = validatePartitionFilesStrategy(N, ii, @() fs.FileInfo.Filename, fs.NumFiles);

    if isFilesStrategy
        % Generate a copy and set the one necessary file.
        partds = pds.copy();
        partfs = fs.subset(ii);
        partds.UnderlyingDatastore = makeDatastoreFromReadSize(partfs, partds.ImportOptions, partds.ReadSize, partds.BlockSize, partds.PartitionMethod);
        partds.reset();
        return;
    end

    % If not Files strategy, try the normal numeric strategy instead.
    partds = partition@matlab.io.datastore.internal.ComposedDatastore(pds, N, ii);
end
