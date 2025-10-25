function fullFileOrFolder = parentFolderResolver(fileOrFolder)
% This function is undocumented and may change in a future release.

% This function validates that the parent folder of the provided file or
% folder exists and resolves the provided file to a full path. Note that
% the relative file or folder itself does not need to exist.

%  Copyright 2017-2022 The MathWorks, Inc.
import matlab.automation.internal.mustBeTextScalar;

mustBeTextScalar(fileOrFolder);
fileOrFolder = char(fileOrFolder);

if exist(fileOrFolder,'dir')==7 %Needed to resolve '..'
    [isAvailableFromPWD,folderInfo] = fileattrib(fileOrFolder);
    if isAvailableFromPWD
        fileOrFolder = folderInfo.Name;
    end
end

if ~strcmp(fileOrFolder,filesep)
    fileOrFolder = strip(fileOrFolder,'right',filesep);
end

[parentFolder, remainingPart1, remainingPart2] = fileparts(fileOrFolder);
if isempty(parentFolder)
    parentFolder = '.';
end

if ~endsWith(parentFolder,filesep)
    parentFolder = [parentFolder, filesep];
end

parentFolder = matlab.automation.internal.folderResolver(parentFolder);
fullFileOrFolder = fullfile(parentFolder,[remainingPart1, remainingPart2]);
end