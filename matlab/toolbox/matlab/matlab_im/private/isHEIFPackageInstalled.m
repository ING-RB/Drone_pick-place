function spkgInstallStatus = isHEIFPackageInstalled
% Check if the HEIF support package is installed. In the installed MATLAB
% environment, the support package files will be under the support package
% path. The support package path is found using
% "matlabshared.supportpkg.getSupportPackageRoot". In the sandbox
% environment, the support package files exist under "matlabroot"

%   Copyright 2025 The MathWorks, Inc.

% Check for heif support package files under the support package path.
isUnderSpkgRoot = exist(fullfile(matlabshared.supportpkg.getSupportPackageRoot,"toolbox","matlab","matlab_images","supportpackages","heif","readheifutil.p"),"file");


% Check for heif support package files under under "matlabroot" path
isUnderMATLABRoot = exist(fullfile(matlabroot,"toolbox","matlab","matlab_images","supportpackages","heif","readheifutil"),"file");

% If the files exist under either of these paths, return true
spkgInstallStatus = isUnderSpkgRoot || isUnderMATLABRoot;

end
