classdef rawUDD < matlab.lang.internal.introspective.classWrapper.UDD & matlab.lang.internal.introspective.classWrapper.raw
    properties (Access = private)
        packageHandle;
        classLoaded = false;
    end
    
    methods
        function cw = rawUDD(className, packagePath, packageHandle, isUnspecifiedConstructor)
            cw.isUnspecifiedConstructor = isUnspecifiedConstructor;
            cw.className = className;
            cw.packageName = packageHandle.Name;
            cw.subClassPath = fullfile(packagePath, append('@', className));
            cw.classPaths = {cw.subClassPath};
            cw.subClassPackageName = cw.packageName;
            cw.packageHandle = packageHandle;
            cw.schemaClass = [];
        end

        function classInfo = getConstructor(cw, ~)
            classInfo = matlab.lang.internal.introspective.classInformation.fullConstructor(cw, cw.packageName, cw.className, cw.subClassPath, false, cw.isUnspecifiedConstructor, true);
        end
    end
    
    methods (Access=protected)
        function classInfo = getLocalElement(cw, elementName, justChecking)
            classInfo = [];
            classMethods = methods(append(cw.packageName, '.', cw.className));
            methodIndex = strcmpi(classMethods, elementName);
            if any(methodIndex)
                elementName = classMethods{methodIndex};
                if justChecking
                    classInfo = matlab.lang.internal.introspective.classInformation.fileMethod(cw, cw.className, cw.subClassPath, cw.subClassPath, elementName, '.m', cw.subClassPackageName);
                else
                    classInfo = cw.getSuperElement(elementName);
                    if ~isempty(classInfo)
                        classInfo.className = cw.className;
                    end
                end
            end
        end
        
        function loadClass(cw)
            if ~cw.classLoaded
                cw.classLoaded = true;
                try %#ok<TRYNC> probably an error parsing the class file
                    cw.schemaClass = cw.packageHandle.findclass(cw.className);
                end
            end
        end
    end
end

%   Copyright 2007-2023 The MathWorks, Inc.
