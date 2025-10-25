classdef RouDiExecutor < handle
    % This class is for internal use only. It may be removed in the future.

    % RouDiExecutor - RouDi (Routing and Discovery) application executor for iceoryx.
    % iceoryx is based on shared memory and features a shared memory
    % management application called RouDi. RouDi is a daemon taking care of
    % allocating enough space within the shared memory each node and is
    % responsible for transporting messages between these nodes.

    % Copyright 2022 The MathWorks, Inc.

    properties (Constant)
       %RouDiExecutable - Application that runs in background to initiate the shared memory pool
       RouDiExecutable = 'iox-roudi';
    end

    methods (Static)
        function manageRouDiApplication(operation)
            % manageRouDiApplication - manage whether to run or stop RouDi based on
            % the number of nodes created on iceoryx middleware

            validateattributes(operation, {'char', 'string'}, {'nonempty'});
            persistent RouDiUserCount;

            if isempty(RouDiUserCount)
                RouDiUserCount = 0;
            end

            if operation == "addNode"
                RouDiUserCount = RouDiUserCount + 1;

                % start RouDi application before creating the first node on rmw_iceoryx_cpp.
                if RouDiUserCount >= 1 && ~ros.ros2.internal.RouDiExecutor.isRunning()
                    ros.ros2.internal.RouDiExecutor.start();
                end
            elseif operation == "removeNode"
                RouDiUserCount = RouDiUserCount - 1;

                % stop RouDi application after clearing the last available node on rmw_iceoryx_cpp.
                if RouDiUserCount == 0 && ros.ros2.internal.RouDiExecutor.isRunning()
                    ros.ros2.internal.RouDiExecutor.stop();
                end
            end
        end
    end

    methods (Static, Access = private)
        function start
            % start Run a RouDi daemon when first node is being created
            % using iceoryx.

            % Start RouDi Application
            pathEnv = ['"' getenv('PATH') '"'];
            unixEnvMap = containers.Map();
            unixEnvMap('glnxa64') = ['"' getenv('LD_LIBRARY_PATH') '"'];
            unixEnvMap('maci64')  = ['"' getenv('DYLD_LIBRARY_PATH') '"'];
            unixEnvMap('maca64')  = ['"' getenv('DYLD_LIBRARY_PATH') '"'];
            
            % Launch RouDi in background to allow creating a ros2node
            execCommandArgsMap = containers.Map();
            execCommandArgsMap('glnxa64') = ['bash -c ''{ PATH=' pathEnv '; LD_LIBRARY_PATH=' unixEnvMap(computer('arch')) '; iox-roudi ; } ' ' & '''];
            execCommandArgsMap('maci64')  = ['bash -c ''{ PATH=' pathEnv '; DYLD_LIBRARY_PATH=' unixEnvMap(computer('arch')) '; iox-roudi ; } ' ' & '''];
            execCommandArgsMap('maca64')  = ['bash -c ''{ PATH=' pathEnv '; DYLD_LIBRARY_PATH=' unixEnvMap(computer('arch')) '; iox-roudi ; } ' ' & '''];
            execCommand = execCommandArgsMap(computer('arch'));

            [status,result] = system(execCommand);
            if status ~= 0
                error(message('ros:utilities:util:StartRouDiError',ros.ros2.internal.RouDiExecutor.RouDiExecutable, result));
            end
            pause(1); % Allow executable to fail

            % Check if RouDi has launched correctly. This is a while
            % loop that checks for a period of 3s if the process ID of the new
            % process can be found (1 second wait at each iteration)
            ts = tic;
            while toc(ts) < 3
                % Add a small pause to avoid spinning the CPU
                pause(0.1);
                if ros.ros2.internal.RouDiExecutor.isRunning()
                    return;
                end
            end
        end

        function stop
            % ROS2 - Kill RouDi Application when all nodes are removed
            % From the session.
            ros.ros2.internal.RouDiExecutor.killNodeForcefully(ros.ros2.internal.RouDiExecutor.RouDiExecutable);
        end

        function isRunning = isRunning(~)
            %isNodeRunning Determine if Roudi is running on system
            %   ISRUNNING = isRunning returns TRUE
            %   if the RouDi application is running on the system.
            %   The function returns FALSE if RouDi is not
            %   running on the system.

            nodeName = ros.ros2.internal.RouDiExecutor.RouDiExecutable;
            isRunning = false;

            % Output pid and args left justified
            if ismac
                cmd = sprintf('ps axo comm | grep -E "%s" | grep -v "grep"',nodeName);
            elseif isunix
                cmd = sprintf('ps axo pid:1,args:1 | grep -Ei "%s(\\s|$)" | grep -v "grep"',nodeName);
            end

            try
                [status,result] = system(cmd);
                if status ~= 0
                    error(message('ros:utilities:util:SystemError',result));
                end
            catch
                result = '';
            end

            if ismac
                isRunning = contains(result,nodeName);
            elseif isunix
                if ~isempty(result)
                    % Find out pid's of potential candidates by finding digits at each
                    % line beginning.
                    % result = '1257 bash\n3022 bash\n12757 bash\n' will return a cell
                    % array {'1257','3022','12757'} using extract below
                    pidList = extract(result,lineBoundary + digitsPattern);
                    % Test comm to make sure it matches appName. In Linux, only
                    % first 15 characters are stored in /proc/pid/comm file so make
                    % sure we only test against first 15 characters of appName
                    pat = nodeName(1:min(15,length(nodeName)));
                    for k = 1:length(pidList)
                        try
                            % ^%s to match process name at the beginning of the
                            % string
                            [status,result] = system(sprintf('cat /proc/%s/comm | grep -i "^%s"',pidList{k},pat));
                            if status ~= 0
                                error(message('ros:utilities:util:SystemError',result));
                            end
                        catch
                            result = '';
                        end
                        if contains(result,pat,IgnoreCase=true)
                            isRunning = true;
                            break;
                        end
                    end
                end
            end
        end
      
        function [status,result] = killProcess(procName)
            % killProcess Kill a process
            cmd = sprintf('pkill -f %s',procName);
            try
                [status,result] = system(cmd);
            catch EX
                result = EX.message;
                status = 1;
            end
        end

        function killNodeForcefully(nodeName)
            [status,result] = ros.ros2.internal.RouDiExecutor.killProcess(nodeName);
            if status ~= 0
                if contains(result,'Operation not permitted')
                    % The user does not have the correct privileges to kill the node
                    error(message('ros:utilities:util:StopRouDiNoPrivileges',nodeName,''));
                elseif contains(result,'no process found')
                    % This is okay. Silently swallow this exception.
                else
                    % Throw generic error if something else went wrong
                    error(message('ros:utilities:util:StopRouDiError',nodeName,result));
                end
            end
        end
    end
end
