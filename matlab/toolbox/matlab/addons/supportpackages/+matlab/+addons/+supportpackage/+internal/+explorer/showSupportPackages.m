function showSupportPackages(supportPackageBaseCodes, entryPointIdentifier)
% showSupportPackages: Opens a filtered list of Support Packages with given
% support packages basecodes

% Copyright 2016-2020 The MathWorks, Inc.    
    try
        narginchk(2,2);
        if ischar(supportPackageBaseCodes)
            matlab.internal.addons.launchers.showExplorer(entryPointIdentifier, 'identifier', supportPackageBaseCodes);
        elseif iscellstr(supportPackageBaseCodes)
            matlab.internal.addons.launchers.showExplorer(entryPointIdentifier, 'identifiers', supportPackageBaseCodes);
        end
    catch exception
        showError(exception);
    end
end