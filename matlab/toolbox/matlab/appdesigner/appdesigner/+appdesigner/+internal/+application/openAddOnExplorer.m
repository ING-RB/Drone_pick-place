function openAddOnExplorer(licenseKey)    
    % Given the license key... will launch the Add Ons 
    
    % Ex: licenseKey =  'Aerospace_Toolbox';
    %     productName = "Aerospace Toolbox";
    %     baseCode =    'AT';
    
    % Copyright 2020-2024 The MathWorks, Inc.
    productName = matlab.internal.product.getProductNameFromFeatureName(licenseKey);
    baseCode = matlab.internal.product.getBaseCodeFromProductName(productName);
    matlab.internal.addons.showAddon(baseCode);
end

