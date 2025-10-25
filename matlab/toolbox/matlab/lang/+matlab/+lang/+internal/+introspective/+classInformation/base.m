classdef base < handle
    properties (SetAccess=protected, GetAccess=public)
        minimalPath (1,1) string = "";
        definition  (1,1) string = "";
        element     (1,1) string = "";

        isPackage       (1,1) logical = false;
        isMethod        (1,1) logical = false;
        isSimpleElement (1,1) logical = false;
    end

    properties
        isAccessible (1,1) logical = true;
    end

    properties (SetAccess=protected, GetAccess=protected)
        whichTopic = '';
    end

    properties (SetAccess=private, GetAccess=private)
        foundHelpFunction = false;
        helpFunction = '';
    end

    properties (SetAccess=public, GetAccess=protected)
        unaryName = '';
        isMinimal = false;
    end

    methods
        function ci = base(definition, minimalPath, whichTopic)
            ci.definition = definition;
            ci.minimalPath = minimalPath;
            ci.whichTopic = whichTopic;
        end

        function whichTopic = minimizePath(ci)
            whichTopic = ci.whichTopic;
            if ~isempty(ci.minimalPath)
                if ci.isMinimal
                    pathParts = regexp(ci.minimalPath, '^(?<qualifyingPath>[^@+]*)(?(qualifyingPath)[\\/])(?<pathItem>.*)', 'names', 'once');
                    ci.minimalPath = pathParts.pathItem;
                else
                    ci.minimalPath = matlab.lang.internal.introspective.minimizePath(ci.minimalPath, ci.isPackage || ci.isConstructor);
                end
            end
        end

        function insertClassName(ci) %#ok<MANU>
        end

        function helpText = getHelp(ci, justH1, hotLinkCommand, topic)
            if nargin < 4
                topic = '';
                if nargin < 3
                    hotLinkCommand = '';
                    if nargin < 2
                        justH1 = false;
                    end
                end
            end
            ci.overqualifyTopic(topic);
            helpText = ci.innerGetHelp(justH1);
            if helpText ~= "" && ~justH1
                helpText = ci.postprocessHelp(helpText, hotLinkCommand);
            end
        end

        function helpText = innerGetHelp(ci, justH1)
            helpText = ci.helpfunc(justH1);
            if helpText == ""
                helpText = ci.getSecondaryHelp(justH1);
            end
        end

        function description = getDescription(~, ~)
            description = '';
        end

        function helpText = getHelpForDescription(ci)
            helpText = ci.getHelp;
        end

        function b = hasHelp(ci)
            % some subclass implementations of hasHelp modify their definitions and
            % call checkHelp twice.
            b = checkHelp(ci);
        end

        function docLinks = getDocLinks(ci)
            docLinks = innerGetDocLinks(ci, ci.fullTopic);
        end

        function set.unaryName(ci, name)
            if ~isempty(regexp(name, '^\w*$', 'once'))
                ci.unaryName = matlab.lang.internal.introspective.extractCaseCorrectedName(ci.definition, name); %#ok<MCSUP>
            end
        end

        function helpText = getSecondaryHelp(~, ~)
            helpText = '';
        end

        function topic = fullTopic(ci)
            topic = ci.definition;
        end

        function b = isClass(~)
            b = false;
        end

        function b = isConstructor(~)
            b = false;
        end

        function b = isMCOSClassOrConstructor(~)
            b = false;
        end

        function b = isMCOSClass(ci)
            b = ci.isClass() && ci.isMCOSClassOrConstructor();
        end

        function b = isInherited(~)
            b = false;
        end

        function k = getKeyword(~)
            k = '';
        end
    end

    methods (Access=protected)
        function b = checkHelp(ci)
            % checkHelp and hasHelp are different since some classInfos (like
            % constructors) can modify their definitions and call checkHelp twice.
            if ci.hasHelpFunction
                b = matlab.lang.internal.introspective.callHelpFunction(ci.helpFunction, ci.definition, true) ~= "";
            else
                docLinks = ci.getDocLinks;
                b = docLinks.referencePage ~= "";
            end
        end

        function helpText = helpfunc(ci, justH1)
            if ci.hasHelpFunction
                helpText = matlab.lang.internal.introspective.callHelpFunction(ci.helpFunction, ci.definition, justH1);
            else
                helpText = '';
            end
        end

        function helpText = postprocessHelp(~, helpText, ~)
        end

        function overqualifyTopic(~, ~)
        end

        function docLinks = innerGetDocLinks(ci, topic)
            docLinks = matlab.lang.internal.introspective.docLinks(ci.definition, topic, ci);
        end

        function b = hasHelpFunction(ci)
            if ~ci.foundHelpFunction
                ci.foundHelpFunction = true;
                [ci.helpFunction, targetExtension] = matlab.lang.internal.introspective.getHelpFunction(ci.whichTopic);
                b = ci.helpFunction ~= "";
                if b
                    [definitionPath, fileName, localFunction] = matlab.lang.internal.introspective.splitFilePath(ci.definition);
                    if ~contains(fileName, '.')
                        ci.definition = append(definitionPath, filesep, fileName, targetExtension, localFunction);
                    end
                end
            else
                b = ci.helpFunction ~= "";
            end
        end
    end
end

%   Copyright 2007-2024 The MathWorks, Inc.
