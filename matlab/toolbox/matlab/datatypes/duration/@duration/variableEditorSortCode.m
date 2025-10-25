function [out,warnmsg] = variableEditorSortCode(~, varName, columnIndexStrings, direction, missingPlacement)
% This function is for internal use only and will change in a
% future release.  Do not use this function.

% Generate MATLAB command to sort duration rows. The direction input
% is true for ascending sorts, false otherwise.

% Copyright 2014-2021 The MathWorks, Inc.
arguments
    ~
    varName
    columnIndexStrings
    direction
    missingPlacement  {mustBeMember(missingPlacement,["auto","first","last"])} = "auto"
end
warnmsg = '';
if iscell(columnIndexStrings)
    columnIndexExpression = ['[' strjoin(columnIndexStrings,' ') ']'];
else
    columnIndexExpression = columnIndexStrings;
end
missingPlacementSyntax = '';
if ~strcmp(missingPlacement, "auto")
   missingPlacementSyntax = [',"MissingPlacement","' char(missingPlacement) '"'];
end

if direction
    out = [varName ' = sortrows(' varName ',' ...
        columnIndexExpression missingPlacementSyntax ');'];
else
    out = [varName ' = sortrows(' varName ',-' ...
        columnIndexExpression missingPlacementSyntax ');'];
end
