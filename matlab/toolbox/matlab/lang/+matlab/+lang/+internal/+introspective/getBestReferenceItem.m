function [best, others] = getBestReferenceItem(refTopics, topic)
    arguments
        refTopics (1,:) matlab.internal.doc.reference.ReferenceTopic;
        topic     (1,1) string;
    end

    refBook = refTopics(1).EntityProduct;
    best = matlab.lang.internal.introspective.helpers.referenceHitIndex;
    candidate = best;
    others = matlab.lang.internal.introspective.helpers.referenceHitIndex.empty();

    checkouts = getCheckouts;

    compareTopic  = lower(replace(topic, '/', '.'));
    topicFolder   = extractBefore(compareTopic, ".");
    strippedTopic = extractAfter(compareTopic, ".");
    for refTopic = refTopics
        [refItems, caseMatch] = refTopic.getReferenceData;
        for i = 1:numel(refItems)
            candidate.item = refItems(i);
            if ~isLicensed(candidate.item.ProductName)
                continue;
            end
            candidate.isCaseMatch = caseMatch(i);
            candidate.index = candidate.index + 1;
            candidate.isParent = refTopic.IsParentSearch;
            candidate.isCheckedOut = ismember(candidate.item.ProductName, checkouts);
            if ~candidate.isParent && ~isempty(candidate.item.RefEntities)
                candidate = findEntityNameMatches(candidate, compareTopic, topicFolder, strippedTopic);
            end
            candidate.isWrongBook = refBook ~= "" && refBook ~= candidate.item.HelpFolder;
            others(end+1) = candidate; %#ok<AGROW>
            best = updateBest(best, candidate);
        end
    end
    if best
        others(best.index) = [];
    end
end

function candidate = findEntityNameMatches(candidate, compareTopic, topicFolder, strippedTopic)
    entityNames = replace([candidate.item.RefEntities.Name], '/', '.');
    lowerNames  = lower(entityNames);
    nameMatches = endsWith(lowerNames, regexpPattern('\<') + compareTopic);
    candidate.isProductQualified = ~any(nameMatches) && topicFolder == lower(candidate.item.HelpFolder);
    if candidate.isProductQualified
        nameMatches = endsWith(lowerNames, strippedTopic);
    end
    candidate.item.RefEntities(~nameMatches) = [];
    candidate.isUnderqualified = any(strlength(entityNames(nameMatches))>strlength(compareTopic));
    candidate.isFunction = isFunction(candidate.item.RefEntities);
end

function b = isFunction(refEntities)
    b = ~isempty(refEntities) && any([refEntities.RefEntityType] == "Function");
end

function best = updateBest(best, candidate)
    if ~isempty(candidate.item.RefEntities)
        if candidate > best
            best = candidate;
        end
    end
end

function checkouts = getCheckouts
    licenses = license('inuse');
    checkouts = string(cellfun(@matlab.internal.product.getProductNameFromFeatureName, {licenses.feature}));
end

function b = isLicensed(productName)
    baseCode = matlab.internal.product.getBaseCodeFromProductName(productName);
    if baseCode ~= ""
        b = matlab.internal.licensing.isProductLicensed(baseCode);
    else
        b = true;
    end
end

%   Copyright 2008-2024 The MathWorks, Inc.
