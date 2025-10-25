classdef (Abstract) App < handle
    %APP Parent class to the M app file

    % Copyright 2023-2024 The MathWorks, Inc.

    properties (Access = {?appdesigner.internal.ddux.AppDDUXTimingManager, ?matlab.ui.internal.controller.FigureController}, Hidden)
        % This contains timestamps for DDUX instrumentation of running Apps
        TimingFields appdesigner.internal.ddux.AppDDUXTimingFields
    end

    methods
        function app = App(varargin)
            if matlab.internal.feature('AppDesignerPlainTextFileFormat') == 0 ...
                    && ~isdeployed()
                % feature control does not work in deployed apps
                % To unblock Deployment team to work with new plain text
                % fileformat, for instance, writing tests, qualifcation, etc.,
                % put a temporary workaround here not to throw error in deployed apps.
                error('MATLABApp:unknownFileType', 'Unknown FileType');
            end

            app.TimingFields = appdesigner.internal.ddux.AppDDUXTimingFields();
            app = appdesigner.internal.service.AppManagementService.initializeMApp(app, varargin);

            if nargout == 0
                clear app;
            end
        end

        function delete(app)
            ams = appdesigner.internal.service.AppManagementService.instance();
            ams.unregisterMApp(app);
        end

        function s = saveobj(~)
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

            obj = s; %#ok<*NASGU>

            error(message('MATLAB:appdesigner:appdesigner:LoadObjWarning'));
        end
    end
end
