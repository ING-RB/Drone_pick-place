classdef AppManagementService < handle
    % APPMANAGEMENTSERVICE Singleton object to manage running apps

    % Copyright 2016-2024 The MathWorks, Inc.

    events (ListenAccess = {?appdesigner.internal.appalert.AppAlertController; ...
            ?appdesigner.internal.apprun.RunnerInterface; ...
            ?appdesigner.internal.apprun.CallbackErrorHandler;...
            ?appdesigner.internal.ddux.AppDDUXTimingManager;...
            ?appdesigner.internal.document.AppDocument; ...
            ?appdesigner.internal.service.WebAppRunner})

        % This event is invoked when the createComponents() method of the
        % app finishes execution and before app startup is executed,
        % which can be used by clients to know when a figure, and components
        % are done creation before waiting completion of app construction
        AppCreateComponentsExecutionCompleted

        % These events are used to mark the time of certain DDUX events and
        % to indicate when the DDUX event should be logged
        AppDDUXTimingMarker
        AppDDUXLogRunning

        % This event is to notify outside that a callback is going to execute from an app
        PreCallbackExecution
        PostCallbackExecution
    end

    properties (Access = private)
        AppTimingDDUXManager appdesigner.internal.ddux.AppDDUXTimingManager
    end

    methods (Access = private)
        function obj = AppManagementService()
            obj.AppTimingDDUXManager = appdesigner.internal.ddux.AppDDUXTimingManager(obj);
        end
    end

    methods (Static)
        obj = instance()
        uiFigure = getFigure(appOrUserComponent)
        value = isAppRunInAppDesigner(app)
        runningAppFigures = getRunningAppFigures()
        command = prepareCommand(fullFileName)
        runningApp = runApp(appFullFileName, appArguments)
        runningApp = runMApp(appFullFileName, appArguments)
        addDynamicProperties(model, propName, propValue, hidden)
        addDynamicPropertiesToFigure(fig, app)
        app = initializeMApp(app, inputArgs)
        [options, inputArgs] = extractMAppInputs(app, inputs)
        dateTime = createDateTime()
    end
end
