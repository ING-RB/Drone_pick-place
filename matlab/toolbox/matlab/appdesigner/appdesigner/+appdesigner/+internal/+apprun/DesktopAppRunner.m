classdef DesktopAppRunner < appdesigner.internal.apprun.RunnerInterface
    % DesktopAppRunner Singleton object to manage running app in App
    % Designer

    % Copyright 2023-2025 The MathWorks, Inc.

    methods(Static)
        % Get singleton instance of the DesktopAppRunner
        function obj = instance()
            persistent localUniqueInstance;
            if isempty(localUniqueInstance) || ~isvalid(localUniqueInstance)
                obj = appdesigner.internal.apprun.DesktopAppRunner();
                localUniqueInstance = obj;
            else
                obj = localUniqueInstance;
            end
        end

        function isException = isBadNumberOfArguments(app, exception)
            % determines if a given exception is due to calling the
            % startup function from the constructor with an incorrect
            % number of arguments;
            appMetaData = metaclass(app);

            % determine stack levels depending on app type
            isMLAPP = isa(app, 'matlab.apps.AppBase');
            if isMLAPP
                appRunFunctionName = 'runApp';
                startupFcnName = 'AppBase.runStartupFcn';
            else
                appRunFunctionName = 'runMApp';
                startupFcnName = 'App.App';
            end
            stackLevelAppRun = find(strcmp(appRunFunctionName, {exception.stack.name}));
            stackLevelStartupFcn = find(strcmp(startupFcnName, {exception.stack.name}));
            
            % define helper functions to check for calls for
            % anonymous/constructor/startupFcn as well as exception
            % identifiers for bad number of input args
            checkAnonymous = @(level, anonymousStr) strncmp(exception.stack(level).name, anonymousStr, length(anonymousStr));
            checkConstructor = @(level) strcmp(exception.stack(level).name, [appMetaData.Name '.' appMetaData.Name]);
            checkStartupFcn = @(level) strcmp(exception.stack(stackLevelAppRun - 2).name, startupFcnName);
            checkInputException = @(depth) (any(strcmp(exception.identifier,  {'MATLAB:TooManyInputs', 'MATLAB:maxrhs'})) && depth == 0 ...
                            || strcmp(exception.identifier, 'MATLAB:minrhs') && depth == 1);

            % handle trimmed/untrimmed exception stacks differently for
            % plain-text apps and MLAPPs
            % todo refactor code to handle both trimmed and untrimmed
            % exception stack after g2466221
            trimmedStack = isempty(stackLevelAppRun) && ~isempty(stackLevelStartupFcn);
            if isMLAPP
                if trimmedStack
                    isException = stackLevelStartupFcn >= 2 && ...
                        checkAnonymous(stackLevelStartupFcn - 1, '@(app)') && ...
                        checkConstructor(stackLevelStartupFcn + 1) && ...
                        checkInputException(stackLevelStartupFcn - 2);
                else
                    isException = ~isempty(stackLevelAppRun) && ...
                        stackLevelAppRun >= 5  && ...
                        checkAnonymous(stackLevelAppRun - 4, '@(app)') && ...
                        checkStartupFcn(stackLevelAppRun - 2) && ...
                        checkConstructor(stackLevelAppRun - 1) && ...
                        checkInputException(stackLevelAppRun - 5);
                end
            else
                if trimmedStack
                    isException = stackLevelStartupFcn >= 1 && ...
                        checkConstructor(stackLevelStartupFcn + 1) && ...
                        checkInputException(stackLevelStartupFcn - 1);
                else
                    isException = ~isempty(stackLevelAppRun) && ...
                        stackLevelAppRun >= 6  && ...
                        checkAnonymous(stackLevelAppRun - 5, '@(obj)') && ...
                        checkStartupFcn(stackLevelAppRun - 2) && ...
                        checkConstructor(stackLevelAppRun - 1) && ...
                        checkInputException(stackLevelAppRun - 6);
                end
            end                
        end
    end

    methods
        function runningApp = run(obj, appFullFileName, appArguments, instantiator)
            % Run the App as if by command line
            % This method is only used by App Designer to run an app
            appdesigner.internal.apprun.RunnerInterface.addAppPathToMATLABPath(appFullFileName);

            % when cleanupObject goes out of scope, it funtionaly triggers
            % startupFcn errors to appear in code view.
            cleanupObject = obj.handleAppError(appFullFileName, appArguments); %#ok<NASGU>

            function appCreatedCallback(e)
                % add two UIFigure dynamic properties after app is created in design-time
                % 1. add IsRunningInAppDesigner properties
                % This is used as indicator if app is running in App Designer
                % run app in MATLAB would not have IsRunningInAppDesigner.
                % this property is used to communite with AppManagementSerice
                % in order to know if the running app is under design-time 
                % or runtime.
                %
                % todo: add dynamic properties IsRunningInAppDesigner on app instance
                % instead on UIFigure.  so AppManagementServide.executeCallback
                % do not have to loop all figure to find this property. 
                % this will result in better performance.
                % 
                isRunningAppProp = addprop(e.Figure, 'IsRunningInAppDesigner');
                isRunningAppProp.Transient = true;
                isRunningAppProp.Hidden = true;
            end

            % Listen to AppCreateComponentsExecutionCompleted to call
            % appCreatedCallback to set uifigure properites
            ams = appdesigner.internal.service.AppManagementService.instance();
            listenerToAppCreateComponentsDone = listener(ams, 'AppCreateComponentsExecutionCompleted', @(~,e)appCreatedCallback(e)); %#ok<NASGU>

            runningApp = instantiator.launchApp(appFullFileName, appArguments);
        end
        
        function runningApp = getRunningApp(obj, fullFileName)
            % Get running app using its full file name

            runningApp = [];
            % Search App based on UIFigure with RunningInstanceFullFileName
            runningAppFigures = appdesigner.internal.service.AppManagementService.getRunningAppFigures();
            for i = length(runningAppFigures):-1:1
                fig = runningAppFigures(i);
                if isprop(fig, 'IsRunningInAppDesigner') && strcmp(fig.RunningInstanceFullFileName, fullFileName)
                    runningApp = fig.RunningAppInstance;
                    break;
                end
            end
        end
    end

    % Give friend access to RunnerInterface which used by AD system level tests
    methods (Access = ?appdesigner.internal.apprun.RunnerInterface)
        function fireAppError(obj, appFullFileName, appArguments, uncaughtException)
            % Trim Exception from app construtor or startupFcn and fire CallbackErrored event

            [~, appName, ext] = fileparts(appFullFileName);
            % find running app by App File Name
            app = obj.getRunningApp(appFullFileName);

            if ~isempty(app) && isvalid(app) && (appdesigner.internal.apprun.DesktopAppRunner.isBadNumberOfArguments(app, uncaughtException))
                % check if the startup function is being executed with too
                % many or too few arguments and rethrow that error with an
                % additional cause
                % remove the app so the figure will not remain open
                delete(app);

                if (strcmp(uncaughtException.identifier, 'MATLAB:minrhs'))
                    newException = MException(message('MATLAB:appdesigner:appdesigner:TooFewAppArgumentsError'));
                    newException = newException.addCause(appdesigner.internal.appalert.TrimmedException(uncaughtException));
                    trimmedException = appdesigner.internal.appalert.TrimmedException(newException);
                else
                    trimmedException = appdesigner.internal.appalert.AppArgumentException(uncaughtException);
                end
            elseif ~isempty(regexp(uncaughtException.message, [appName, ext], 'once'))
                % Exception is a syntax error in the app. The message
                % contains the name of the app file and the line/column of
                % the syntax error.
                trimmedException = appdesigner.internal.appalert.TrimmedException(uncaughtException);
            elseif ~isempty(appArguments) && ~any(contains({uncaughtException.stack.name}, 'startupFcn'))
                % Exception occured upon evalin of one of the app arguments
                % and not in the app startupFcn.
                % (Ex: argument uses an undefined function or variable).
                % This check must come after checking for syntax error.
                trimmedException = appdesigner.internal.appalert.AppArgumentException(uncaughtException);
            else
                trimmedException = appdesigner.internal.appalert.TrimmedException(uncaughtException);
            end

            % Fire callback errored event to notify clients
            obj.CallbackErrorHandler.notifyCallbackErroredEvent(trimmedException, appFullFileName);
        end        
    end

    methods (Access = private)
        % Private constructor to prevent creating object externally
        function obj = DesktopAppRunner()
            
        end

        function oc = handleAppError(obj, appFullFileName, appArguments)
            % use onCleanup to handle uncaught error from app constructor
            % and startupFcn

            % clear EventsCollector first to collect error only from running app
            ec = appdesigner.internal.apprun.AppDesignerEventsCollector.instance();
            ec.clearEvents();

            function collectAppError()
                % get uncaught Exception from EventsCollector
                uncaughtException = ec.getUncaughtException(appFullFileName);

                % if no uncaught exception is found, return rightway
                if ~isa(uncaughtException, 'MException')
                    return;
                end

                obj.fireAppError(appFullFileName, appArguments, uncaughtException);
            end

            oc = onCleanup(@()collectAppError());
        end
    end
end
