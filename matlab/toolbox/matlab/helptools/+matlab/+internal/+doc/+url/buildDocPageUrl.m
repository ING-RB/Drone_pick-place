function docUrl = buildDocPageUrl(prodId,relPath)
    arguments
        prodId (1,1) string = ""
        relPath (1,1) string = ""
    end

    docPage = matlab.internal.doc.url.MwDocPage;
    docPage.Product = prodId;
    docPage.RelativePath = relPath;
    docUrl = string(docPage.getUrl);
end

% Copyright 2020-2021 The MathWorks, Inc.
