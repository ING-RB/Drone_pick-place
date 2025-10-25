function suggestions = getSuggestions(searchtext)
    if matlab.internal.doc.services.DocLocation.getActiveLocation == "WEB"
        suggestions = getOnlineDocSuggestions(searchtext);
    else
        suggestions = getInstalledDocSuggestions(searchtext);
    end
end

function suggestions = getInstalledDocSuggestions(searchtext)
    params = struct('q',searchtext);
    [~, resp] = matlab.internal.doc.search.sendSearchMessage('suggest', 'Params', params);
    suggestions = jsonencode(resp);
end

function suggestions = getOnlineDocSuggestions(searchtext)
    url = matlab.internal.doc.services.DocLocation.WEB.getDocRootDomain;
    lang = string(matlab.internal.doc.i18n.getDocLanguage);
    release = string(matlab.internal.doc.getDocCenterRelease);
    url.Path = ["help", "search", "suggest", "doccenter", lang, release];
    query = matlab.net.QueryParameter("q", searchtext);
    prodFilter = matlab.net.QueryParameter("prodfilter", getProductFilter);
    url.Query = [query, prodFilter];

    webOptions = weboptions("ContentType", "text");
    suggestions = webread(url, webOptions);
end

function prodFilter = getProductFilter
    products = matlab.internal.doc.product.getInstalledTopLevelDocProducts;
    baseCodes = string({products.BaseCode});
    baseCodes(baseCodes == "") = [];
    prodFilter = strjoin(baseCodes);
end