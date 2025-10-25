function editorObj = openAndGoToOffset(fileName, startPosition, selectionLength)
%matlab.desktop.editor.openAndGoToOffset Open file and highlight selection.
%   EDITOROBJ = matlab.desktop.editor.openAndGoToOffset(FILENAME, STARTPOSITION, SELECTIONLENGTH)
%   opens FILENAME in the MATLAB Editor, highlights the selection, and 
%   creates a Document object. FILENAME must include the full path, 
%   otherwise a MATLAB:Editor:Document:PartialPath exception is thrown.
%
%   If FILENAME does not exist, MATLAB returns an empty Document array.
%   This function supports scalar arguments only, and does not display
%   any dialog boxes.
%
%   See also matlab.desktop.editor.openDocument,
%   matlab.desktop.editor.openAndGoToFunction,
%   matlab.desktop.editor.Document/goToLine.

%   Copyright 2020-2022 The MathWorks, Inc.

    fileName = convertStringsToChars(fileName);

    matlab.desktop.editor.EditorUtils.assertChar(fileName, 'FILENAME');
    matlab.desktop.editor.EditorUtils.assertNumericScalar(startPosition, 'STARTPOSITION');
    matlab.desktop.editor.EditorUtils.assertLessEqualInt32Max(startPosition, 'STARTPOSITION');
    matlab.desktop.editor.EditorUtils.assertNumericScalar(selectionLength, 'SELECTIONLENGTH');
    matlab.desktop.editor.EditorUtils.assertLessEqualInt32Max(selectionLength, 'SELECTIONLENGTH');

    editorObj = matlab.desktop.editor.openDocument(fileName);
        
    if ~isempty(editorObj)
        [startLine, startColumn] = matlab.desktop.editor.indexToPositionInLine(editorObj, startPosition, 'AcknowledgeLineEnding', 1);
        [endLine, endColumn] = matlab.desktop.editor.indexToPositionInLine(editorObj, startPosition+selectionLength, 'AcknowledgeLineEnding', 1);

        editorObj.Selection = [startLine, startColumn, endLine, endColumn];
    end
end
