classdef GenerationDisplayClient < rptgen.internal.gui.GenerationMessageClient
    %GENERATIONDISPLAYCLIENT Display report generation messages
    %   Used by the Report Explorer to display messages during report generation.
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    methods
        
        function clearMessages(obj) %#ok<MANU>
            import rptgen.internal.gui.*
            GenerationDisplayClient.staticClearMessages();
        end
        
        function addMessage(obj,message,priority) %#ok<INUSL>
            import rptgen.internal.gui.*
            GenerationDisplayClient.staticAddMessage(message,priority);
        end
        
        function setPriorityFilter(obj,priority) %#ok<INUSL>
            import rptgen.internal.gui.*
            GenerationDisplayClient.staticSetPriorityFilter(priority);
        end
        
        function priority = getPriorityFilter(obj) %#ok<MANU>
            import rptgen.internal.gui.*
            priority =  GenerationDisplayClient.staticGetPriorityFilter();
        end

        function enableFilterList(obj) %#ok<MANU>
            import rptgen.internal.gui.*
            GenerationDisplayClient.enableFilterList();
        end

        function disableFilterList(obj) %#ok<MANU>
            import rptgen.internal.gui.*
            GenerationDisplayClient.disableFilterList();
        end
        
    end
    
    methods (Static)
        
        function client = MessageClient(varargin)
            persistent CLIENT
            if nargin > 0
                CLIENT = varargin{1};
            end
            client = CLIENT;
        end
        
        function client = DefaultClient(varargin)
            persistent CLIENT
            if nargin > 0
                CLIENT = varargin{1};
            end
            client = CLIENT;
        end
        
        function reset()
            % Sets the static variables to reasonable defaults
            import rptgen.internal.gui.*
            if isempty(GenerationDisplayClient.DefaultClient)
                GenerationDisplayClient.DefaultClient(GenerationMessageStdout);
            end
            setPriorityFilter(GenerationDisplayClient.DefaultClient,3);
            GenerationDisplayClient.MessageClient(GenerationDisplayClient.DefaultClient);
        end
        
        function client = getMessageClient()
            import rptgen.internal.gui.*
            if isempty(GenerationDisplayClient.MessageClient)
                GenerationDisplayClient.reset();
            end
            client = GenerationDisplayClient.MessageClient;
        end
        
        function setMessageClient(gmc)
            import rptgen.internal.gui.*
            GenerationDisplayClient.MessageClient(gmc);
        end
        
        function staticClearMessages()
            import rptgen.internal.gui.*
            GenerationDisplayClient.getMessageClient().clearMessages();
        end
        

        function staticAddMessage(message,priority)
            % @param message Note that this method will replace carriage
            % returns in the message @param priority An integer 1-6.  Lower
            % numbers are more important.  Be careful with priority 1
            % messages as they signal an unexpected error which will fail
            % QE tests.
            import rptgen.internal.gui.*
            if ~isempty(message)
                message = string(message);
                message = strrep(message,newline," ");
                GenerationDisplayClient.getMessageClient().addMessage(message,priority);
            end
        end
    
        function staticAddMessageMultiLine(message,priority)
            % @param message A message to be added.  Carriage returns
            % define new lines. @param priority An integer 1-6.  Lower
            % numbers are more important. Be careful with priority 1
            % messages as they signal an unexpected
            %error which will fail QE tests.
            import rptgen.internal.gui.*
            
            if ~isempty(message)
                message = string(message);
                lines = split(message,newline);
                for line = lines
                    GenerationDisplayClient.getMessageClient().addMessage(line,priority);
                end
            end
        end
        
        function staticSetPriorityFilter(priority)
            import rptgen.internal.gui.*
            GenerationDisplayClient.MessageClient().setPriorityFilter(priority);
        end
    
        function priority = staticGetPriorityFilter()
            import rptgen.internal.gui.*
            priority = GenerationDisplayClient.MessageClient().getPriorityFilter();
        end

        function messages = indentString(messages,priority)
            % A general utility method. Many implementors will want to indent
            % strings according to priority.
            messages = string(messages);
            n = priority-1;
            for i=1:n
                messages = "  " + messages;
            end
        end
    
        
    end
    
    
end

