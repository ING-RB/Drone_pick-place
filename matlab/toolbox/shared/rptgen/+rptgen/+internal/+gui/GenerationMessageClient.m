classdef GenerationMessageClient < handle
    %GENERATIONMESSAGECLIENT Defines message client interface.
    %   Defines the interface that a message client must implement.
    
    % Copyright 2020 The MathWorks, Inc.

      
    methods (Abstract)
        
        % Clears any currently displayed messages in the client
        clearMessages(obj)
             
        % Adds a message to the client display
        addMessage(obj,message,priority);
        
        
        % Only messages of PRIORITY or lower will be displayed.
        setPriorityFilter(obj,priority);
        
        
        % Only messages of PRIORITY or lower will be displayed.
        priority = getPriorityFilter(obj);

        % Enables the message filter list
        enableFilterList(obj)

        % Disables the message filter list
        disableFilterList(obj)     
    end
end

