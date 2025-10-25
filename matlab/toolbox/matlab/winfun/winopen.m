function winopen(filename)
%WINOPEN Open a file or directory using Microsoft Windows.
%   WINOPEN FILENAME opens the file or directory FILENAME using the
%   appropriate Microsoft Windows shell command, based on the file type and
%   extension.
%   This function behaves as if the you had double-clicked on the file
%   or directory inside of the Windows Explorer.
%
%   Examples:
%
%     If you have Microsoft Word installed, then
%     winopen('c:\myinfo.doc')
%     opens that file in Microsoft Word if the file exists, and errors if
%     it doesn't.
%
%     winopen('c:\')
%     opens a new Windows Explorer window, showing the contents of your C
%     drive.
%   
%   See also OPEN, DOS, WEB.
  
%   Copyright 1984-2025 The MathWorks, Inc.

if ~ispc
    error(message('MATLAB:winopen:PcOnly'));
end

narginchk(1,1);

filename = convertStringsToChars(filename);

if ~ischar(filename)
    error(message('MATLAB:string:MustBeSingleString', getString(message('MATLAB:string:Input'))));
end

if ~exist(filename,'file')
    error(message('MATLAB:winopen:FileNotFound'));
end

%On Vista and Windows7, we can no longer pass in a path with forward
%slashes.
filename = strrep(filename, '/', '\');

pathstr = '';
if ~isfolder(filename)
    fullfilename = matlab.io.internal.validators.validateFileName(filename);
    [pathstr, name, extension] = fileparts(fullfilename{1});
    filename = [name extension];
end

matlab.internal.winfun.winopenbuiltin(pathstr, filename);