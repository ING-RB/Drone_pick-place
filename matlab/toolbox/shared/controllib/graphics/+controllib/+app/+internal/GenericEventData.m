classdef GenericEventData < event.EventData
    %LISTEVENTDATA Class used to pass event data during notify

%   Copyright 2015-2020 The MathWorks, Inc.
    
    % The ListEventData class can be used to pass event data to clients
    % when the event being fired is a list changed event. Any list can be
    % modified through three operations - add, remove, change (or set to a
    % new value). This class lets the user add a type to the list changed
    % event along with the new data (after the change).
    
    properties
        Data        % Data that was changed
    end
    
    methods
        function this = GenericEventData(Data)
            % Check number of inputs
            narginchk(1,1);
            this.Data = Data;
        end
    end
    
end

