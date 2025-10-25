function structArrayStruct = buildStructStruct(tabularArray)
%BUILDSTRUCTSTRUCT Builds a 1x1 struct array used to convert nested tables
%into arrow::StructArrays.

% Copyright 2022 The MathWorks, Inc.

    import matlab.io.arrow.internal.matlab2arrow
    import matlab.io.arrow.internal.matlab2arrow.bitPackLogical
    import matlab.io.internal.arrow.error.ExceptionType
    import matlab.io.internal.arrow.error.ExceptionFactory
    import matlab.io.internal.arrow.error.appendDotIndexOperation

    dataStruct = struct("FieldName", [], "FieldData", [], "NestedLevel", []);

    % If the input is a timetable, always write the RowTimes to the file.
    % If the input is a table, write the RowNames if they are not empty.
    writeRowLabels = hasRowLabels(tabularArray);


    % Store the VariableNames + RowNamesLabel (if required) in a cellstr.
    % These values correspond to the arrow::StructArray's field names.
    if writeRowLabels
        dataStruct.FieldName = [getRowLabelName(tabularArray) getVariableNames(tabularArray)];
    else
        dataStruct.FieldName = [getVariableNames(tabularArray)];
    end

    numFields = width(tabularArray) + double(writeRowLabels);

    % Cannot convert tables with zero variables and zero row names
    % to arrow StructArrays.
    if numFields == 0
        ExceptionFactory.throw(ExceptionType.ZeroVariableTable);
    end

    dataStruct.FieldData = cell(numFields, 1);

    % Store the RowNames or RowTimes if required.
    if writeRowLabels
        dataStruct.FieldData{1} = matlab2arrow(getRowLabels(tabularArray));
    end

    % currFieldIndex is 2 if input is a timetable or if RowNames is not empty.
    currFieldIndex = 1 + double(writeRowLabels);
    numVariables = width(tabularArray);

    % Recursively call matlab2arrow on each Variable in the
    % table/timetable.
    nestedLevel = 1;
    for ii = 1:numVariables
        try
            dataStruct.FieldData{currFieldIndex} = matlab2arrow(tabularArray.(ii));
        catch ME
            % Get the variable name from dataStruct instead of tabularArray
            % because tabularArray may be a TableWrapper.
            appendDotIndexOperation(ME, string(dataStruct.FieldName{currFieldIndex}));
        end

        innerArrowType = dataStruct.FieldData{ii}.ArrowType;
        currFieldIndex = currFieldIndex + 1;
        if innerArrowType == "list_array" || innerArrowType == "struct"
            innerNestedLevel = dataStruct.FieldData{ii}.Data.NestedLevel;
            nestedLevel = max(innerNestedLevel, nestedLevel) + 1;
            if nestedLevel > 125
                ExceptionFactory.throw(ExceptionType.ExceedsMaxNestingLevel);
            end
        end
    end

    % Store the max number of times matlab2arrow was called when
    % deconstructing the nested table variables. Required because there is
    % a bug in Arrow.
    dataStruct.NestedLevel = nestedLevel;

    % Using bitPackLogical to get the valid struct with the expected
    % fields. It's not possible to write out null struct elements to
    % parquet from MATLAB.
    validStruct = bitPackLogical(logical.empty(0, 1));
    structArrayStruct = struct("ArrowType", 'struct', "Type", 'struct', ...
                               "Data", dataStruct, "Valid", validStruct);
end

function tf = hasRowLabels(tabularArray)
    tf = false;
    if isa(tabularArray, "matlab.io.internal.arrow.list.TabularWrapper")
        % Must use dot notation to invoke the hasRowLabels() method.
        % Local functions have higher precedence than object functions, so
        % hasRowLabels(tabularArray) would invoke the current function
        % again. Using dot notation bypasses this problem.
        tf = tabularArray.hasRowLabels();
    elseif istimetable(tabularArray)
        tf = true;
    elseif ~isempty(tabularArray.Properties.RowNames)
        tf = true;
    end
end

function name = getRowLabelName(tabularArray)
    if isa(tabularArray, "matlab.io.internal.arrow.list.TabularWrapper")
        % Must use dot notation to invoke the getRowLabelName() method.
        % Local functions have higher precedence than object functions, so
        % getRowLabelName(tabularArray) would invoke the current function
        % again. Using dot notation bypasses this problem.
        name = tabularArray.getRowLabelName();
    else
        name = tabularArray.Properties.DimensionNames{1};
    end
end

function labels = getRowLabels(tabularArray)
    if isa(tabularArray, "matlab.io.internal.arrow.list.TabularWrapper")
        % Must use dot notation to invoke the getRowLabels() method.
        % Local functions have higher precedence than object functions, so
        % getRowLabels(tabularArray) would invoke the current function
        % again. Using dot notation bypasses this problem.
        labels = tabularArray.getRowLabels();
    elseif istimetable(tabularArray)
        labels = tabularArray.Properties.RowTimes;
    else
        labels = tabularArray.Properties.RowNames;
    end
end

function varNames = getVariableNames(tabularArray)
    if isa(tabularArray, "matlab.io.internal.arrow.list.TabularWrapper")
        % Must use dot notation to invoke the getVariableNames() method.
        % Local functions have higher precedence than object functions, so
        % getVariableNames(tabularArray) would invoke the current function
        % again. Using dot notation bypasses this problem.
        varNames = tabularArray.getVariableNames();
    else
        varNames = tabularArray.Properties.VariableNames;
    end
end
