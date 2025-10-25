classdef fileMethod < matlab.lang.internal.introspective.classInformation.method
    methods
        function ci = fileMethod(classWrapper, className, basePath, derivedPath, methodName, fileType, packageName)
            fileName = append(methodName, fileType);
            definition = fullfile(basePath, fileName);
            whichTopic = fullfile(derivedPath, fileName);
            ci@matlab.lang.internal.introspective.classInformation.method(classWrapper, packageName, className, methodName, definition, whichTopic, whichTopic);
        end

        function insertClassName(ci)
            ci.minimalPath = regexprep(ci.minimalPath, '(.*[\\/])(.*)', append('$1', ci.className, filemarker, '$2'));
        end
        
        function setAccessible(ci)
            packagedName = matlab.lang.internal.introspective.makePackagedName(ci.packageName, ci.className);
            metaClass = matlab.lang.internal.introspective.getMetaClass(packagedName);
            if isempty(metaClass)
                ci.isAccessible = true;
            else
                classMethod = matlab.lang.internal.introspective.getMethod(metaClass, ci.element);
                ci.setStatic(classMethod.Static);
                ci.setAccessibleFromMeta(classMethod);
            end
        end

        function helpText = getSecondaryHelp(ci, justH1)
            % Did not find help for a file function, see if there is help for a local function.
            % This is for an anomalous case, in which a method is defined as both a file in an @-dir
            % and as a local function in a classdef, in which the local function will eclipse the file.
            ci.definition = regexprep(ci.definition, '@(?<className>\w+)[\\/](?<methodName>\w*)(?<ext>\.\w+)?$', '@$<className>/$<className>$<ext>>$<methodName>');
            helpText = ci.helpfunc(justH1);
            if helpText == ""
                helpText = ci.getSecondaryHelp@matlab.lang.internal.introspective.classInformation.method(justH1);
            end            
        end
    end
end

%   Copyright 2007-2024 The MathWorks, Inc.
