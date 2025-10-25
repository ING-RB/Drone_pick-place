function addInstalledSupportPackagesToPath
% addInstalledSupportPackagesToPath Adds installed support packages to the
% MATLAB search path
 
% Copyright 2016 The MathWorks, Inc.
pathFileLocation = fullfile( ...
    matlabshared.supportpkg.internal.getSupportPackageRootNoCreate, ...
    'ssiSearchFolders');
matlab.internal.addons.addFoldersToPathFrom(pathFileLocation);