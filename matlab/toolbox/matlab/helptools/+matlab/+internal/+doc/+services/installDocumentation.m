function installDocumentation
    spkgBaseCodesCellArray = cellstr(getSpkgBaseCodes);
    window = matlab.internal.SupportSoftwareInstallerLauncher();
    window.launchWindow('DPKG', '', '', spkgBaseCodesCellArray);
end

function spkgBaseCodes = getSpkgBaseCodes
    products = matlab.internal.doc.product.getInstalledTopLevelDocProducts;
    baseCodes = string({products.BaseCode});
    baseCodes(baseCodes == "") = [];
    spkgBaseCodes = "DPKG_" + string(baseCodes);
end