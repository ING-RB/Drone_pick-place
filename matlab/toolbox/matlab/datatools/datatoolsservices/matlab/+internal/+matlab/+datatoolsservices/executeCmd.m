% This class is unsupported and might change or be removed without
% notice in a future version.

% executeCmd executes the specified code in the user's current workspace.  Any
% errors generated from the command are ignored.

% Copyright 2019-2021 The MathWorks, Inc.

function executeCmd(evalStr, waitForIdle)
    arguments
        evalStr
        waitForIdle = true;
    end
    evalStr = convertStringsToChars(evalStr);
    if iscellstr(evalStr)
        evalStr = evalStr{1};
    end
    
    % Wrap the command to eval in try/catch, ignoring any failures
    evalStr = "try;eval(""" + strrep(evalStr, '"', '""') + """);catch;end";

    if ~waitForIdle
        internal.matlab.datatoolsservices.logDebug("datatoolsservices::executeCmd::sync", "Cmd: " + evalStr);

        evalin('debug', evalStr);
    else
        internal.matlab.datatoolsservices.logDebug("datatoolsservices::executeCmd::aysnc", "Cmd: " + evalStr);

        evalCmd = @(es,ed)evalin('caller', evalStr);
        builtin('_dtcallback', evalCmd, ...
            internal.matlab.datatoolsservices.getSetCmdExecutionTypeIdle);
    end
end
