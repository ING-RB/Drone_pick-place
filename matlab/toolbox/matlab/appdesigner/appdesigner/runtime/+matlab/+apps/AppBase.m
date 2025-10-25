classdef AppBase < handle
    %APPBASE This is the base class of an App which contains methods needed by Apps.

    % Copyright 2021-2024 The MathWorks, Inc.

    properties(Access = {...
            ?matlab.ui.internal.controller.FigureController...
            ?appdesigner.internal.ddux.AppDDUXTimingManager...
            })
        % This contains timestamps for DDUX instrumentation of running Apps
        TimingFields appdesigner.internal.ddux.AppDDUXTimingFields
    end

    methods
        function obj = AppBase()
            obj.TimingFields = appdesigner.internal.ddux.AppDDUXTimingFields();

            ams = appdesigner.internal.service.AppManagementService.instance();
            ams.sendDDUXTimingMarkerEvent(obj, 'CreateComponentsStarted');
        end
    end

    methods
        function delete(app)
            ams = appdesigner.internal.service.AppManagementService.instance();
            ams.unregister(app);
        end

        function s = saveobj(obj)
            % Saving an instance of an app object is not supported.
            s = [];
            backTraceState = warning('query','backtrace');
            warning('off','backtrace');
            warning(message('MATLAB:appdesigner:appdesigner:SaveObjWarning'));
            warning(backTraceState);
        end
    end

    methods (Static)
        function obj = loadobj(s)
            % Loading an instance of an app object is not supported.
            obj = s;
            error(message('MATLAB:appdesigner:appdesigner:LoadObjWarning'));
        end
    end

    methods (Access = protected, Sealed = true)
        function newCallback = createCallbackFcn(app, callback, requiresEventData)
            if nargin == 2
                requiresEventData = false;
            end

            ams = appdesigner.internal.service.AppManagementService.instance();
            newCallback = @(source, event)executeCallback(ams, ...
                app, callback, requiresEventData, event);
        end

        function runStartupFcn(app, startfcn)
            ams = appdesigner.internal.service.AppManagementService.instance();
            ams.runStartupFcn(app, startfcn);
        end

        function registerApp(app, uiFigure)
            ams = appdesigner.internal.service.AppManagementService.instance();
            % registerApp is called immediately after createComponents() in user generated code
            ams.sendDDUXTimingMarkerEvent(app, 'CreateComponentsEnded');

            ams.register(app, uiFigure);
        end

        function setAutoResize(~, uiFigure, value)
            matlab.ui.internal.layout.setAutoResize(uiFigure, value);
        end

        function runningApp = getRunningApp(app)
            ams = appdesigner.internal.service.AppManagementService.instance();
            runningApp = ams.getRunningSingleton(app);
        end
    end
end
