function resolveUnaryClass(obj, className, elementName, elementSpecified)
    [obj.resolvedSymbol.whichTopic, className, packageName] = obj.resolveClassMFile(className);

    if className ~= ""
        if nargin < 3
            elementName = className;
            elementSpecified = false;
        end
        [packagePath, ~, classExt] = fileparts(obj.resolvedSymbol.whichTopic);
        classHandle = matlab.lang.internal.introspective.classWrapper.rawMCOS(className, extractAfter(classExt, 1), packagePath, packageName, true, ~elementSpecified, obj.resolvedSymbol.isCaseSensitive);
        obj.resolvedSymbol.classInfo = classHandle.getClassInformation(elementName, obj.justChecking);
    end
end

%   Copyright 2014-2024 The MathWorks, Inc.
