function addOnsInstallationFolder = setAddOnsInstallationFolderToDefault
%
% This is a private function and is not meant to be called directly.

% Copyright 2018 The MathWorks, Inc.

% ToDo: This is a duplicate of matlab/toolbox/matlab/toolboxmanagement/matlab_api/+matlab/+addons/+toolbox/setAddOnsInstallationFolderToDefault.m
% Extract the logic to a common utility

[allPrefDirsRoot, ~, ~] = fileparts(prefdir);
[mwDirectoryRoot, ~, ~] = fileparts(allPrefDirsRoot);
defaultInstallationFolder = fullfile(mwDirectoryRoot, 'MATLAB Add-Ons');
preferredFolderToSet = defaultInstallationFolder;
s = settings;
if (~exist(defaultInstallationFolder, 'dir') || (numel(dir(defaultInstallationFolder)) <= 2))
	legacyDefaultInstallationFolder = fullfile(userpath, 'Add-Ons');
    if (exist(legacyDefaultInstallationFolder, 'dir') && (numel(dir(legacyDefaultInstallationFolder)) > 2))
        preferredFolderToSet = legacyDefaultInstallationFolder;
    end
end
s.matlab.addons.InstallationFolder.PersonalValue = preferredFolderToSet;

addOnsInstallationFolder = java.io.File(preferredFolderToSet).toPath;
end
