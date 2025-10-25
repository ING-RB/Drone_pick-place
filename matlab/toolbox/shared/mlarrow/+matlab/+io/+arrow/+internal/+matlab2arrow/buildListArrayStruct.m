function listArrayStruct = buildListArrayStruct(cellArray)
%BUILDLISTARRAYSTRUCT
%   Builds a 1x1 struct array used to convert cell arrays into
%   arrow::ListArrays.
%
%   Copyright 2021-2022 The MathWorks, Inc.

    arguments
        cellArray(:, 1) cell
    end

    import matlab.io.arrow.internal.matlab2arrow.bitPackLogical
    import matlab.io.arrow.internal.matlab2arrow.CellArrayType
    import matlab.io.internal.arrow.error.ExceptionType
    import matlab.io.internal.arrow.error.ExceptionFactory

    numRows = size(cellArray, 1);

    searchResult = findFirstValidValue(cellArray);

    if searchResult.CellArrayType == CellArrayType.AllMissing
        unpackedValidityBitmap = false([numRows, 1]);
        startOffsets = zeros([numRows + 1, 1], "uint64");
    else
        % Compute the Arrow ListArray offsets and unpacked validity bitmap.
        [startOffsets, unpackedValidityBitmap] = ...
            computeOffsetsAndUnpackedValidityBitmap(cellArray, searchResult.FirstValidValueIndex);
    end

    % Convert row vectors into column vectors.
    % At this point, all of the cell array elements must have consistent
    % type. If they didn't the TypeChecker would have thrown an error
    % already.
    if searchResult.CellArrayType == CellArrayType.ContainsValidValue
        tabularElements = istabular(cellArray{searchResult.FirstValidValueIndex});
        if ~tabularElements
            cellArray = cellfun(@(x) reshape(x, [], 1), cellArray, "UniformOutput", false);
        end
    else
        % The cell array only contains scalar <missing> values if
        % searchResult.CellArrayType is not equal to
        % CellArrayType.ContainsValidValue.
        tabularElements = false;
    end

    % Remove all NULL elements.
    % This works because Arrow ListArrays only store actual data for
    % non-NULL elements. In other words, the offsets array will have
    % length 0 for any NULL list elements.
    cellArray = cellArray(unpackedValidityBitmap);

    if ~tabularElements
        % Concatenate all non-NULL values together into one contiguous array.
        unwrappedCell = vertcat(cellArray{:});
    else
        unwrappedCell = matlab.io.internal.arrow.list.TabularWrapper(cellArray);
    end

    try
        values = matlab.io.arrow.internal.matlab2arrow(unwrappedCell);
    catch ME
        handleArrowException(ME, startOffsets);
    end

    % Validate the cell array does not exceed the maximum nesting level.
    nestedLevel = 1;
    if values.ArrowType == "list_array" || values.ArrowType == "struct"
        nestedLevel = values.Data.NestedLevel + 1;
        if nestedLevel > 125
            ExceptionFactory.throw(ExceptionType.ExceedsMaxNestingLevel);
        end
    end

    listArrayStruct.ArrowType = 'list_array';
    listArrayStruct.Type = values.ArrowType;
    listArrayStruct.Data.StartOffsets = startOffsets;
    listArrayStruct.Data.Values = values;
    listArrayStruct.Data.NestedLevel = nestedLevel;
    listArrayStruct.Valid = bitPackLogical(unpackedValidityBitmap);
end

function [startOffsets, unpackedValidityBitmap] = computeOffsetsAndUnpackedValidityBitmap(cellArray, firstValidValueIndex)
    import matlab.io.internal.arrow.list.typeCheckerFactory
    import matlab.io.internal.arrow.error.ExceptionType
    import matlab.io.internal.arrow.error.ExceptionFactory
    import matlab.io.internal.arrow.error.appendBracesIndexOperation

    if istabular(cellArray{firstValidValueIndex})
        numRowsFunc = @height;
    else
        numRowsFunc = @numel;
    end

    numRows = size(cellArray, 1);
    startOffsets = zeros([numRows + 1, 1], "uint64");
    unpackedValidityBitmap = true(numRows, 1);
    unpackedValidityBitmap(1:firstValidValueIndex - 1) = false;

    % Construct a TypeChecker based on the type of the first valid value.
    try
        typeChecker = typeCheckerFactory(cellArray{firstValidValueIndex});
    catch ME
        appendBracesIndexOperation(ME, firstValidValueIndex);
    end

    % Iterate through the input cell array and build the corresponding
    % Arrow validity bitmap and offsets array.
    for ii = firstValidValueIndex:numRows
        currentElement = cellArray{ii};
        % Set the validity bitmap to 0 at the current index (ii)
        % if the input cell array contains a <missing> value.
        if class(currentElement) == "missing"
            if ~isscalar(currentElement)
                ExceptionFactory.throw(ExceptionType.NonScalarMissing, ii);
            end
            unpackedValidityBitmap(ii) = false;
            startOffsets(ii + 1) = startOffsets(ii);
        else
            % Validate that the current element has a consistent type.
            % All elements in the cell array must have the same type.
            try
                typeChecker.checkType(currentElement);
            catch ME
                appendBracesIndexOperation(ME, ii, firstValidValueIndex);
            end
            startOffsets(ii + 1) = startOffsets(ii) + numRowsFunc(currentElement);
        end
    end

end

function searchResult = findFirstValidValue(cellArray)
    import matlab.io.arrow.internal.matlab2arrow.SearchResult
    import matlab.io.arrow.internal.matlab2arrow.CellArrayType
    import matlab.io.internal.arrow.error.ExceptionType
    import matlab.io.internal.arrow.error.ExceptionFactory

    searchResult = SearchResult();
    for ii = 1:numel(cellArray)
        if class(cellArray{ii}) == "missing"
            % Error immediately if we find a non-scalar <missing>.
            if ~isscalar(cellArray{ii})
                ExceptionFactory.throw(ExceptionType.NonScalarMissing, ii);
            end
        else
            searchResult.FirstValidValueIndex = ii;
            searchResult.CellArrayType = CellArrayType.ContainsValidValue;
            return;
        end
    end
end

function handleArrowException(except, startOffsets)
    if isa(except, "matlab.io.internal.arrow.error.ArrowException")
        % Updates the IndexArgument of the last IndexOperation whose Type =
        % IndexType.Braces. Also appends a new IndexOperation whose Type =
        % IndexType.Braces.
        except = updateLastBracesOperationArgument(except, startOffsets);
    end
    throw(except);
end
