function resolveWithTypos(obj)
    if obj.fixTypos && isempty(matlab.lang.internal.introspective.hashedDirInfo(obj.resolvedSymbol.topicInput))
        topicInput = obj.resolvedSymbol.topicInput;
        [path, file, ext] = fileparts(topicInput);
        if path == ""
            candidateList = {obj.introspectiveContext.WorkspaceVariables.name};
            possibleTopic = matlab.lang.internal.errorrecovery.namesuggestion(file, candidateList);
            if possibleTopic ~= ""
                possibleTopic = append(possibleTopic, ext);
                obj.doResolve(possibleTopic, true);
                if obj.resolvedSymbol.isResolved
                    if ~isempty(obj.resolvedSymbol.classInfo) && ~obj.resolvedSymbol.classInfo.isAccessible
                        obj.resetTopic;
                        obj.resolvedSymbol.isInaccessible = true;
                    else
                        obj.resolvedSymbol.isTypo = true;
                        obj.resolvedSymbol.resolvedTopic = possibleTopic;
                    end
                else
                    refName = obj.referenceResolve(possibleTopic);
                    if refName ~= ""
                        obj.resolvedSymbol.isTypo = true;
                        obj.setBuiltinName(refName);
                    end
                end
            end
        end
    end
end

%   Copyright 2015-2023 The MathWorks, Inc.
