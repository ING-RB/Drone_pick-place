function t = buildTable(tableStruct, opts, assembleTable)
%BUILDTABLE
%   Helper function that converts an struct representing an arrow::Table
%   into a MATLAB table.
%
% TABLESTRUCT is a 1x1 struct.
%
% TABLESTRUCT contains the following fields:
%
% Field Name    Class          Description
% ----------    ----------     -------------------------------------------
% ArrowType     char           Must be 'table'.
% Names         cellstr        Names of the table variables.
% Columns       Nx1 struct     A N by 1 struct array in which each struct
%                              represents one column in the table.


%   Copyright 2021 The MathWorks, Inc.

    arguments
        tableStruct (1,1) struct {mustBeArrowTableStruct}
        opts(1, 1) Arrow2MatlabOptions = Arrow2MatlabOptions
        assembleTable(1, 1) logical = true
    end

    import matlab.io.arrow.internal.Arrow2MatlabOptions
    import matlab.io.arrow.internal.validateStructFields
    import matlab.io.arrow.internal.arrow2matlab.makeUniqueVariableNames

    columns = tableStruct.Columns;
    numVariables = numel(columns);

    % Unmarshal each struct array corresponding to a variable in the table.
    unpackedArray = cell(1, numVariables);
    for index = 1:numVariables
        opts.TableVariableName = tableStruct.Names{index};
        unpackedArray{index} = matlab.io.arrow.internal.arrow2matlab(columns(index), opts);
    end
    
    % Exit early if the table does not need to be assembled. This occurs
    % when TableBuilder is used by parquetread2 to assemble tables.
    if ~assembleTable
        t = unpackedArray;
        return;
    end

    % Construct the table directly using the table constructor for better performance
    % when converting Arrow tables with a large number of columns.
    t = table(unpackedArray{:});
    
    % Compute unique, valid VariableNames and DimensionNames for the output
    % table.
    variableNames = convertCharsToStrings(tableStruct.Names);
    dimensionNames = t.Properties.DimensionNames;
    [variableNames, dimensionNames, variableDescriptions] = ...
        makeUniqueVariableNames(variableNames, dimensionNames, opts.PreserveVariableNames);
    
    % Set the modified dimension and variable names on the output table.
    t.Properties.DimensionNames = dimensionNames;
    t.Properties.VariableNames = variableNames;
    
    % Store original variable names in the VariableDescriptions property
    % if they were modified to use valid MATLAB table variable names.
    if ~isempty(variableDescriptions)
        t.Properties.VariableDescriptions = variableDescriptions;
    end
end

function mustBeArrowTableStruct(tableStruct)
    import matlab.io.arrow.internal.validateStructFields

    requiredFields = ["ArrowType", "Names", "Columns"];
    validateStructFields(tableStruct, requiredFields);
    if tableStruct.ArrowType ~= "table"
        id = "MATLAB:io:arrow:arrow2matlab:WrongArrowType";
        error(message(id, "table", tableStruct.ArrowType));
    end
end
