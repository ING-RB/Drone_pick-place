function set(preferredInstallationPath)
%   SET Internal function to set add-ons install location to a preferred path in Desktop platforms
%   PREFERREDINSTALLATIONPATH: New add-ons installation path

% Copyright 2023 The MathWorks Inc.
    matlab.internal.addons.util.setInstallationRootAndRegistrationRoot(preferredInstallationPath, preferredInstallationPath);
end