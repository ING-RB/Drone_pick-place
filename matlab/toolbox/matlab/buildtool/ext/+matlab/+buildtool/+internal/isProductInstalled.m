function tf = isProductInstalled(productName)
% This function is unsupported and might change or be removed without notice
% in a future version.

% Copyright 2023-24 The MathWorks, Inc.

verInfo = ver;
productNames = string({verInfo.Name});
isProductInstalled = any(productNames.matches(productName));

tf = isProductInstalled && isProductLicensed(productName);
end

function tf = isProductLicensed(productName)
baseCode = matlab.internal.product.getBaseCodeFromProductName(productName);
tf = matlab.internal.licensing.isProductLicensed(baseCode);
end


