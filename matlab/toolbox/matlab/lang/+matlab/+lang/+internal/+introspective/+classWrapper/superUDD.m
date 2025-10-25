classdef superUDD < matlab.lang.internal.introspective.classWrapper.UDD & matlab.lang.internal.introspective.classWrapper.super
    methods
        function cw = superUDD(schemaClass, subClassPath, subClassPackageName)
            cw.subClassPackageName = subClassPackageName;
            cw.subClassPath = subClassPath;
            cw.schemaClass = schemaClass;
            cw.className = schemaClass.Name;
            cw.packageName = schemaClass.Package.Name;
            allPackageDirs = matlab.lang.internal.introspective.hashedDirInfo(append('@', cw.packageName));
            packagePaths = {allPackageDirs.path};
            cw.classPaths = strcat(packagePaths, append('/@', cw.className));
        end
        
        function classInfo = getElement(cw, elementName, justChecking)
            if strcmpi(cw.className, elementName)
                classInfo = cw.getSuperElement(elementName);
            else
                classInfo = cw.getElement@matlab.lang.internal.introspective.classWrapper.UDD(elementName, justChecking);
            end
        end
        
        function b = hasClassHelp(cw)
            classInfo = cw.getClassHelpFile;
            if isempty(classInfo)
                b = false;
            else
                b = classInfo.hasHelp;
            end
        end

        function classInfo = getSimpleElementHelpFile(cw)
            classInfo = cw.getFileMethod('schema');
        end
    end
    
    methods (Access=protected)
        function classInfo = getLocalElement(cw, elementName, ~)
            classInfo = cw.getSuperElement(elementName);
        end

        function b = isConstructor(~, ~)
            b = false;
        end

        function classInfo = getClassHelpFile(cw)
            classInfo = cw.getFileMethod(cw.className);
        end
    end
end

%   Copyright 2007-2024 The MathWorks, Inc.
