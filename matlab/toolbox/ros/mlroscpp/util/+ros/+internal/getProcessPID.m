function pid = getProcessPID(processName)
%This function is for internal use only. It may be removed in the future.

%   Copyright 2020-2023 The MathWorks, Inc.

% Create a map of system commands that will query for running application

if getenv('MW_ROS_CORE_SHUTDOWN_LOG_MSGS')
    disp("* Inside getProcessPID function *");
    disp("Process Name: " + processName)
    if ~ispc
        [status, result] = system(sprintf('ps ax | grep -E ''ros|python'''));
        disp("Status before getting PID :"+status)
        disp("Result before getting PID :"+result)
    else
        [status, result] = system(sprintf('tasklist | findstr /I "ros python WindowsTerminal"'));
        disp("Status before getting PID :"+status)
        disp("Result before getting PID :"+result)
    end
end

isAppRunningCmdMap = containers.Map({'win64','maci64','maca64','glnxa64'}, ...
    {sprintf('tasklist /FI "WINDOWTITLE eq %s" /FO TABLE /NH', processName), ... use tasklist
    sprintf('ps ax | grep "%s" | grep -v "grep"', processName), ...  use pidof
    sprintf('ps ax | grep "%s" | grep -v "grep"', processName), ...  use pidof
    sprintf('ps ax | grep "%s" | grep -v "grep"', processName) ...  use pidof
    });

% Get the correct command
cmd = isAppRunningCmdMap(computer('arch'));
[status, result] = system(cmd);
result_data = strsplit(strtrim(result));

if getenv('MW_ROS_CORE_SHUTDOWN_LOG_MSGS')
    disp("Result: " +result)
    disp("Status: " + status)
end

if isequal(status, 0)
    if ispc
        pid  = str2double(result_data{2});
    else
        pid = str2double(result_data{1});
    end
else
    % Assigning pid 0 when unable to fetch the PID
    pid = 0;
end

if getenv('MW_ROS_CORE_SHUTDOWN_LOG_MSGS')
    disp("PID obtained: "+ pid)
    if ~ispc
        [status, result] = system(sprintf('ps ax | grep -E ''ros|python'''));
        disp("Status after getting PID :"+status)
        disp("Result after getting PID :"+result)
    else
        [status, result] = system(sprintf('tasklist | findstr /I "ros python WindowsTerminal"'));
        disp("Status after getting PID :"+status)
        disp("Result after getting PID :"+result)
    end
    disp("* Exiting getProcessPID function *");
end

end
