function showSupportPackagesForBaseProducts(baseProductBaseCodes, entryPointIdentifier)
% showSupportPackagesForBaseProducts: List Support Packages that have
% dependency on the given list of base product basecodes

% Copyright 2016-2020 The MathWorks, Inc.
    try
        narginchk(2,2);
        matlab.internal.addons.launchers.showExplorer(entryPointIdentifier, "dependencies", baseProductBaseCodes);
    catch exception
        showError(exception);
    end
end