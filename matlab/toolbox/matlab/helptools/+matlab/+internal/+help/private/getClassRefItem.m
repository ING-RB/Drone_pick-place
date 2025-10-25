function refItem = getClassRefItem(className, productName)
    refTopic = matlab.internal.doc.reference.ReferenceTopic(className);
    refTopic.EntityPrecision = matlab.internal.reference.api.EntityPrecision.Exact_Match;
    refTopic.EntityTypes = matlab.internal.doc.reference.getClassEntityTypes;
    refItem = refTopic.getReferenceData;
    if ~isempty(refItem)
        refItem([refItem.ProductName]~=productName) = [];
        refItem(cellfun('isempty', {refItem.ClassPropertyGroups})) = [];
        if ~isempty(refItem)
            refItem = refItem(1);
        end
    end
end

%   Copyright 2022 The MathWorks, Inc.
