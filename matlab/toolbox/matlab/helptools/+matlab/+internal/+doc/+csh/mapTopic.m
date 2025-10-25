function helpPath = mapTopic(topicPath, topicId)
    helpPath = "";
    helpTopicMap = matlab.internal.doc.csh.HelpTopicMap.fromTopicPath(topicPath);
    if ~isempty(helpTopicMap)
        helpPath = helpTopicMap.mapTopic(topicId);
    end
end
%   Copyright 2020 The MathWorks, Inc.
