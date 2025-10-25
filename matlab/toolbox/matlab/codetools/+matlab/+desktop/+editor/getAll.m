function objs = getAll
%matlab.desktop.editor.getAll Find all open Editor Documents.
%   EDITOROBJS = matlab.desktop.editor.getAll returns an array of Document
%   objects corresponding to all open documents in the MATLAB Editor. The order
%   of Document objects in array is not guaranteed and might differ from the order
%   of open document tabs or sequence of the opening of the documents.
%
%   Example: List the file names of all open documents.
%
%      allDocs = matlab.desktop.editor.getAll;
%      allDocs.Filename
%
%   See also matlab.desktop.editor.Document, matlab.desktop.editor.findOpenDocument,
%   matlab.desktop.editor.getActive, matlab.desktop.editor.openDocument.

%   Copyright 2008-2020 The MathWorks, Inc.

assertEditorAvailable;

objs = matlab.desktop.editor.Document.getAllOpenEditors;

end