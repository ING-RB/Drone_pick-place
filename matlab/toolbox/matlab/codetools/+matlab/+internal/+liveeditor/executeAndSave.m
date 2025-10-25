function executionTime = executeAndSave(fileName)
% executeAndSave - executes and saves the file
%
%   executeAndSave(fileName) - executes the Live Code file and saves the results into
%   the Live Code file 
%
%   Example:
%
%       matlab.internal.liveeditor.executeAndSave(liveCodeFileName);

%   Copyright 2014-2023 The MathWorks, Inc.

validateattributes(fileName, {'char'}, {'nonempty'}, mfilename, 'FileName', 1)

if ~(matlab.desktop.editor.EditorUtils.isLiveCodeFile(fileName))
    error('matlab:internal:liveeditor:executeAndSave', 'FileName must be a MLX file.');
end

fileName = matlab.internal.liveeditor.LiveEditorUtilities.resolveFileName(fileName);
if ~isfile(fileName)
    error('matlab:internal:liveeditor:open', 'The file "%s" must exist.', fileName);
end

editorObj = matlab.desktop.editor.openDocument(fileName, 'Visible', 0);
cleanup = onCleanup(@() editorObj.closeNoPrompt);
fileNameToExecute = editorObj.Filename;
executionTime = matlab.internal.liveeditor.LiveEditorUtilities.execute(editorObj.Editor.RtcId, fileNameToExecute);
editorObj.save;
end
