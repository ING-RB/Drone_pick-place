classdef BlockedRepeatedDatastore < matlab.io.Datastore ...
        & matlab.io.datastore.internal.ComposedDatastore
    %matlab.io.datastore.internal.BlockedRepeatedDatastore   A generic datastore that
    %   iterates over blocks using a BlockSize.
    %
    %   Input Datastore:
    %     >> fwrite("file1.bin", 35); 35 bytes in 1 file.
    %     >> fwrite("file2.bin", 22); 22 bytes in the second file.
    %     >> fds = fileDatastore(["file1.bin" "file2.bin"], ReadFcn=@(x) x);
    %
    %     Data: |--------------Read 1---------------|--------Read 2--------|
    %     Info: |--------------Info 1---------------|--------Info 2--------|  2 reads total.
    %                                                                         2 partitions.
    %
    %   Output Datastore:
    %     >> blkds = fds.blockedRepeat(BlockSize=14, ...
    %                                  SizeFcn=@(~, info) info.FileSize,
    %                                  IncludeInfo=true);
    %
    %     Iter: |----- SizeFcn(Read1) => 35 --------| SizeFcn(Read2) => 22 |
    %           |-----------------------------------|----------------------|
    %           |   Block 1   |   Block 2   |Block 3|   Block 1   | Block 2|
    %           |-----------------------------------|----------------------|
    %           |<-BlockSize->|<-BlockSize->|<-...->|<-BlockSize->|<-....->|
    %           |  14 bytes   |  14 bytes   |7 bytes|  14 bytes   |8 bytes |
    %
    %     Data: |    Read1    |    Read1    | Read1 |    Read2    | Read2  |
    %     Info: |    Info1    |    Info1    | Info1 |    Info2    | Info2  |
    %           |BlockStart=1 |BlockStart=15|BStr=29|BlockStart=1 |BStr=15 |
    %           |BlockEnd  =14|BlockEnd  =28|BEnd=35|BlockEnd  =14|BEnd=22 |
    %           |BlockIndex=1 |BlockIndex=2 |BIdx=3 |BlockIndex=1 |BIdx=2  |  5 reads total.
    %                                                                         5 partitions.
    %
    %   BLKDS = matlab.io.datastore.internal.BlockedRepeatedDatastore(DS, BlockSize=SZ, SizeFcn=FCN)
    %       returns a new datastore BLKDS that repeats each read of DS over blocks of size SZ
    %       in extents computed using the function FCN.
    %
    %       The BlockSize, SZ, must be a positive integer scalar double. BlockSize can also
    %       be Inf, in which case only one block is generated per read of DS.
    %
    %       The SizeFcn, FCN, must have the following signature:
    %
    %           function N = SizeFcn(data)
    %
    %       where data is the from the output of the underlying datastore, DS. The value
    %       returned by SizeFcn, N, must be a non-negative integer scalar double.
    %
    %       Note that the SizeFcn may be called 2 times per read of DS. So it should be a
    %       function that does not cause any side effects.
    %
    %   BLKDS = matlab.io.datastore.internal.BlockedRepeatedDatastore(..., IncludeInfo=TF)
    %       specifies whether the info struct should be included when calling SizeFcn.
    %       By default IncludeInfo is set to false.
    %
    %       If IncludeInfo is set to true, the SizeFcn must have the following signature:
    %
    %           function N = SizeFcn(data, info)
    %
    %       where data and info are returned from each read of the input datastore DS.
    %
    %   Note: The "info" struct returned by calling read() on BlockedRepeatedDatastore contains the
    %         following new fields:
    %          - BlockStart: The first value in the block. Will always be >= 1.
    %          - BlockEnd: The last value in the block. Will always be >= 0.
    %          - BlockIndex: Index of the current block. Will always be >= 1.
    %
    %         If the SizeFcn returned 0, BlockStart will be 1 and BlockEnd will be 0.
    %         This corresponds to a range of [1:0], which is an empty vector in MATLAB.
    %
    %   matlab.io.datastore.internal.BlockedRepeatedDatastore Properties:
    %
    %     UnderlyingDatastore - The underlying datastore.
    %     BlockSize           - The maximum size of each block.
    %     SizeFcn             - Function handle or FunctionObject used to compute the total size
    %                           corresponding to each read.
    %
    %   See also: arrayDatastore, matlab.io.datastore.internal.ComposedDatastore

    %   Copyright 2022 The MathWorks, Inc.

    properties (Access = protected)
        UnderlyingDatastore = arrayDatastore([]);
    end

    properties (Dependent, SetAccess = private)
        BlockSize
        SizeFcn
        IncludeInfo
    end

    methods
        function blkds = BlockedRepeatedDatastore(UnderlyingDatastore, Args)
            arguments
                UnderlyingDatastore (1, 1) {matlab.io.datastore.internal.validators.mustBeDatastore}
                Args.BlockSize      (1, 1) double {mustBePositive, mustBeReal}
                Args.SizeFcn
                Args.IncludeInfo       (1, 1) logical = false
                Args.BlockStartOffset  (1, 1) double {mustBeNonnegative, mustBeFinite, mustBeReal} = 0
                Args.AllSizeFcn
            end

            % Copy and reset the input datastore on construction.
            uds = UnderlyingDatastore.copy();
            uds.reset();

            % Validate SizeFcn
            import matlab.io.datastore.internal.functor.*;
            SizeFcn = makeFunctionObject(Args.SizeFcn);

            % Validate BlockSize.
            BlockSize = validateBlockSize(Args.BlockSize);


            func1 = BlockedRepetitionFunctionObject(BlockSize, SizeFcn, Args.IncludeInfo);
            func2 = BlockedInfoFunctionObject(BlockSize, SizeFcn, Args.IncludeInfo, Args.BlockStartOffset);

            if isfield(Args, 'AllSizeFcn')
                 uds = uds.repeat(func1, IncludeInfo=Args.IncludeInfo, ...
                    RepeatAllFcn=@(fds, RepeatFcn, IncludeInfo)convertSizesToNumBlocksForNumPartitions(fds, RepeatFcn, IncludeInfo, BlockSize, Args.AllSizeFcn)) ...
                    .transform(func2, IncludeInfo=true);
            else
                uds = uds.repeat(func1, IncludeInfo=Args.IncludeInfo) ...
                    .transform(func2, IncludeInfo=true);
            end


            blkds.UnderlyingDatastore = uds;
        end

        function value = get.BlockSize(blkds)
            value = getUnderlyingProperty(blkds, "BlockSize");
        end

        function value = get.SizeFcn(blkds)
            value = getUnderlyingProperty(blkds, "SizeFcn");
        end

        function value = get.IncludeInfo(blkds)
            value = getUnderlyingProperty(blkds, "IncludeInfo");
        end

    end

    properties (Access = private, Constant)
        % Save-load metadata.
        % ClassVersion = 1 corresponds to the first release of BlockedRepeatedDatastore in R2022b.
        ClassVersion(1, 1) double = 1;
    end

    methods (Hidden)
        S = saveobj(blkds);
    end

    methods (Hidden, Static)
        blkds = loadobj(S);
    end
end

function value = getUnderlyingProperty(ds, propName)
tds = ds.getUnderlyingDatastore("matlab.io.datastore.TransformedDatastore");
value = tds.Transforms{1}.(propName);
end

function BlockSize = validateBlockSize(BlockSize)
arguments
    BlockSize (1, 1) double {mustBePositive, mustBeReal}
end

if isinf(BlockSize)
    % Only 1 positive inf double value.
    return;
end

attributes = ["integer" "positive" "real"];
validateattributes(BlockSize, "numeric", attributes, string(missing), "BlockSize");
end

function NumBlocksAll = convertSizesToNumBlocksForNumPartitions(fds, RepeatFcn, IncludeInfo, BlockSize, AllSizeFcn)
% This function will only get called for numpartitions.
% i.e. only when bulk operations are needed.
allSizes = AllSizeFcn(fds, RepeatFcn, IncludeInfo);
NumBlocksAll = idivide(uint64(allSizes), uint64(BlockSize), "ceil");
end
