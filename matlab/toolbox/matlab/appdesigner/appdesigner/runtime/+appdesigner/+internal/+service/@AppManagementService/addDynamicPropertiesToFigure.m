function addDynamicPropertiesToFigure(fig, app)
%

%   Copyright 2024 The MathWorks, Inc.

    appdesigner.internal.service.AppManagementService.addDynamicProperties(fig, 'RunningAppInstance', app);
    [fileName, ~] = which(class(app));
    appdesigner.internal.service.AppManagementService.addDynamicProperties(fig, 'RunningInstanceFullFileName', fileName, true);

    cacheService = appdesigner.internal.cacheservice.CacheService.instance();
    cacheFile = cacheService.getAppViewCacheFilePath(fileName);
    if ~isempty(cacheFile)
       appdesigner.internal.service.AppManagementService.addDynamicProperties(fig, 'AppViewCacheFile', cacheFile, true);
    end

end
