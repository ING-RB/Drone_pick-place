classdef ErrorHandler < handle
    %ErrorHandler To customize error handling for you application, derive
    % from this class and override issueError. Install an instance of your 
    % class on the editor's commandProcessor like this:
    % editor.commandProcessor.setErrorHandler(yourErrorHandler)
    % If you want to delegate to another error handler, you may
    % construct an object of type such as 
    % diagram.editor.command.DebugErrorHandler and issue the error on 
    % that one.

    methods
        function self = ErrorHandler()
            self.m_uuid = diagram.editor.command.CppErrorHandler.generateNewUUID();
        end
    end

    methods (Abstract)
        issueError(~, id, msg)
    end
    
    properties (Access = private)
        m_uuid;
    end
    
    methods (Sealed, Hidden)
        function uuid = getUUID(self)
            uuid = self.m_uuid;
        end
    end
end