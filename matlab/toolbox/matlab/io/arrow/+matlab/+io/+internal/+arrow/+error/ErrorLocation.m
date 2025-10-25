classdef ErrorLocation < matlab.mixin.Scalar
%ERRORLOCATION Represents a sequence of indexing operations to apply to an
% array.

% Copyright 2022 The MathWorks, Inc.

    properties(SetAccess = private)
        %LOCATION      A vector of IndexOperations representing a sequence
        %              of indexing operatons to apply to an array.
        Location(1, :) matlab.io.internal.arrow.error.IndexOperation
    end

    methods
        function obj = ErrorLocation(location)
            arguments
                location = matlab.io.internal.arrow.error.IndexOperation.empty(1, 0)
            end
            obj.Location = location;
        end

        function obj = appendBracesIndexOperation(obj, indexArgument)
            import matlab.io.internal.arrow.error.IndexType
            import matlab.io.internal.arrow.error.IndexOperation

            obj.Location(end + 1) = IndexOperation(IndexType.Braces, indexArgument);
        end

        function obj = appendDotIndexOperation(obj, indexArgument)
            import matlab.io.internal.arrow.error.IndexType
            import matlab.io.internal.arrow.error.IndexOperation

            indexOp = IndexOperation(IndexType.Dot, indexArgument);
            obj.Location(end + 1) = indexOp;
        end

        function obj = updateLastBracesOperationArgument(obj, startOffsets)
            import matlab.io.internal.arrow.error.IndexType
            import matlab.io.internal.arrow.error.IndexOperation

            if isempty(obj.Location)
                exceptionType = matlab.io.internal.arrow.error.ExceptionType.Unknown;
                matlab.io.internal.arrow.error.ExceptionFactory.throw(exceptionType);
            end

            % Find the last IndexOperation whose Type = IndexType.Braces
            locationIndex = find([obj.Location.Type] == IndexType.Braces, 1, "last");

            % Make sure locationIndex is not empty. Should never happen in
            % production.
            throwUnknownExceptionIfNotValidIndex(locationIndex);

            % Store the value of this operation's IndexArgument
            locationIndexArg = obj.Location(locationIndex).IndexArgument;

            % Find the index of the last element in startOffsets which is
            % less than locationIndexArg. This element is the
            % represents the starting location of a new "row" in the list
            % array.
            beginOffsetIndex = find(startOffsets < locationIndexArg, 1, "last");

            % Make sure beginOffsetIndex is not empty. Should never happen
            % in production.
            throwUnknownExceptionIfNotValidIndex(beginOffsetIndex);

            beginOffsetValue = startOffsets(beginOffsetIndex);

            % Determine what the actual value IndexArgument should be for
            % the IndexOperation at index locationIndex by subtracting
            % beginOffsetValue from locationIndexArg.
            updatedLocationIndexArg = locationIndexArg - beginOffsetValue;
            obj.Location(locationIndex).IndexArgument = double(updatedLocationIndexArg);

            % Add a new IndexOperation whose Type = Index.Braces. It's
            % IndexArgument is the last index in startOffsets that is less
            % than locationIndexArg.
            obj.Location(end + 1) = IndexOperation(IndexType.Braces, double(beginOffsetIndex));
        end

        function indexExpression = getIndexingExpression(obj, variableName)
            numIndexOp = numel(obj.Location);
            indexStrs = strings([1, 1 + numIndexOp]);
            indexStrs(1) = variableName;
            strIdx = 2;
            for ii = numIndexOp:-1:1
                indexStrs(strIdx) = obj.Location(ii).OperationString;
                strIdx = strIdx + 1;
            end
            indexExpression = join(indexStrs, "");
        end
    end
end

function throwUnknownExceptionIfNotValidIndex(index)
    if isempty(index)
        exceptionType = matlab.io.internal.arrow.error.ExceptionType.Unknown;
        matlab.io.internal.arrow.error.ExceptionFactory.throw(exceptionType);
    end
end
