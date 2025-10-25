function shortnames = getShortNames
    products = matlab.internal.doc.product.getInstalledTopLevelDocProducts;
    shortnames = string({products.ShortName});
end