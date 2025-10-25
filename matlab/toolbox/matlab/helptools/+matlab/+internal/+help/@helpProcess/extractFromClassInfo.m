function extractFromClassInfo(hp, classInfo)

    hp.objectSystemName         = classInfo.fullTopic;

    if ~hp.justChecking
        hp.isMCOSClassOrConstructor = classInfo.isMCOSClassOrConstructor;
        hp.isMCOSClass              = classInfo.isMCOSClass;
        hp.isDir                    = classInfo.isPackage;

        if classInfo.isMethod && ~isempty(classInfo.superWrapper)
            hp.fullTopic = classInfo.definition;
        end

        hp.docLinks = classInfo.getDocLinks;

        if hp.docLinks.isFirstHit && ~classInfo.isInherited
            hp.objectSystemName = hp.docLinks.referencePage;
        end
    end
end

%   Copyright 2007-2024 The MathWorks, Inc.
