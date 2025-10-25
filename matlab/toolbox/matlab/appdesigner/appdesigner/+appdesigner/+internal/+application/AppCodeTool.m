classdef AppCodeTool < handle
    %APPCODETOOL Processes goto and debug events by ensuring that the app
    % is opened and ready before passing along the event to the client.

    %    Copyright 2015-2024 The MathWorks, Inc.

    properties (Access = private)
        % AppDesignEnvironment instance
        AppDesignEnvironment

        % Listener to AppModel client loaded event
        AppModelCreatedListener

        % Queue of debug events that occur while app is loading
        DebugEventQueue = {};
    end

    methods
        function obj = AppCodeTool(appDesignEnvironment)
            obj.AppDesignEnvironment = appDesignEnvironment;
        end

        function delete(obj)
            if ~isempty(obj.AppModelCreatedListener)
                delete(obj.AppModelCreatedListener);
                obj.AppModelCreatedListener = [];
            end
        end

        function processGoToLineColumn(obj, file, line, column, selectLine)
            %  PROCESSGOTOLINECOLUMN Go to line/column in the app's Code View

            scrollToView = true;

            obj.doProcessGoToLineColumn(file, line, column, scrollToView, selectLine, @obj.processGoToAppReadyCallback);
        end

        function processDebugInfo(obj, currentFilepath, currentMlappLineNumber, mlappsInStack)
            %  PROCESSDEBUGMLAPP Process debug event involving MLAPPs
            %
            %   processDebugInfo() will
            %       1) Set debug state of all apps opened in App Designer that
            %       are found in the debug call stack (mlappsInStack)
            %
            %       2) Open/Bring to front the app, if any, that is the current
            %       frame on the call stack (filepath).
            %       It uses doProcessGoToLineColumn to bring code view to front
            %       and place the cursor on the line where execution is stopped
            %       for debugging
            %
            %       3) Queues calls to processDebugInfo that occur while the
            %       debugging app is loading. Once the app is done loading, the
            %       queue is flushed and processed.

            if isempty(obj.AppModelCreatedListener)
                % No app is loading and so proceed with processing the data

                % Ensure the path file seperators are consistent
                currentFilepath = fullfile(currentFilepath);

                obj.updateExistingAppModelStates(mlappsInStack);

                if ~isempty(currentFilepath)
                    % Since filepath is not empty, execution is
                    % stopped in an MLAPP file for debugging. Execute
                    % goToLineColumn to open/bring to front the app in App
                    % Designer and place cursor on the line execution is stopped on.
                    column = 1;
                    scrollToView = false; % RTC handles scrolling when debugging
                    obj.doProcessGoToLineColumn(currentFilepath, currentMlappLineNumber, column, scrollToView, false,...
                        @obj.processDebugAppReadyCallback);
                end
            else
                % An app is loading and so queue the event to be processed once the app is ready to handle it.
                obj.DebugEventQueue{end+1} = {currentFilepath, currentMlappLineNumber, mlappsInStack};
            end
        end
    end

    methods (Access = private)
        function updateExistingAppModelStates(obj, mlappsInStack)
            % Process mlappsInstack
            appDesignerModel = obj.AppDesignEnvironment.AppDesignerModel;

            for idx = 1 : length(appDesignerModel.Children)
                appModel = appDesignerModel.Children(idx);

                if any(strcmpi(appModel.FullFileName, mlappsInStack))
                    % App is in the stack and opened
                    % Only set app's debugging state to true only if it is not already true
                    if ~appModel.IsDebugging
                        obj.setAppModelIsDebugging(appModel);
                    end
                else
                    % App is not in the stack
                    % If it was debugging, it is not now and so set debugging state to false.
                    if appModel.IsDebugging
                        appModel.IsDebugging = false;
                        desktopAppRunner = appdesigner.internal.apprun.DesktopAppRunner.instance();
                        ams = appdesigner.internal.service.AppManagementService.instance();

                        if ams.isAppRunInAppDesigner(appModel.FullFileName) && ...
                                isempty(desktopAppRunner.getRunningApp(appModel.FullFileName)) && ...
                                ~appModel.IsLaunching
                            % dbquit has occured during app construction before
                            % the running app instance could be registered with
                            % the AppManagementService. This can result in the
                            % app's figure being left open which puts the app in
                            % a bad state and so close the figure (g1353572).
                            %
                            % If appModel.IsLanching is true, the user didn't hit
                            % dbquit butis stepping through the App Designer app
                            % instantiation code (g1764890).
                            appFig = obj.findAppFigure(appModel.FullFileName);
                            delete(appFig);
                        end
                    end
                end
            end
        end

        function doProcessGoToLineColumn(obj, file, line, column, scrollToView, selectLine, appReadyCallback)
            % doProcessGoToLineColumn() will send 'goToLineColumn' event to
            % client side through CodeModel peer node to ask to locate the code

            % if the app is not loaded, we call `appdesigner` and wait for the appClientLoaded event
            % this event originates from the client, keyword: "AppModelOpened"

            appModel = obj.getAppModelByFilename(file);

            if isempty(appModel)
                try
                    observer = obj.AppDesignEnvironment.openApp(file);
                    obj.AppModelCreatedListener = event.listener(observer, 'AppClientLoaded', ...
                        @(o, e)obj.handleAppModelCreated(e.AppModel, file, line, column, scrollToView, selectLine, appReadyCallback));
                catch exception
                    delete(obj.AppModelCreatedListener);
                    obj.AppModelCreatedListener = [];
                    rethrow(exception);
                end
            else
                message = obj.getUncaughtExceptionMessage(file);
                appModel.CodeModel.sendGoToLineColumnEventToClient(line, column, scrollToView, selectLine, message);
            end
        end

        function appModel = getAppModelByFilename(obj, filename)
            % searches appDesignerModel for an appModel by the given filepath

            appModel = [];

            appDesignerModel = obj.AppDesignEnvironment.AppDesignerModel;

            for idx = 1 : length(appDesignerModel.Children)
                if strcmp(filename, appDesignerModel.Children(idx).FullFileName) || (ispc && strcmpi(filename, appDesignerModel.Children(idx).FullFileName))
                    appModel = appDesignerModel.Children(idx);
                    break;
                end
            end
        end

        function handleAppModelCreated(obj, appModel, file, line, column, scrollToView, selectLine, appReadyCallback)
            % handler that the app client has loaded

            if strcmp(file, appModel.FullFileName)
                delete(obj.AppModelCreatedListener);

                obj.AppModelCreatedListener = [];

                appReadyCallback(appModel, line, column, scrollToView, selectLine);
            end
        end

        function processGoToAppReadyCallback(obj, appModel, line, column, scrollToView, selectLine)
            % Callback to be executed once app has been loaded due to a
            % goToLineColumn event and is ready to be used

            message = obj.getUncaughtExceptionMessage(appModel.FullFileName);

            appModel.CodeModel.sendGoToLineColumnEventToClient(line, column, scrollToView, selectLine, message);
        end

        function processDebugAppReadyCallback(obj, appModel, line, column, scrollToView, ~)
            % Callback to be executed once app has been loaded due to a debug event and is ready to be used

            obj.setAppModelIsDebugging(appModel);

            % Request client to perform goToLineColumn
            message = obj.getUncaughtExceptionMessage(appModel.FullFileName);
            appModel.CodeModel.sendGoToLineColumnEventToClient(line, column, scrollToView, false, message);

            % Process and flush DebugEventQueue
            %
            % Use a local copy of the queue and clear out the instance's
            % queue. This is necessary because one of the queued
            % events might cause another app to load which could then
            % potentially cause events to queue again and execute this
            % function again.
            %
            % Ex: App1's startup function instantiates App2 and each app
            % has breakpoint in each constructor. From command line, user
            % instantiates App1 and execution hits breakpoint. While App1
            % is loading, user executes dbcont which causes the breakpoint
            % in App2 to be hit. The user then hit dbcont again before App1
            % has finished loading. These two dbcont events are queued and
            % aren't processed until App1 finishes loading. When the first
            % dbcont event is processed it needs to load App2 and so the
            % second dbcont event will be queued again to wait until App2
            % has finished loading. Need a local copy of the queue to
            % handle this properly.
            localQueue = obj.DebugEventQueue;
            obj.DebugEventQueue = {};
            for i=1:length(localQueue)
                obj.processDebugInfo(localQueue{i}{:});
            end
        end

        function setAppModelIsDebugging(~, appModel)
            % Set the app to be debugging
            appModel.IsDebugging = true;

            % Attach LiveAlert listener if the running app
            % from MATLAB triggers debugging
            appModel.addErrorAlertListener();
        end

        function appFig = findAppFigure(~, fullFileName)
            % Get the running app figure using its full file name

            appFig = [];

            runningAppFigures = appdesigner.internal.service.AppManagementService.getRunningAppFigures();

            for i=1:length(runningAppFigures)
                fig = runningAppFigures(i);
                appMeta = metaclass(fig.RunningAppInstance);
                whichResult = which('-all', appMeta.Name);

                if any(cellfun(@(x) strcmp(x,fullFileName), whichResult))
                    appFig = fig;
                end
            end
        end

        function message = getUncaughtExceptionMessage(~, filepath)
            message = '';
            ec = appdesigner.internal.apprun.AppDesignerEventsCollector.instance();
            exception = ec.getUncaughtException(filepath);
            if ~isempty(exception)
                message = exception.message;
            end
        end
    end
end
