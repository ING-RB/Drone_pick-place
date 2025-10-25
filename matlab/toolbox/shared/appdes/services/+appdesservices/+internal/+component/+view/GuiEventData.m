classdef GuiEventData < event.EventData
    % GUIEVENTDATA This is event data used by ProxyView GuiEvent event. It
    % is used to communicate with Design time controllers. We store view
    % model event data as run time controllers expect view model event
    % data. This allows design time controllers to revert the event data if
    % needed.
    
    properties(SetAccess='private', GetAccess='public')
        % A structure containing event data. There is a field in this
        % structure for each piece of event data. The value of the field is
        % contains the actual data. 
        Data;
        
        %
        Originator;
        
        IsFromClient;
        
        ViewModelEventData
    end
    
    methods
        function eventData = GuiEventData(data, originator, isFromClient, viewModelEventData)
            %  EVENTDATA = GUIEVENTDATA(DATA) create GuiEventData and
            %  initialize data field
            %
            % DATA the custom event data.
            
            assert(isstruct(data), 'event data must be a struct');
            
            eventData.Data = data;
            
            if nargin >= 2
                eventData.Originator = originator;
            end
            
            eventData.IsFromClient = [];
            if nargin >= 3
                eventData.IsFromClient = isFromClient;
            end
            
            eventData.ViewModelEventData = [];
            if nargin >= 4
                eventData.ViewModelEventData = viewModelEventData;
            end
        end

        function data = getData(obj)
            data = obj.Data;
        end
        
        function originator = getOriginator(obj)
            originator = obj.Originator;
        end
        
        function isFromClient = isFromClient(obj)
            if isempty(obj.IsFromClient)
                % PeerModel case
                isFromClient = ~isempty(originator);
            else
                isFromClient = obj.IsFromClient;
            end
        end
        
    end
end

