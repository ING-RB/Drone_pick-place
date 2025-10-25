classdef EventCoalescer
    %EventCoalescer Utility methods to coalesce multiple function calls
    %   Utilities to throttle or debounce function calls

    % Copyright 2023-2024 The MathWorks, Inc.
    properties(Constant)
        DEFAULT_THROTTLE_DURATION (1,1) double = 1.1; % seconds
        DEFAULT_DEBOUNCE_DURATION (1,1) double = 0.1; % seconds
    end

    methods (Static)
        % Throttles calls to callback function based on eventId and source
        % pair.  First call to callback goes through and subsequent calls
        % only go through if elapsed time is greater than throtleDuration.
        %
        % Arguments:
        %           eventId: unique event identifier
        %          callback: callback to execute/throttle
        % Named Arguments:
        %             scope: unique identifier for event scope(UUID)
        %  throttleDuration: throttle duration (e.g. how often to let events through)
        %             reset: resets the time, and event will go through
        % callbackArguments: cell array of arguments to be passed to callback
        %          errorFcn: callback function if an error occurs when trying to execute callback
        %          forceRun: set to force execution regardless if still within throttle time
        %    fullEventReset: reset full event queue for all scopes and events (debug only)
        function didRun = throttle(eventId, callback, NVPairs)
            arguments
                eventId (1,1) string;
                callback function_handle;
                NVPairs.scope (1,1) string = "";
                NVPairs.throttleDuration (1,1) double = matlab.internal.datatoolsservices.EventCoalescer.DEFAULT_THROTTLE_DURATION;
                NVPairs.reset (1,1) logical = false;
                NVPairs.callbackArguments cell = {};
                NVPairs.errorFcn function_handle {mustBeScalarOrEmpty} = function_handle.empty;
                NVPairs.forceRun (1,1) logical = false;
                NVPairs.fullEventReset (1,1) logical = false;
            end

            internal.matlab.datatoolsservices.logDebug("datatoolsservices::eventcoalescer::throttle", "scope: " + NVPairs.scope + "  eventId: " + eventId);

            currentTime = datetime('now');
            didRun = false;

            persistent eventStack;
            if isempty(eventStack) || NVPairs.fullEventReset
                internal.matlab.datatoolsservices.logDebug("datatoolsservices::eventcoalescer::throttle", "init");
                eventStack = dictionary();
            end

            scope = NVPairs.scope;

            if ~isConfigured(eventStack) || ~isKey(eventStack, scope)
                eventStack(scope) = dictionary(string.empty, struct.empty);
            end

            throttleDur = NVPairs.throttleDuration;

            eventDict = eventStack(scope);
            if ~isKey(eventDict, eventId)
                eventDict(eventId) = struct('throttleDuration', throttleDur, 'lastTimestamp', currentTime);
            end
            eventStruct = eventDict(eventId);

            if NVPairs.reset
                eventStruct.lastTimestamp = currentTime;
                eventStruct.throttleDuration = throttleDur;
            end

            timeDiff = seconds(currentTime - eventStruct.lastTimestamp);

            if  NVPairs.forceRun || timeDiff == 0 || timeDiff >= eventStruct.throttleDuration
                try
                    internal.matlab.datatoolsservices.logDebug("datatoolsservices::eventcoalescer::throttle::execCallback", "scope: " + NVPairs.scope + "  eventId: " + eventId + "callback: " + func2str(callback));
                    if ~isempty(NVPairs.callbackArguments)
                        callback(NVPairs.callbackArguments{:});
                    else
                        callback();
                    end
                    didRun = true;
                catch e
                    internal.matlab.datatoolsservices.logDebug("datatoolsservices::EventCoalescer::Throttle::CallbackError", e.message);
                    if ~isempty(NVPairs.errorFcn)
                        try
                            errorFcn(e);
                        catch ee
                            internal.matlab.datatoolsservices.logDebug("datatoolsservices::EventCoalescer::Throttle::ErrorFcnError", ee.message);
                        end
                    end
                end

                eventStruct.lastTimestamp = currentTime;
            end

            eventDict(eventId) = eventStruct;
            eventStack(scope) = eventDict;
        end

        % Debounces calls to callback function based on eventId and source
        % pair.  Uses a timer to limit number of times the callback is
        % called.  Callback will only be called once the debouceDuration
        % has elapsed.  All inputs from calls before debounceDuration has
        % completed are store and full queue of values is passed to
        % callback function once debounceDuration has elapsed.  Each call
        % to debounce resets timer to zero when called before
        % debounceDuration has elapsed.
        %
        % Arguments:
        %           eventId: unique event identifier
        %          callback: callback to execute/throttle
        % Named Arguments:
        %             scope: unique identifier for event scope(UUID)
        %   debouceDuration: debounce duration (e.g. how long to wait before running callback)
        %             reset: resets the time, and event will go through
        % callbackArguments: cell array of arguments to be passed to callback
        %          errorFcn: callback function if an error occurs when trying to execute callback
        %          forceRun: set to force execution regardless if still within throttle time
        %    fullEventReset: reset full event queue for all scopes and events (debug only)
        %         cancelAll: cancel timers for input scope
        function didRun = debounce(eventId, callback, NVPairs)
            arguments
                eventId (1,1) string;
                callback function_handle {mustBeScalarOrEmpty} = function_handle.empty;
                NVPairs.scope (1,1) string = "";
                NVPairs.debouceDuration (1,1) double = matlab.internal.datatoolsservices.EventCoalescer.DEFAULT_DEBOUNCE_DURATION;
                NVPairs.reset (1,1) logical = false;
                NVPairs.callbackArguments cell = {};
                NVPairs.errorFcn function_handle {mustBeScalarOrEmpty} = function_handle.empty;
                NVPairs.forceRun (1,1) logical = false;
                NVPairs.fullEventReset (1,1) logical = false;
                NVPairs.cancelAll (1,1) logical = false;
            end

            internal.matlab.datatoolsservices.logDebug("datatoolsservices::eventcoalescer::debounce", "scope: " + NVPairs.scope + "  eventId: " + eventId);

            currentTime = datetime('now');
            didRun = false;

            % There are three levels to how we keep track of events.
            % 1. The "event stack". This keeps track of events from different "scopes".
            %   - For example, if we have a Live Script with three Variable Editors, we have three "scopes", one for each Variable Editor.
            % 2. An "event dictionary". Each dictionary corresponds to a different scope, and keeps track of events that we must still process.
            % 3. An "event struct". A struct contains information on the type of event, its associated callback, etc.

            persistent eventStack;
            if isempty(eventStack) || NVPairs.fullEventReset
            internal.matlab.datatoolsservices.logDebug("datatoolsservices::eventcoalescer::debounce", "init");
                eventStack = dictionary();
            end

            scope = NVPairs.scope;

            if ~isConfigured(eventStack) || ~isKey(eventStack, scope)
                eventStack(scope) = dictionary(string.empty, struct.empty);
            end

            debounceDur = NVPairs.debouceDuration;

            eventDict = eventStack(scope);

            if NVPairs.cancelAll
                internal.matlab.datatoolsservices.logDebug("datatoolsservices::eventcoalescer::debounce::cancelAll", "scope: " + NVPairs.scope);
                k = keys(eventDict);
                for i=1:length(k)
                    eventStruct = eventDict(k{i});
                    eventStruct = stopCurrenttimer(eventStruct, NVPairs.scope, eventId);
                end
                
                return;
            end

            if ~isKey(eventDict, eventId)
                eventDict(eventId) = struct('debounceDuration', debounceDur, 'lastTimestamp', currentTime);
            else
                % Stop current timer
                eventStruct = eventDict(eventId);
                eventStruct = stopCurrenttimer(eventStruct, NVPairs.scope, eventId);
            end
            eventStruct = eventDict(eventId);

            if NVPairs.reset
                eventDict = remove(eventDict, eventId);
                eventStack(scope) = eventDict;

                internal.matlab.datatoolsservices.logDebug("datatoolsservices::eventcoalescer::debounce::reset", "scope: " + NVPairs.scope + " eventId: " + eventId);

                return;
            end

            if ~isfield(eventStruct, 'eventQueue')
                eventStruct.eventQueue = {};
            end
            eventStruct.eventQueue{end+1} = NVPairs.callbackArguments;

            % Define the callback function that gets executed when a timer fires an "Executing" event.
            function callUserFcn()
                try
                    internal.matlab.datatoolsservices.logDebug("datatoolsservices::eventcoalescer::debounce::execCallback", "scope: " + NVPairs.scope + "  eventId: " + eventId + " callback: " + func2str(callback));
                    if nargin(callback) > 0
                        callback(eventStruct.eventQueue);
                    else
                        callback();
                    end
                    didRun = true;
                catch e
                    internal.matlab.datatoolsservices.logDebug("datatoolsservices::EventCoalescer::Debounce::CallbackError", e.message);
                    if ~isempty(NVPairs.errorFcn)
                        try
                            errorFcn(e);
                        catch ee
                            internal.matlab.datatoolsservices.logDebug("datatoolsservices::EventCoalescer::Debounce::ErrorFcnError", ee.message);
                        end
                    end
                end

                % g3443334: We must be very careful when referencing shared variables (the ones that glow blue,
                % indicating that this nested function's variable shares the same value as the parent function).
                %
                % Remember that anonymous functions provide variable closure. This is particularly dangerous when
                % we refer to "eventDict"---if we directly reference the shared variable "eventDict", we're using
                % the version _when the timer was set up_, NOT the version it's currently at. This means that we
                % could inadvertently drop other timers that have been set up in the meantime.
                % - This problem would not happen if structs behaved as if they were copied by reference.
                %
                % To combat this, we do not use "eventDict".
                % - We still use "eventStack" because it's a persistent variable and thus avoids closure behavior
                %   altogether. We can rely on this being up to date.
                % - We still use "eventStruct" because these structs don't get stale.
                stopCurrenttimer(eventStruct, NVPairs.scope, eventId);

                localEventDict = eventStack(scope);
                eventStack(scope) = remove(localEventDict, eventId);
            end
            eventStruct.lastTimestamp = currentTime;

            eventStruct.timer = internal.IntervalTimer(debounceDur);
            eventStruct.listener = event.listener(eventStruct.timer, 'Executing', @(~,~) callUserFcn());
            start(eventStruct.timer);

            eventDict(eventId) = eventStruct;
            eventStack(scope) = eventDict;
        end

        % Calls throttle and debounce so that callback fires immediately
        % then subsequent calls are queued until debounceDuration has
        % elapsed.
        %
        % Arguments:
        %           eventId: unique event identifier
        %          callback: callback to execute/throttle
        % Named Arguments:
        %             scope: unique identifier for event scope(UUID)
        %  throttleDuration: throttle duration (e.g. how often to let events through)
        %   debouceDuration: debounce duration (e.g. how long to wait before running callback)
        %             reset: resets the time, and event will go through
        % callbackArguments: cell array of arguments to be passed to callback
        %          errorFcn: callback function if an error occurs when trying to execute callback
        %          forceRun: set to force execution regardless if still within throttle time
        %    fullEventReset: reset full event queue for all scopes and events (debug only)
        function throttleDebounce(eventId, throttleCallback, NVPairs)
            arguments
                eventId (1,1) string;
                throttleCallback function_handle {mustBeScalarOrEmpty} = function_handle.empty;
                NVPairs.scope (1,1) string = "";
                NVPairs.throttleDuration (1,1) double = matlab.internal.datatoolsservices.EventCoalescer.DEFAULT_THROTTLE_DURATION;
                NVPairs.debouceDuration (1,1) double = matlab.internal.datatoolsservices.EventCoalescer.DEFAULT_DEBOUNCE_DURATION;
                NVPairs.debounceCallback function_handle {mustBeScalarOrEmpty} = throttleCallback;
                NVPairs.reset (1,1) logical = false;
                NVPairs.callbackArguments cell = {};
                NVPairs.errorFcn function_handle {mustBeScalarOrEmpty} = function_handle.empty;
                NVPairs.forceRun (1,1) logical = false;
                NVPairs.fullEventReset (1,1) logical = false;
            end

            internal.matlab.datatoolsservices.logDebug("datatoolsservices::eventcoalescer::throttleDebounce", "scope: " + NVPairs.scope + "  eventId: " + eventId);

            noDeb = rmfield(NVPairs, 'debouceDuration');
            noThr = rmfield(NVPairs, 'throttleDuration');
            noDeb = rmfield(noDeb, 'debounceCallback');
            noThr = rmfield(noThr, 'debounceCallback');
            nvpNoDeb = namedargs2cell(noDeb);
            nvpNoThr = namedargs2cell(noThr);


            didRun = matlab.internal.datatoolsservices.EventCoalescer.throttle(eventId, throttleCallback, nvpNoDeb{:});
            if ~didRun
                internal.matlab.datatoolsservices.logDebug("datatoolsservices::eventcoalescer::throttleDebounce", "NR in throttle debouncing. scope: " + NVPairs.scope + "  eventId: " + eventId);
                matlab.internal.datatoolsservices.EventCoalescer.debounce(eventId, NVPairs.debounceCallback, nvpNoThr{:});
            else
                internal.matlab.datatoolsservices.logDebug("datatoolsservices::eventcoalescer::throttleDebounce", "Run in throttle resetting. scope: " + NVPairs.scope + "  eventId: " + eventId);
                matlab.internal.datatoolsservices.EventCoalescer.debounce(eventId, NVPairs.debounceCallback, nvpNoThr{:}, 'reset', true);
            end

        end
    end
end

function eventStruct = stopCurrenttimer(eventStruct, debugInfoScope, debugInfoEventId)
    arguments
        eventStruct      % The struct representing an event which holds the timer to stop
        debugInfoScope   % The "scope" the event struct belongs to
        debugInfoEventId % The "event ID" assigned to the event struct
    end

    currentTimer = eventStruct.timer;
    if isvalid(currentTimer)
        internal.matlab.datatoolsservices.logDebug("datatoolsservices::eventcoalescer::stopCurrenttimer", "scope: " + debugInfoScope + " eventId: " + debugInfoEventId);
        stop(currentTimer);
        if ~isempty(eventStruct.listener)
            delete(eventStruct.listener);
            eventStruct.listener = [];
        end
    end
    eventStruct = rmfield(eventStruct, 'timer');
    eventStruct = rmfield(eventStruct, 'listener');
end
