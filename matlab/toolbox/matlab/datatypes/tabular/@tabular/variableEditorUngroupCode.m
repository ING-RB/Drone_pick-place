function [ungroupCode,msg] = variableEditorUngroupCode(this,varName,col)
% This function is for internal use only and will change in a
% future release.  Do not use this function.

% Generate MATLAB command to ungroup variables in column position defined
% by the input variabe col.

%   Copyright 2011-2020 The MathWorks, Inc.

msg = '';
[tableVarNames, varIndices] = variableEditorColumnNames(this);
if isdatetime(this.rowDim.labels) || isduration(this.rowDim.labels)
    % colNames, varIndices and colClasses include the rownames, if they are
    % datetimes or duration.  
    varIndices(1) = [];
    tableVarNames(1) = [];
    varIndices = varIndices-1;
    col = col-1;
end

index = find(varIndices(1:end-1)<=col,1,'last');

if isvarname(tableVarNames{index})
    ungroupCode = [varName ' = splitvars(' varName ', ''' tableVarNames{index} ''');'];
else
    ungroupCode = [varName ' = splitvars(' varName ', ' num2str(index) ');'];
end
