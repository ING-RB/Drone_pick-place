classdef TestCommandLogger < diagram.editor.command.CommandLogger
    %TESTCOMMANDLOGGER logs all command requests and responses.
    % See full documentation here: https://confluence.mathworks.com/display/WDE/Command+Error+Handling
    
    properties
        requests;
        responses;
        verbose (1,1) logical;
    end
    
    methods
        function obj = TestCommandLogger()
            obj.verbose = false;
            obj.clear();
        end
        
        function clear(self)
            self.requests = [];
            self.responses = [];
        end
        
        function logRequest(self, request)
            if (self.verbose)
                str = "Command  request: ";
                try
                    command = request.command;
                    if ~isempty(command)
                        str = str + "Command: """ + command.StaticMetaClass.name + """, ";
                    end
                catch ex %#ok
                end
                str = str + "Action: """ + string(request.action) + """, ActionOrigin: """ + string(request.actionOrigin) + """";
                
                disp(str);
            end
            
            if isempty(self.requests)
                self.requests = request;
            else
                self.requests(end+1) = request;
            end
        end
        
        function logResponse(self, response)
            % Response data will be in a struct in the form of
            %        action: "execute"
            %  actionOrigin: "Client"
            %          type: "diagram.editor.command.MoveCommand"
            %   description: "Move"
            %          uuid: "b771211f-ee2b-4e97-8077-236f3fd0207a"
            %        result: "Success"
            %        reason: ""
            
            response = string(response);
            if (self.verbose)
                str = "Command response: " + response;
                disp(str);
            end
            
            rawStruct = jsondecode(response);
            resultIds = ["Cancel", "Fail", "Timeout", "Success"];
            
            processedResult = struct();
            processedResult.action = string(rawStruct.action);
            processedResult.actionOrigin = string(rawStruct.origin);
            if isempty(rawStruct.command)            
                processedResult.type = "";
                processedResult.description = "";
                processedResult.uuid = "";
            else
                processedResult.type = string(rawStruct.command.type);
                processedResult.description = string(rawStruct.command.description);
                processedResult.uuid = string(rawStruct.command.uuid);
            end
            processedResult.result = resultIds(rawStruct.response.result + 1);
            processedResult.reason = rawStruct.response.reason;
            
            if isempty(self.responses)
                self.responses = processedResult;
            else
                self.responses(end+1) = processedResult;
            end
        end
    end
end

