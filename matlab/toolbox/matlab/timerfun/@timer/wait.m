function wait(obj)
%WAIT Wait until the timer stops running.
%
%    WAIT(OBJ) blocks the MATLAB command line and waits until the
%    timer, represented by the timer object OBJ, stops running.
%    When a timer stops running, the value of the timer object's
%    Running property changes from 'On' to 'Off'.
%
%    If OBJ is an array of timer objects, WAIT blocks the MATLAB
%    command line until all the timers have stopped running.
%
%    If the timer is not running, WAIT returns immediately.
%
%    See also TIMER/START, TIMER/STOP.
%

%    Copyright 2001-2021 The MathWorks, Inc.

if ~all(isvalid(obj))
    error(message('MATLAB:timer:invalid'));
end

checkInfiniteTimer(obj);
blockCmdWinUntilTimerIsProcessed(obj);
end

function blockCmdWinUntilTimerIsProcessed(obj)
len = length(obj);
% wait for the end of each timer.
for lcv = 1:len
    if (isvalid(obj(lcv)))
        % wait until timer.Running property changes to off
        builtin('waitfor', obj(lcv), 'Running', 'off');
    end
end



end

function checkInfiniteTimer(obj)

len = length(obj);

for lcv = 1:len
    if strcmp(get(obj(lcv),'ExecutionMode'),'singleShot')
        %skip
    else
        if (~isfinite(obj(lcv).TasksToExecute))
            error(message('MATLAB:timer:infinitetimer'));
        end
    end
end
end



