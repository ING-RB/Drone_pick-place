function openAndSave(sourceFileName, destinationFile)
% openAndSave - Opens a source MATLAB code file and save as MATLAB Live Code file
%
%   openAndSave(sourceFileName, destinationFile) - open the source MATLAB code file
%   and saves to the destination Live Code file
%
%   Example:
%
%       matlab.internal.liveeditor.openAndSave(sourceFileName, destinationFile);

%   Copyright 2014-2023 The MathWorks, Inc.

validateattributes(sourceFileName, {'char'}, {'nonempty'}, mfilename, 'sourceFileName', 1)

validateattributes(destinationFile, {'char'}, {'nonempty'}, mfilename, 'destinationFile', 2)

destinationFile = matlab.internal.liveeditor.LiveEditorUtilities.resolveFileName(destinationFile);
if ~matlab.desktop.editor.EditorUtils.isLiveCodeFile(destinationFile)
    error('matlab:internal:liveeditor:save', 'Destination file must be a Live Code file.');
end

sourceFileName = matlab.internal.liveeditor.LiveEditorUtilities.resolveFileName(sourceFileName);
if ~isfile(sourceFileName)
    error('matlab:internal:liveeditor:open', 'The file "%s" must exist.', sourceFileName);
end

if matlab.desktop.editor.EditorUtils.isLiveCodeFile(sourceFileName)
    [status, msg, msgId] = copyfile(sourceFileName, destinationFile, 'f');
    assert(status == 1, msgId, strrep(msg, '\', '\\'));
    attribs = '+w';
    if ispc
        attribs = strcat(attribs, ' -h');
    end
    fileattrib(destinationFile, attribs);
else
    fileModel = matlab.internal.livecode.FileModel.convertFileToLiveCode(sourceFileName, destinationFile);
    assert(~isempty(fileModel), message('MATLAB:Editor:Document:SaveFailedUnknown', destinationFile));
end
end
