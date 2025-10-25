classdef GenericEventData < matlab.ui.eventdata.internal.AbstractEventData
    % This class is the event data class for all the data browser events
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties(SetAccess = 'private')
        Data;
    end
    
    methods

        function obj = GenericEventData(eventData)
            obj = obj@matlab.ui.eventdata.internal.AbstractEventData();
            if isa(eventData,'matlab.ui.eventdata.CellEditData')
                % an editable struct with identical fields is created to
                % replace CellEditData.
                obj.Data = struct('Indices', eventData.Indices,...
                    'DisplayIndices', eventData.DisplayIndices,...
                    'PreviousData', eventData.PreviousData,...
                    'EditData', eventData.EditData,...
                    'NewData', eventData.NewData,...
                    'Error', eventData.Error,...
                    'Source', eventData.Source,...
                    'EventName', eventData.EventName);
            else
                % otherwise, it is a structure by default
                obj.Data = eventData;
            end
        end
        
    end
    
end

