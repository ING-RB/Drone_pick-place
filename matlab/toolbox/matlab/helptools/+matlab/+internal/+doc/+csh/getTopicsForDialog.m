function topics = getTopicsForDialog(dialogId)
    shortnames = matlab.internal.doc.csh.getShortNames;
    topics = string.empty;
    for i = 1:length(shortnames)
        shortname = shortnames(i);
        topicMap = matlab.internal.doc.csh.getTopicMapForProduct(shortname);
        if ~isempty(topicMap)
            keys = topicMap(:,1);
            prodTopics = keys(startsWith(keys,dialogId));
            topics = [topics;prodTopics]; %#ok<AGROW>
        end
    end
end
