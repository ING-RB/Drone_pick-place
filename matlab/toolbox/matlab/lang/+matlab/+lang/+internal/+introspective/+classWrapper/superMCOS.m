classdef superMCOS < matlab.lang.internal.introspective.classWrapper.MCOS & matlab.lang.internal.introspective.classWrapper.super
    properties (SetAccess=private, GetAccess=private)
        elementKeyword = '';
        classElement;
    end

    methods
        function cw = superMCOS(metaClass, subClassPath, subClassName, subClassPackageName, isCaseSensitive, elementKeyword, classElement)
            packagedName = metaClass.Name;
            [className, packages] = regexp(packagedName, '\w*$', 'match', 'split', 'once');
            classFile = matlab.lang.internal.introspective.safeWhich(packagedName);
            classDir = fileparts(classFile);

            if classDir == ""
                packages = replace(packages{1}, '.', filesep);
                packages = replace(packages, letterBoundary("start"), '+');
                classFolder = matlab.lang.internal.introspective.hashedDirInfo(packages + "@" + className);
                if ~isempty(classFolder)
                    classDir = classFolder(1).path;
                else
                    classFile = matlab.lang.internal.introspective.safeWhich(append(packages, className));
                    classDir = fileparts(classFile);
                end
            end

            cw = cw@matlab.lang.internal.introspective.classWrapper.MCOS(packagedName, className, classDir);
            cw.metaClass = metaClass;

            packageList = regexp(cw.packagedName, '\w+(?=\.)', 'match');
            if isempty(packageList)
                allClassDirs = matlab.lang.internal.introspective.hashedDirInfo(append('@', cw.className));
                cw.classPaths = {allClassDirs.path};
            else
                packageFolder = join(append('+', string(packageList)), '/');
                classFolder = packageFolder + '/@' + cw.className;
                classFolders = matlab.lang.internal.introspective.hashedDirInfo(classFolder);
                cw.classPaths = {classFolders.path};
            end

            cw.subClassPath          = subClassPath;
            cw.subClassName          = subClassName;
            cw.subClassPackageName   = subClassPackageName;

            cw.isCaseSensitive = isCaseSensitive;
            cw.elementKeyword = elementKeyword;
            cw.classElement = classElement;
        end

        function classInfo = getSimpleElement(cw, classElement, elementKeyword)
            classdefInfo = cw.getSimpleElementHelpFile;
            classInfo = matlab.lang.internal.introspective.classInformation.simpleMCOSElement(cw, classElement, fileparts(classdefInfo.definition), elementKeyword, cw.subClassPackageName);
        end

        function b = hasClassHelp(cw)
            if cw.metaClass.Hidden
                b = false;
            else
                classInfo = cw.getClassHelpFile;
                b = classInfo.hasHelp;
            end
        end

        function classInfo = getSimpleElementHelpFile(cw)
            classInfo = cw.getClassHelpFile;
        end

        function elementMeta = getElementMeta(cw, ~)
            elementMeta = cw.classElement;
        end
    end

    methods (Access=protected)
        function classInfo = getLocalElement(cw, elementName, ~)
            if cw.elementKeyword == ""
                classInfo = cw.innerGetLocalMethod(elementName, cw.classElement.Abstract, cw.classElement.Static);
            else
                classInfo = cw.getSimpleElement(cw.classElement, cw.elementKeyword);
            end
        end

        function b = isConstructor(~, ~)
            b = false;
        end

        function classInfo = getClassHelpFile(cw)
            classInfo = matlab.lang.internal.introspective.classInformation.simpleMCOSConstructor(cw.className, matlab.lang.internal.introspective.safeWhich(fullfile(cw.classDir, cw.className)), false);
            if ~isempty(cw.metaClass.Namespace)
                classInfo.packageName = cw.metaClass.Namespace.Name;
            end
        end
    end
end

%   Copyright 2007-2024 The MathWorks, Inc.
