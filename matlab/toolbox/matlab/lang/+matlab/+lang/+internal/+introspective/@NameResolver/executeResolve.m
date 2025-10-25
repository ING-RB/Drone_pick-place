function executeResolve(obj, isCaseSensitive)
    try
        if nargin > 1
            obj.resolvedSymbol.isCaseSensitive = isCaseSensitive;
            obj.doResolve(obj.resolvedSymbol.topicInput, obj.findVariables);
            return;
        end

        obj.resolvedSymbol.isCaseSensitive = true;
        obj.doResolve(obj.resolvedSymbol.topicInput, obj.findVariables);

        if obj.resolvedSymbol.isResolved
            return;
        end

        if matlab.lang.internal.introspective.isAbsoluteFile(obj.resolvedSymbol.topicInput)
            refName = "";
            hasExactRefMatch = false;
        else
            [refName, refCaseMatch, refUnderqualified] = obj.referenceResolve(obj.resolvedSymbol.topicInput);
            hasExactRefMatch = refCaseMatch && ~refUnderqualified && obj.findBuiltins;
        end

        if ~hasExactRefMatch || obj.helpPath ~= ""
            obj.resolvedSymbol.isCaseSensitive = false;
            obj.doResolve(obj.resolvedSymbol.topicInput, obj.findVariables);

            if hasExactRefMatch && ~obj.isPathQualified || refName ~= "" && isOverqualified(obj)
                obj.resolvedSymbol.classInfo  = [];
                obj.resolvedSymbol.whichTopic = '';
            end
        end

        if obj.resolvedSymbol.isResolved
            return;
        end

        if refName ~= ""
            obj.resolvedSymbol.isCaseSensitive = refCaseMatch;
            if ~refUnderqualified
                if obj.findBuiltins
                    if ~obj.justChecking
                        mcosResolver = matlab.lang.internal.introspective.MCOSMetaResolver(refName);
                        mcosResolver.resolveUsingCase(true);
                        if mcosResolver.isResolved
                            obj.resolvedSymbol.classInfo = mcosResolver;
                            obj.resolvedSymbol.isAlias = mcosResolver.isClass && any(mcosResolver.resolvedMeta.Aliases == refName);
                        end
                    end
                    obj.setBuiltinName(refName);
                    return;
                end
            else
                obj.resolvedSymbol.isUnderqualified = true;
                if obj.justChecking
                    obj.setBuiltinName(refName);
                    return;
                end
                obj.doResolve(refName, false);
                if obj.resolvedSymbol.isResolved
                    obj.resolvedSymbol.isCaseSensitive = refCaseMatch;
                    return;
                elseif obj.findBuiltins
                    obj.setBuiltinName(refName);
                    return;
                end
            end
        end

        obj.resolvedSymbol.isCaseSensitive = true;
        obj.underqualifiedResolve(obj.resolvedSymbol.topicInput);

        if obj.resolvedSymbol.isResolved
            return;
        end

        obj.resolvedSymbol.isCaseSensitive = false;
        obj.underqualifiedResolve(obj.resolvedSymbol.topicInput);

        if obj.resolvedSymbol.isResolved
            return;
        end

        if obj.findBuiltins
            obj.resolvedSymbol.isCaseSensitive = true;
            obj.resolvedSymbol.isBuiltin = matlab.lang.internal.introspective.isBuiltin(obj.resolvedSymbol.topicInput);
            if ~obj.malformed && ~obj.resolvedSymbol.isBuiltin
                obj.resolveWithTypos;
            end
        end
    catch
        obj.resolvedSymbol.classInfo    = [];
        obj.resolvedSymbol.nameLocation = '';
        obj.resolvedSymbol.whichTopic   = '';
    end
end

function b = isOverqualified(obj)
    b = obj.resolvedSymbol.whichTopic ~= "";
    if b
        [~, functionName] = fileparts(obj.resolvedSymbol.whichTopic);
        standardName = matlab.lang.internal.diagnostic.getStandardFunctionName(obj.resolvedSymbol.whichTopic, functionName);
        b = strlength(standardName) < strlength(obj.resolvedSymbol.topicInput);
    end
end

%   Copyright 2013-2024 The MathWorks, Inc.
