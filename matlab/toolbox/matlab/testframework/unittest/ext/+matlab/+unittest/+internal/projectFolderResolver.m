function projectRoot = projectFolderResolver(folder)
% This function is undocumented.

%  Copyright 2018-2024 The MathWorks, Inc.
import matlab.unittest.internal.folderResolver;
import slproject.isUnderProjectRoot;

fullName = folderResolver(folder);

[underRoot, projectRoot] = isUnderProjectRoot(fullfile(fullName, 'resources'));
if ~underRoot || ~strcmp(fullName, projectRoot)
    error(message('MATLAB:automation:io:FileIO:InvalidProjectRootFolder', folder));
end
projectRoot = string(projectRoot);
end

