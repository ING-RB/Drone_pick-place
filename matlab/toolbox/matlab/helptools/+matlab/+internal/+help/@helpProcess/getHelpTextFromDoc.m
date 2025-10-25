function found = getHelpTextFromDoc(hp, classInfo, justH1, ignoreCase)
    found = false;
    if hp.helpOnInstance && hp.objectSystemName == ""
        return;
    end
    if hp.docLinks.isSet
        docTopic = hp.objectSystemName;
    else
        if isfile(hp.fullTopic)
            [~, hp.topic] = fileparts(hp.fullTopic);
        end
        hp.docLinks = matlab.lang.internal.introspective.docLinks(hp.fullTopic, hp.topic, classInfo);
        if ~hp.docLinks.caseMatch && ~ignoreCase && hp.fullTopic ~= "" && ~hp.isTypo
            % don't preemptively take a case mismatch from the doc if a name was found
            % on the path.
            return;
        end
        if hp.fullTopic == ""
            docTopic = '';
        else
            docTopic = hp.topic;
        end
    end

    if ~isempty(hp.docLinks.referenceItem)
        if ~ignoreCase && hp.docLinks.referenceItem.Purpose == ""
            return;
        end
        if ~hp.docLinks.isParent || hp.docLinks.isConstructor
            if docTopic == "" || hp.docLinks.isConstructor
                [docTopic, ~, caseMatch] = matlab.internal.help.getTopicFromReferenceItem(hp.docLinks.referenceItem);
                hp.objectSystemName = docTopic;
                hp.docLinks.caseMatch = hp.docLinks.caseMatch && caseMatch;
                hp.isTypo = hp.isTypo || ~hp.docLinks.caseMatch;
            end
            if hp.wantHyperlinks
                helpCommand = hp.command;
            else
                helpCommand = '';
            end
            hp.helpStr = matlab.internal.help.getHelpTextFromReferenceItem(hp.docLinks.referenceItem, docTopic, helpCommand, justH1=justH1);

            if ~isempty(classInfo) && classInfo.isInherited
                hp.helpStr = matlab.lang.internal.introspective.helpers.modifyInheritedHelp(classInfo, hp.helpStr, helpCommand);
            end

            hp.needsHotlinking = false;
            hp.isUnderqualified = hp.isUnderqualified || strlength(hp.objectSystemName) > strlength(hp.inputTopic);
            hp.displayBanner = hp.displayBanner || matlab.internal.help.entityTypeNeedsBanner(hp.docLinks.referenceItem);
            hp.topic = docTopic;

            found = true;
        end
    end
end

%   Copyright 2013-2024 The MathWorks, Inc.
