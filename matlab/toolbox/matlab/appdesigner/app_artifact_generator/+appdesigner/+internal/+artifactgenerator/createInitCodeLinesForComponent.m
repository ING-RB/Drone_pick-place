function [componentProperties, componentInfo] = createInitCodeLinesForComponent(codeBuilder, element, parentCodeName, dataMap, filepath, iterateChildren, isLoad)
    %CREATEINITCODELINEFORCOMPONENT

%   Copyright 2024 The MathWorks, Inc.

    arguments
        codeBuilder appdesigner.internal.artifactgenerator.AppMCodeBuilder
        element matlab.io.xml.dom.Element
        parentCodeName char
        dataMap dictionary
        filepath string
        iterateChildren logical = true
        isLoad logical = false
    end

    import appdesigner.internal.artifactgenerator.AppendixConstants;

    componentInfo = [];

    className = element.TagName;

    [informalInterface, additionalArgs, callbackFunctions] = appdesigner.internal.artifactgenerator.extractMappingData(dataMap, className);

    % FIX THIS, IT IS AN ASSUMPTION AND NOT ROBUST
    % Should look at UAC registrations, but can't until registrations are deployable, any other solution for this??
    % Deployable registration epic: https://jira.mathworks.com/browse/FILESYSUI-8853
    isUac = strcmp(informalInterface, className);

    codeName = element.getAttribute('name');
    
    if isempty(codeName)
        ex = appdesigner.internal.artifactgenerator.exception.AppAppendixException(filepath);
        throw(ex);
    end

    [componentProperties, childrenEl] = appdesigner.internal.artifactgenerator.getPropertiesFromComponentElement(element, parentCodeName, AppendixConstants.GeneratedCodeAppObjectName, isLoad);

    if isLoad
        componentInfoTemplate = struct( ...
            'ClassName', '', ...
            'CodeName', '', ...
            'AssignedCallbacks', [], ...
            'LabelName', '', ...
            'IsResponsiveContainer', false, ...
            'Children', []);

        componentInfo = componentInfoTemplate;

        componentInfo.ClassName = className;
        componentInfo.CodeName = codeName;
        componentInfo.AssignedCallbacks = [];
        componentInfo.Children = [];
        componentInfo.LabelName = '';
        componentInfo.IsResponsiveContainer = false;

        labelNameAttr = element.getAttribute('labelName');
        if ~isempty(labelNameAttr)
            componentInfo.LabelName = labelNameAttr;
        end

        responsiveAttr = element.getAttribute('autoReflow');
        if ~isempty(responsiveAttr)
            if strcmp(responsiveAttr, 'true')
                componentInfo.IsResponsiveContainer = true;
            end
        end

        [argumentString, extraLines, postChildrenLines, componentInfo.AssignedCallbacks] = ...
            appdesigner.internal.artifactgenerator.getComponentPropertyAssignments(className, additionalArgs, componentProperties, codeName, callbackFunctions, isUac, isLoad);
    else

        [argumentString, extraLines, postChildrenLines] = appdesigner.internal.artifactgenerator.getComponentPropertyAssignments(className, additionalArgs, componentProperties, codeName, callbackFunctions, isUac, isLoad);
    end

    ctor = append(AppendixConstants.GeneratedCodeAppObjectName, '.', codeName, ' = ', informalInterface, '(', argumentString, ');');

    if isLoad
        dynamicProperty{1} = append(AppendixConstants.AppManagementServiceVariable, '.addDynamicProperties(', AppendixConstants.GeneratedCodeAppObjectName, '.', codeName, ', ', '''DesignTimeProperties''', ', ', ...
            'struct(', '''CodeName''', ', ''', codeName, '''), false, false);');
    else
        dynamicProperty = append(AppendixConstants.AppManagementServiceVariable, '.addDynamicProperties(', AppendixConstants.GeneratedCodeAppObjectName, '.', codeName, ', ', '''AD_CodeName''', ', ''', codeName, ''');');
    end

    codeBuilder.addCodeLines([ctor, extraLines, dynamicProperty]);

    if ~isLoad && strcmp(className, appdesigner.internal.artifactgenerator.AppendixConstants.UIFigureTagName)
        codeBuilder.addCodeLine(append(AppendixConstants.AppManagementServiceVariable, '.addDynamicPropertiesToFigure(', AppendixConstants.GeneratedCodeAppObjectName, '.', codeName, ', ', AppendixConstants.GeneratedCodeAppObjectName, ');'));
    end

    if iterateChildren && isa(childrenEl, 'matlab.io.xml.dom.Element')
        if isLoad
            componentInfo.Children = repmat(componentInfoTemplate, 1, childrenEl.getChildElementCount());
            childrenIndex = 1;
        end

        childNode = childrenEl.getFirstElementChild();

        while ~isempty(childNode) && isvalid(childNode)
            if isLoad
                [~, componentInfo.Children(childrenIndex)] = ...
                    appdesigner.internal.artifactgenerator.createInitCodeLinesForComponent(codeBuilder, childNode, codeName, dataMap, filepath, iterateChildren, isLoad);
                childrenIndex = childrenIndex + 1;
            else
                appdesigner.internal.artifactgenerator.createInitCodeLinesForComponent(codeBuilder, childNode, codeName, dataMap, filepath, iterateChildren, isLoad);
            end

            childNode = childNode.getNextElementSibling();
        end
    end

    codeBuilder.addCodeLines(postChildrenLines);
end
