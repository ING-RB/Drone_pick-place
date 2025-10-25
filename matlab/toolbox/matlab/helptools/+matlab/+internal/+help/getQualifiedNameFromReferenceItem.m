% In a list of ref entities, return the one that is the "most qualified"
function qualifiedName = getQualifiedNameFromReferenceItem(refItem)
    refEntities = refItem.RefEntities;
    if isempty(refEntities)
        qualifiedName = "";
    elseif isscalar(refEntities)
        qualifiedName = refEntities.Name;
    else
        entityNames = [refEntities.Name];
        hasDots = contains(entityNames, '.');
        if any(hasDots)
            entityNames = entityNames(hasDots);
        end
        qualifiedName = entityNames(1);
    end
end

% Copyright 2021-2023 The MathWorks, Inc.
