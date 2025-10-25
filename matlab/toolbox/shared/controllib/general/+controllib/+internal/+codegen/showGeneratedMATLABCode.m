function showGeneratedMATLABCode(str,SmartIndent)
% SHOWGENERATEDMATLABCODE
%
% Generates matlab code in the editor given STR. STR can be either cell
% array of strings or string. SmartIndent is true or false.

% Copyright 2008-2020 The MathWorks, Inc.

if nargin<2
    SmartIndent = true;
end

if iscell(str)
    str = controllib.internal.codegen.cellstr2char(str);
end

% Throw to command window if editor is not available. Note
% matlab.desktop.editor.* is supported in MOTW.
if matlab.desktop.editor.isEditorAvailable
    % Convert to char array, add line endings
    editorDoc = matlab.desktop.editor.newDocument(str);
    if SmartIndent
        editorDoc.smartIndentContents;
    end
    % Scroll document to line 1
    editorDoc.goToLine(1);
else
    disp(str);
end
end