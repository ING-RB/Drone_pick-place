function manageApp(obj, app, uiFigure)
    % 1) Make running figure have a dynamic property to point to the
    % running app instance, and a dynamic property to have the full
    % filename of the app

%   Copyright 2024 The MathWorks, Inc.

    appdesigner.internal.service.AppManagementService.addDynamicPropertiesToFigure(uiFigure, app);

    % 2) Set up listener to figure destroyed event
    addlistener(uiFigure, 'ObjectBeingDestroyed', @(src, e)delete(app));

    % 3) Fire AppCreateComponentsExecutionCompleted event. At this
    % point, the app's layout, including figure, components, has been created
    notify(obj, 'AppCreateComponentsExecutionCompleted', appdesigner.internal.service.CreateComponentsCompletedEventData(app, uiFigure));

    % Log app running information
    % Do not log app running information if it's a deployed app
    if ~obj.isAppRunInAppDesigner(app) && ~isdeployed()
        [fileName, ~] = which(class(app));
        notify(obj, 'AppDDUXLogRunning', appdesigner.internal.ddux.CreateAppDDUXLogRunningEventData(app, uiFigure, fileName));
    end
end
