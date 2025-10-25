function validateFileCanBeCreated(fileName)
% This function is undocumented and may change in a future release.

%validateFileCanBeCreated - Checks that a file can be created in a specific location
%
% The check is performed by trying to write an empty file to the location
% with the same name and then deleting it. An error is thrown if unsuccessful.

% Copyright 2016-2024 The MathWorks, Inc.

fileName = matlab.unittest.internal.parentFolderResolver(fileName);

parentFolder = fileparts(fileName);

% Check that directory is readable. If the directory is not
% readable then dir is empty and does not even return '.' or '..'.
if isempty(dir(parentFolder))
    error(message('MATLAB:automation:io:FileIO:CouldNotWriteToFileUnreadableDirectory',...
        fileName,parentFolder));
end

% Check that we can create a dummy file with the same name
[fid,errMsg] = fopen(fileName,'w+');
if fid < 1
    error(message('MATLAB:automation:io:FileIO:CouldNotWriteToFile',...
        fileName,errMsg));
end
fclose(fid);

% Remove the dummy file
delete(fileName);
end

% LocalWords:  unittest
