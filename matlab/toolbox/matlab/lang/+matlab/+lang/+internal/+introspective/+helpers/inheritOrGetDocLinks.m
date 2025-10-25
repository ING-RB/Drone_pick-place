function docLinks = inheritOrGetDocLinks(classInfo)
    if classInfo.isInherited
        docLinks = matlab.lang.internal.introspective.docLinks("", append(classInfo.fullSuperClassName, '.', classInfo.element), classInfo);
    else
        docLinks = matlab.lang.internal.introspective.docLinks;
    end
    if docLinks.referencePage == "" || docLinks.isParent
        docLinks = matlab.lang.internal.introspective.docLinks("", classInfo.fullTopic, classInfo);
    end
end

%   Copyright 2024 The MathWorks, Inc.
