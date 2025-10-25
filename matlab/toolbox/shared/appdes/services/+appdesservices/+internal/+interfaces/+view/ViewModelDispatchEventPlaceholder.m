classdef ViewModelDispatchEventPlaceholder < appdesservices.internal.interfaces.view.ViewModelOperationPlaceholder
    %VIEWMODELDISPATCHEVENTPLACEHOLDER A placeholder to queue dispatchEvent() 
    % call on a ViewModel

    % Copyright 2024 MathWorks, Inc.
    
    properties (SetAccess = private)
        EventName
        EventData
        Originator
    end
    
    methods
        function obj = ViewModelDispatchEventPlaceholder(eventName, eventData, orginator)
            arguments
                eventName 
                eventData 
                orginator = [];
            end
            obj.EventName = eventName;
            obj.EventData = eventData;
            obj.Originator = orginator;
        end
        
        function attach(obj, vm)
            if ~isempty(obj.Originator)
                vm.dispatchEvent(obj.EventName, obj.EventData, obj.Originator);
            else
                vm.dispatchEvent(obj.EventName, obj.EventData);
            end
        end
    end
end

