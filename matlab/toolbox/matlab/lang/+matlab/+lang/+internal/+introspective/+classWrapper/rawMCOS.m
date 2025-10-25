classdef rawMCOS < matlab.lang.internal.introspective.classWrapper.MCOS & matlab.lang.internal.introspective.classWrapper.raw
    properties (SetAccess=private, GetAccess=private)
        packageName = '';
    end

    methods
        function cw = rawMCOS(className, fileType, packagePath, packageName, classHasNoAtDir, isUnspecifiedConstructor, isCaseSensitive)
            
            packagedName = matlab.lang.internal.introspective.makePackagedName(packageName, className);
            
            if classHasNoAtDir
                classDir = packagePath;
            else
                classDir = fullfile(packagePath, append('@', className));
            end
            
            cw = cw@matlab.lang.internal.introspective.classWrapper.MCOS(packagedName, className, classDir);
            
            cw.classHasNoAtDir          = classHasNoAtDir;
            cw.isUnspecifiedConstructor = isUnspecifiedConstructor;
            cw.packageName              = packageName;
            cw.fileType                 = fileType;
            cw.subClassPath             = classDir;
            cw.subClassPackageName      = cw.packageName;
            cw.subClassName             = cw.className;
            cw.isCaseSensitive          = isCaseSensitive;
        end

        function classInfo = getConstructor(cw, justChecking)
            if cw.isUnspecifiedConstructor
                classInfo = matlab.lang.internal.introspective.classInformation.fullConstructor(cw, cw.packageName, cw.className, cw.subClassPath, cw.classHasNoAtDir, true, justChecking);
            else
                classInfo = matlab.lang.internal.introspective.classInformation.localConstructor(cw.packageName, cw.className, cw.subClassPath, justChecking);
            end
        end

        function classInfo = getElement(cw, elementName, justChecking)
            if cw.classHasNoAtDir
                classInfo = cw.getLocalElement(elementName, justChecking);
            else
                classInfo = cw.getElement@matlab.lang.internal.introspective.classWrapper.MCOS(elementName, justChecking);
            end
            if ~isempty(classInfo)
                classInfo.setAccessible;
            end
        end
        
        function classInfo = getMethod(cw, classMethod)
            cw.loadClass;
            elementName = classMethod.Name;

            classInfo = cw.getFileMethod(elementName);
            if isempty(classInfo)
                classInfo = cw.innerGetMethod(classMethod);
            else
                classInfo.setAccessibleFromMeta(classMethod);
            end
        end

        function classInfo = getSimpleElement(cw, classElement, elementKeyword, justChecking)
            cw.loadClass;

            definingClass = classElement.DefiningClass;
            if definingClass == cw.metaClass || justChecking
                if ~justChecking && classElement.Description == ""
                    if which(fullfile(cw.classDir, cw.className)) == ""
                        classInfo = [];
                        return;
                    end
                end
                classInfo = matlab.lang.internal.introspective.classInformation.simpleMCOSElement(cw, classElement, cw.subClassPath, elementKeyword, cw.subClassPackageName);
            else
                definingClassWrapper = matlab.lang.internal.introspective.classWrapper.superMCOS(definingClass, cw.subClassPath, cw.subClassName, cw.subClassPackageName, cw.isCaseSensitive, elementKeyword, classElement);
                classInfo = definingClassWrapper.getSimpleElement(classElement, elementKeyword);
                classInfo.className = cw.className;
                classInfo.superWrapper = definingClassWrapper;
            end
            classInfo.isAccessible = classInfo.isAccessibleElement(classElement);
            switch (elementKeyword)
            case 'properties'
                classInfo.setStatic(classElement.Constant);
            case 'enumeration'
                classInfo.setStatic(true);
            end
        end
    end

    methods (Access=protected)
        function classInfo = getLocalElement(cw, elementName, justChecking)
            classInfo = [];
            cw.loadClass;
            if ~isempty(cw.metaClass)
                classMethod = matlab.lang.internal.introspective.getMethod(cw.metaClass, elementName, cw.isCaseSensitive);

                if ~isempty(classMethod)
                    classInfo = cw.innerGetMethod(classMethod);
                else
                    [classElement, elementKeyword] = matlab.lang.internal.introspective.getSimpleElement(cw.metaClass, elementName, cw.isCaseSensitive);

                    if ~isempty(classElement)
                        classInfo = cw.getSimpleElement(classElement, elementKeyword, justChecking);
                    end
                end
            end
        end
    end

    methods (Access=private)
        function classInfo = innerGetMethod(cw, classMethod)
            elementName = classMethod.Name;
            definingClass = classMethod.DefiningClass;
            if definingClass == cw.metaClass
                classInfo = innerGetLocalMethod(cw, elementName, classMethod.Abstract, classMethod.Static);
            else
                classInfo = cw.getSuperClassInfo(definingClass, '', classMethod);
            end
            if ~isempty(classInfo)
                classInfo.setAccessibleFromMeta(classMethod);
            end
        end
    end
end

%   Copyright 2007-2024 The MathWorks, Inc.
