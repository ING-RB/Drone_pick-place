function procedureName = getTestProcedureNames(filename)
% The getTestProcedureNames function allows the user to use a filename
% to obtain one or more procedure names, based on where the user places the
% mouse cursor or if the user selects more than one test function.

% Copyright 2019 The MathWorks, Inc.

import matlab.unittest.internal.ui.toolstrip.procedureNameFinder;

editorObj = matlab.desktop.editor.findOpenDocument(filename);
extendedSelection = editorObj.ExtendedSelection;
cursorRowStart = extendedSelection(:, 1);
cursorColumnStart = extendedSelection(:, 2);
cursorRowEnd = extendedSelection(:, 3);
cursorColumnEnd = extendedSelection(:, 4);
procedureName = procedureNameFinder(editorObj.Text,filename,cursorRowStart,cursorColumnStart,cursorRowEnd,cursorColumnEnd);
end