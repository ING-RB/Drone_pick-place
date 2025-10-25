classdef UserComponentRunner < appdesigner.internal.apprun.RunnerInterface
    % UserComponentRunner Singleton object to manage running User Components
    % in App Designer

    % Copyright 2023 The MathWorks, Inc.

    methods(Static)
        % Get singleton instance of the UserComponentRunner
        function obj = instance()
            persistent localUniqueInstance;
            if isempty(localUniqueInstance) || ~isvalid(localUniqueInstance)
                obj = appdesigner.internal.apprun.UserComponentRunner();
                localUniqueInstance = obj;
            else
                obj = localUniqueInstance;
            end
        end
    end

    methods
        function runningComponent = run(obj, fullFileName)
            % Run the custom componnet in App Designer, this method is only used by
            % appdesigner custom component authoring

            appdesigner.internal.apprun.RunnerInterface.addAppPathToMATLABPath(fullFileName);
            % handle constructor error after component is created
            cleanupObject = obj.handleUserComponentError(fullFileName);
            
            command = appdesigner.internal.service.AppManagementService.prepareCommand(fullFileName);
            runningComponent = evalin('base', command);
            
            obj.manageUserComponent(runningComponent, runningComponent.Parent);
        end        
    end

    % Give friend access to RunnerInterface which used by AD system level tests
    methods (Access = ?appdesigner.internal.apprun.RunnerInterface)
        function fireUserComponentError(obj, fullFileName, uncaughtException)
            % Trim Exception from user component construtor or postSetupFcn and fire CallbackErrored event
            trimmedException = appdesigner.internal.appalert.TrimmedException(uncaughtException);
            % Fire callback errored event to notify clients
            obj.CallbackErrorHandler.notifyCallbackErroredEvent(trimmedException, fullFileName);
        end
    end

    methods (Access = private)
        % Private constructor to prevent creating object externally
        function obj = UserComponentRunner()
            
        end

        function manageUserComponent(obj, compInstance, uiFigure)
            % Set component figure property to indicate that componennt is running in App Designer
            isRunningAppProp = addprop(uiFigure, 'IsRunningInAppDesigner');
            isRunningAppProp.Transient = true;
            isRunningAppProp.Hidden = true;
            % set component figure property as the full filename of component
            [fileName, ~] = which(class(compInstance));
            fileNameProp = addprop(uiFigure, 'RunningInstanceFullFileName');
            fileNameProp.Transient = true;
            fileNameProp.Hidden = true;
            uiFigure.RunningInstanceFullFileName = fileName;
        end

        function oc = handleUserComponentError(obj, fullFileName)
            % use onCleanup to handle uncaught error from user component constructor
            % and postSetupFcn

            % clear EventsCollector first to collect error only from running user component
            ec = appdesigner.internal.apprun.AppDesignerEventsCollector.instance();
            ec.clearEvents();

            function collectCompError()
                % get uncaught Exception from EventsCollector
                uncaughtException = ec.getUncaughtException(fullFileName);
                % if no uncaught exception is found, return rightway
                if ~isa(uncaughtException, 'MException')
                    return;
                end
                obj.fireUserComponentError(fullFileName, uncaughtException);
            end

            oc = onCleanup(@()collectCompError());
        end
    end
end
