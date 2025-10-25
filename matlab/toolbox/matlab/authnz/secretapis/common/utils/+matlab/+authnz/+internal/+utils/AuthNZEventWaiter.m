% Provides a means of waiting for an event to occur with a timeout

%   Copyright 2022-2024 The MathWorks, Inc.

classdef AuthNZEventWaiter < matlab.mixin.SetGet & matlab.mixin.Copyable


    properties (Access = private)
        Listeners = [];
        EventReceived = true;
    end
    
    properties (SetAccess = private)
        Mutex = false;
    end
    
    methods
        function obj = AuthNZEventWaiter(l, varargin)
            import matlab.authnz.internal.utils.weakCallbackMethod

            % Copy the relevant properties from the listener passed in.
            if isa( l, 'event.proplistener' )
                listeners = { ...
                    event.proplistener( l.Object, l.Source, l.EventName,  weakCallbackMethod(obj, @eventTriggered) ); ...
                    event.listener( l.Object, 'ObjectBeingDestroyed', weakCallbackMethod(obj, @eventTriggered) );
                    };
            elseif isa( l, 'event.listener' )
                listeners = { ...
                    event.listener( l.Source, l.EventName,            weakCallbackMethod(obj, @eventTriggered) ); ...
                    event.listener( l.Source, 'ObjectBeingDestroyed', weakCallbackMethod(obj, @eventTriggered) );
                    };
            else
                % The first argument is not a listener of any type.
                error(message('MATLAB:authnz:secretapis:EventWaiterNotListener'));
            end

            % Store everything
            obj.set ('Listeners', listeners, varargin{:} );
        end

        function set.EventReceived(obj,value)
            validateattributes(value,{'logical'}, {'scalar'},'','EventReceived')
            obj.EventReceived = value;
        end

        function OK = waitForEvent(obj, isValidWaitFcn, timeout, defaultCallbackPeriod)
            % waitForEvent  Waits for an event to occur, with a specified timeout
            %   OK = waitForEvent(ISVALIDWAITFCN) waits indefinitely with no time-out. 
            %   OK = waitForEvent(ISVALIDWAITFCN, TIMEOUT) waits and with the timeout TIMEOUT
            %   ISVALIDWAITFCN = no arg function handle which returns true
            %   if we should continue to wait, and false otherwise
            %   TIMEOUT can be of the following types: - numeric  (representing the time to wait in seconds before timing-out)
            %                                          - datetime (representing a deadline at which to time-out)
            %                                          - duration (representing the time to wait before timing-out)

            if nargin > 2
                validateattributes(timeout, {'numeric', 'datetime', 'duration'}, {'scalar'}, '', 'timeout')

                % Convert datetime and durations to numeric (representing seconds)
                if isdatetime(timeout)
                    timeout = max(seconds(timeout - datetime('now')), 0);
                elseif isduration(timeout)
                    timeout = seconds(timeout);
                end
                validateattributes(timeout, {'numeric'}, {'nonnegative', 'nonnan'}, '', 'timeout')
            else
                timeout = inf;
            end
            
            if nargin < 4
                % Calculate the callback period and number of tasks for the timer object
                [~, undocConfig] = pctconfig();
            
                % Default period for the timer object in seconds
                defaultCallbackPeriod = undocConfig.mjspollinterval;
            end
            validateattributes(defaultCallbackPeriod, {'numeric'}, {'nonnegative', 'nonnan'}, '', 'defaultCallbackPeriod')

            % callbackPeriod should be to nearest millisecond as that is the maximum
            % precision allowed by the timer object
            if timeout < defaultCallbackPeriod
                callbackPeriod = iRoundToNearestMillisecond(timeout);
                numberOfTasks = 1;
            else
                callbackPeriod = iRoundToNearestMillisecond(defaultCallbackPeriod);
                numberOfTasks = ceil(timeout/callbackPeriod);
            end

            % Create timer object
            t = timer('TimerFcn', {@iTimerFcn, obj, numberOfTasks, isValidWaitFcn});
            c = onCleanup(@() iCleanupTimer(t));

            % Set properties of timer object appropriately due to the fact that they
            % cannot have a period less than or equal to 0.001
            if timeout <= 0.001
                t.StartFcn = {@iTimerFcn, obj, numberOfTasks, isValidWaitFcn};
            else
                t.StartDelay = callbackPeriod;
                t.Period = callbackPeriod;
                t.TasksToExecute = numberOfTasks;
                t.ExecutionMode = 'fixedDelay';
            end

            start(t);
            
            % Block waiting for a change in Mutex to true
            waitfor(obj, 'Mutex', true);

            OK = obj.EventReceived;
        end
    end

    methods (Hidden)
        function eventTriggered(obj,varargin) % Used by teventwaiter
            obj.Mutex = true;
        end
        
        function resetEvent(obj) % Used by teventwaiter
            obj.Mutex = false;
        end
    end
end

%--------------------------------------------------------------------------
%
%--------------------------------------------------------------------------
function iTimerFcn(timerObj, eventObj, obj, numberOfTasks, isValidWaitFcn)
% We want to manually trigger the event in two situations. The first is if the
% Timeout has been reached. If the event type is 'StartFcn'
% then a Timeout less than or equal to 0.001 was chosen and has been reached. If
% numberOfTasks is equal to the TasksExecuted property, then a Timeout of
% greater than 0.001 was chosen and has been reached. The second situation
% is if the isValidWaitFcn indicates that the wait is no longer valid.
if strcmp(eventObj.Type, 'StartFcn') ||...
        timerObj.TasksExecuted == numberOfTasks || ~isValidWaitFcn()
    iTimerTriggered(obj);
end
end

%--------------------------------------------------------------------------
%
%--------------------------------------------------------------------------
function iTimerTriggered(obj)
obj.EventReceived = false;
obj.eventTriggered;
end

%--------------------------------------------------------------------------
%
%--------------------------------------------------------------------------
function iCleanupTimer(timerObj)
stop(timerObj);
delete(timerObj);
end

%--------------------------------------------------------------------------
%
%--------------------------------------------------------------------------
function roundedTimeInSeconds = iRoundToNearestMillisecond(timeInSeconds)
roundedTimeInSeconds = round(timeInSeconds, 3);
end
