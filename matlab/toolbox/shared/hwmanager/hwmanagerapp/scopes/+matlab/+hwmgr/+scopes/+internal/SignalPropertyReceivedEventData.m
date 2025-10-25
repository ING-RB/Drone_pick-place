classdef (Hidden, ConstructOnLoad) SignalPropertyReceivedEventData < event.EventData
% SignalPropertyReceivedEventData Time Scope event that MessageHandler
% sends to notify signal of on-demand front-end property arrival.

%   Copyright 2020 The MathWorks, Inc.

    properties
        ID
        Property
        Value
    end
    
    methods
        function data = SignalPropertyReceivedEventData(message)
            data.ID = message.identifier;
            data.Property = message.property;
            data.Value = message.value;
        end
    end
end
