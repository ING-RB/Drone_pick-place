function openStatus = isOpen(filename)
%matlab.desktop.editor.isOpen Determine if specified file is open in Editor.
%   OPENSTATUS = matlab.desktop.editor.isOpen(FILENAME) returns logical
%   TRUE when the file FILENAME is open in the MATLAB Editor. Otherwise, it
%   returns FALSE. The FILENAME input must include the full path.
%
%   Example: Open fft.m in the Editor, and then check that it is open.
%   Close it, and then check that it is closed.
%
%      fftPath = which('fft.m');
%
%      % Open file, and then check if open:
%      fftDoc = matlab.desktop.editor.openDocument(fftPath);
%      check_fft = matlab.desktop.editor.isOpen(fftPath)
%
%      % Close file, and then check if closed:
%      fftDoc.close;
%      check_fft = matlab.desktop.editor.isOpen(fftPath)
%
%   See also matlab.desktop.editor.Document, matlab.desktop.editor.Document.Opened,
%   matlab.desktop.editor.openDocument.

%   Copyright 2009-2021 The MathWorks, Inc.

assertEditorAvailable;

filename = convertStringsToChars(filename);

matlab.desktop.editor.EditorUtils.assertChar(filename, 'FILENAME');
assert(matlab.desktop.editor.EditorUtils.isAbsolute(filename), ...
    message('MATLAB:Editor:Document:NotAbsolutePath'));
obj = matlab.desktop.editor.Document.findEditor(filename);
openStatus = false;
if ~isempty(obj)
    openStatus = obj.Opened;
else
end
