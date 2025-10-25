function [fig, componentData] = initMAppComponentsForLoad(filepath)
    %INITMAPPCOMPONENTSFORLOAD
    % Entry point for generating and executing component creation code for
    % loading an plain-text app into App Designer.

    % Copyright 2024 The MathWorks, Inc.

    arguments
        filepath string
    end

    import appdesigner.internal.artifactgenerator.AppendixConstants;

    uid = appdesigner.internal.cacheservice.generateUidFromFilepath(filepath);

    methodName = append('ad_', uid);

    initInfo = appdesigner.internal.service.MAppInitializationInfo();

    initInfo.ContentUID = append(uid, '_load');

    initInfo.CacheService = appdesigner.internal.cacheservice.CacheService.instance();

    initInfo.CacheService.clearBucket(initInfo.ContentUID);

    initInfo.AppOptions = appdesigner.internal.apprun.AppOptions();

    initInfo.AppOptions.Filepath = filepath;

    initInfo.XMLEvaluator = matlab.io.xml.xpath.Evaluator();

    initInfo.FileContent = appdesigner.internal.cacheservice.readAppFile(char(initInfo.AppOptions.Filepath));

    initInfo.ComponentXMLString = appdesigner.internal.artifactgenerator.getAppendixByGrammarName(...
        initInfo.FileContent, AppendixConstants.AppLayoutIdentifier, AppendixConstants.AppRootElementName);

    initInfo.RunConfigXMLString = appdesigner.internal.artifactgenerator.getAppendixByGrammarName(...
        initInfo.FileContent, AppendixConstants.AppRunConfigIdentifier, AppendixConstants.AppRunConfigRootElementName);

    initInfo.LayoutDocument = appdesigner.internal.artifactgenerator.XMLUtil.parseAppXML(initInfo.AppOptions.Filepath, initInfo.FileContent, initInfo.ComponentXMLString);

    [codeContent, componentData] = appdesigner.internal.artifactgenerator.generateCreateComponentsFileContent(initInfo, methodName, true);

    initInfo.CacheService.addComponentInitFunction(initInfo.ContentUID, codeContent);

    [~, mInitFilepath] = initInfo.CacheService.hasComponentInitFunction(initInfo.ContentUID);

    try
        createComponents = appdesigner.internal.cacheservice.getMAPPComponentInitHandle(char(mInitFilepath));

        fig = createComponents([]);

    catch e
        if isempty(codeContent)
            codeContent = fileread(mInitFilepath);
        end

        ex = appdesigner.internal.artifactgenerator.exception.AppAppendixComponentException(...
            e, initInfo.AppOptions, mInitFilepath, codeContent, initInfo.FileContent);

        throwAsCaller(ex);
    end

end