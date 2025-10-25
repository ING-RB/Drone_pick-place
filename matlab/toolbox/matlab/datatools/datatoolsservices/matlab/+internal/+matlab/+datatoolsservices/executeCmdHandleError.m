% This class is unsupported and might change or be removed without
% notice in a future version.

% executeCmdHandleError executes the specified code in the user's current
% workspace.  Any errors generated from the command are passed to the specified
% error function.

% Copyright 2019-2024 The MathWorks, Inc.

function executeCmdHandleError(evalStr, errorFcn, waitForIdle)
    arguments
        evalStr
        errorFcn
        waitForIdle = true;
    end
    evalStr = convertStringsToChars(evalStr);
    if iscellstr(evalStr)
        evalStr = evalStr{1};
    end
    evalStr = strrep(evalStr, '"', '""');
    
    evalStr = "try;eval(""" + evalStr + """);catch exFromExecuteCmdHandleError;" + ...
        errorFcn + "(exFromExecuteCmdHandleError.message);clear('exFromExecuteCmdHandleError');end";
    
    if ~waitForIdle
        evalin('debug', evalStr);
    else
        try
            evalCmd = @(es,ed)evalin('caller', evalStr);
            builtin('_dtcallback', evalCmd, ...
                internal.matlab.datatoolsservices.getSetCmdExecutionTypeIdle);
        catch e
            % Additional logging for quarantined test failures g3227867
            error('An error occurred: %s\nThe command used is: %s', e.getReport(), evalStr);
        end
    end
end
