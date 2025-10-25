function helpStr = getHelpTextForDescription(topic)
    helpStr = '';
    topic = char(topic);
    nameResolver = matlab.lang.internal.introspective.resolveName(topic);
    if nameResolver.isResolved
        if ~isempty(nameResolver.classInfo)
            helpStr = nameResolver.classInfo.getHelpForDescription;
        elseif nameResolver.nameLocation ~= ""
            helpFunction = matlab.lang.internal.introspective.getHelpFunction(nameResolver.nameLocation);
            if helpFunction ~= ""
                helpStr = matlab.lang.internal.introspective.callHelpFunction(helpFunction, nameResolver.nameLocation, false);
            end
        end
        preferSingleSource = matlab.internal.help.preferSingleSource(nameResolver.nameLocation);
        if helpStr == "" || preferSingleSource
            topic = nameResolver.resolvedTopic;
            docLinks = matlab.lang.internal.introspective.docLinks(nameResolver.nameLocation, topic, nameResolver.classInfo);
            if ~isempty(docLinks.referenceItem) && (~docLinks.isParent || docLinks.isConstructor)
                if docLinks.referenceItem.Purpose ~= "" || helpStr == ""
                    helpStr = matlab.internal.help.getHelpTextFromReferenceItem(docLinks.referenceItem, topic);
                end
            end
        end

        helpStr = strip(helpStr);
        headerTopic = nameResolver.resolvedTopic;

        helpStr = matlab.internal.help.managePrefix(helpStr, headerTopic, false);
    end
end

%   Copyright 2021-2024 The MathWorks, Inc.
