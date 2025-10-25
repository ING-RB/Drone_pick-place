function [sortCode,msg] = variableEditorSortCode(~,varName,columnIndexStrings,direction, missingPlacement)
% These functions are for internal use only and will change in a
% future release.  Do not use this function.

% Generate MATLAB command to sort categorical variables. The direction input
% is true for ascending sorts, false otherwise.

%   Copyright 2013-2021 The MathWorks, Inc.
arguments
    ~
    varName
    columnIndexStrings
    direction
    missingPlacement  {mustBeMember(missingPlacement,["auto","first","last"])} = "auto"
end
msg = '';
% Create an array of column indices, e.g., [1 3 5]
if iscell(columnIndexStrings)
    %     columnIndexExpression = '[';
    %     for k=1:length(columnIndexStrings)-1
    %         columnIndexExpression = sprintf('%s%s,',columnIndexExpression,columnIndexStrings{k});
    %     end
    %     columnIndexExpression = sprintf('%s%s]',columnIndexExpression,columnIndexStrings{end});
    columnIndexExpression = ['[' strjoin(columnIndexStrings,' ') ']'];
else
    columnIndexExpression = columnIndexStrings;
end

 missingPlacementSyntax = '';
 if ~strcmp(missingPlacement, "auto")
    missingPlacementSyntax = [',"MissingPlacement","' char(missingPlacement) '"'];
 end

% varSubIndexExpression = [varName '(:,' columnIndexExpression ')'];
% if direction
%     sortCode = [varSubIndexExpression ' = sortrows(' varSubIndexExpression ',1,''ascend'');'];
% else
%     sortCode = [varSubIndexExpression ' = sortrows(' varSubIndexExpression ',1,''descend'');'];
% end
if direction
    sortCode = [varName ' = sortrows(' varName ',' columnIndexExpression missingPlacementSyntax ');'];
else
    sortCode = [varName ' = sortrows(' varName ',-' columnIndexExpression missingPlacementSyntax ');'];
end
