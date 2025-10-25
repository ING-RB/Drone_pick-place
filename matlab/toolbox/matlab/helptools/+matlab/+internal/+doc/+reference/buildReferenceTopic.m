function [refTopic, topicName, topicPath] = buildReferenceTopic(topicName, isVariable)
    resolved = matlab.lang.internal.introspective.resolveName(topicName, JustChecking=false);
    topicPath = resolved.nameLocation;
    toolbox = matlab.lang.internal.introspective.getToolboxFolder(topicPath, topicName);
    refTopicBuilder = matlab.internal.doc.reference.ReferenceTopicBuilder(topicName, isVariable, topicPath, resolved.classInfo, toolbox);
    [refTopic, updatedName] = refTopicBuilder.buildRefTopics;
    if updatedName ~= ""
        topicName = updatedName;
    end
    if topicPath == "" && matlab.internal.help.folder.hasHelp(topicName)
        topicPath = topicName;
    end
end

%   Copyright 2023-2024 The MathWorks, Inc.
