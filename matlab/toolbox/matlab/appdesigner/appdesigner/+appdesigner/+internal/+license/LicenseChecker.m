classdef LicenseChecker < handle
    %LICENSECHECKER Provide a fast way to do license checking for toolbox
    % that is required in App Designer
    % APIs are provided to check if a toolbox is licensed or installed 
    % by product flex name.
    % 
    % At MATHWORKS, the toolbox licence is managed through three names:
    % Product Name: user readable friendly name, which may change as product
    %               evolves
    % Flex Name: it is used for license manager system, which is still 
    %              kind of readable, and we should
    %              use to store either in our mlapp file or in our code base
    % Base Code: internal short toolbox name, like "AT" for "aerospace_toolbox",
    %             which should be staying unchanged, and not quite readable.
    %

    % Copyright 2021-2024 The MathWorks, Inc.
    
    properties (Constant)        
        Finder = dependencies.internal.analysis.toolbox.ToolboxFinder;
    end
    
    methods (Static)
        function isLicensed = isProductLicensed(productFlexName)
            % Check if a product is licensed by product flex name
            
            isLicensed = matlab.internal.licensing.isProductLicensed(...
                appdesigner.internal.license.LicenseChecker.getBaseCodeByFlexName(productFlexName));
        end

        function isInstalled = isProductInstalled(productFlexName)
            % Check if a product is installed in current MATLAB by product flex name
            
            productInfo = appdesigner.internal.license.LicenseChecker.Finder.fromFlexName(productFlexName);
            isInstalled = productInfo.IsInstalled;
        end

        function isAvailable = isProductAvailable(productFlexName)
            % Return true only if a product is installed and licensed by product name
            % Product flex name is supported limiting to three products listed
            % in the property - ProductFlexNameMap - to be compatible with App Designer usage

            import appdesigner.internal.license.LicenseChecker;

            % To avoid calling into fromFlexName multiple times, we do not 
            % use isProductInstalled() and isProductLicensed() APIs in this module.
            productInfo = appdesigner.internal.license.LicenseChecker.Finder.fromFlexName(productFlexName);
            % Use the 'short-circuit and' to eliminate
            % any unnecessary calls to license servers.
            % So first check if the product has installed or not
            % then check if the product is licensed or not
            isAvailable = productInfo.IsInstalled && ...
                matlab.internal.licensing.isProductLicensed(productInfo.BaseCode);
        end

        function isCheckoutSuccess = checkoutProduct(productFlexName)
            isCheckoutSuccess = false;

            [status, errmsg] = license('checkout', productFlexName);

            if (status == 1) && isempty(errmsg)
                isCheckoutSuccess = true;
            end
        end
    end

    methods (Static, Access = private)
        function baseCode = getBaseCodeByFlexName(productFlexName)
            % Return product base code name from flex name.

            productInfo = appdesigner.internal.license.LicenseChecker.Finder.fromFlexName(productFlexName);
            baseCode = productInfo.BaseCode;
        end
    end
end

