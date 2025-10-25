classdef Edit < handle & matlab.mixin.Heterogeneous
    %Edit - Base class for undoable commands
    
    %   Copyright 2017 The MathWorks, Inc.
    
    % Cannot change the string of the undo button.  Remove this for now.
%     properties
%         Label
%     end
    
    methods
        function redo(this)
            % By default redo does the exact same action as execute.  This
            % is sometimes overloaded to do a slightly different action
            % based on the application.  For instance, creating new
            % objects, the execute creates a new one, the undo could remove
            % it and cache the object and the redo puts the cached object
            % back.
            execute(this);
        end
        
        % These methods are made concrete in order to make an empty vector
        function undo(~)
            % NO OP
        end
        function execute(~)
            % NO OP
        end
        
        function str = getDescription(~)
            str = '';
        end
    end 
end