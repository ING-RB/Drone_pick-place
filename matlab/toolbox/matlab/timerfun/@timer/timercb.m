function timercb(obj,type,val,event)
%TIMERCB Wrapper for timer object callback.
%
%   TIMERCB(OBJ,TYPE,VAL,EVENT) calls the function VAL with parameters
%   OBJ and EVENT.  This function is not intended to be called by the
%   user.
%
%   See also TIMER

% Copyright 2001-2022 The MathWorks, Inc.
previousCallingContextType = 'unknown';

% DeletionStopFcn is a special 'type', only called by
% delete method of timer. DeletionStopFcn is basically StopFcn.
% but whereas other StopFcn calls will not be fired, in case of invalid
% timer obj, this special DeletionStopFcn will fire regardless of
% whether the TimerObject is invalid/valid
%if ~isvalid(obj) && ~strcmp(type, 'DeletionStopFcn')
if (~strcmp(type, 'DeletionStopFcn') &&  (~isvalid(obj)))
    return;
end
% e.g. in a fixedRate timer, we might have already
% scheduled a timerfcn to call back, but the user has
% already called stop(timer).
if (obj.stopRequested && strcmp(type, 'TimerFcn'))
    return;
end

try
    if(obj.errorReached) && (strcmp(type,'TimerFcn'))
        return;
    end
catch
end

if (strcmp(type, 'DeletionStopFcn'))
    previousCallingContextType = 'DeletionStopFcn';
    type = 'StopFcn';
end

try
    % Re-query and cache the callback fcn val, if a valid timerobject was provided.
    % The try-catch is important, since the timer obj might get deleted and invalid
    % in between query and we might want to run some
    % callback fcn (StopFcn in particular) on destruction/cleanup of a timer
    % object. The TimerObject might already be invalid by that point, in which
    % case, we cannot re-query for callback fcn change.
    val = obj.(type);
    timername = obj.Name;
    errorFcnVal = obj.('ErrorFcn');
catch
    timername = 'invalid';
end

try
    if (strcmp(type,'TimerFcn') && ...
            isempty(val) && ...
            strcmp(obj.Running, 'on'))
        error(message('MATLAB:timer:cannotSetEmptyTimerFcnWhileRunning'));
    end

    if any(type==["StartFcn","StopFcn","ErrorFcn"]) && isempty(val)
        % in the new version, we don't set any of the values on the
        % backend. The backend doesn't know/care whether there is a
        % value for one of those aforementioned callbacks. If they are
        % empty just return.
        return;
    end
    eventStruct = struct("Type",event.Type,"Data",struct('time',event.Data));
    if isa(val,'char') % strings are evaled in base workspace.
        evalin('base',val);
    else % non-strings are fevaled with calling object and event struct as parameters
        % Construct the event structure.  The callback is expected to be of cb(obj,event,...) format
        % if error was reached
        if(obj.errorReached) && (strcmp(type,'ErrorFcn'))
            eventStruct.Data.message = obj.errorReachedMsgStr;
            eventStruct.Data.messageID = obj.errorReachedMsgId;
        end

        % make sure val is a cell / only not a cell if user specified a function handle as callback.
        if isa(val, 'function_handle')
            val = {val};
        end
        % Execute callback function.

        if iscell(val)
            if (~isvalid(obj) && strcmp(previousCallingContextType, 'DeletionStopFcn'))
                feval(val{1}, timer.empty(), eventStruct, val{2:end});
            else
                feval(val{1}, obj, eventStruct, val{2:end});
            end

        else
            error(message('MATLAB:timer:incorrectCallbackInput'));
        end
    end
catch exception
    % save the exception, so that if errordFcn is defined for the timer
    % It can use that information on the errorFcn run
    obj.errorReachedMsgId  = exception.identifier;
    obj.errorReachedMsgStr = exception.message;

    if strcmp(exception.identifier, ...
            'MATLAB:timer:cannotSetEmptyTimerFcnWhileRunning')
        % Displays the exception message without throwing it,
        % presumably because we do not want clients to know about timercb
        % and the timer backend implementation.
        disp(getReport(MException(exception.identifier, '%s', ...
            getString(message(exception.identifier)))));
    else
        identifier = 'MATLAB:timer:badcallback';
        % Displays the exception message without throwing it.
        disp(getReport(MException(identifier, '%s', ...
            getString(message(identifier, type, timername, exception.message)))));
    end

    if ~ismember(type, {'ErrorFcn'})
        % if it's an erroFcn erroring skip doing anything
        try

            obj.errorReached = true;
            if ~isempty(errorFcnVal)
                if (~strcmp(type, 'StopFcn'))
                    shouldScheduleFollowupStopFcn = true;
                else
                    shouldScheduleFollowupStopFcn = false;
                end
                obj.coreBackend.forceErrorCallback(shouldScheduleFollowupStopFcn);
            end

        catch
            identifier = 'MATLAB:timer:unableToExecuteErrorFcn';
            disp(getReport(MException(identifier, '%s', ...
                getString(message(identifier)))));

        end
    end
end
