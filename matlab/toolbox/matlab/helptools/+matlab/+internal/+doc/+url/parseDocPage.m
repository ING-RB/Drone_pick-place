function docPage = parseDocPage(docUrl)
    [~, docPage] = matlab.internal.doc.url.DocPageParser.isDocPage(docUrl);
end

% Copyright 2020-2021 The MathWorks, Inc.
