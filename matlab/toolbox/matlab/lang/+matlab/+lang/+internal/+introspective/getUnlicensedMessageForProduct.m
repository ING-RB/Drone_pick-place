function unlicensedMessage = getUnlicensedMessageForProduct(funcName, licenseName)
    unlicensedMessage = message.empty;
    productName = matlab.internal.product.getProductNameFromFeatureName(licenseName);
    if productName ~= ""
        baseCode = matlab.internal.product.getBaseCodeFromProductName(productName);
        idForUsageDataAnalytics = 'ErrorRecovery';
        messageID = "MATLAB:ErrorRecovery:UnlicensedFunctionInSingleProduct";
        callBack = 'matlab.internal.addons.launchers.showExplorer';
        productLink = matlab.lang.internal.introspective.generateErrorRecoveryLine(callBack, productName, idForUsageDataAnalytics, 'identifier', baseCode);
        unlicensedMessage = matlab.lang.internal.introspective.createInaccessibleMessage(messageID, funcName, productLink);
    end
end

% Copyright 2022-2023 The MathWorks, Inc.
