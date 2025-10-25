classdef MLAPPLicenseValidator < appdesigner.internal.serialization.validator.MLAPPValidator
    % MLAPPLicenseValidator validator to check licenses based on what is
    % saved in the MLApp
    
    % Copyright 2018-2024 The MathWorks, Inc.
    
    methods
        function validateMetaData(obj, metadata)
            % This looks at metadata.RequiredProducts and:
            %
            % 1) license tests that the stored product flex names are available
            %
            % 2) Check if the toolbox is also installed
            %
            % If any of these come back as non empty, there will be an
            % error

            import appdesigner.internal.license.LicenseChecker;
            allRequiredProducts = metadata.RequiredProducts;
            
            unlicensedProductNames = {};
            unlicensedProductKeys = {};
            uninstalledProductNames = {};
            uninstalledProductKeys = {};
            
            % First, check for license availability
            for idx = 1:length(allRequiredProducts)
                
                licenseKey = allRequiredProducts{idx};
                
                % Get the license name from the key
                %
                %  Ex: 'Aerospace_Toolbox' -> 'Aerospace Toolbox'
                productName = matlab.internal.product.getProductNameFromFeatureName(licenseKey);

                if(~isempty(productName))
                    licenseName = char(productName);
                else
                    % If for some reason the feature name lookup
                    % doesn't know the product name, just use the license
                    % key
                    %
                    % This would be the case when there is a toolbox from
                    % a future release
                    licenseName = licenseKey;
                end


                % Test install license name
                isInstallAvailable = LicenseChecker.isProductInstalled(licenseKey);
                if(isInstallAvailable)
                    % Sometimes, the user may have license for the product but it cannot be checkout.
                    % Therefore, try checking out the license. If checkout false, add corresponding warning.
                    % See g3299475
                    isLicenseAvailable = LicenseChecker.checkoutProduct(licenseKey);
                    if(~isLicenseAvailable)
                        unlicensedProductNames{end+1} = licenseName;
                        unlicensedProductKeys{end+1} = licenseKey;
                    end
                else
                    % License is not installed.
                    uninstalledProductNames{end+1} = licenseName;
                    uninstalledProductKeys{end+1} = licenseKey;
                end
            end
            
            % Create warnings if either unlicensed or uninstalled exist
            %
            % Only create 1 warning, don't make both
            if(~isempty(unlicensedProductNames))
                
                warningStruct = struct('ProductNames', {unlicensedProductNames}, ...
                    'ProductKeys',  {unlicensedProductKeys}, ...
                    'Message', getString(message('appdesigner:application_js:Dialogs:toolboxErrorTopMessage',...
                    getString(message('appdesigner:application_js:Dialogs:licenseErrorTopMessage')))));
                obj.addWarning('MissingLicense', warningStruct);
                
            elseif(~isempty(uninstalledProductNames))
                
                warningStruct = struct('ProductNames', {uninstalledProductNames}, ...
                    'ProductKeys',  {uninstalledProductKeys},...
                    'Message', getString(message('appdesigner:application_js:Dialogs:toolboxErrorTopMessage',...
                    getString(message('appdesigner:application_js:Dialogs:installationErrorTopMessage')))));
                obj.addWarning('MissingInstall', warningStruct);
                
            end
        end
    end
end