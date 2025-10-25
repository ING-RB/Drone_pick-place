function isLaunched = launchSSIWindow(installFolder, basecode)
% Utility function to launch SSI window with the install from internet or
% MLPKGINSTALL workflow.

% Copyright 2021 Mathworks Inc.

launcher = matlab.internal.SupportSoftwareInstallerLauncher();
launcher.launchWindow("MLPKGINSTALL", [], installFolder, basecode);
isLaunched = launcher.isWindowInstantiated;
end