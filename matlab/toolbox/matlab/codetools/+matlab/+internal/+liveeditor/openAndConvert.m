function openAndConvert(sourceFileName, destinationFile, varargin)
% openAndConvert - Opens a source MATLAB Rich Code file and convert file
%
%   openAndSave(sourceFileName, destinationFile) - open the source Live Code file
%   and convert to the destination file
%
%   Example:
%
%       matlab.internal.liveeditor.openAndConvert(liveCodeFileName, htmlFileName);

%   Copyright 2015-2023 The MathWorks, Inc.

validateattributes(sourceFileName, {'char'}, {'nonempty'}, mfilename, 'sourceFileName', 1);

validateattributes(destinationFile, {'char'}, {'nonempty'}, mfilename, 'destinationFile', 2);

destinationFile = matlab.internal.liveeditor.LiveEditorUtilities.resolveFileName(destinationFile);
if matlab.desktop.editor.EditorUtils.isLiveCodeFile(destinationFile)
    error('matlab:internal:liveeditor:save', 'Destination file must not be a Live Code file.');
end

sourceFileName = matlab.internal.liveeditor.LiveEditorUtilities.resolveFileName(sourceFileName);
if ~isfile(sourceFileName)
    error('matlab:internal:liveeditor:open', 'The file "%s" must exist.', sourceFileName);
end

editorObj = matlab.desktop.editor.openDocument(sourceFileName, 'Visible', 0);
cleanup = onCleanup(@() editorObj.closeNoPrompt);

matlab.desktop.editor.EditorUtils.assertOpen(editorObj, 'DOCUMENT');

matlab.desktop.editor.internal.exportDocumentByID( ...
    editorObj.Editor.RtcId,...
    'Destination', destinationFile,...
    varargin{:});
end