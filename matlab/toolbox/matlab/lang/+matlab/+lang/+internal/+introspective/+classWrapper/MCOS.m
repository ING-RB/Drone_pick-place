classdef MCOS < matlab.lang.internal.introspective.classWrapper.base
    properties
        packagedName = '';
    end
    
    properties (SetAccess=protected, GetAccess=protected)
        metaClass = [];
        classDir = '';
        classHasNoAtDir = false;
        fileType = '';
    end
    
    methods
        function [helpText, shadowedClassInfo, shadowedWrapper] = getShadowedHelp(cw, elementName, justH1)
            helpText = '';
            shadowedClassInfo = [];
            shadowedWrapper = [];
            cw.loadClass;
            if ~isempty(cw.metaClass)
                supers = cw.metaClass.SuperClasses;
                for i = 1:numel(supers)
                    super = supers{i};
                    superElement = matlab.lang.internal.introspective.getMethod(super, elementName, true);
                    if isempty(superElement)
                        [superElement, elementKeyword] = matlab.lang.internal.introspective.getSimpleElement(super, elementName, true);
                    else
                        elementKeyword = '';
                    end
                    if ~isempty(superElement)
                        definingClass = superElement.DefiningClass;
                        shadowedClassInfo = cw.getSuperClassInfo(definingClass, elementKeyword, superElement);
                        % hasHelp is recursive, so superclass shadowed classes will be found
                        if ~isempty(shadowedClassInfo)
                            helpText = shadowedClassInfo.innerGetHelp(justH1);
                            if helpText ~= ""
                                shadowedWrapper = shadowedClassInfo.superWrapper;
                                return;
                            end
                        end
                    end
                end
            end
        end
        
        function elementMeta = getElementMeta(cw, elementName)
            elementMeta = [];
            cw.loadClass;
            if ~isempty(cw.metaClass)
                elementMeta = matlab.lang.internal.introspective.getMethod(cw.metaClass, elementName);
            end
        end
        
        function helpText = getElementDescription(cw, elementName, justH1)
            helpText = '';
            elementMeta = cw.getElementMeta(elementName);
            if ~isempty(elementMeta)
                fullElementName = matlab.lang.internal.introspective.getFullElementName(cw.packagedName, elementMeta);
                helpText = matlab.lang.internal.introspective.getBuiltinHelpText(elementMeta, fullElementName, justH1);
            end
        end
    end
    
    methods (Access=protected)
        function cw = MCOS(packagedName, className, classDir)
            cw.packagedName = packagedName;
            cw.className = className;
            cw.classDir = classDir;
            if endsWith(cw.classDir, append('@', cw.className))
                cw.classPaths = {cw.classDir};
            end
        end
        
        function loadClass(cw)
            if isempty(cw.metaClass)
                cw.metaClass = matlab.lang.internal.introspective.getMetaClass(cw.packagedName);
            end
        end
        
        function classInfo = getSuperClassInfo(cw, definingClass, elementKeyword, classElement)
            definingClassWrapper = matlab.lang.internal.introspective.classWrapper.superMCOS(definingClass, cw.subClassPath, cw.subClassName, cw.subClassPackageName, cw.isCaseSensitive, elementKeyword, classElement);
            classInfo = definingClassWrapper.getElement(classElement.Name, false);
            if ~isempty(classInfo)
                classInfo.className = cw.className;
                if cw.classHasNoAtDir
                    classInfo.insertClassName;
                end
                definingClassWrapper.classHasNoAtDir = cw.classHasNoAtDir;
                classInfo.superWrapper = definingClassWrapper;
            end
        end
        
        function classInfo = innerGetLocalMethod(cw, methodName, isAbstract, isStatic)
            classInfo = [];
            if cw.classDir ~= ""
                classMFile = which(fullfile(cw.classDir, cw.className));
                [~, ~, ext] = fileparts(classMFile);
                if ~strcmp(ext, '.p') && ~isAbstract && ~any(strcmp(which('-subfun',classMFile), append(cw.className, '.', methodName)))
                    return;
                end
                if isAbstract
                    classInfo = matlab.lang.internal.introspective.classInformation.abstractMethod(cw, cw.className, cw.classDir, classMFile, cw.subClassPath, cw.subClassName, methodName, cw.subClassPackageName);
                else
                    classInfo = matlab.lang.internal.introspective.classInformation.localMethod(cw, cw.className, cw.classDir, classMFile, cw.subClassPath, cw.subClassName, methodName, cw.subClassPackageName);
                end
                classInfo.setStatic(isStatic);
            end
        end
    end
end

%   Copyright 2007-2024 The MathWorks, Inc.
