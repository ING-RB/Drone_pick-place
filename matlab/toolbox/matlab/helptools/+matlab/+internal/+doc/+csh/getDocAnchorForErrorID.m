function [shortname, topicId] = getDocAnchorForErrorID(errorId)
    arguments
        errorId (1,1) string = lasterror().identifier; %#ok<LERR>
    end
    shortname = missing;
    topicId = missing;
    parts = split(errorId, ':');
    if ~isscalar(parts)
        docProduct = matlab.internal.doc.product.getDocProductInfo(lower(parts(1)));
        if ~isempty(docProduct)
            shortname = string(docProduct.ShortName);
            topicId = join(["error", parts(2:end)'], '_');
        end
    end
end

% Copyright 2019-2021 The MathWorks, Inc.
