function [classMFile, className, packageName] = resolveClassMFile(obj, topic)
    className = '';
    packageName = '';
    slashes = ["\" "/"];
    hasSlash = contains(topic, slashes);
    if ~obj.resolveOverqualified && hasSlash
        classMFile = '';
    else
        classMFile = matlab.lang.internal.introspective.safeWhich(topic, obj.resolvedSymbol.isCaseSensitive);
    end
    if classMFile ~= ""
        [isClassMFile, className, whichComment] = matlab.lang.internal.introspective.isClassMFile(classMFile);
        if ~isClassMFile
            className = '';
            if whichComment ~= "" && ~hasSlash
                classMFile = '';
            end
        end            
    elseif ~obj.resolvedSymbol.isCaseSensitive && ~obj.resolvedSymbol.foundVar
        [classMFile, descriptor] = which(replace(topic, slashes, '.'));
        [isClass, className, packageName] = matlab.lang.internal.introspective.isClassComment(descriptor);
        if isClass && endsWith(classMFile, ' is a built-in method')
            fullClassName =  matlab.lang.internal.introspective.makePackagedName(packageName, className);
            nr = matlab.lang.internal.introspective.NameResolver(fullClassName, QualifyingPath=obj.helpPath, JustChecking=obj.justChecking, IntrospectiveContext=obj.introspectiveContext, ResolveOverqualified=obj.resolveOverqualified);
            nr.doResolve(fullClassName, false);
            classMFile = nr.resolvedSymbol.nameLocation;
            isClass = classMFile ~= "";
        end
        if isClass
            obj.resolvedSymbol.isAlias = matlab.lang.internal.introspective.extractCaseCorrectedName(classMFile, topic) == "";
        else
            classMFile = '';
            className = '';
        end
    end        
end

%   Copyright 2019-2024 The MathWorks, Inc.
