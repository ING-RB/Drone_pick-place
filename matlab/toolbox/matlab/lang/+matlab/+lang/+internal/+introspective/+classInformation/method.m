classdef method < matlab.lang.internal.introspective.classInformation.classElement
    properties
        isAbstract = false;
    end

    methods
        function ci = method(classWrapper, packageName, className, methodName, definition, minimalPath, whichTopic)
            ci@matlab.lang.internal.introspective.classInformation.classElement(classWrapper, packageName, className, methodName, definition, minimalPath, whichTopic);
            ci.isMethod = true;
        end

        function k = getKeyword(~)
            k = 'methods';
        end

        function setAccessibleFromMeta(ci, methodMeta)
            ci.isAccessible = matlab.lang.internal.introspective.isAccessible(methodMeta, 'methods');
            ci.inheritHelp = ~ischar(methodMeta.Access) || methodMeta.Access ~= "private";
        end
    end
end

%   Copyright 2007-2023 The MathWorks, Inc.
