classdef SelectedNodesChangedData < matlab.ui.eventdata.internal.AbstractEventData
    % This class is for the event data of 'SelectionChanged' events
    
    % Copyright 2016-2020 The MathWorks, Inc.
    
    properties(SetAccess = 'private')
        SelectedNodes;
        
        PreviousSelectedNodes;
    end
    
    methods
        function obj = SelectedNodesChangedData(newValue, oldValue)
            % The new and old value are required input.
            
            narginchk(2, 2);
                                    
            % Populate the properties
            obj.SelectedNodes = newValue;
            obj.PreviousSelectedNodes = oldValue;
                        
        end
    end
end

