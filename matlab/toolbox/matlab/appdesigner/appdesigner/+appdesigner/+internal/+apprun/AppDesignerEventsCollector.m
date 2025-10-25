classdef AppDesignerEventsCollector < handle
    % APPDESIGNEREVENTSCOLLECTOR collect events to find uncaught errors
    % when user runs app in App Designer in order to show live alert
    % provides methods:
    % clearEvents - clear all events in events collector
    % getUncaughtException - find uncaught event and return EventCollectorException
    % isAppException - check if the error is related to the running app

    % Copyright 2023-2024 The MathWorks, Inc.

    properties (Access = private)
        % Events collector to be used collect uncaught exception from app code
        EventsCollector
    end

    methods(Static)
        function obj = instance()
            persistent localUniqueInstance;
            if isempty(localUniqueInstance)
                obj = appdesigner.internal.apprun.AppDesignerEventsCollector();
                localUniqueInstance = obj;
            else
                obj = localUniqueInstance;
            end
        end
    end

    methods
        function uncaughtException = clearEvents(obj)
            obj.EventsCollector.clear();
        end

        function uncaughtException = getUncaughtException(obj, fullFileName)
            % Use EventsCollector to get uncaught exception without catch exception
            % return EventCollectorException based on Events(i).payload.exception struct
            events = obj.EventsCollector.Events;
            for i=1:numel(events)
                if strcmp(events(i).type, 'UncaughtError')
                    uncaughtError = events(i).payload.exception;
                    
                    % only return uncaught exception related to the running mlapp file
                    if obj.isAppException(uncaughtError, fullFileName)
                        uncaughtException = events(i).payload.jsonParsedException.exceptionJSON;
                        % clear EventsCollector because uncaughtError Exception is returned and handled
                        obj.EventsCollector.clear();
                        return;
                    end
                end
            end
            % return empty if no uncaught exception is found
            uncaughtException = [];
        end
    end

    methods(Access=private)
        % Private constructor to prevent creating object externally
        function obj = AppDesignerEventsCollector()
            obj.EventsCollector = matlab.internal.structuredoutput.EventsCollector;
            obj.EventsCollector.setCheckRelevant(false);
        end
    end

    methods (Static, Access=private)
        % Check if the error is related to the running app
        function isAppEx = isAppException(uncaughtError, fullFileName)

            [~, appName] = fileparts(fullFileName);

            % errors coming from the running app have the app's fullfile in the stack - see g2992102
            % for syntax errors, the stack won't have the app's fullfile but the function name will be the app name
            isAppRun = false;
            if uncaughtError.frames.count == 1
                isAppRun = contains([uncaughtError.frames.item.file], fullFileName);
            elseif uncaughtError.frames.count > 1
                isAppRun = contains([cell2mat(uncaughtError.frames.item).file], fullFileName);
            end

            isAppRunEx = isAppRun || strcmp(uncaughtError.function, appName);

            % unrecognized input arg is thrown from evalin, not running app - see g3035209
            isBadInputArg = matches(uncaughtError.id, 'MATLAB:UndefinedFunction') ...
                && matches(uncaughtError.function,'evalin');

            isAppEx = isAppRunEx || isBadInputArg;
        end
    end
end