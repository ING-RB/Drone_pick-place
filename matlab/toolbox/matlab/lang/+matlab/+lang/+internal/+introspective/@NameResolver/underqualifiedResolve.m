function underqualifiedResolve(obj, topic)
    if ~isempty(regexp(topic, '^\w+(?:\.\w+)?$', 'once'))
        if matlab.internal.help.folder.hasHelp(topic)
            obj.resolvedSymbol.isInaccessible = true;
        else
            [whichTopics, whichDescriptors] = which(topic, '-all');
            if obj.resolvedSymbol.isCaseSensitive
                % The results from which are case insensitive, if the NameResolver in its
                % case sensitive pass, filter out the classes that will be rejected as case
                % mismatches by doResolve. This prevents doResolve from loading a class to
                % look for a case sensitive match that is not there.
                [whichPaths, whichNames] = fileparts(whichTopics);
                builtins = whichPaths == "";
                classdefs = ~matches(whichNames, topic, IgnoreCase=true);
                caseMatches = matches(whichNames, topic) | builtins | classdefs;
                whichDescriptors(~caseMatches) = [];
            end
            for i = 1:numel(whichDescriptors)
                whichDescriptor = whichDescriptors{i};
                [qualifiedTopic, methodName] = matlab.lang.internal.introspective.getUnderqualifiedName(topic, whichDescriptor);
                if qualifiedTopic ~= ""
                    obj.doResolve(qualifiedTopic, false);
                    if obj.resolvedSymbol.isResolved
                        if isempty(obj.resolvedSymbol.classInfo) || ~obj.resolvedSymbol.classInfo.isAccessible
                            obj.resetTopic;
                            obj.resolvedSymbol.isInaccessible = true;
                        else
                            obj.resolvedSymbol.isUnderqualified = true;
                            if isInheritedMethod(obj.resolvedSymbol.classInfo)
                                qualifiedTopic = append(obj.resolvedSymbol.classInfo.superWrapper.packagedName, '/', methodName);
                                obj.resolvedSymbol.classInfo = [];
                                obj.doResolve(qualifiedTopic, false);
                            end
                            break;
                        end
                    end
                end
            end
        end
    end
end

function b = isInheritedMethod(classInfo)
    b = classInfo.isMethod && ~isempty(classInfo.superWrapper) && classInfo.superWrapper.hasClassHelp;
end

%   Copyright 2015-2024 The MathWorks, Inc.
