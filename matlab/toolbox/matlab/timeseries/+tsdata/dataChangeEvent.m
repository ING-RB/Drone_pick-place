classdef (CaseInsensitiveProperties,TruncatedProperties) dataChangeEvent < event.EventData & matlab.mixin.SetGet
    properties (SetObservable)
        Action = [];
        Index = [];
    end
    methods
        function h = dataChangeEvent(Action, Ind)
            %DataChangeEvent  Subclass of EVENTDATA to handle tree structure changes
            set(h,'Action',Action,'Index',Ind);
        end  % dataChangeEvent
    end
end

