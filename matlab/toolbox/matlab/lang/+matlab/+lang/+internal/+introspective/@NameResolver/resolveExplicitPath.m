function resolveExplicitPath(obj, topic)

    atOccurances = count(topic, '@');

    if atOccurances == 2
        UDDParts = regexp(topic, '^(?<path>.*?[\\/])?(?<package>@\w+)[\\/](?<class>@\w+)(?<methodSep>[\\/])?(?<method>(?(methodSep)\w+))?(?(method)\.\w+)?$', 'names', obj.regexpCaseOption);
        if ~isempty(UDDParts)
            % Explicitly two @ directories
            obj.UDDClassInformation(UDDParts);
            obj.malformed = isempty(obj.resolvedSymbol.classInfo);
        end
    else
        MCOSParts = regexp(topic, '^(?<path>[\\/]?([^@+][^\\/]*[\\/])*)?(?<packages>\+\w+([\\/]\+\w+)*)?(?<classSep>(?(packages)([\\/]@)?|(?(path)|^[\\/]?)@))(?<class>(?(classSep)\w+))(?<methodSep>[\\/])?(?<method>(?(methodSep)\w+))?(?<ext>(?(method)\.\w+))?(?<marker>>)?(?<local>(?(marker)\w+))?$', 'names', obj.regexpCaseOption);
        if ~isempty(MCOSParts)
            % Explicitly zero or more + directories and/or one @ directory
            obj.MCOSClassInformation(topic, MCOSParts);
            obj.malformed = isempty(obj.resolvedSymbol.classInfo);
        elseif matlab.io.internal.common.isAbsolutePath(topic)
            elementSpecified = contains(topic, filemarker);
            if elementSpecified
                element = extractAfter(topic, filemarker);
                topic = extractBefore(topic, filemarker);
            else
                [~, element] = fileparts(topic);
            end
            obj.resolveUnaryClass(topic, element, elementSpecified);
            if isempty(obj.resolvedSymbol.classInfo) && obj.resolvedSymbol.whichTopic ~= ""
                [~, obj.resolvedSymbol.resolvedTopic] = fileparts(string(obj.resolvedSymbol.whichTopic));
                if elementSpecified
                    element = matlab.lang.internal.introspective.getCaseCorrectLocalName(obj.resolvedSymbol.whichTopic, element);
                    obj.resolvedSymbol.resolvedTopic = append(obj.resolvedSymbol.resolvedTopic, filemarker, element);
                end
            end
        end
    end
end

%   Copyright 2013-2024 The MathWorks, Inc.
