function ed = getExamplesDir
% 

%   Copyright 2020-2023 The MathWorks, Inc.

% Unsupported and for internal use only.
publishTempPwd = getappdata(0,'demo_publishing_temp_directory');
releaseDir = matlab.internal.examples.getExampleReleaseDir;
if publishTempPwd
    ed = publishTempPwd;
else
    ed = fullfile(userDir, releaseDir);
end
% Verify if the value returned is valid.
if isempty(ed) || any(ed < 32) || strcmp(ed, releaseDir) || strcmp(ed, [filesep, releaseDir])
   error(message("MATLAB:examples:PathNotValid"));
end
end


function userWorkFolder = userDir
userPathString = userpath;
userPathFolders = strsplit(userPathString, {pathsep,';'});
firstFolder = userPathFolders{1};
if isfolder(firstFolder)
    userWorkFolder = firstFolder;
else
    userWorkFolder = system_dependent('getuserworkfolder', 'default');
    if ~isfolder(userWorkFolder)
       userWorkFolder = tempdir;
    end
end
end
