function [docTopic, classMeta, caseMatch] = getTopicFromReferenceItem(refItem)
    entityName = matlab.internal.help.getQualifiedNameFromReferenceItem(refItem);
    classMeta = [];
    caseMatch = true;
    import matlab.internal.reference.property.DeprecationStatus;
    if refItem.DeprecationStatus < DeprecationStatus.Error && matlab.lang.internal.introspective.isMATLABItem(refItem)
        if contains(entityName, notFunctionChar)
            functionName = getFunctionName(entityName);
            if ~ismissing(functionName) && isShadowedOrdinaryFunction(functionName, refItem)
                entityName = functionName;
            end
        end
        mcosResolver = resolveMCOSName(entityName);
        if mcosResolver.isResolved
            entityName = mcosResolver.fullTopic;
            if mcosResolver.isClass
                classMeta = mcosResolver.resolvedMeta;
            end
            caseMatch = mcosResolver.isCaseSensitive;
        end
    end
    docTopic = char(entityName);
end

function mcosResolver = resolveMCOSName(name)
    mcosResolver = matlab.lang.internal.introspective.MCOSMetaResolver(name);
    mcosResolver.executeResolve();
end

function b = isShadowedOrdinaryFunction(functionName, candidateItem)
    whichName = onlyOrdinaryFunctionWhich(functionName);
    b = whichName ~= "" && isBestUnqualified(candidateItem, functionName, whichName);
end

function pattern = notFunctionChar
    pattern = regexpPattern('\W');
end

function functionName = getFunctionName(qualifiedName)
    functionName = regexp(qualifiedName, '\w+$', 'match', 'once');
end

function whichName = onlyOrdinaryFunctionWhich(name)
    [whichName, whichComment] = which(name);
    if whichComment ~= ""
        whichName = "";
    end
end

function b = isBestUnqualified(refItem, name, whichName)
    if ~matlab.lang.internal.introspective.isAbsoluteFile(whichName)
        whichName = "";
    end
    toolboxFolder = matlab.lang.internal.introspective.getToolboxFolder(whichName, name);
    bestUnqualified = matlab.lang.internal.introspective.getReferenceHitIndex(name, whichName, [], toolboxFolder);
    b = bestUnqualified.item.HelpLocation == refItem.HelpLocation && bestUnqualified.item.Href == refItem.Href;
end

%   Copyright 2021-2024 The MathWorks, Inc.
