function [moveCode,msg] = variableEditorMoveColumn(this,varName,startCol,endCol)
% This function is for internal use only and will change in a
% future release.  Do not use this function.

%   Copyright 2011-2021 The MathWorks, Inc.

msg = '';
[TvarNames,varIndices] = variableEditorColumnNames(this);
if isdatetime(this.rowDim.labels) || isduration(this.rowDim.labels)
    % varIndices includes the rownames, if they are datetimes or duration.
    % This isn't needed for the move function.
    TvarNames(1) = [];
    varIndices(1) = [];
    varIndices = varIndices-1;
end

startIndex = find(varIndices<=startCol,1,'last');
endIndex = find(varIndices<=endCol,1,'last');

if endIndex >= length(varIndices) % moving to the end
    if ~isvarname(TvarNames{startIndex}) || ~isvarname(TvarNames{endIndex-1})
        moveCode = [varName ' = movevars(' varName ', ' num2str(startIndex) ', "After", ' num2str(endIndex-1) ');'];
    else
        moveCode = [varName ' = movevars(' varName ', ' '"' TvarNames{startIndex} '"' ', "After", ' '"' TvarNames{endIndex-1} '"' ');'];
    end
else
    if ~isvarname(TvarNames{startIndex}) || ~isvarname(TvarNames{endIndex})
        moveCode = [varName ' = movevars(' varName ', ' num2str(startIndex) ', "Before", '  num2str(endIndex) ');'];
    else
        moveCode = [varName ' = movevars(' varName ', ' '"' TvarNames{startIndex} '"' ', "Before", ' '"' TvarNames{endIndex} '"' ');'];
    end
    
end
