
function start(obj)
%START Start timer(s) running.
%
%    START(OBJ) starts the timer running, represented by the timer
%    object, OBJ. If OBJ is an array of timer objects, START starts
%    all the timers. Use the TIMER function to create a timer object.
%
%    START sets the Running property of the timer object, OBJ, to 'On',
%    initiates TimerFcn callbacks, and executes the StartFcn callback.
%
%    The timer stops running when one of the following conditions apply:
%     - The number of TimerFcn callbacks executed equals the number
%       specified by the TasksToExecute property.
%     - The STOP(OBJ) command is issued.
%     - An error occurs while executing a TimerFcn callback.
%
%    See also TIMER, TIMER/STOP.

%    RDD 11-20-2001
%    Copyright 2001-2022 The MathWorks, Inc.

    try
        len = length(obj);
        err = false;
        shouldWarnOrErr = false;
        alreadyRunning = false;

        for lcv = 1:len % foreach object in OBJ array

            if ( obj(lcv).coreBackend.Running == 1) % if timer already running, flag as error/warning
                alreadyRunning = true;
                if ~(obj(lcv).stopRequested)
                    shouldWarnOrErr = true;
                end
            else
                try
                    % In case this timer obj was started
                    % previously, was not deleted and is part matlab.internal.timer.lifetimeManager,
                    % and is being re-used again.
                    obj(lcv).errorReached = false;
                    obj(lcv).errorReachedMsgId = '';
                    obj(lcv).errorReachedMsgStr = '';
                    obj(lcv).stopRequested = false;

                    % NOTE : obj.coreBackend.TasksToExecute can be set/reset while timerfcn is running.
                    % As such, this is the only (controlling) property other than callbacks, that can
                    % potentially change and affect timer during timerfcn
                    % call
                    % There is a potential for race condition; consider the
                    % situation where timer1.TasksToExecute = 20; timer has already scheduled
                    % all the necessary timerfcns & stopfcn on MATLAB thread
                    % (e.g. in the case where BusyMode = 'Queue' this is
                    % highly possible). And then the user asks
                    % TasksToexecute = 18; timer will not honor that.
                    % It is better to use timerfcn and check a condition to
                    % control taskExecution midcall, stead of changing
                    % TasksToExecute midcall.
                    % G2280799
                    obj(lcv).coreBackend.StartDelay = obj(lcv).getStartDelayInMiliSec_internal;
                    obj(lcv).coreBackend.Period = obj(lcv).getPeriodMiliSec_internal;
                    obj(lcv).coreBackend.BusyMode = double(obj(lcv).BusyMode);
                    obj(lcv).coreBackend.ExecutionMode = double(obj(lcv).ExecutionMode);
                    if (isempty(obj(lcv).TimerFcn))
                        error(message('MATLAB:timer:cannotStartTimerWithNoTimerFcn'));
                    end
                    obj(lcv).coreBackend.start();

                catch exception
                    err = true; % flag as error/warning needing to be thrown at end
                end
            end
        end

        if (len==1) % if OBJ is singleton, above problems are thrown as errors
            if shouldWarnOrErr
                error(message('MATLAB:timer:alreadystarted'));
            elseif err % throw actual error
                throw(exception);
            end
        else % if OBJ is an array, above problems are thrown as warnings
            if shouldWarnOrErr
                state = warning('backtrace','off');
                warning(message('MATLAB:timer:alreadystarted'));
                warning(state);
            elseif err
                state = warning('backtrace','off');
                warning(message('MATLAB:timer:errorinobjectarray'));
                warning(state);
            end
        end

    catch ME
        if ~all(isvalid(obj))
            if len==1
                error(message('MATLAB:timer:invalid'));
            else
                error(message('MATLAB:timer:someinvalid'));
            end
        else
            rethrow(ME);
        end
    end

end
