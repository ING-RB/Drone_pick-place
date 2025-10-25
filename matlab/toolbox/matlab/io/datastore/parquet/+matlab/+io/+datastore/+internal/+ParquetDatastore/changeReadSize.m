function uds = changeReadSize(uds, newReadSize, partitionMethod, partitionMethodDerivedFromAuto)
%changeReadSize   Implements special-case behavior for numeric->rowgroup,
%   rowgroup->numeric, and numeric->numeric ReadSize changes.

%   Copyright 2022-2023 The MathWorks, Inc.

    arguments
        uds (1, 1) matlab.io.Datastore
        newReadSize
        partitionMethod {matlab.io.datastore.internal.ParquetDatastore.mustBeValidPartitionMethod}
        partitionMethodDerivedFromAuto (1, 1) {mustBeNumericOrLogical}
    end

    import matlab.io.datastore.internal.ParquetDatastore.mustBeValidReadSize
    import matlab.io.datastore.internal.ParquetDatastore.mustBeValidPartitionMethod
    import matlab.io.datastore.internal.ParquetDatastore.makeDatastoreFromReadSize


    [oldReadMode, oldReadSize] = mustBeValidReadSize(uds.ReadSize);
    [newReadMode, newReadSize] = mustBeValidReadSize(newReadSize);
    partitionMethod = mustBeValidPartitionMethod(partitionMethod);
    
    persistent compatibilityDict

    if (partitionMethodDerivedFromAuto)
        if isempty(compatibilityDict)
            readModeKey = ["numeric", "rowgroup", "file"];
            partitionMethodVal = ["rowgroup", "rowgroup", "file"];
            compatibilityDict = dictionary(readModeKey, partitionMethodVal);
        end
        partitionMethod = compatibilityDict(newReadMode);
    end

    % If oldReadSize and newReadSize are identical, do nothing and return
    % early.
    if isequaln(oldReadSize, newReadSize)
        return;
    end

    % Numeric -> Numeric conversion can just set the ReadSize on the
    % underlying datastore. No reset() should be done.
    if oldReadMode == "numeric" && newReadMode == "numeric"
        uds.changeReadSize(newReadSize);
        return;
    end

    % Numeric -> RowGroup should just extract the underlying
    % rowgroup-reading datastore. This preserves any subsetted
    % rowgroup indices.
    if oldReadMode == "numeric" && newReadMode == "rowgroup"
        cls = "matlab.io.datastore.internal.ParquetDatastore.UnderlyingDatastore.RowGroupDatastore";
        uds = getUnderlyingDatastore(uds, cls);
        uds.reset();
        return;
    end

    import matlab.io.datastore.internal.ParquetDatastore.UnderlyingDatastore.PaginatedRowGroupDatastore

    % RowGroup -> Numeric should just apply numeric paging over the old
    % rowgroup-reading datastore. This preserves any subsetted rowgroup indices.
    if oldReadMode == "rowgroup" && newReadMode == "numeric" ...
            && partitionMethod == "rowgroup"
        % Currently only for rowgroup PartitionMethod , we are doing this.
        % For other PartitionMethods this should error(atleast for now).
        % Let makeDatastoreFromReadSize raise those errors.
        % If we start supporting other PartitionMethods, add them to the if
        % condition then.
        uds = PaginatedRowGroupDatastore(uds, newReadSize);
        uds.reset();
        return;
    end
    uds = makeDatastoreFromReadSize(uds.FileSet, uds.ImportOptions, newReadSize, 128*1000*1000, partitionMethod, uds.Schema);

end
