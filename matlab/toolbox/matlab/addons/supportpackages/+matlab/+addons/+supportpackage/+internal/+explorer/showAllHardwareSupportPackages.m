function showAllHardwareSupportPackages(entryPointIdentifier)
% SHOWALLHARDWARESUPPORTPACKAGES Shows a filtered view of all Hardware
% Support packages in Add-on Explorer

% Copyright 2016-2020 The MathWorks, Inc.
    try
        narginchk(1,1);
        matlab.internal.addons.launchers.showExplorer(entryPointIdentifier, "addOnType", "hardware_support")
    catch exception
        showError(exception);
    end
end