classdef GenerationMessageStdout < rptgen.internal.gui.GenerationMessageClient
    %GENERATIONMESSAGESTDOUT Displays messages in the MATLAB command window.
    %   Allows the Report Explorer to display report generation messages in
    %   the MATLAB command window.
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties (Access=private)
        FilterLevel double = 3;
    end
    
    methods
        
        function clearMessages(obj) %#ok<MANU>
        end
        
        function addMessage(obj,message,priority)
             import rptgen.internal.gui.*
            if priority <= obj.FilterLevel              
                fprintf('%s\n',GenerationDisplayClient.indentString(message,priority));
            end
        end
        
        function setPriorityFilter(obj,priority)
            obj.FilterLevel = priority;
        end
        
        function priority = getPriorityFilter(obj)           
            priority = obj.FilterLevel;
        end

        function enableFilterList(obj) %#ok<MANU>
        end

        function disableFilterList(obj) %#ok<MANU>
        end
        
    end
end

