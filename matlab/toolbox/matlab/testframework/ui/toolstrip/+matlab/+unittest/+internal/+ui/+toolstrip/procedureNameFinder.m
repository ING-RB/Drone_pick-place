function procedureName = procedureNameFinder(fileText,filename,cursorRowStart,cursorColumnStart,cursorRowEnd,cursorColumnEnd)
% This function is undocumented and may change in a future release.

% Copyright 2019-2020 The MathWorks, Inc.

import matlab.unittest.internal.ui.toolstrip.getSelectedTestProcedureNames;

if(isequal(cursorRowStart,-1))
    procedureName = cell(1,0);
else
    indexOfAllnewLines = [1;regexp(fileText,'[\n]').'];
    cursorPositionStart = (indexOfAllnewLines(cursorRowStart) + cursorColumnStart);
    cursorPositionEnd = indexOfAllnewLines(cursorRowEnd) + cursorColumnEnd;
    procedureName = getSelectedTestProcedureNames(filename,cursorPositionStart,cursorPositionEnd);
end