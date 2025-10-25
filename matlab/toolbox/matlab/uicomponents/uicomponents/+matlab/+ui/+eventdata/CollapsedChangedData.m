classdef CollapsedChangedData < matlab.ui.eventdata.internal.AbstractEventData
    % This class is for the event data of 'CollapsedChangedData' events
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties(SetAccess = 'private')
        AccordionPanel
        PreviousCollapsed
        Collapsed
    end
    
    methods
        function obj = CollapsedChangedData(node, collapsed)
            % The accordion panel and new value are required input.
            narginchk(2, 2);
            
            % Populate the properties
            obj.AccordionPanel = node;
            obj.PreviousCollapsed = ~collapsed;
            obj.Collapsed = collapsed;
        end
    end
end

