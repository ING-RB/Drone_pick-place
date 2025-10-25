classdef simpleMCOSElement < matlab.lang.internal.introspective.classInformation.classElement
    properties (SetAccess=private, GetAccess=private)
        elementKeyword;
        elementMeta;
    end

    methods
        function ci = simpleMCOSElement(classWrapper, elementMeta, classPath, elementKeyword, packageName)
            if ischar(classWrapper)
                className = classWrapper;
                classWrapper = [];
            else
                className = classWrapper.className;
            end
            elementName = elementMeta.Name;
            definition = fullfile(classPath, append(className, filemarker, elementName));
            whichTopic = which(fullfile(classPath, className));
            ci@matlab.lang.internal.introspective.classInformation.classElement(classWrapper, packageName, className, elementName, definition, definition, whichTopic)
            ci.elementKeyword = elementKeyword;
            ci.isSimpleElement = true;
            ci.elementMeta = elementMeta;
        end

        function b = isAccessibleElement(ci, classElement)
            b = matlab.lang.internal.introspective.isAccessible(classElement, ci.elementKeyword);
        end

        function topic = fullTopic(ci)
            topic = append(matlab.lang.internal.introspective.makePackagedName(ci.packageName, ci.className), ci.separator, ci.element);
        end

        function k = getKeyword(ci)
            k = ci.elementKeyword;
        end

        function description = getDescription(ci, justH1)
            description = matlab.lang.internal.introspective.getBuiltinHelpText(ci.elementMeta, ci.fullTopic, justH1);
        end
    end

    methods (Access=protected)
        function helpText = helpfunc(ci, justH1)
            helpText = matlab.lang.internal.introspective.callHelpFunction(@ci.getHelpTextFromFile, ci.whichTopic, justH1);
        end
    end

    methods (Access=protected)
        function patterns = helpPatterns(ci)
            patterns.section = append('^(?<offset>\s*', ci.elementKeyword, '\>.*)(?<inside>.*\n)*?^\s*end\>');
            patterns.element = '^(?<preHelp>[ \t]*+%.*+\n)*(?<offset>[ \t]*+)(?<element>\w++)(''[^\n'']*+''|[^\n%])*+(?<postHelp>%.*+\n)?';
        end
    end

    methods (Static, Access=protected)
        function [helpText, prependName] = extractHelpText(helpSection)
            prependName = false;
            if helpSection.preHelp ~= ""
                helpText = helpSection.preHelp;
            else
                prependName = true;
                helpText = helpSection.postHelp;
            end
        end
    end
end


%   Copyright 2007-2024 The MathWorks, Inc.
