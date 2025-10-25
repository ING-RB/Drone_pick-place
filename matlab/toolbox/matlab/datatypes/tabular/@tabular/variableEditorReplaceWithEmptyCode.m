function [str,msg] = variableEditorReplaceWithEmptyCode(tabularData,varname, row, col, rowStr, colStr)
% This function is for internal use only and will change in a
% future release.  Do not use this function.

% Generate MATLAB command replace contents of a table variable with it's
% empty value

%   Copyright 2022-2024 The MathWorks, Inc.
arguments
    tabularData
    varname
    row
    col
    rowStr string = []
    colStr string = []
end

% RowStr is a formatted string containing the row indexing. For e.g.
% '1:2,5:6,8:end'.
if isempty(rowStr)
    if isscalar(row)
        rowStr = num2str(row);
    else
        rowStr = strjoin(compose("%d:%d",row), ',');
    end
end
msg = '';

[colNames,varIndices,colClasses] = variableEditorColumnNames(tabularData);

if isdatetime(tabularData.rowDim.labels) || isduration(tabularData.rowDim.labels)
    % colNames, varIndices and colClasses include the rownames, if they are
    % datetimes or duration.  These aren't needed for the replaceWithEmptyCode function.
    colNames(1) = [];
    varIndices(1) = [];
    varIndices = varIndices-1; %#ok<NASGU>
    colClasses(1) = [];
    % col also includes the time column, so decrement it
    col = col-1;
end

% If more than one col is specified, take the first column alone into
% account
if length(col) > 1
    col = col(1);
end
sz = size(tabularData,2);
if col> sz
    col = sz;
end

% The indices passed in are already to the left of the table col (accounted
% for grouped col indices)
j = col;

import matlab.internal.tabular.generateDotSubscripting
colname = colNames{j};
vardata = tabularData.data{j};
% Assign rhs to be the empty value replacement for different datatypes.
if iscategorical(vardata)
    rhs = "'" +string(categorical.undefLabel) + "'";
elseif isstring(vardata)
    rhs = "missing";
elseif isdatetime(vardata)
    rhs = "NaT";
elseif iscellstr(vardata)
    rhs = "{''}";
elseif colClasses{j} == "cell"
    rhs = "{[]}";
elseif colClasses{j} == "double" || ...
        islogical(vardata) || ... 
        strncmp(colClasses{j}, 'uint', 4) || ...
        strncmp(colClasses{j}, 'int', 3) || ...
        isduration(vardata) || iscalendarduration(vardata)
    rhs = "0";
else
    rhs = "[]";
end
% Currently grouped columns are all edited as once.
% TODO: Add Ability to replace individual subcolumns within a grouped column
dotSubsStr = generateDotSubscripting(tabularData,colname, varname);
dotSubsStr = strjoin(string(dotSubsStr), '');
if colClasses{j} == "char"
    % Need to get all the content of the value at the specified row
    % to replace with empty value.
    [~, columns] = size(tabularData.dotReference(colname));
    str =  dotSubsStr + "(" + num2str(rowStr) + ",1:" + num2str(columns) + ") = 0;";
elseif ~isempty(colStr)
    str =  dotSubsStr + "("  + num2str(rowStr) + "," + num2str(colStr) + ") = " + rhs + ";";
else
    str =  dotSubsStr + "("  + num2str(rowStr) + ") = " + rhs + ";";
end
