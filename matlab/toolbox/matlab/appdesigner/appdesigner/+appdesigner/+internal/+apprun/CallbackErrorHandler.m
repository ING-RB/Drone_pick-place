classdef CallbackErrorHandler < handle
    % CallbackErrorHandler to manage exceptions from callbacks of running apps
    % in App Designer

    % Copyright 2023 The MathWorks, Inc.

    events (ListenAccess = {?appdesigner.internal.appalert.AppAlertController})
        % This event is fired when there's an exception or error happening
        % in the app's callback or startup function
        CallbackErrored
    end

    properties (Access = protected)
        ListenerToPreCallbackExecution;
        ListenerToPostCallbacExecution;
    end

    methods (Static)
        % Get singleton instance of the CallbackErrorHandler
        function obj = instance()
            persistent localUniqueInstance;
            if isempty(localUniqueInstance) || ~isvalid(localUniqueInstance)
                obj = appdesigner.internal.apprun.CallbackErrorHandler();
                localUniqueInstance = obj;
            else
                obj = localUniqueInstance;
            end
        end
    end

    methods
        function delete(obj)
            delete(obj.ListenerToPreCallbackExecution);
            delete(obj.ListenerToPostCallbacExecution);
        end
    end

    methods (Access = private)
        function obj = CallbackErrorHandler()
            
            % Listen to callback related events to handle exceptions from callback
            ams = appdesigner.internal.service.AppManagementService.instance();
            obj.ListenerToPreCallbackExecution = addlistener(...
                ams, 'PreCallbackExecution',...
                @(~,e)obj.handlePreCallbackExecution(e.Object));

            obj.ListenerToPostCallbacExecution = addlistener(...
                ams, 'PostCallbackExecution',...
                @(~,e)obj.handlePostCallbackExecution(e.Object));
        end
    end

    % Give friend access to RunnerInterface which used by AD system level tests
    methods (Access = {?appdesigner.internal.apprun.RunnerInterface, ?appdesigner.internal.application.AppCodeTool})
        function fireCallbackError(obj, app, uncaughtException)
            callbackException = appdesigner.internal.appalert.TrimmedException(uncaughtException);
            % set appFullFileName
            [appFullFileName, ~] = which(class(app));
            % Fire callback errored event to notify clients
            obj.notifyCallbackErroredEvent(callbackException, appFullFileName);
        end

        function notifyCallbackErroredEvent(obj, exception, appFullFileName)
            notify(obj, 'CallbackErrored', ...
                appdesigner.internal.appalert.CallbackErroredData(exception, appFullFileName));
        end

        function handlePreCallbackExecution(obj, app)
            ams = appdesigner.internal.service.AppManagementService.instance();
            if ~ams.isAppRunInAppDesigner(app)
                return;
            end

            % clear EventsCollector first to collect error only from callback function
            ec = appdesigner.internal.apprun.AppDesignerEventsCollector.instance();
            ec.clearEvents();
        end

        function oc = handlePostCallbackExecution(obj, app)
            % use onCleanup to handle component callback uncaught error
            ams = appdesigner.internal.service.AppManagementService.instance();
            if ~ams.isAppRunInAppDesigner(app)
                return;
            end

            function collectCallbackError()
                % Handle uncaught Exception from component callback function
                % get uncaught Exception from EventsCollector
                [appFullFileName, ~] = which(class(app));
                ec = appdesigner.internal.apprun.AppDesignerEventsCollector.instance();
                uncaughtException = ec.getUncaughtException(appFullFileName);
                % if no uncaught exception is found, return rightway
                if ~isa(uncaughtException, 'MException')
                    return;
                end
                obj.fireCallbackError(app, uncaughtException);
            end

            oc = onCleanup(@()collectCallbackError());
        end        
    end
end
