function installToolboxes(mltbxRepoPath)
%   INSTALLTOOLBOXES Silently Installs toolboxes from mltbx files location in the
%                    given path
%   MLTBXREPOPATH = Path to a repository of mltbx files

% Copyright 2023 The MathWorks Inc.

mltbxFiles = dir(fullfile(mltbxRepoPath,'*.mltbx')); 

for k = 1:length(mltbxFiles)

  mltbxFileName = mltbxFiles(k).name;

  mltbxFilePath = fullfile(mltbxFiles(k).folder, mltbxFileName);
 
  matlab.addons.install(mltbxFilePath, true, 'add');

end

end