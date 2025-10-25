classdef FileDatastore < matlab.io.datastore.internal.ParquetDatastore.UnderlyingDatastore
%FileDatastore   A datastore that reads entire Parquet files.

%   Copyright 2022-2023 The MathWorks, Inc.

    properties (Access = protected)
        UnderlyingDatastore = arrayDatastore([]);
    end

    properties (Dependent)
        ImportOptions
    end

    properties (SetAccess=private)
        ReadSize = "file";
    end

    properties (SetAccess=private)
        PartitionMethod = "file";
    end


    methods
        function fds = FileDatastore(varargin)
            fds.UnderlyingDatastore = makeUnderlyingDatastore(varargin{:});
        end

        function opts = get.ImportOptions(ds)
        % Get the TransformedDatastore and extract the current
        % ImportOptions from the FunctionObject.
            tds = getUnderlyingDatastore(ds, "matlab.io.datastore.TransformedDatastore");

            opts = tds.Transforms{1}.ImportOptions;
        end

        function set.ImportOptions(ds, opts)
        % This will recompute the schema and reset() the datastore
        % stack.
            ds.UnderlyingDatastore = makeUnderlyingDatastore(ds.FileSet, opts);
        end
    end

    methods (Static)
        function obj = loadobj(S)
        % Throw the version incompatibility error if necessary.
            loadobj@matlab.io.datastore.internal.ParquetDatastore.UnderlyingDatastore(S);

            % Reconstruct the object.
            obj = matlab.io.datastore.internal.ParquetDatastore.UnderlyingDatastore.FileDatastore();
            obj.UnderlyingDatastore = S.UnderlyingDatastore;
        end
    end
end

function uds = makeUnderlyingDatastore(fs, pio, schema)
    arguments
        fs (1, 1) matlab.io.datastore.FileSet = matlab.io.datastore.FileSet({});
        pio (1, 1) matlab.io.parquet.internal.ParquetImportOptions = matlab.io.parquet.internal.ParquetImportOptions();
        schema = matlab.io.datastore.internal.ParquetDatastore.computeSchema(fs, pio);
    end

    import matlab.io.datastore.internal.FileDatastore2
    import matlab.io.datastore.internal.ParquetDatastore.functor.ParquetReadFunctionObject

    uds = FileDatastore2(fs, ReadFcn=@matlab.io.parquet.internal.ParquetReadCacher) ...
          .transform(ParquetReadFunctionObject(pio), IncludeInfo=true) ...
          .overrideSchema(schema);
end
