classdef PaginatedRowGroupDatastore < matlab.io.datastore.internal.ParquetDatastore.UnderlyingDatastore
%PaginatedRowGroupDatastore   A datastore that reads rowgroups from Parquet
%   files and returns a numeric range of rows at a time.

%   Copyright 2022-2023 The MathWorks, Inc.

    properties (Access = protected)
        UnderlyingDatastore = arrayDatastore([]);
    end

    properties (Dependent)
        ImportOptions
    end

    properties (SetAccess=private, Dependent)
        ReadSize;
    end

    properties (SetAccess=private, Dependent)
        PartitionMethod;
    end

    properties (Constant)
        RowGroupDatastoreClassName  = "matlab.io.datastore.internal.ParquetDatastore.UnderlyingDatastore.RowGroupDatastore";
        PaginatedDatastoreClassName = "matlab.io.datastore.internal.PaginatedDatastore";
    end

    methods
        function prgds = PaginatedRowGroupDatastore(varargin)
            prgds.UnderlyingDatastore = makeUnderlyingDatastore(varargin{:});
        end

        function opts = get.ImportOptions(ds)
        % Get the ImportOptions from RowgroupDatastore.
            opts = getUnderlyingDatastore(ds, ds.RowGroupDatastoreClassName).ImportOptions;
        end

        function set.ImportOptions(ds, opts)
        % Get the current RowGroupDatastore and set the new
        % ImportOptions on it. This will recompute the schema.
            rgds = getUnderlyingDatastore(ds, ds.RowGroupDatastoreClassName);
            rgds.ImportOptions = opts;

            % This will reset() the datastore stack.
            ds.UnderlyingDatastore = makeUnderlyingDatastore(rgds, ds.ReadSize);
        end

        function readSize = get.ReadSize(ds)
        % Get the ReadSize from the Pagination layer.
            readSize = ds.getUnderlyingDatastore(ds.PaginatedDatastoreClassName).ReadSize;
        end

        function partitionMethod = get.PartitionMethod(ds)
        % Get the ReadSize from the Pagination layer.
            partitionMethod = ds.getUnderlyingDatastore(ds.RowGroupDatastoreClassName).PartitionMethod;
        end

        function changeReadSize(ds, readSize)
        % Set the ReadSize on the Pagination layer.
            ds.getUnderlyingDatastore(ds.PaginatedDatastoreClassName).ReadSize = readSize;
        end
    end

    methods (Static)
        function obj = loadobj(S)
        % Throw the version incompatibility error if necessary.
            loadobj@matlab.io.datastore.internal.ParquetDatastore.UnderlyingDatastore(S);

            % Reconstruct the object.
            obj = matlab.io.datastore.internal.ParquetDatastore.UnderlyingDatastore.PaginatedRowGroupDatastore();
            obj.UnderlyingDatastore = S.UnderlyingDatastore;
        end
    end
end

function uds = makeUnderlyingDatastore(rgds, readSize)
    arguments
        rgds (1, 1) matlab.io.datastore.internal.ParquetDatastore.UnderlyingDatastore.RowGroupDatastore = ...
            matlab.io.datastore.internal.ParquetDatastore.UnderlyingDatastore.RowGroupDatastore();
        readSize (1, 1) double = 1;
    end

    % Maintain the RowGroupDatastore's iteration pattern and
    % paginate around it.
    % This helps preserve any subsetted rowgroup indices.
    uds = rgds.paginate(ReadSize=readSize) ...
          .overrideSchema(rgds.Schema);
end
