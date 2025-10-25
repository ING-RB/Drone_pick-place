function validateFolderForWrite(fullFileName)
%VALIDATEFOLDERFORWRITE - Given a full file name, check that the file
%location is writable.
%
% INPUT:
%    fullFileName {char} - full file name (with or without extension).
%    This file is in the location that will be tested for writability.

% Copyright 2020 The MathWorks, Inc.

path = fileparts(fullFileName);

% Assert that the path exists
success = fileattrib(path);

if ~success
    error(message('appmigration:appmigration:NotWritableLocation', fullFileName));
end

% Create a random folder name so no existing folders are affected
randomNumber = floor(rand*1e12);
testDirPrefix = 'appMigrationToolTempData_';
testDir = [testDirPrefix, num2str(randomNumber)];
while exist(testDir, 'dir')
    % The folder name should not match an existing folder
    % in the directory
    randomNumber = randomNumber + 1;
    testDir = [testDirPrefix, num2str(randomNumber)];
end

% Attempt to write a folder in the save location
isWritable = mkdir(path, testDir);
if ~isWritable
    error(message('appmigration:appmigration:NotWritableLocation', fullFileName));
end

status = rmdir(fullfile(path, testDir));
if status ~=1
    warning(message('appmigration:appmigration:TempFolderWarning',fullfile(path, testDir)));
end

end