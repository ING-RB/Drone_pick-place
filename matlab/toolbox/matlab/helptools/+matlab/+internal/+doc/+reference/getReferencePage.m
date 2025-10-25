function [docPage, displayText, primitive] = getReferencePage(topic, allowSearch)
    arguments
        topic matlab.internal.doc.reference.ReferenceTopicInput {mustBeScalarOrEmpty} = matlab.internal.doc.ReferenceTopicInput.empty
        allowSearch (1,1) logical = true
    end

    displayText = string.empty;
    topicPath = string.empty;
    primitive = false;

    if isempty(topic)
        docPage = matlab.internal.doc.url.MwDocPage;
        return;
    end

    docPage = checkForProductOrToolbox(topic.Topic);
    if ~isempty(docPage)
        return;
    end

    refTopics = matlab.internal.doc.reference.ReferenceTopic.empty;

    if isempty(refTopics)
        if isArgNamePreferred(topic)
            % The input argument may be a case-insensitive match for
            % a variable name. Since it is not the exact variable name
            % we should see if there's a better match elsewhere.
            [argTopic, referenceTopic] = matlab.internal.doc.reference.buildReferenceTopic(topic.ArgName, false);
            docPage = findReferencePage(argTopic, referenceTopic);
            if ~isempty(docPage)
                return;
            end
        end
        [refTopics, referenceTopic, topicPath] = matlab.internal.doc.reference.buildReferenceTopic(topic.Topic, topic.IsVariable);
    end

    if ~isempty(refTopics)
        if refTopics(1).IsPrimitive
            primitive = true;
            return;
        end

        docPage = findReferencePage(refTopics, referenceTopic);
        if ~isempty(docPage)
            return;
        end
    end

    % Check if we can display help of some kind.
    if isempty(topicPath) || topicPath == ""
        topicPath = referenceTopic;
    else
        displayText = matlab.internal.doc.livecode.getMlxDoc(topicPath);
        if ~isempty(displayText)
            docPage = matlab.internal.doc.url.RichTextPage(topicPath, "mlx");
            return;
        end
    end

    hasHelp = matlab.internal.help.helpwin.isHelpAvailable(topicPath, 'doc');
    if hasHelp || ~allowSearch
        docPage = getHelpDocPage(topicPath);
    elseif allowSearch
        docPage = matlab.internal.doc.url.DocSearchPage(referenceTopic);
    end
end

function docPage = findReferencePage(refTopics, topicName)
    docPage = matlab.internal.doc.url.DocPage.empty;

    if isempty(refTopics)
        return;
    end

    best = matlab.lang.internal.introspective.getBestReferenceItem(refTopics, topicName);
    if best
        refItem = best.item;
        docPage = getReferenceItemDocPage(refItem);
        docPage.Origin = matlab.internal.doc.url.DocPageOrigin("ReferenceItem", topicName);

        if checkForOverload(topicName)
            overloadString = topicName + " " + isMethodOrProperty(refItem);
            overloadParam = matlab.net.QueryParameter('overload',overloadString);
            docPage.Query = [docPage.Query overloadParam];
        end
    end
end

function docPage = checkForProductOrToolbox(topic)
    prod = matlab.internal.doc.product.getDocProductInfo(topic);
    if ~isempty(prod)
        docPage = matlab.internal.doc.url.MwDocPage;
        docPage.Product = prod;
        return;
    end

    prod = matlab.internal.doc.project.getDocPageCustomToolbox(topic);
    if ~isempty(prod)
        docPage = matlab.internal.doc.url.CustomDocPage;
        docPage.Product = prod;
        docPage.RelativePath = prod.LandingPage;
    else
        docPage = matlab.internal.doc.url.DocPage.empty;
    end
end

function classEntity = isMethodOrProperty(refItem)
    import matlab.internal.reference.property.RefEntityType;
    entityType = refItem.RefEntities(1).RefEntityType;
    classEntity = entityType == RefEntityType.Property || entityType == RefEntityType.Method;
end

function isOverloaded = checkForOverload(topic)
    % Check if a broad query for the topic matches more than one item.
    overloadTopic = matlab.internal.doc.reference.ReferenceTopic(topic);
    isOverloaded = ~isscalar(overloadTopic.getReferenceData);
end

function docPage = getReferenceItemDocPage(refItem)
    docPage = matlab.internal.doc.url.MwDocPage;
    docPage.Product = refItem.HelpLocation;
    docPage.RelativePath = refItem.Href;
end

function docPage = getHelpDocPage(topicPath)
    if matlab.internal.livecode.FileModel.isLiveCodeFile(topicPath)
        docPage = matlab.internal.doc.url.RichTextPage(topicPath);
    else
        docPage = matlab.internal.doc.url.HelpwinPage(topicPath, 'doc');
    end
end

%   Copyright 2021-2025 The MathWorks, Inc.
