function errorCallback = getExtendedErrorCallback(errorId)
    errorCallback = strings(0);
    [shortname, topicId] = matlab.internal.doc.csh.getDocAnchorForErrorID(errorId);
    if ~ismissing(shortname)
        topicMap = matlab.internal.doc.csh.DocPageTopicMap(shortname, "", false);
        if topicMap.topicExists(topicId)
            errorCallback = "helpview('" + shortname + "','" + topicId + "')";
        end
    end
end

% Copyright 2019-2021 The MathWorks, Inc.
