classdef base < handle
    properties (SetAccess=protected, GetAccess=public)
        className = '';
    end
    
    properties (SetAccess=protected, GetAccess=protected)
        classPaths = {};
        subClassName = '';
        subClassPath = '';
        subClassPackageName = '';
        isCaseSensitive = false;
    end
    
    methods (Abstract, Access=protected)
        classInfo = getLocalElement(cw, elementName, justChecking);
    end
    
    
    methods
        function classInfo = getClassInformation(cw, elementName, justChecking)
            if cw.isConstructor(elementName)
                classInfo = cw.getConstructor(justChecking);
            else
                classInfo = cw.getElement(elementName, justChecking);
            end
        end

        function classInfo = getElement(cw, elementName, justChecking)
            classInfo = cw.getFileMethod(elementName);
            if isempty(classInfo)
                classInfo = cw.getLocalElement(elementName, justChecking);
            end
        end
        
        function [helpText, shadowedClassInfo, shadowedWrapper] = getShadowedHelp(~, ~, ~, ~)
            helpText = '';
            shadowedClassInfo = [];
            shadowedWrapper = [];
        end
        
        function helpText = getElementDescription(~, ~, ~)
            helpText = '';
        end
    end

    methods (Access=protected)
        function classInfo = getFileMethod(cw, methodName)
            classInfo = [];
            for j=1:numel(cw.classPaths)
                allClassInfo = matlab.lang.internal.introspective.hashedDirInfo(cw.classPaths{j}, cw.isCaseSensitive);
                if isempty(allClassInfo)
                    cw.classPaths{j} = fileparts(cw.classPaths{j});
                else
                    for i = 1:numel(allClassInfo)
                        classDirInfo = allClassInfo(i);
                        [fixedName, foundTarget, fileType] = matlab.lang.internal.introspective.extractFile(classDirInfo, methodName, cw.isCaseSensitive);
                        if foundTarget
                            classInfo = matlab.lang.internal.introspective.classInformation.fileMethod(cw, cw.className, classDirInfo.path, cw.subClassPath, fixedName, fileType, cw.subClassPackageName);
                            return;
                        end
                    end
                end
            end
        end
        
        function b = isConstructor(cw, methodName)
            b = matlab.lang.internal.introspective.casedStrCmp(cw.isCaseSensitive, cw.className, methodName);
        end
    end
end

%   Copyright 2007-2024 The MathWorks, Inc.
