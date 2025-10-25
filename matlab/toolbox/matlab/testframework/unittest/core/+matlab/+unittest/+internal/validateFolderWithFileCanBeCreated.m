function validateFolderWithFileCanBeCreated(folder,file)
% This function is undocumented and may change in a future release.

%validateFolderWithFileCanBeCreated - Checks that a folder with file can be created in a specific location
%
% The check is performed by first attempting to create the folder if it
% doesn't already exist, and then attempting to write to an empty file to
% the folder with the same name. Afterwards, the file is removed and if the
% folder didn't already exist, the folder is removed as well. An error is
% thrown if unsuccessful.

% Copyright 2017-2024 The MathWorks, Inc.
import matlab.unittest.internal.validateFileCanBeCreated;
import matlab.unittest.internal.CancelableCleanup;
import matlab.unittest.internal.mustBeTextScalar;

folder = matlab.unittest.internal.parentFolderResolver(folder);
mustBeTextScalar(file);
file = char(file);

if isfolder(folder)
    validateFileCanBeCreated(fullfile(folder,file));
    return;
end

[canMakeFolder,msg,~] = mkdir(folder);
if ~canMakeFolder
    error(message('MATLAB:automation:io:FileIO:CouldNotCreateFolder',...
        folder,msg));
end

cleanupObj = CancelableCleanup(@() rmdir(folder));
validateFileCanBeCreated(fullfile(folder,file));
cleanupObj.cancel();

rmdir(folder);
end

% LocalWords:  unittest
