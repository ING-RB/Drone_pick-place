function prodName = getDocProductName(toolbox, getShort)
    arguments
        toolbox  (1,1) string;
        getShort (1,1) logical = true;
    end

    persistent productCache;
    persistent cachedDocroot;
    if isempty(cachedDocroot) || ~strcmp(cachedDocroot, docroot)
        cachedDocroot = docroot;
        productCache = containers.Map;
    end

    if productCache.isKey(toolbox)
        prod = productCache(toolbox);
    else
        prod = matlab.internal.doc.product.getDocProductInfo(toolbox);
        productCache(toolbox) = prod;
    end

    if isempty(prod)
        prodName = "";
    else
        if getShort
            prodName = string(prod.ShortName);
        else
            prodName = string(prod.DisplayName);
        end
    end
end

% Copyright 2020-2022 The MathWorks, Inc.
