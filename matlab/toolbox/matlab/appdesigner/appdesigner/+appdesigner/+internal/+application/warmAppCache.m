function warmAppCache(filepath)
    %WARMAPPCACHE

%   Copyright 2024 The MathWorks, Inc.
    
    arguments
        filepath string
    end

    import appdesigner.internal.artifactgenerator.AppendixConstants;

    uid = appdesigner.internal.cacheservice.generateUidFromFilepath(filepath);

    methodName = append('ad_', uid);

    cacheService = appdesigner.internal.cacheservice.CacheService.instance();

    [isPresent, ~] = cacheService.hasComponentInitFunction(methodName);

    if ~isPresent
        initInfo = appdesigner.internal.service.MAppInitializationInfo();

        initInfo.AppOptions = appdesigner.internal.apprun.AppOptions();

        initInfo.AppOptions.Filepath = filepath;

        initInfo.XMLEvaluator = matlab.io.xml.xpath.Evaluator();

        initInfo.FileContent = appdesigner.internal.cacheservice.readAppFile(char(initInfo.AppOptions.Filepath));

        initInfo.ComponentXMLString = appdesigner.internal.artifactgenerator.getAppendixByGrammarName(...
            initInfo.FileContent, AppendixConstants.AppLayoutIdentifier, AppendixConstants.AppRootElementName);
    
        initInfo.RunConfigXMLString = appdesigner.internal.artifactgenerator.getAppendixByGrammarName(...
            initInfo.FileContent, AppendixConstants.AppRunConfigIdentifier, AppendixConstants.AppRunConfigRootElementName);

        initInfo.LayoutDocument = appdesigner.internal.artifactgenerator.XMLUtil.parseAppXML(initInfo.AppOptions.Filepath, initInfo.FileContent, initInfo.ComponentXMLString);

        codeContent = appdesigner.internal.artifactgenerator.generateCreateComponentsFileContent(initInfo, methodName);

        cacheService.addComponentInitFunction(methodName, codeContent);
    end
end
