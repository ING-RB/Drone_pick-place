classdef TestErrorHandler < diagram.editor.command.ErrorHandler
    %TestErrorHandler collects errors and allows you to see what errors
    %have been issued

    properties
        errors = [];
    end
    
    methods
        function clear(self)
            self.errors = [];
        end
        
        function id = getFirstErrorId(self)
            id = [];
            if ~isempty(self.errors)
                err = self.errors(1);
                id = err.id;
            end
        end
        
        function issueError(self, id, msg, request)
            err = struct(id=string(id), msg=string(msg), request=request);
            if isempty(self.errors)
                self.errors = err;
            else
                self.errors(end+1) = err;
            end
        end
    end
end