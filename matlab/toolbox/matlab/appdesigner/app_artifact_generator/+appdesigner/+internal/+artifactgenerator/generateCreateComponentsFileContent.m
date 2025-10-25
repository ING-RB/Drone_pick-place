function [codeFileContent, componentData] = generateCreateComponentsFileContent (initInfo, methodName, isLoad)
    %GENERATECREATECOMPONENTSFILECONTENT

%   Copyright 2024 The MathWorks, Inc.

    arguments
        initInfo appdesigner.internal.service.MAppInitializationInfo % handle container with various initialization data points
        methodName string % the name of the generated method being written
        isLoad logical = false
    end

    figureElement = initInfo.XMLEvaluator.evaluate('//UIFigure', initInfo.LayoutDocument, matlab.io.xml.xpath.EvalResultType.NodeSet);

    if isempty(figureElement)
        ex = appdesigner.internal.artifactgenerator.exception.AppAppendixException(initInfo.AppOptions.Filepath);
        throw(ex);
    end

    figureChildren = initInfo.XMLEvaluator.evaluate('//Children', figureElement, matlab.io.xml.xpath.EvalResultType.Node);

    if ~isempty(figureChildren)
        contextMenuElements = appdesigner.internal.artifactgenerator.XMLUtil.getContextMenuElements(figureChildren);
    else
        figureChildren = initInfo.LayoutDocument.createElement('Children');
        figureElement.appendChild(figureChildren);
        contextMenuElements = [];
    end

    [codeFileContent, componentData] = appdesigner.internal.artifactgenerator.generateInitializationCode(...
        initInfo, figureElement, figureChildren, contextMenuElements, methodName, isLoad);
end
