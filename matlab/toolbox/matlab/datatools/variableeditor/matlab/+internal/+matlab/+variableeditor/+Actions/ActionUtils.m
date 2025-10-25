classdef ActionUtils
    % ACTIONUTILS Helper functions to be used by all actions
    
    % Copyright 2020-2025 The MathWorks, Inc.
    
    
    methods(Static)
        function executeCommand(command, workspace)
            arguments
                command
                workspace = "debug"
            end
            if isstring(workspace) || ischar(workspace) || iscellstr(workspace)
                internal.matlab.datatoolsservices.executeCmd(command, false);
            else
                evalin(workspace, command);
            end
        end
        
        function publishCode(channel, code, postExecutionCode, errorFcn)
            arguments
                channel string
                code string
                postExecutionCode string = []
                errorFcn string = []
            end
            c = internal.matlab.datatoolsservices.CodePublishingService.getInstance;            
            if ~isempty(errorFcn) || ~isempty(postExecutionCode)
                c.publishCode(channel, code, errorFcn, postExecutionCode);
            else
                c.publishCode(channel, code);
            end            
        end

        function ch = createCodePublishingChannel(managerChannel, channelSuffix)
            % Returns the unique channel name for unique windows appended
            % by the variable name.
            ch = internal.matlab.datatoolsservices.VariableUtils.createCodePublishingChannel(managerChannel, channelSuffix);
        end
    end
end

