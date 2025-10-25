classdef MCOSMetaResolver < handle
    properties
        resolvedMeta = [];
        fullTopic = '';

        fullTopicElements = {''};
        isCaseSensitive;

        isPackage = false;
        isClass = false;
        isConstructor = false;
        isMethod = false;
        fullClassName = "";
        fullSuperClassName = "";
        superWrapper = [];
        element = '';
        elementKeyword = '';
        isAccessible = true;
        unaryName = '';
        isInherited = false;

        isMinimal = true;
        definition = '';
    end

    properties (Dependent, SetAccess = private)
        minimalPath;
    end

    methods
        function obj = MCOSMetaResolver(topic)
            persistent mcosPattern
            persistent separators
            if isempty(mcosPattern)
                identifiers = asManyOfPattern(alphanumericsPattern(1) | characterListPattern("_*<>[],"), 1);
                separators = characterListPattern(".\/");
                mcosPattern = identifiers + asManyOfPattern(separators + identifiers);
            end
            if matches(topic, mcosPattern)
                obj.fullTopicElements = split(topic, separators);
            end
        end

        function executeResolve(obj)
            if ~any(cellfun('isempty', obj.fullTopicElements))
                obj.resolveUsingCase(true);

                if ~obj.isResolved
                    obj.resolveUsingCase(false);
                end
            end
        end

        function resolveUsingCase(obj, isCaseSensitive)
            obj.isCaseSensitive = isCaseSensitive;
            if isCaseSensitive
                obj.quickResolve();
            else
                obj.doResolve();

                if ~obj.isResolved
                    obj.resolveAliasClass;
                end
            end
        end

        function b = isResolved(obj)
            b = ~isempty(obj.resolvedMeta);
        end

        function b = isSimpleElement(obj)
            b = obj.fullClassName ~= "" && ~obj.isMethod;
        end

        function b = isMCOSClass(obj)
            b = obj.isClass;
        end

        function b = isMCOSClassOrConstructor(obj)
            b = obj.isClass || obj.isConstructor;
        end

        function docLinks = getDocLinks(obj)
            docLinks = matlab.lang.internal.introspective.helpers.inheritOrGetDocLinks(obj);
        end

        function minimalPath = minimizePath(obj)
            minimalPath = obj.fullTopic;
        end

        function keyword = getKeyword(obj)
            keyword = obj.elementKeyword;
        end

        function minimalPath = get.minimalPath(obj)
            minimalPath = obj.fullTopic;
        end

        function helpStr = getHelp(varargin)
            helpStr = '';
        end

        function description = getDescription(obj, justH1)
            description = matlab.lang.internal.introspective.getBuiltinHelpText(obj.resolvedMeta, obj.fullTopic, justH1);
            if description == ""
                if obj.isConstructor
                    description = matlab.lang.internal.introspective.getBuiltinHelpText(obj.resolvedMeta.DefiningClass, obj.fullTopic, justH1);
                elseif obj.isClass
                    className = extract(obj.fullTopic, regexpPattern("\w+$"));
                    constructorIndex = strcmp({obj.resolvedMeta.MethodList.Name}, className);
                    constructorIndex = find(constructorIndex, 1);
                    if constructorIndex ~= 0
                        description = matlab.lang.internal.introspective.getBuiltinHelpText(obj.resolvedMeta.MethodList(constructorIndex), obj.fullTopic, justH1);
                    end
                end
            end
        end

        function classInfo = getClassInfo(obj)
            if obj.isClass
                obj.fullTopicElements = split(string(obj.fullTopic), '.');
                if isscalar(obj.fullTopicElements)
                    packageName = "";
                else
                    packageName = join(obj.fullTopicElements(1:end-1), '.');
                end
                className = obj.fullTopicElements(end);
                classInfo = matlab.lang.internal.introspective.classInformation.builtinClass(packageName, className);
            else
                classInfo = obj;
            end
        end
    end

    methods(Access=private)
        function quickResolve(obj)
            multipart = numel(obj.fullTopicElements) > 1;
            if multipart
                parentName = char(join(obj.fullTopicElements(1:end-1), '.'));
                elementName = obj.fullTopicElements(end);
                class = matlab.lang.internal.introspective.getMetaClass(parentName);
                if ~isempty(class)
                    obj.resolveMCOSClassElement(class, elementName);
                    if obj.isResolved
                        return;
                    end
                end
            end
            fullName = char(join(obj.fullTopicElements, '.'));
            class = matlab.lang.internal.introspective.getMetaClass(fullName);
            if ~isempty(class)
                obj.setClass(class);
                return;
            end
            if multipart
                package = meta.package.fromName(parentName);
                if ~isempty(package)
                    obj.resolveMCOSPackagedFunction(package, elementName);
                    if obj.isResolved
                        return;
                    end
                end
            end
            package = meta.package.fromName(fullName);
            if ~isempty(package)
                obj.setPackage(package);
                return;
            end
        end

        function doResolve(obj)
            classes = meta.class.getAllClasses();
            classes = [classes{:}];

            obj.resolveMCOSClass(classes, obj.fullTopicElements);

            if ~obj.isResolved
                packages = meta.package.getAllPackages();
                packages = [packages{:}];

                obj.resolveMCOSPackage(packages, obj.fullTopicElements);
            end
        end

        function resolveMCOSPackage(obj, packages, topicElements)
            if ~isempty(packages) && ~isempty(topicElements)

                packageMatches = obj.getMetaInfoByName(packages, topicElements{1});

                for package = packageMatches
                    obj.resolveMCOSClass(package.ClassList, topicElements(2:end));

                    if ~obj.isResolved
                        obj.resolveMCOSPackagedFunction(package, topicElements(2:end));
                    end

                    if ~obj.isResolved
                        if numel(topicElements) > 1
                            obj.resolveMCOSPackage(package.PackageList, topicElements(2:end));
                        else
                            obj.setPackage(package);
                        end
                    end

                    if obj.isResolved
                        break;
                    end
                end
            end
        end

        function setPackage(obj, package)
            obj.resolvedMeta = package;
            obj.fullTopic = package.Name;
            obj.isPackage = true;
        end

        function setClass(obj, class)
            obj.resolvedMeta = class;
            obj.fullTopic = class.Name;
            obj.isAccessible = ~class.Hidden;
            obj.isClass = true;
        end

        function resolveMCOSClass(obj, classes, topicElements)
            if ~isempty(classes) && ~isempty(topicElements) && numel(topicElements) < 3
                classMatches = obj.getMetaInfoByName(classes, topicElements{1});

                if ~isempty(classMatches) && isscalar(topicElements)
                    obj.setClass(classMatches(1));
                else
                    for classMatch = classMatches
                        obj.resolveMCOSClassElement(classMatch, topicElements(2));
                        if obj.isResolved
                            break;
                        end
                    end
                end
            end
        end

        function resolveMCOSPackagedFunction(obj, package, topicElements)
            if ~isempty(package) && isscalar(topicElements)
                obj.resolveElementMetaInfo("", topicElements{1}, package.FunctionList);

                if obj.isResolved
                    obj.fullTopic = append(package.Name, '.', obj.resolvedMeta.Name);
                end
            end
        end

        function resolveMCOSClassElement(obj, class, topicElements)
            if ~isempty(class) && isscalar(topicElements)
                obj.element = topicElements{1};

                obj.elementKeyword = 'methods';
                obj.resolveElementMetaInfo(class.Name, obj.element, class.MethodList);
                obj.isConstructor = matlab.lang.internal.introspective.casedStrCmp(obj.isCaseSensitive, obj.fullTopicElements{end}, obj.fullTopicElements{end-1});
                if obj.isResolved
                    if ~obj.isConstructor
                        obj.isMethod = true;
                    end
                elseif obj.isConstructor
                    obj.elementKeyword = 'class';
                    obj.resolvedMeta = class;
                    obj.fullClassName = class.Name;
                else
                    obj.elementKeyword = 'properties';
                    obj.resolveElementMetaInfo(class.Name, obj.element, class.PropertyList);
                end
                if ~obj.isResolved
                    obj.elementKeyword = 'events';
                    obj.resolveElementMetaInfo(class.Name, obj.element, class.EventList);
                end
                if ~obj.isResolved
                    obj.elementKeyword = 'enumeration';
                    obj.resolveElementMetaInfo(class.Name, obj.element, class.EnumerationMemberList);
                end

                if obj.isResolved
                    obj.isAccessible = matlab.lang.internal.introspective.isAccessible(obj.resolvedMeta, obj.elementKeyword);
                    obj.fullTopic = matlab.lang.internal.introspective.getFullElementName(class.Name, obj.resolvedMeta);
                end
            end
        end

        function resolveAliasClass(obj)
            classMeta = obj.resolveAliasClassParts(obj.fullTopicElements);
            if ~isempty(classMeta)
                obj.setClass(classMeta);
            elseif numel(obj.fullTopicElements) > 1
                classMeta = obj.resolveAliasClassParts(obj.fullTopicElements(1:end-1));
                if ~isempty(classMeta)
                    obj.resolveMCOSClassElement(classMeta, obj.fullTopicElements(end));
                end
            end
        end

        function classMeta = resolveAliasClassParts(obj, parts)
            oldName = char(join(parts, '.'));
            [~, descriptor] = which(oldName);
            className = regexp(descriptor, '^[\w\.]*(?= constructor$)', 'match', 'once');
            classMeta = [];
            if className ~= ""
                classMeta = matlab.lang.internal.introspective.getMetaClass(className);
                if ~isempty(classMeta)
                    obj.isCaseSensitive = strcmp(className, oldName);
                end
            end
        end

        function matchedMetaInfo = getMetaInfoByName(obj, metaInfoList, name)
            if obj.isCaseSensitive
                regexpCase = 'matchcase';
            else
                regexpCase = 'ignorecase';
            end

            isMatch = regexp({metaInfoList.Name},append('\<', regexptranslate('escape', name), '$'),'once', regexpCase);
            isMatch = ~cellfun('isempty', isMatch);

            if any(isMatch)
                matchedMetaInfo = metaInfoList(isMatch);
                matchedMetaInfo = matchedMetaInfo(:)';
            else
                matchedMetaInfo = [];
            end
        end

        function resolveElementMetaInfo(obj, className, elementName, elementList)
            if ~obj.isResolved
                match = matlab.lang.internal.introspective.casedStrCmp(obj.isCaseSensitive,{elementList.Name}, elementName);
                match = find(match,1);

                if match ~= 0
                    obj.resolvedMeta = elementList(match);
                    obj.fullClassName = className;
                    definingClass = obj.resolvedMeta.DefiningClass;
                    if ~isempty(definingClass)
                        definingClassName = definingClass.Name;
                        obj.isInherited = ~matches(definingClassName, className);
                        if obj.isInherited
                            obj.fullSuperClassName = definingClassName;
                            obj.superWrapper = matlab.lang.internal.introspective.classWrapper.superMCOS(definingClass, '', className, '', obj.isCaseSensitive, obj.elementKeyword, obj.resolvedMeta);
                        end
                    end
                end
            end
        end
    end
end

%   Copyright 2014-2024 The MathWorks, Inc.
