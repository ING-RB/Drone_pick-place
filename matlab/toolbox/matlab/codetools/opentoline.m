function opentoline(fileName, lineNumber, columnNumber)
%OPENTOLINE Open to specified line in function file in Editor
%   This function is unsupported and might change or be removed without
%   notice in a future version.
%
%   OPENTOLINE(FILENAME, LINENUMBER, COLUMN)
%   LINENUMBER the line to scroll to in the Editor. The absolute value of
%   this argument will be used.
%   COLUMN argument is optional. If it is not present, the whole line
%   will be selected.
%
%   Note: A tab character is treated as a single character position within
%   a line. Therefore, the position within a line might differ from the
%   column number displayed in the Editor status bar.
%
%   See also matlab.desktop.editor.openAndGoToLine, matlab.desktop.editor.openAndGoToFunction.

%   Copyright 1984-2024 The MathWorks, Inc.

    %% Throw error if backend is not supported
    if isUnsupported
        nse = connector.internal.notSupportedError;
        nse.throwAsCaller;
    end

    %% Check if an external editor is set and open accordingly
    s = settings;
    if ~s.matlab.editor.UseMATLABEditor.ActiveValue
        edit(fileName);
        return;
    end

    lineNumber = abs(lineNumber); % dbstack uses negative numbers for "after"

    selectLine = (nargin == 2);

    if selectLine
        columnNumber = 1;
    end

    matlab.desktop.editor.EditorUtils.assertPositiveLessEqualInt32Max(lineNumber, 'LINE');
    matlab.desktop.editor.EditorUtils.assertPositiveLessEqualInt32Max(columnNumber, 'COLUMN');

    %% First check if there is for an editor that is open. (supports unsaved buffers)
    foundEditor = findOpenDocument(fileName);
    if ~isempty(foundEditor)
        foundEditor.makeActive;
        goToLineColumn(foundEditor, lineNumber, columnNumber, selectLine);
        return;
    end

    %% Otherwise, try and open a new editor for this file

    % complete the path if it is not absolute
    if ~matlab.desktop.editor.EditorUtils.isAbsolute(fileName)
        % resolve the filename to the current folder if a partial path is provided.
        fileName = fullfile(pwd, fileName);
    end

    if ~isfile(fileName)
        return;
    end

    %% Determine if there are any file type specific handlers
    openAction = matlab.codetools.internal.getActionForFileType(fileName, 'opentoline');

    if ~isempty(openAction)
        feval(openAction, fileName, lineNumber, columnNumber, selectLine);
        return;
    end

    %% No specific handlers found - open the editor
    editorObj = matlab.desktop.editor.openDocument(fileName);

    % go to a line and a column, if fileName exists
    goToLineColumn(editorObj, lineNumber, columnNumber, selectLine);
end

function foundDoc = findOpenDocument(fileName)
    canonicalFilename = matlab.desktop.editor.EditorUtils.getCanonicalPath(fileName);
    isFilenameCanonicalized = ~strcmp(fileName, canonicalFilename);
    foundDoc = [];
    docs = matlab.desktop.editor.getAll();
    for c = 1:numel(docs)
        if (isFilenameCanonicalized && strcmp(canonicalFilename, docs(c).Filename)) ...
                || strcmp(fileName, docs(c).Filename)
            foundDoc = docs(c);
            return;
        end
    end
end

function goToLineColumn(editorObj, lineNumber, columnNumber, selectLine)
    if (~isempty(editorObj))
        editorObj.goToPositionInLine(lineNumber, columnNumber);
        if selectLine
            editorObj.Selection = [lineNumber 1 lineNumber Inf];
        end
    end
end

function tf = isUnsupported
    tf = matlab.desktop.editor.internal.useConnectorEditorService ...
        || startsWith(connector.internal.getClientType(), 'mss', 'IgnoreCase', true);
end