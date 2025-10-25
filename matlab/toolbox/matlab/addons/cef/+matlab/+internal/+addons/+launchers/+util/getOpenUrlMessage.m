function openUrlMessage = getOpenUrlMessage(url, context, postMessageTag)
    % getOpenUrlMessage: API that can be used to construct Open URL message
    % to be sent to Add-on Explorer
    
    % Copyright: 2019 The MathWorks, Inc.
    configuration = struct("postMessageTag", postMessageTag, "context", context);
    openUrlMessage = jsonencode(struct("url", url, "configuration", configuration));
    
end

