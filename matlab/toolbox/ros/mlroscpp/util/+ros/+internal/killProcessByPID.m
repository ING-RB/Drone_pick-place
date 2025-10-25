function [status, result] = killProcessByPID(pid)
%This function is for internal use only. It may be removed in the future.

%   Copyright 2020-2021 The MathWorks, Inc.

% kills the process using its PID

if getenv('MW_ROS_CORE_SHUTDOWN_LOG_MSGS')
    disp("* Inside killProcessByPID function *");
end

if ispc
    [status, result] = system(sprintf('taskkill /F /T /PID %d"',pid));
else
    % The PID refers to the shell script responsible for launching the ROS master.
    % The child process, which is the actual ROS master, is a Python process.
    % In this step, we terminate the child process (ROS master), which subsequently
    % results in the termination of the parent process (the shell script that initiated the ROS master).
    if getenv('MW_ROS_CORE_SHUTDOWN_LOG_MSGS')
        disp("PID of core to be killed: "+ pid)
    end
    [status, result] = system(sprintf('pgrep -P %d | xargs kill -9',pid)); 
    if getenv('MW_ROS_CORE_SHUTDOWN_LOG_MSGS')
        disp("Status after Child Process Killed: "+status)
        disp("Result after Child Process Killed: "+result)
        [st, res] = system(sprintf('ps ax | grep -E ''ros|python'''));
        disp("Status after deleting core :"+st)
        disp("Result after deleting core :"+res)
    end
end

if getenv('MW_ROS_CORE_SHUTDOWN_LOG_MSGS')
    disp("* Exiting killProcessByPID function *");
end

end