function initializeDatastore(pds, hadoopInfo)
%initializeDatastore   Reconfigure ParquetDatastore to read through
%   Hadoop data.

%   Copyright 2022-2023 The MathWorks, Inc.

    import matlab.io.datastore.internal.ParquetDatastore.mapByteOffsetToRowGroupIndices

    % Return early if ParquetDatastore is in the full file reading mode.
    if pds.isfullfile()
        pds.Files = hadoopInfo.FileName;
        return;
    end

    if (isnumeric(pds.ReadSize) && pds.PartitionMethod == "bytes")
        error(message("MATLAB:parquetdatastore:properties:unsupportedPartitionMethodAndReadSizeCombo", "numeric", "bytes"));
    end

    if (strcmp(pds.ReadSize, "rowgroup") && pds.PartitionMethod == "bytes")

        import matlab.io.datastore.internal.ParquetDatastore.UnderlyingDatastore.BlockedRowGroupDatastore

        pds.Files = hadoopInfo.FileName;
        hadoopMode = true;
        pds.UnderlyingDatastore = BlockedRowGroupDatastore(pds.UnderlyingDatastore.FileSet, ...
                                                           pds.UnderlyingDatastore.ImportOptions,...
                                                           hadoopInfo.Size, ...
                                                           pds.UnderlyingDatastore.Schema,...
                                                           hadoopInfo.Offset, ...
                                                           hadoopMode);

        return;
    end




    % In the rowgroup-based reading modes, we need to map the Offset and
    % Size in the HadoopInfo struct to a range of rowgroups in the Parquet
    % file.
    indices = mapByteOffsetToRowGroupIndices(hadoopInfo.FileName, hadoopInfo.Offset, hadoopInfo.Size);

    % Since numeric ReadSize is not subsettable, convert to RowGroup
    % readsize and map back to numeric later.
    oncl = onCleanup(@() setfield(pds, "ReadSize", pds.ReadSize));
    pds.ReadSize = "rowgroup";

    % Set the correct filename on the ParquetDatastore.
    pds.Files = hadoopInfo.FileName;

    % Now subset by rowgroup indices. This should also reset the datastore.
    pds.UnderlyingDatastore = pds.UnderlyingDatastore.subset(indices);

    % Cleanup code will map back to numeric ReadSize if necessary.
end
