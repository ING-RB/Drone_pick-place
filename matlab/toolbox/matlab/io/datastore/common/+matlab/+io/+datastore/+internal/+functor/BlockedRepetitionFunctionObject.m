classdef BlockedRepetitionFunctionObject < matlab.mixin.internal.FunctionObject ...
                                         & matlab.mixin.Copyable
%BlockedRepetitionFunctionObject   Returns the number of blocks for the
%   input data and info.

%   Copyright 2022 The MathWorks, Inc.

    properties
        BlockSize (1, 1) double {mustBePositive} = inf;
        SizeFcn   (1, 1) {mustBeA(SizeFcn, "matlab.mixin.internal.FunctionObject")} ...
             = matlab.io.datastore.internal.functor.FunctionHandleFunctionObject(@(data) 1);
        IncludeInfo (1, 1) logical = false;
    end

    methods
        function func = BlockedRepetitionFunctionObject(BlockSize, SizeFcn, IncludeInfo)
            func.BlockSize   = BlockSize;
            func.SizeFcn     = SizeFcn;
            func.IncludeInfo = IncludeInfo;
        end

        function NumBlocks = parenReference(func, varargin)

            % If BlockSize is inf, don't even bother calling the SizeFcn.
            % Just return NumBlocks=1. This results in only 1 repetition per file.
            if isinf(func.BlockSize)
                NumBlocks = 1;
                return;
            end

            % Call SizeFcn with varargin to account for the possibility of either
            % IncludeInfo being set to true or false.
            totalSize = func.SizeFcn(varargin{:});

            % Validate the output of SizeFcn before proceeding.
            mustBeInteger(totalSize);
            mustBeNonnegative(totalSize);

            % Divide the Size by the BlockSize to get the total number of blocks
            % for this read.
            % Do all of this in integer math to avoid potential floating point rounding issues.
            NumBlocks = idivide(uint64(totalSize), uint64(func.BlockSize), "ceil");
        end
    end

    methods (Access = protected)
        % Override copyElement to deep-copy the SizeFcn.
        function funcCopy = copyElement(func)
            funcCopy = copyElement@matlab.mixin.Copyable(func);
            funcCopy.SizeFcn = copy(func.SizeFcn);
        end
    end

    % Save-load logic.
    properties (Constant)
        % Save-load metadata.
        % ClassVersion = 1 corresponds to the first release of ParquetDatastore2 in R2022b.
        ClassVersion (1, 1) double = 1;
    end

    methods
        function S = saveobj(obj)
            % Store save-load metadata.
            S = struct("EarliestSupportedVersion", 1);
            S.ClassVersion = obj.ClassVersion;

            % State properties
            S.BlockSize   = obj.BlockSize;
            S.SizeFcn     = obj.SizeFcn;
            S.IncludeInfo = obj.IncludeInfo;
        end
    end

    methods (Static)
        function obj = loadobj(S)

            import matlab.io.datastore.internal.functor.BlockedRepetitionFunctionObject

            if isfield(S, "EarliestSupportedVersion")
                % Error if we are sure that a version incompatibility is about to occur.
                if S.EarliestSupportedVersion > BlockedRepetitionFunctionObject.ClassVersion
                    error(message("MATLAB:io:datastore:common:validation:UnsupportedClassVersion"));
                end
            end

            % Reconstruct the object.
            obj = BlockedRepetitionFunctionObject(S.BlockSize, S.SizeFcn, S.IncludeInfo);
        end
    end
end
