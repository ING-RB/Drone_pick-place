classdef MutualExclusiveComponentSelectionChangeData < event.EventData
    % This class is for the event data of 'SelectionChange' events
    
    % Copyright 2015-2020 The MathWorks, Inc.
    
    properties (SetAccess = 'private')
        isInteractive;
    end
    
    methods
        function obj = MutualExclusiveComponentSelectionChangeData(isInteractivelySelected)                    
            % Populate the properties
            obj.isInteractive = isInteractivelySelected;
                        
        end
    end
end
