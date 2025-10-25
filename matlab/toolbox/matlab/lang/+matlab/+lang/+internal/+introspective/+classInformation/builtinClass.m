classdef builtinClass < matlab.lang.internal.introspective.classInformation.constructor
    methods
        function ci = builtinClass(packageName, className)
            ci@matlab.lang.internal.introspective.classInformation.constructor(packageName, className, '', '', false);
            ci.minimalPath = ci.fullTopic;
        end
        
        function b = isClass(~)
            b = true;
        end
        
        function b = isMCOSClassOrConstructor(~)
            b = true;
        end
                
        function constructorInfo = getConstructorInfo(ci, ~)
            constructorInfo = ci.getStructInfo(ci.metaClass);
        end
        
        function methodInfo = getMethodInfo(ci, classMethod, ~)
            methodInfo = ci.getStructInfo(classMethod);
        end
        
        function elementInfo = getSimpleElementInfo(ci, classElement, ~, ~)
            elementInfo = ci.getStructInfo(classElement);
        end
    end

    methods (Access=private)
        function structInfo = getStructInfo(ci, elementMeta)
            structInfo.getHelp = @(~)'';
            fullElementName = matlab.lang.internal.introspective.getFullElementName(ci.fullClassName, elementMeta);
            structInfo.getDescription = @(justH1)matlab.lang.internal.introspective.getBuiltinHelpText(elementMeta, fullElementName, justH1);
        end
    end
end

%   Copyright 2019-2023 The MathWorks, Inc.
