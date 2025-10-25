function newUrl = evalLinkClickHandling(customDocUrl)
    if isempty(customDocUrl)
        newUrl = '';
        return;
    end

    customDocPage = matlab.internal.doc.url.parseDocPage(customDocUrl);
    if ~isa(customDocPage, "matlab.internal.doc.url.CustomDocPage")
        newUrl = customDocUrl;
        return;
    end

    % If the url already contains 3pdocurl just return.
    queryParams = customDocPage.Query;
    for k=1:numel(queryParams)
        queryParam = queryParams(k);
        if (queryParam.Name == "3pdocurl" && queryParam.Value == "true")
            newUrl = customDocUrl;
            return;
        end
    end

    newUrl = string(getNavigationUrl(customDocPage)); 
end
