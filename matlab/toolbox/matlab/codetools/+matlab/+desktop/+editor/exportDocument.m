function result = exportDocument(document, varargin)
%matlab.desktop.editor.exportDocument exports an opened Document to a specific format.
% DOCUMENT has to be a matlab.desktop.editor.Document (opened in JavaScript
% based editor).
%   If this function is called with just two arguments, the second is
%   interpeted as the target file path. Otherwise, the arguments are
%   expected as name/Value pairs.
%   
%   FILEPATH = matlab.desktop.editor.exportDocument(DOCUMENT, FILEPATH) exports the
%   given DOCUMENT to the file given by FILEPATH. The export format is guessed from
%   the FILEPATH.
%
%   RESULT = matlab.desktop.editor.exportDocument(DOCUMENT, VARARGIN) exports the
%   given DOCUMENT to a target specified by given options.
%   VARARGIN is a sequence of name/value pairs where at least either 'Format' or
%   'Destination' (or both) must be specified.
%   See individual exporters in matlab.desktop.editor.export.* for supported options and return values.
%
% Examples:
%    doc = matlab.desktop.editor.openDocument('path/to/livescript.mlx')
%    filePath = exportDocument(doc, 'path/to/file.html')
%    filePath = exportDocument(doc, "path/to/file.tex")
%    filePath = exportDocument(doc, 'Destination', 'path/To/file.pdf', 'LaunchFile', true)
%    filePath = exportDocument(doc, 'Format', 'tex', 'Destination', "path/To/file.txt")
%    htmlString = exportDocument(doc, 'Format', 'html')

%   Copyright 2020 The MathWorks, Inc.

    matlab.desktop.editor.EditorUtils.assertScalar(document);

    matlab.desktop.editor.EditorUtils.assertOpen(document, 'DOCUMENT');

    if ~matlab.desktop.editor.EditorUtils.isLiveCodeFile(document.Filename)
        error('This function does not yet support exporting file types other than .mlx.');
    end

    result = matlab.desktop.editor.internal.exportDocumentByID(document.Editor.RtcId, varargin{:});
end
