function app = initializeMApp(app, args)
    %INITIALIZEMAPP primary entry point for plain-text app file format initialization

%   Copyright 2024 The MathWorks, Inc.

    arguments
        app matlab.apps.App
        args cell
    end

    import appdesigner.internal.artifactgenerator.AppendixConstants;

    initInfo = appdesigner.internal.service.MAppInitializationInfo;

    initInfo.AppHandle = app;

    initInfo.AppManagementService = appdesigner.internal.service.AppManagementService.instance();

    [initInfo.AppOptions, inputArgs] = initInfo.AppManagementService.extractMAppInputs(app, args);

    initInfo.FileContent = appdesigner.internal.cacheservice.readAppFile(char(initInfo.AppOptions.Filepath));

    initInfo.ComponentXMLString = appdesigner.internal.artifactgenerator.getAppendixByGrammarName(...
        initInfo.FileContent, AppendixConstants.AppLayoutIdentifier, AppendixConstants.AppRootElementName);

    initInfo.RunConfigXMLString = appdesigner.internal.artifactgenerator.getAppendixByGrammarName(...
        initInfo.FileContent, AppendixConstants.AppRunConfigIdentifier, AppendixConstants.AppRunConfigRootElementName);

    if strcmp(initInfo.FileContent, "") || strcmp(initInfo.ComponentXMLString, "")
        ex = appdesigner.internal.artifactgenerator.exception.AppAppendixException(initInfo.AppOptions.Filepath);
        throwAsCaller(ex);
    end

    if ~strcmp(initInfo.RunConfigXMLString, "")
        initInfo.RunConfigDocument = appdesigner.internal.artifactgenerator.XMLUtil.parseXML(initInfo.RunConfigXMLString);
    end
    
    isSingleton = false;
    if ~isempty(initInfo.RunConfigDocument)
        isSingleton = initInfo.XMLEvaluator.evaluate('//SingleRunningInstance', initInfo.RunConfigDocument, matlab.io.xml.xpath.EvalResultType.Boolean);
    end

    if isSingleton
        [existingInstance, fig] = initInfo.AppManagementService.getMAPPSingletonInstance(app);

        if ~isempty(existingInstance)
            app = existingInstance;

            focus(fig);

            return;
        end
    end

    initInfo.CacheService = appdesigner.internal.cacheservice.CacheService.instance();

    initInfo.ContentUID = appdesigner.internal.cacheservice.generateUid(initInfo.AppOptions.Filepath + initInfo.ComponentXMLString);

    if initInfo.AppOptions.ClearCache
        initInfo.CacheService.clearBucket(initInfo.ContentUID);
    end

    initInfo.CacheBucket = initInfo.CacheService.getBucket(initInfo.ContentUID, struct('expires', initInfo.AppOptions.CacheExpireDate));

    initInfo.LayoutDocument = appdesigner.internal.artifactgenerator.XMLUtil.parseAppXML(initInfo.AppOptions.Filepath, initInfo.FileContent, initInfo.ComponentXMLString);

    [fig, ~] = appdesigner.internal.artifactgenerator.initializeAppComponents(initInfo);

    appdesigner.internal.artifactgenerator.AppLogger.logLink('ad_cachepath', initInfo.CacheBucket.getPath(), 'Open Cache Bucket');

    initInfo.AppManagementService.register(app, fig);

    startupFcnName = "";
    if ~isempty(initInfo.RunConfigDocument)
        startupFcnName = initInfo.XMLEvaluator.evaluate('//StartupFcn', initInfo.RunConfigDocument, matlab.io.xml.xpath.EvalResultType.String);
    end

    if strlength(startupFcnName) > 0
        initInfo.AppManagementService.runStartupFcn(app, @(obj)obj.(startupFcnName)(inputArgs{:}), fig);
    end
end