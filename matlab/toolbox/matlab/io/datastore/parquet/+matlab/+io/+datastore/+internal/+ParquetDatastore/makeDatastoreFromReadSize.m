function ds = makeDatastoreFromReadSize(fs, pio, readSize, blockSize, partitionMethod, schema)
%makeDatastoreFromReadSize   Construct a new composed datastore stack from
%    the input fileset, ParquetImportOptions, and ReadSize.

%   Copyright 2022-2023 The MathWorks, Inc.

    arguments
        fs       (1, 1) matlab.io.datastore.FileSet
        pio      (1, 1) matlab.io.parquet.internal.ParquetImportOptions
        readSize
        blockSize (1, 1) double {mustBePositive, mustBeFinite, mustBeReal}
        partitionMethod
        schema = []
    end

    import matlab.io.datastore.internal.ParquetDatastore.computeSchema
    import matlab.io.datastore.internal.ParquetDatastore.mustBeValidReadSize
    import matlab.io.datastore.internal.ParquetDatastore.mustBeValidPartitionMethod
    import matlab.io.datastore.internal.ParquetDatastore.crossValidatePartitionMethodAndReadMode
    import matlab.io.datastore.internal.ParquetDatastore.determineConcretePartitionMethodForAutoPartition

    [readMode, readSize] = mustBeValidReadSize(readSize);
    partitionMethod = mustBeValidPartitionMethod(partitionMethod);

    if (partitionMethod == "auto")
        partitionMethod = determineConcretePartitionMethodForAutoPartition(readMode);
    end

    crossValidatePartitionMethodAndReadMode(readMode, partitionMethod);


    % Compute the schema if not supplied.
    if nargin < 6
        schema = computeSchema(fs, pio);
    end

    import matlab.io.datastore.internal.ParquetDatastore.UnderlyingDatastore.FileDatastore
    import matlab.io.datastore.internal.ParquetDatastore.UnderlyingDatastore.RowGroupDatastore
    import matlab.io.datastore.internal.ParquetDatastore.UnderlyingDatastore.BlockedRowGroupDatastore
    import matlab.io.datastore.internal.ParquetDatastore.UnderlyingDatastore.PaginatedRowGroupDatastore


    %+----------+----------+-------------------------+--------------------------+-----------------+-------------------------+
    %|          |          |                         | PARTITIONMETHOD          |                 |                         |
    %+==========+==========+=========================+==========================+=================+=========================+
    %|          |          | rowgroup                | bytes                    | file            | auto                    |
    %+----------+----------+-------------------------+--------------------------+-----------------+-------------------------+
    %|          | rowgroup | RowGroupDatastore       | BlockedRowGroupDatastore | notYetSupported | RowGroupDatastore       |
    %+----------+----------+-------------------------+--------------------------+-----------------+-------------------------+
    %| READSIZE | numeric  | PaginatedDatastore(rds) | PaginatedDatastore(bds)  | notYetSupported | PaginatedDatastore(rds) |
    %+----------+----------+-------------------------+--------------------------+-----------------+-------------------------+
    %|          | file     | error                   | error                    | FileDatastore   | FileDatastore           |
    %+----------+----------+-------------------------+--------------------------+-----------------+-------------------------+


    switch readMode
      case "file"
        ds = fileReader(fs, pio, schema, partitionMethod);
      case "rowgroup"
        ds = rowgroupReader(fs, pio, schema, blockSize, partitionMethod);
      case "numeric"
        ds = numericReader(fs, pio, schema, readSize, partitionMethod);
    end


    function ds = rowgroupReader(fs, pio, schema, blockSize, partitionMethod)
        switch (partitionMethod)
          case "rowgroup"
            ds = RowGroupDatastore(fs, pio, schema);
          case "bytes"
            ds = BlockedRowGroupDatastore(fs, pio, blockSize, schema);
          case "file"
            % FileRowGroupDatastore not implemented
            error(message("MATLAB:parquetdatastore:properties:unsupportedPartitionMethodAndRowgroupReadSizeCombo", "file"));
        end
    end

    function ds = fileReader(fs, pio, schema, partitionMethod)
        switch (partitionMethod)
          case "file"
            ds = FileDatastore(fs, pio, schema);
          otherwise
            % do nothing
            % case "rowgroup"
            % case "bytes"
            % handled by crossValidatePartitionMethodAndReadMode
        end
    end

    function ds = numericReader(fs, pio, schema, readSize, partitionMethod)
        switch(partitionMethod)
          case "rowgroup"
            ds = PaginatedRowGroupDatastore(RowGroupDatastore(fs, pio, schema), readSize);
          case "file"
            % PaginatedDatastore(fds) not implemented
            error(message("MATLAB:parquetdatastore:properties:unsupportedPartitionMethodAndReadSizeCombo", "numeric", "file"));
          case "bytes"
            % PaginatedDatastore(bds) not implemented
            error(message("MATLAB:parquetdatastore:properties:unsupportedPartitionMethodAndReadSizeCombo", "numeric", "bytes"));
        end
    end
end
