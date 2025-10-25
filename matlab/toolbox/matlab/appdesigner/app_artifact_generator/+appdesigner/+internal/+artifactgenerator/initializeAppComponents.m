function [fig, ccStartDateTime] = initializeAppComponents(initInfo)
    %INITIALIZEAPPCOMPONENTS

%   Copyright 2024 The MathWorks, Inc.

    arguments
        initInfo appdesigner.internal.service.MAppInitializationInfo
    end

    methodName = append('ad_', initInfo.ContentUID);

    [methodIsPresent, mInitFilepath] = initInfo.CacheService.hasComponentInitFunction(initInfo.ContentUID);

    codeContent = [];

    if ~methodIsPresent
        initInfo.AppManagementService.sendDDUXTimingMarkerEvent(initInfo.AppHandle,'GenerateInitMCodeStarted');

        codeContent = appdesigner.internal.artifactgenerator.generateCreateComponentsFileContent(initInfo, methodName);

        initInfo.CacheService.addComponentInitFunction(initInfo.ContentUID, codeContent);

        initInfo.AppManagementService.sendDDUXTimingMarkerEvent(initInfo.AppHandle,'GenerateInitMCodeEnded');
    end

    appdesigner.internal.artifactgenerator.AppLogger.logLink('ad_executingFilepath', initInfo.AppOptions.Filepath, 'Open M app File');

    appdesigner.internal.artifactgenerator.AppLogger.logLink('ad_componentInitCode', mInitFilepath, 'Open CreateComponents M Code');

    ccStartDateTime = appdesigner.internal.service.AppManagementService.createDateTime();

    try
        createComponents = appdesigner.internal.cacheservice.CacheService.getComponentInitFunctionHandle(mInitFilepath);

        initInfo.AppManagementService.sendDDUXTimingMarkerEvent(initInfo.AppHandle,'CreateComponentsStarted');

        fig = createComponents(initInfo.AppHandle);

        initInfo.AppManagementService.sendDDUXTimingMarkerEvent(initInfo.AppHandle,'CreateComponentsEnded');
    catch e
        if isempty(codeContent)
            codeContent = fileread(mInitFilepath);
        end

        ex = appdesigner.internal.artifactgenerator.exception.AppAppendixComponentException(...
            e, initInfo.AppOptions, mInitFilepath, codeContent, initInfo.FileContent);

        throwAsCaller(ex);
    end

    generator = appdesigner.internal.artifactgenerator.ClientGenerator();

    generator.generateClientCache(fig, initInfo.CacheBucket);
end
