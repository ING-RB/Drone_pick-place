function nestedTable = buildNestedTable(arrowStruct, opts)
%BUILDNESTEDTABLE
%   Builds a nested table from an arrow::StructArray.
%
%   Copyright 2022 The MathWorks, Inc.
    arguments
        arrowStruct(1, 1) {mustBeArrowStructStruct}
        opts(1, 1) Arrow2MatlabOptions = Arrow2MatlabOptions
    end

    import matlab.io.arrow.internal.Arrow2MatlabOptions
    import matlab.io.arrow.internal.arrow2matlab.makeUniqueVariableNames

    numChunks = numel(arrowStruct.Data);
    nestedTableChunks = cell(numChunks, 1);

    % Iterate over each chunk and convert the struct representing an
    % arrow::StructArray into a nested table.
    for ii = 1:numChunks
        chunk = arrowStruct.Data(ii);
        chunkValues = cell(1, numel(chunk.FieldData));

        for jj = 1:numel(chunk.FieldData)
            fieldData = chunk.FieldData{jj};

            fieldData.Valid = bitandValidityBitmaps(arrowStruct.Valid(ii), fieldData.Valid);

            values = matlab.io.arrow.internal.arrow2matlab(fieldData, opts);
            chunkValues{jj} = values;
        end

        nestedTableChunks{ii} = chunkValues;
    end

    % Vertically concatenate the table chunks together into one giant cell array.
    verticallyCombinedChunks = vertcat(nestedTableChunks{:});

    % Build table with default VariableNames before computing the valid
    % variable names, dimension names, and variable descriptions.
    nestedTable = table(verticallyCombinedChunks{:});

    % We use the 1st Data element here, but this is somewhat arbitrary
    % because the field names will be repeated in all Data elements.
    variableNames = convertCharsToStrings(arrowStruct.Data(1).FieldName);

    % Build the final nested table, using the struct field names as table
    % VariableNames.
    [validVariableNames, dimensionNames, variableDescriptions] = ...
        makeUniqueVariableNames(variableNames, nestedTable.Properties.DimensionNames,...
                                opts.PreserveVariableNames);

    % Set the modified dimension and variable names on the output table.
    nestedTable.Properties.DimensionNames = dimensionNames;
    nestedTable.Properties.VariableNames = validVariableNames;

    % Store original variable names in the VariableDescriptions property
    % if they were modified to use valid MATLAB table variable names.
    if ~isempty(variableDescriptions)
        nestedTable.Properties.VariableDescriptions = variableDescriptions;
    end
end

function validBitmap = bitandValidityBitmaps(structValidBitmap, fieldValidBitmap)
    if isempty(structValidBitmap.Values)
        % the struct's validity bitmap is empty.
        validBitmap = fieldValidBitmap;
    elseif isempty(fieldValidBitmap.Values)
        % the field's validity bitmap is empty.
        validBitmap = structValidBitmap;
    else
        % Both the struct's and the field's bitmaps are not empty. Bit i
        % should only be set to 1 if Bit i in the struct's bitmap and Bit i
        % in the field's bitmap are both set to 1..
        values = bitand(structValidBitmap.Values, fieldValidBitmap.Values);
        validBitmap = struct("ArrowType", 'buffer', "Length",...
                             structValidBitmap.Length, 'Values', values);
    end
end

function mustBeArrowStructStruct(structStruct)
    import matlab.io.arrow.internal.validateStructFields

    requiredFields = ["ArrowType", "Type", "Data", "Valid"];
    validateStructFields(structStruct, requiredFields);
    if structStruct.ArrowType ~= "struct"
        id = "MATLAB:io:arrow:arrow2matlab:WrongArrowType";
        error(message(id, "struct", structStruct.ArrowType));
    end
end
