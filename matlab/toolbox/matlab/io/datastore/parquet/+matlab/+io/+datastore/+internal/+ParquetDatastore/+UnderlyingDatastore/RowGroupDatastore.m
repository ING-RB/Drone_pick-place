classdef RowGroupDatastore < matlab.io.datastore.internal.ParquetDatastore.UnderlyingDatastore
%RowGroupDatastore   A datastore that reads rowgroups from Parquet files.

%   Copyright 2022-2023 The MathWorks, Inc.

    properties (Access = protected)
        UnderlyingDatastore = arrayDatastore([]);
    end

    properties (Dependent)
        ImportOptions
    end

    properties (SetAccess=private)
        ReadSize = "rowgroup";
    end

    properties (SetAccess=private)
        PartitionMethod = "rowgroup";
    end

    methods
        function rgds = RowGroupDatastore(varargin)
            rgds.UnderlyingDatastore = makeUnderlyingDatastore(varargin{:});
        end

        function opts = get.ImportOptions(ds)
        % Get the TransformedDatastore and extract the current
        % ImportOptions from the FunctionObject.
            tds = getUnderlyingDatastore(ds, "matlab.io.datastore.TransformedDatastore");

            opts = tds.Transforms{1}.ImportOptions;
        end

        function set.ImportOptions(ds, opts)
        % Get the old RepetitionIndices out.
            cls = "matlab.io.datastore.internal.RepeatedDatastore";
            rptds = getUnderlyingDatastore(ds.UnderlyingDatastore, cls);
            oldIndices = rptds.RepetitionIndices;

            % This will recompute the schema and reset() the datastore
            % stack.
            ds.UnderlyingDatastore = makeUnderlyingDatastore(ds.FileSet, opts);

            % Set the old RepetitionIndices back so we don't lose
            % post-partitioned state.
            rptds = getUnderlyingDatastore(ds.UnderlyingDatastore, cls);
            rptds.RepetitionIndices = oldIndices;
        end
    end

    methods (Static)
        function obj = loadobj(S)
        % Throw the version incompatibility error if necessary.
            loadobj@matlab.io.datastore.internal.ParquetDatastore.UnderlyingDatastore(S);

            % Reconstruct the object.
            obj = matlab.io.datastore.internal.ParquetDatastore.UnderlyingDatastore.RowGroupDatastore();
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
          .repeat(@(reader) reader.InternalReader.NumRowGroups, RepeatAllFcn=@matlab.io.datastore.internal.ParquetDatastore.computeNumRowGroups) ...
          .transform(ParquetReadFunctionObject(pio), IncludeInfo=true) ...
          .overrideSchema(schema);
end
