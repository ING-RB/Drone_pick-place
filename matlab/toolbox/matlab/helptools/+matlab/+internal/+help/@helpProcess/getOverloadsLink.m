function linkText = getOverloadsLink(hp)
    linkText = '';
    overloadTopic = getOverloadTopic(hp);

    if overloadTopic == ""
        return;
    end

    if ~matlab.lang.internal.introspective.isMATLABItem(hp.docLinks.referenceItem)
        return;
    end

    overloadQualifiedTopic = hp.objectSystemName;

    if overloadQualifiedTopic == ""
        overloadQualifiedTopic = overloadTopic;
    elseif ~contains(overloadQualifiedTopic, '/')
        % The topic is underqualified and doesn't have a slash, this means that it
        % is a static method, and the dot separating the class from the method
        % needs to be changed to a slash so getOverloads knows to ignore this class
        overloadQualifiedTopic = replace(overloadQualifiedTopic, "." + overloadTopic + textBoundary('end'), "/" + overloadTopic);
    end

    if matlab.lang.internal.introspective.overloads.hasOverloads(overloadQualifiedTopic, hp.callerContext.Imports)
        linkID = 'MATLAB:introspective:help:OverloadedMethods';
        linkFcn = 'matlab.lang.internal.introspective.overloads.displayOverloads';
        linkText = hp.getOtherNamesLink(overloadTopic, overloadQualifiedTopic, linkID, linkFcn);
    end
end

function overloadTopic = getOverloadTopic(hp)
    overloadTopic = '';

    if ~hp.helpOnInstance && hp.inputTopic ~= ""
        [filePath, singleName, extension] = fileparts(hp.inputTopic);

        if filePath == "" && isvarname(singleName) && (extension == "" || matlab.lang.internal.introspective.safeWhich(hp.inputTopic) ~= "")
            % Topic is not a compound name
            overloadTopic = matlab.lang.internal.introspective.extractCaseCorrectedName(hp.topic, singleName);
            if overloadTopic == ""
                [~, overloadTopic] = fileparts(hp.topic);
            end
        elseif hp.elementKeyword == "" || hp.elementKeyword == "packagedItem"
            % For compound names, do not look if the resolved name is an element of a
            % class. "packagedItem" is the only non-empty value that is not an element
            % of a class.
            overloadTopic = hp.objectSystemName;
        end
    end
end

%   Copyright 2015-2024 The MathWorks, Inc.
