classdef ReferenceTopic < matlab.lang.internal.introspective.stringable
    properties
        EntityName (1,1) string
        EntityTypes matlab.internal.reference.property.RefEntityType
        EntityProduct (1,1) string

        TypeExactMatch logical = true

        IsParentSearch logical = false

        ProductPrecision matlab.internal.doc.reference.ProductPrecision
        EntityPrecision matlab.internal.reference.api.EntityPrecision
        IsPrimitive logical = false

        CaseMatch logical = true
    end

    methods
        function obj = ReferenceTopic(entityName)
            obj.EntityName = entityName;
        end

        function [refData, caseMatch] = getReferenceData(obj)
            result = matlab.lang.internal.introspective.cache.lookup(@doLookup, obj);
            refData = result.refData;
            caseMatch = result.caseMatch;
        end
    end

    methods (Access=private)
        function refRequest = buildReferenceRequest(obj)
            types = getIncludedTypes(obj);
            refRequest = matlab.internal.reference.api.ReferenceRequest(obj.EntityName, types);
            refRequest.Comparator = buildComparator(obj);
            refRequest.EntityCaseSensitivity = matlab.internal.reference.api.EntityCaseSensitivity.Sensitive;
            if isempty(obj.EntityPrecision)
                % Infer the precision...
                if contains(obj.EntityName,".")
                    refRequest.EntityPrecision = matlab.internal.reference.api.EntityPrecision.Exact_Match;
                else
                    refRequest.EntityPrecision = matlab.internal.reference.api.EntityPrecision.Ignore_Package;
                end
            else
                refRequest.EntityPrecision = obj.EntityPrecision;
            end

            if filterByProduct(obj)
                refRequest.Products = obj.EntityProduct;
            end
        end

        function comparator = buildComparator(obj)
            import matlab.internal.reference.api.comparator.EntityNameMatchComparator;
            import matlab.internal.reference.api.comparator.EntityTypeMatchComparator;
            import matlab.internal.reference.api.comparator.ProductMatchComparator;
            import matlab.internal.reference.api.comparator.EntityTypeOrderComparator;
            import matlab.internal.reference.api.comparator.PreferredOrderComparator;
            import matlab.internal.reference.api.comparator.CompoundReferenceComparator;

            comparators = {};
            comparators{end+1} = EntityNameMatchComparator(obj.EntityName);

            if ~isempty(obj.EntityTypes)
                for entityType = obj.EntityTypes
                    comparators{end+1} = EntityTypeMatchComparator(entityType); %#ok<AGROW>
                end
            end

            if sortByProduct(obj)
                comparators{end+1} = ProductMatchComparator(obj.EntityProduct);
            end

            comparators{end+1} = EntityTypeOrderComparator;
            comparators{end+1} = PreferredOrderComparator;
            comparator = CompoundReferenceComparator(comparators);
        end

        function types = getIncludedTypes(obj)
            if obj.TypeExactMatch && ~isempty(obj.EntityTypes)
                types = obj.EntityTypes;
            else
                types = matlab.internal.reference.property.RefEntityType.empty;
            end
        end

        function sort = sortByProduct(obj)
            sort = obj.EntityProduct ~= "" && ~isempty(obj.ProductPrecision) && obj.ProductPrecision.isSort;
        end

        function filter = filterByProduct(obj)
            filter = obj.EntityProduct ~= "" && ~isempty(obj.ProductPrecision) && obj.ProductPrecision.isFilter;
        end
    end
end

function result = doLookup(obj)
    refReq = buildReferenceRequest(obj);
    dataRet = matlab.internal.reference.api.ReferenceDataRetriever(refReq);
    caseSensitiveRefData = dataRet.getReferenceData;
    if obj.CaseMatch && ~isempty(caseSensitiveRefData)
        refData = caseSensitiveRefData;
        caseMatch = true(size(refData));
    else
        refReq.EntityCaseSensitivity = matlab.internal.reference.api.EntityCaseSensitivity.Insensitive;
        dataRet = matlab.internal.reference.api.ReferenceDataRetriever(refReq);
        refData = dataRet.getReferenceData;
        caseMatch = true(size(refData));
        [~, i] = setdiff(getUrls(refData), getUrls(caseSensitiveRefData));
        caseMatch(i) = false;
    end
    result.refData = refData;
    result.caseMatch = caseMatch;
end

function refUrls = getUrls(refData)
    refUrls = [refData.HelpLocation] + "/" + [refData.Href];
end

% Copyright 2020-2024 The MathWorks, Inc.
