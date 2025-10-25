function [referenceName, caseMatch, isUnderqualified] = referenceResolve(obj, topic)
    if obj.resolvedSymbol.foundVar
        topic = obj.resolvedSymbol.resolvedTopic;
    elseif obj.lowerBeforeRef
        topic = lower(topic);
    end
    [referenceName, caseMatch, isUnderqualified] = resolveTopic(topic, []);
    if referenceName == ""
        splitConstructor = regexpi(topic, '^(?<package>.*)\<(?<class>\w*)\W(?<constructor>\k<class>)$', 'names', 'once');
        if ~isempty(splitConstructor)
            removedConstructor = append(splitConstructor.package, splitConstructor.class);
            entityTypes = matlab.internal.doc.reference.getClassEntityTypes;
            [referenceName, caseMatch, isUnderqualified] = resolveTopic(removedConstructor, entityTypes);
            if referenceName ~= ""
                referenceName = regexprep(referenceName, '\<\w*$', '$0/$0');
                caseMatch = caseMatch && strcmp(splitConstructor.class, splitConstructor.constructor);
            end
        elseif isPotentialClassElement(topic)
            topic = replace(topic, '/', '.');
            [referenceName, caseMatch, isUnderqualified] = resolveTopic(topic, []);
        end
    end
end

function b = isPotentialClassElement(topic)
    b = contains(topic, '/') && matches(topic, regexpPattern('[\w./]*'));
end

function [referenceName, caseMatch, isUnderqualified] = resolveTopic(topic, entityTypes)
    refTopic = matlab.internal.doc.reference.ReferenceTopic(topic);
    refTopic.EntityTypes = entityTypes;
    refTopic.CaseMatch = false;
    best = matlab.lang.internal.introspective.getBestReferenceItem(refTopic, topic);

    caseMatch        = best.isCaseMatch;
    isUnderqualified = best.isUnderqualified;
    if best
        referenceName = matlab.internal.help.getQualifiedNameFromReferenceItem(best.item);
    else
        referenceName = "";
    end
end

%   Copyright 2021-2024 The MathWorks, Inc.
