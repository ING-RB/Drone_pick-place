classdef BlockedRowGroupDatastore < matlab.io.datastore.internal.ParquetDatastore.UnderlyingDatastore
    %BlockedRowGroupDatastore   A datastore that reads rowgroups corresponding to byte ranges from Parquet files.

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
        PartitionMethod = "bytes";
    end

    properties (Dependent)
        BlockSize
    end

    methods
        function brgds = BlockedRowGroupDatastore(varargin)
            brgds.UnderlyingDatastore = makeUnderlyingDatastore(varargin{:});
        end

        function opts = get.ImportOptions(ds)
            % Get the TransformedDatastore and extract the current
            % ImportOptions from the FunctionObject.
            tds = getUnderlyingDatastore(ds, "matlab.io.datastore.TransformedDatastore");

            opts = tds.Transforms{2}.ImportOptions;
        end

        function set.ImportOptions(ds, opts)
            % This will recompute the schema and reset() the datastore
            % stack.
            ds.UnderlyingDatastore = makeUnderlyingDatastore(ds.FileSet, opts, ds.BlockSize);
        end

        function bs = get.BlockSize(ds)
            % Get this from the underlying BlockedRepeatedDatastore.
            uds = getUnderlyingDatastore(ds, "matlab.io.datastore.internal.BlockedRepeatedDatastore");
            bs = uds.BlockSize;
        end

        function set.BlockSize(ds, bs)
            % This will recompute the schema and reset() the datastore stack.
            ds.UnderlyingDatastore = makeUnderlyingDatastore(ds.FileSet, ds.ImportOptions, bs);
        end
    end

    methods (Static)
        function obj = loadobj(S)
            % Throw the version incompatibility error if necessary.
            loadobj@matlab.io.datastore.internal.ParquetDatastore.UnderlyingDatastore(S);

            % Reconstruct the object.
            obj = matlab.io.datastore.internal.ParquetDatastore.UnderlyingDatastore.BlockedRowGroupDatastore();
            obj.UnderlyingDatastore = S.UnderlyingDatastore;
        end
    end
end


function uds = makeUnderlyingDatastore(fs, pio, blockSize, schema, blockStartOffset, hadoopMode)
arguments
    fs (1, 1) matlab.io.datastore.FileSet = matlab.io.datastore.FileSet({});
    pio (1, 1) matlab.io.parquet.internal.ParquetImportOptions = matlab.io.parquet.internal.ParquetImportOptions();
    blockSize (1, 1) double {mustBePositive, mustBeFinite, mustBeReal} = 128*1000*1000;
    schema = matlab.io.datastore.internal.ParquetDatastore.computeSchema(fs, pio);
    blockStartOffset (1, 1) double {mustBeNonnegative, mustBeFinite, mustBeReal} = 0;
    hadoopMode (1, 1) logical = false;
end

import matlab.io.datastore.internal.FileDatastore2
import matlab.io.datastore.internal.ParquetDatastore.functor.ParquetReadFunctionObject

if (hadoopMode)
    totalSize = @(~,~) blockSize;
    uds = FileDatastore2(fs, ReadFcn=@matlab.io.parquet.internal.ParquetReadCacher) ...
        .blockedRepeat(BlockSize=blockSize, SizeFcn=totalSize, IncludeInfo=true, BlockStartOffset=blockStartOffset);      
else
    totalSize = @(~, info) info.FileSize;
    uds = FileDatastore2(fs, ReadFcn=@matlab.io.parquet.internal.ParquetReadCacher) ...
        .blockedRepeat(BlockSize=blockSize, SizeFcn=totalSize, IncludeInfo=true, BlockStartOffset=blockStartOffset, AllSizeFcn=@myCustomRepeatAllFcn);       
end

uds = uds.transform(@mapInfoStructBytesToRowGroupOffsets, IncludeInfo=true) ...
        .transform(@flipping, IncludeInfo=true) ...
        .paginate(ReadSize=1)...
        .transform(@flipuback, IncludeInfo=true)...
        .transform(ParquetReadFunctionObject(pio), IncludeInfo=true) ...
        .overrideSchema(schema);
end

function [data, info] = flipping(data,info)
temp = data;
data = info.RepetitionIndex;
info.parquetReadCacher = temp;
end

function [data, info] = flipuback(data,info)
info.RepetitionIndex = data;
temp = info.parquetReadCacher;
data = temp;
end


function [data, info] = mapInfoStructBytesToRowGroupOffsets(data, info)
byteOffset = info.BlockStart - 1; % Convert to 0-based offset.
blockSize = info.BlockEnd - info.BlockStart + 1;

import matlab.io.datastore.internal.ParquetDatastore.mapByteOffsetToRowGroupIndices;
info.RepetitionIndex = mapByteOffsetToRowGroupIndices(info.Filename, byteOffset, blockSize);

% Remove unnecessary info struct fields.
info = rmfield(info, ["BlockStart" "BlockEnd" "BlockIndex"]);
end


function N = myCustomRepeatAllFcn(fds, ~, ~)
% N = myCustomRepeatAllFcn(fds, RepeatFcn, IncludeInfo)
N = fds.FileSet.FileInfo.FileSize;
end

