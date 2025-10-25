classdef BlockedInfoFunctionObject < matlab.io.datastore.internal.functor.BlockedRepetitionFunctionObject
%BlockedInfoFunctionObject   Decorates the info struct for BlockedRepeatedDatastore.

%   Copyright 2022 The MathWorks, Inc.

    properties
        BlockStartOffset (1, 1) double {mustBeNonnegative, mustBeFinite, mustBeReal} = 0
    end
    methods
        function func = BlockedInfoFunctionObject(BlockSize, SizeFcn, IncludeInfo, BlockStartOffset)
            arguments
                BlockSize (1, 1) double {mustBePositive} = inf;
                SizeFcn   (1, 1) {mustBeA(SizeFcn, "matlab.mixin.internal.FunctionObject")} ...
                    = matlab.io.datastore.internal.functor.FunctionHandleFunctionObject(@(data) 1);
                IncludeInfo (1, 1) logical = false;

                BlockStartOffset  (1, 1) double {mustBeNonnegative, mustBeFinite, mustBeReal} = 0
            end

            func = func@matlab.io.datastore.internal.functor.BlockedRepetitionFunctionObject(BlockSize, SizeFcn, IncludeInfo);
            func.BlockStartOffset   =  BlockStartOffset;
        end

        function [data, info] = parenReference(func, data, info)
        % Nothing to be done for data.
        % The info struct has one new property from RepeatedDatastore: RepetitionIndex.
        % RepetitionIndex needs to be removed and three new properties: BlockIndex,
        % BlockStart, and BlockEnd need to be added.

            index = info.RepetitionIndex;
            info = rmfield(info, "RepetitionIndex");


            if func.IncludeInfo
                TotalSize = func.SizeFcn(data, info);
            else
                TotalSize = func.SizeFcn(data);
            end


            info.BlockIndex = index;

            % Handle the BlockSize=Inf and empty block cases early.
            if isinf(func.BlockSize) || isempty(index)
                info.BlockStart = 1;
                info.BlockEnd = TotalSize; % Note: Might be 0 if empty block.
                return;
            end


            info.BlockStart = ((info.BlockIndex-1) * func.BlockSize) + 1 + func.BlockStartOffset;
            info.BlockEnd = info.BlockIndex * func.BlockSize + func.BlockStartOffset;

            % Account for the first block overshooting due to BlockStartOffset
            if info.BlockStart > TotalSize
                info.BlockStart = TotalSize ;
            end


            % Account for the last block potentially being truncated.
            if info.BlockEnd > TotalSize
                info.BlockEnd = TotalSize;
            end
        end
    end

    methods
        function S = saveobj(obj)
            S = saveobj@matlab.io.datastore.internal.functor.BlockedRepetitionFunctionObject(obj);
            S.BlockStartOffset = obj.BlockStartOffset;
        end
    end

    methods (Static)
        function obj = loadobj(S)

            import matlab.io.datastore.internal.functor.BlockedInfoFunctionObject
            import matlab.io.datastore.internal.functor.BlockedRepetitionFunctionObject

            if isfield(S, "EarliestSupportedVersion")
                % Error if we are sure that a version incompatibility is about to occur.
                if S.EarliestSupportedVersion > BlockedRepetitionFunctionObject.ClassVersion
                    error(message("MATLAB:io:datastore:common:validation:UnsupportedClassVersion"));
                end
            end

            % Reconstruct the object.
            obj = BlockedInfoFunctionObject(S.BlockSize, S.SizeFcn, S.IncludeInfo, S.BlockStartOffset);
        end
    end
end
