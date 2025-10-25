function doResolve(obj, topic, resolveWorkspace)
    if obj.resolvedSymbol.foundVar
        topic = obj.resolvedSymbol.resolvedTopic;
    elseif resolveWorkspace
        [topic, obj.resolvedSymbol.foundVar, obj.resolvedSymbol.topicInput] = matlab.internal.help.getClassNameFromWS(topic, obj.introspectiveContext.WorkspaceVariables, ~obj.resolvedSymbol.isCaseSensitive);
    end
    
    if obj.helpPath ~= "" && isValidIdentifier(topic)
        
        processedHelpPath = regexprep(obj.helpPath, '[@+]', '');
        
        if ~isempty(processedHelpPath) && isempty(obj.resolvedSymbol.classInfo)
            
            obj.resolveImplicitPath(fullfile(processedHelpPath, topic));
            
            if isempty(obj.resolvedSymbol.classInfo) && matlab.lang.internal.introspective.containers.isClassDirectory(obj.helpPath)
                [processedHelpPath, pop] = fileparts(processedHelpPath);
                if pop ~= ""
                    obj.resolveImplicitPath(fullfile(processedHelpPath, topic));
                end
            end
            
            if ~isempty(obj.resolvedSymbol.classInfo) && ~obj.resolvedSymbol.classInfo.isAccessible
                obj.resolvedSymbol.classInfo  = [];
                obj.resolvedSymbol.whichTopic = '';
            end
        end
    end
    
    if isempty(obj.resolvedSymbol.classInfo)
        % innerDoResolve may populate classInfo
        obj.innerDoResolve(topic);
    else
        obj.isPathQualified = true;
    end
    
    if ~isempty(obj.resolvedSymbol.classInfo)
        obj.resolvedSymbol.whichTopic = obj.resolvedSymbol.classInfo.minimizePath;
        obj.resolvedSymbol.elementKeyword = obj.resolvedSymbol.classInfo.getKeyword;
        obj.resolvedSymbol.resolvedTopic = obj.resolvedSymbol.classInfo.fullTopic;
    elseif obj.resolvedSymbol.foundVar
        obj.resolvedSymbol.resolvedTopic = topic;
    end
end

function b = isValidIdentifier(name)
    b = isvarname(name) || iskeyword(name);
end

%   Copyright 2014-2023 The MathWorks, Inc.
