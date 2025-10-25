function listArray = buildListArray(arrowStruct, opts)
%BUILDLISTARRAY
%   Builds a cell array from an arrow::ListArray or an arrow::LargeListArray.
%
%   Copyright 2021 The MathWorks, Inc.
    arguments
        arrowStruct(1, 1) {mustBeArrowListArrayStruct}
        opts(1, 1) Arrow2MatlabOptions = Arrow2MatlabOptions
    end

    import matlab.io.arrow.internal.Arrow2MatlabOptions

    numChunks = numel(arrowStruct.Data);
    listArrayChunks = cell(numChunks, 1);

    if numel(arrowStruct.Data) > 0 && arrowStruct.Data(1).Values.ArrowType == "struct"
        % Handles creating a cell array of tables from an arrow::ListArray
        % containing arrow::StructArrays.
        createList = @createListOfTables;
    else
        % Handles creating cell arrays of primitive arrays (double, string,
        % cell, etc.) from an arrow::ListArray containing all other
        % supported arrow types.
        createList = @createListOfVectors;
    end

    % Iterate over each chunk and convert the struct representing an
    % arrow::ListArray into a cell array.
    for ii = 1:numChunks
        % Convert the underlying arrow::Array into its corresponding MATLAB
        % datatype.
        values = matlab.io.arrow.internal.arrow2matlab(arrowStruct.Data(ii).Values, opts);

        % Unpack the validity bitmap into a logical array containing
        % true values at indices that correspond to the indices of null
        % elements in the arrow::ListArray.
        nullIndices = ~(matlab.io.arrow.internal.arrow2matlab(arrowStruct.Valid(ii)));
        startOffsets = arrowStruct.Data(ii).StartOffsets;

        % Create the cell array that corresponds to arrow::ListArray
        listArray = createList(startOffsets, values);

        % Set the cell elements that correspond to null elements in the
        % arrow::ListArray to the scalar <missing> value.
        listArray(nullIndices) = {missing};
        listArrayChunks{ii} = listArray;
    end

    % Vertically concatenate the chunks together into an Nx1 cell array
    listArray = vertcat(listArrayChunks{:});
end

function cellArray = createListOfTables(startOffsets, values)
    numRows = numel(startOffsets) - 1;
    cellArray = cell(numRows, 1);
    for ii = 1:numRows
        idx = startOffsets(ii) + 1:startOffsets(ii + 1);
        cellArray{ii} = values(idx, :);
    end
end

function cellArray = createListOfVectors(startOffsets, values)
    numRows = numel(startOffsets) - 1;
    cellArray = cell(numRows, 1);
    for ii = 1:numRows
        % When indexing into the values array, subsref returns a 1x0 vector
        % if these two conditions are true:
        %
        %   1. the array returned by matlab2arrow is scalar
        %
        %   2. startOffsets(ii) + 1 > startOffsets(ii + 1)
        %
        % Because of this, we need to call reshape to ensure cellArray only
        % contains column vectors.
        idx = startOffsets(ii) + 1:startOffsets(ii + 1);
        cellArray{ii} = reshape(values(idx), [], 1);
    end
end

function mustBeArrowListArrayStruct(listArrayStruct)
    import matlab.io.arrow.internal.validateStructFields

    requiredFields = ["ArrowType", "Type", "Data", "Valid"];
    validateStructFields(listArrayStruct, requiredFields);
    if listArrayStruct.ArrowType ~= "list_array"
        id = "MATLAB:io:arrow:arrow2matlab:WrongArrowType";
        error(message(id, "list_array", listArrayStruct.ArrowType));
    end
end
