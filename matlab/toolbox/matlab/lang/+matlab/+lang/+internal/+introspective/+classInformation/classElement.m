classdef classElement < matlab.lang.internal.introspective.classInformation.classItem
    properties (SetAccess=private, GetAccess=protected)
        separator = '/';
        classWrapper;
    end

    properties
        superWrapper                     = [];
        fullSuperClassName (1,1) string  = "";
        inheritHelp        (1,1) logical = true;
    end

    methods
        function ci = classElement(classWrapper, packageName, className, element, definition, minimalPath, whichTopic)
            ci@matlab.lang.internal.introspective.classInformation.classItem(packageName, className, definition, minimalPath, whichTopic);
            ci.classWrapper = classWrapper;
            ci.inheritHelp = ~isempty(classWrapper);
            ci.element = element;
        end

        function topic = fullTopic(ci)
            topic = ci.makeTopic(ci.fullClassName);
        end

        function docLinks = getDocLinks(ci)
            ci.prepareSuperClassName;
            docLinks = matlab.lang.internal.introspective.helpers.inheritOrGetDocLinks(ci);
        end

        function helpText = getSecondaryHelp(ci, justH1)
            helpText = '';
            if ci.inheritHelp
                [helpText, superClassInfo, ci.superWrapper] = ci.classWrapper.getShadowedHelp(ci.element, justH1);
                if ~isempty(superClassInfo)
                    % definition needs to refer to the implementation
                    ci.definition = superClassInfo.definition;
                end
            end
        end

        function b = isInherited(ci)
            b = ci.fullSuperClassName ~= "";
        end

        function description = getDescription(ci, justH1)
            description = ci.classWrapper.getElementDescription(ci.element, justH1);
        end

        function elementOffset = getElementOffset(ci)
            [~, elementOffset] = ci.getHelpTextFromFile(ci.whichTopic, true);
        end

        function setAccessible(~)
        end

        function setStatic(ci, b)
            if b
                ci.separator = '.';
            else
                ci.separator = '/';
            end

        end
    end

    methods (Access=protected)
        function [helpText, offset] = getHelpTextFromFile(ci, fullPath, justH1)
            helpText = '';
            offset = 0;
            classFile = matlab.internal.getCode(fullPath);
            allHelpSections = ci.getAllHelpSections(classFile);
            allHelpSections(~strcmp(ci.element, {allHelpSections.element})) = [];
            for helpSection = allHelpSections
                offset = helpSection.offset;
                [helpText, prependName] = ci.extractHelpText(helpSection);
                if helpText ~= ""
                    if justH1
                        helpText = matlab.lang.internal.introspective.containers.extractH1Line(helpText);
                    end
                    helpText = matlab.internal.help.sanitizeHelpComments(helpText, justH1);
                    if prependName
                        helpText = char(append(' ', ci.element, ' -', helpText));
                    end
                    return;
                end
            end
        end

        function allHelpSections = getAllHelpSections(ci, classFile)
            patterns = ci.helpPatterns;
            [helpSections, sectionOffset] = regexp(classFile, patterns.section, 'names', 'dotexceptnewline', 'lineanchors');
            helpSections = arrayfun(@(section, offset)setfield(section, 'offset', strlength(section.offset) + offset), helpSections, sectionOffset);

            [allHelpSections, helpOffset] = regexp({helpSections.inside}, patterns.element, 'names', 'dotexceptnewline', 'lineanchors');
            for idx = 1:numel(allHelpSections)
                allHelpSections{idx} = arrayfun(@(help, offset) setfield(help, 'offset', strlength(help.preHelp) + strlength(help.offset) + offset - 1 + helpSections(idx).offset), allHelpSections{idx}, helpOffset{idx});
            end
            allHelpSections = [allHelpSections{:}];
        end

        function patterns = helpPatterns(~)
            patterns.section = '';
            patterns.element = '';
        end

        function helpText = postprocessHelp(ci, helpText, hotLinkCommand)
            ci.prepareSuperClassName;
            if ci.isInherited
                helpText = matlab.lang.internal.introspective.helpers.modifyInheritedHelp(ci, helpText, hotLinkCommand);
            end
        end

        function prepareSuperClassName(ci)
            if ~isempty(ci.superWrapper)
                ci.fullSuperClassName = ci.superWrapper.packagedName;
            end
        end
    end

    methods (Static, Access=protected)
        function [helpText, prependName] = extractHelpText(~)
            helpText = '';
            prependName = false;
        end
    end

    methods (Access=private)
        function topic = makeTopic(ci, className)
            topic = append(className, ci.separator, ci.element);
        end
    end
end
%   Copyright 2012-2024 The MathWorks, Inc.
