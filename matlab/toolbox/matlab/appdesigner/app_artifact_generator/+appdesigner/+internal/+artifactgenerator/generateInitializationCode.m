 function [initCode, componentInfo] = generateInitializationCode (initInfo, figureEl, figureChildrenEl, contextMenuElList, fcnName, isLoad)
    % GENERATEINITIALIZATIONCODE

%   Copyright 2024 The MathWorks, Inc.

    arguments
        initInfo appdesigner.internal.service.MAppInitializationInfo
        figureEl matlab.io.xml.dom.Element
        figureChildrenEl matlab.io.xml.dom.Element
        contextMenuElList (1,:) cell
        fcnName string
        isLoad logical = false
    end
    
    % Do not create a too big array to hold code lines, which would impact performance.
    % Based on experiments, code lines would be less than half of component XML data
    % structure.
    codeLineSize = round(length(strsplit(initInfo.ComponentXMLString)) / 2);
    codeBuilder = appdesigner.internal.artifactgenerator.AppMCodeBuilder(codeLineSize);

    constants = appdesigner.internal.artifactgenerator.AppendixConstants;

    codeBuilder.addCodeLine(append("function fig = ", fcnName, "(", codeBuilder.ObjectName, ")"));
    
    codeBuilder.addCodeLine(append(constants.AppManagementServiceVariable," = appdesigner.internal.service.AppManagementService.instance();"));

    codeBuilder.addCodeLine(append(constants.PathToAppFileVariable, " = '", fileparts(initInfo.AppOptions.Filepath), "';"));
    
    dataMap = appdesigner.internal.artifactgenerator.getComponentDataMap();
    
    [figureProperties, figureComponentInfo] = appdesigner.internal.artifactgenerator.createInitCodeLinesForComponent(codeBuilder, figureEl, "", dataMap, initInfo.AppOptions.Filepath, false, isLoad);

    figureCodeName = figureEl.getAttribute("name");
    
    contextMenuCount = length(contextMenuElList);

    componentInfo = [];

    if isLoad
        componentInfoTemplate = struct( ...
            'ClassName', '', ...
            'CodeName', '', ...
            'AssignedCallbacks', [], ...
            'LabelName', '', ...
            'IsResponsiveContainer', false, ...
            'Children', []);

        componentInfo = figureComponentInfo;

        componentInfo.ContextMenus = [];

        ctxMenuData = repmat(componentInfoTemplate, 1, contextMenuCount);
    end

    for i = 1:contextMenuCount
        if isLoad
            [~, ctxMenuData(i)] = appdesigner.internal.artifactgenerator.createInitCodeLinesForComponent( ...
                codeBuilder, contextMenuElList{i}, figureCodeName, dataMap, initInfo.AppOptions.Filepath, true, isLoad);
        else
            appdesigner.internal.artifactgenerator.createInitCodeLinesForComponent( ...
                codeBuilder, contextMenuElList{i}, figureCodeName, dataMap, initInfo.AppOptions.Filepath, true, isLoad);
        end
    end
    
    appdesigner.internal.artifactgenerator.assignFigureContextMenu(codeBuilder, figureCodeName, figureProperties);
    
    children = figureChildrenEl.getChildNodes();

    childrenCount = children.getLength();

    if isLoad
        childrenData = repmat(componentInfoTemplate, 1, childrenCount);
        childrenIndex = 1;
    end

    for i=1:childrenCount
        child = children.item(i - 1);
        if isa(child, "matlab.io.xml.dom.Element") && ~strcmp(child.TagName, 'ContextMenu')
            if isLoad
                [~, childrenData(childrenIndex)] = ...
                    appdesigner.internal.artifactgenerator.createInitCodeLinesForComponent(codeBuilder, child, figureCodeName, dataMap, initInfo.AppOptions.Filepath, true, isLoad);

                childrenIndex = childrenIndex + 1;
            else
                appdesigner.internal.artifactgenerator.createInitCodeLinesForComponent(codeBuilder, child, figureCodeName, dataMap, initInfo.AppOptions.Filepath, true);
            end
        end
    end

    if isLoad
        childrenData = childrenData(1:childrenIndex - 1);
    end
    
    codeBuilder.addCodeLine(append("fig = ", codeBuilder.ObjectName, ".", figureCodeName, ";"));
    
    codeBuilder.addCodeLine("end");
    
    initCode = codeBuilder.joinCodeLines();

    if isLoad
        componentInfo.Children = childrenData;
        componentInfo.ContextMenus = ctxMenuData;
    end
end