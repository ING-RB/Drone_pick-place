classdef fileConstructor < matlab.lang.internal.introspective.classInformation.constructor
    properties (SetAccess=protected, GetAccess=protected)
        noAtDir = true;
        classPath = '';
        classWrapper = [];
        isCaseSensitive = false;
    end
    
    methods
        function ci = fileConstructor(packageName, className, classPath, fullPath, noAtDir, justChecking, isCaseSensitive)
            ci@matlab.lang.internal.introspective.classInformation.constructor(packageName, className, fullPath, fullPath, justChecking);
            ci.classPath = classPath;
            ci.noAtDir = noAtDir;
            
            if nargin > 6
               ci.isCaseSensitive = isCaseSensitive; 
            end
        end
        
        function helpText = getSecondaryHelp(ci, justH1)
            ci.prepareForSecondaryHelp;
            helpText = ci.helpfunc(justH1);
        end
        
        function b = hasHelp(ci)
            b = ci.checkHelp;
            if ~b
                ci.prepareForSecondaryHelp;
                b = ci.checkHelp;
            end
        end
        
        function constructorInfo = getConstructorInfo(ci, useClassHelp)
            constructorInfo = [];
            if useClassHelp || ci.checkHelp
                % only concerned with constructor info if there is both class and constructor help
                constructorInfo = matlab.lang.internal.introspective.classInformation.localConstructor(ci.packageName, ci.className, ci.classPath, false);
                if ~useClassHelp && ~constructorInfo.hasHelp
                    constructorInfo = [];                    
                end
            end
        end
        
        function methodInfo = getMethodInfo(ci, classMethod, inheritHelp)
            ci.createWrapper;
            methodInfo = ci.classWrapper.getMethod(classMethod);
            if ~isempty(methodInfo)
                methodInfo.inheritHelp = inheritHelp;
            end
        end
        
        function elementInfo = getSimpleElementInfo(ci, classElement, elementKeyword, inheritHelp)
            ci.createWrapper;
            elementInfo = ci.classWrapper.getSimpleElement(classElement, elementKeyword, false);
            if ~isempty(elementInfo)
                elementInfo.inheritHelp = inheritHelp;
            end
        end
    end
    
    methods (Access=private)
        function prepareForSecondaryHelp(ci)
            % did not find help for the constructor, see if there is help for the localFunction constructor
            ci.definition = append(ci.whichTopic, filemarker, ci.className);
        end

        function createWrapper(ci)
            if isempty(ci.classWrapper)
                if ci.noAtDir
                    packagePath = ci.classPath;
                else
                    packagePath = fileparts(ci.classPath);
                end
                ci.classWrapper = matlab.lang.internal.introspective.classWrapper.rawMCOS(ci.className, '', packagePath, ci.packageName, ci.noAtDir, false, ci.isCaseSensitive);
            end
        end
    end
end

%   Copyright 2007-2023 The MathWorks, Inc.
