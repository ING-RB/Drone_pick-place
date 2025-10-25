function output = checkLicenses(licenseNames)
    %CHECKLICENSES Checks if the licenses are available and returns a
    %logical array of the results;
    
    %   Copyright 2021 The MathWorks, Inc.
    
    output = cellfun(@(name)appdesigner.internal.license.LicenseChecker.isProductAvailable(name), licenseNames);
end

