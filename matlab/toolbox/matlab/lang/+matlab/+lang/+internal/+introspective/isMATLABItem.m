function [b, entityType] = isMATLABItem(refItem)
    import matlab.internal.reference.property.RefEntityType;

    if isempty(refItem)
        entityType = RefEntityType.Function;
    elseif isempty(refItem.RefEntities)
        entityType = RefEntityType.Unknown;
    else
        entityType = min([refItem.RefEntities.RefEntityType]);
        entityType = RefEntityType(entityType);
        if entityType == RefEntityType.Function && all(arrayfun(@iskeyword, [refItem.RefEntities.Name]))
            entityType = RefEntityType.Keyword;
        end
    end

    b = entityType < RefEntityType.Package;
end

%   Copyright 2022-2024 The MathWorks, Inc.
