classdef DialogManagerEventData < matlab.ui.eventdata.internal.AbstractEventData
% DialogManagerEventData is the event data class for DialogManager

% Author(s): Rong Chen
% Copyright 2019-2020 The MathWorks, Inc.
    
    properties(SetAccess = 'private')
        Figure;
    end
    
    methods

        function obj = DialogManagerEventData(fig)
            obj = obj@matlab.ui.eventdata.internal.AbstractEventData();
            obj.Figure = fig;
        end
        
    end
    
end

