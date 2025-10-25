classdef NodeTextChangedData < matlab.ui.eventdata.internal.AbstractEventData
    % This class is for the event data of 'NodeTextChangedData' events
    
    % Copyright 2016-2020 The MathWorks, Inc.
    
    properties(SetAccess = 'private')
        Node;
        
        Text;
        
        PreviousText;
    end
    
    methods
        function obj = NodeTextChangedData(node, newValue, oldValue)
            % The node, new and old value are required input.
            
            narginchk(3, 3);
                                    
            % Populate the properties
            obj.Node = node;
            obj.Text = newValue;
            obj.PreviousText = oldValue;
                        
        end
    end
end

