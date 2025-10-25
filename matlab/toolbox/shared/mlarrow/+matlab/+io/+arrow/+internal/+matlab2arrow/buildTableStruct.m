function tableStruct = buildTableStruct(t)
%BUILDTABLESTRUCT
%   Builds the struct array used to represent a table in the C++
%   layer.
%
% STRUCTARRAY is a N x 1 struct array.
%
% STRUCTARRAY contains the following fields:
%
% Field Name    Class      Description
% ----------    ------     ----------------------------------------------
% Columns       struct     N by 1 struct array where each struct represents
%                          one column of the table.
% Names         char       A cellstr of the table's column names
% ArrowType     char       Always set to 'table'

    import matlab.io.internal.arrow.error.appendDotIndexOperation

    columnStructArray = struct("ArrowType", {}, "Type", {},...
                               "Valid", {}, "Data", {});

    tableType = class(t);
    if tableType == "timetable"
        rowLabelsName = "RowTimes";
    else
        rowLabelsName = "RowNames";
    end

    numColumns = width(t);
    currColumnStructIndex = numColumns;
    columnNames = t.Properties.VariableNames;
    % If RowNames or RowTimes exist, then convert them
    % into "ordinary" variables.
    if istimetable(t) || ~isempty(t.Properties.(rowLabelsName))
        currColumnStructIndex = numColumns + 1;
        marshaled_array = matlab.io.arrow.internal.matlab2arrow(t.Properties.(rowLabelsName));
        columnStructArray(1, :) = marshaled_array;
        columnNames = [t.Properties.DimensionNames(1) columnNames];
    end

    % Iterate over each variable in the table, extracting the underlying
    % array data. Iterate in reverse to avoid constant reallocating of the
    % columns struct array
    for idx = numColumns:-1:1
        data = t.(idx);

        % marshal the underlying data to the corresponding unpacked_array.
        try
            columnStructArray(currColumnStructIndex, 1) = ...
                matlab.io.arrow.internal.matlab2arrow(data);
        catch ME
            appendDotIndexOperation(ME, string(columnNames{currColumnStructIndex}));
        end

        currColumnStructIndex = currColumnStructIndex - 1;
    end

    tableStruct.ArrowType = 'table';
    tableStruct.Names = columnNames;
    tableStruct.Columns = columnStructArray;
end
