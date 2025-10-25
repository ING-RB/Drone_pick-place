classdef DataChangedData < matlab.ui.eventdata.internal.AbstractEventData
    % This class is the event data class for 'DataChanged' events
    
    % Copyright 2019-2020 The MathWorks, Inc.
    
    properties(SetAccess = 'private')
        Data;
        
        PreviousData;
    end
    
    methods
        function obj = DataChangedData(newData, previousData)
            % data and previous data are required
            narginchk(2,2);
            
            % Call super which will take care of the additional inputs
            obj = obj@matlab.ui.eventdata.internal.AbstractEventData();
            
            obj.Data = newData;
            obj.PreviousData = previousData;
            
        end
    end
end

