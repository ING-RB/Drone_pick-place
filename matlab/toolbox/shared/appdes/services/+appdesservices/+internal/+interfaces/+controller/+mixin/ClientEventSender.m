classdef ClientEventSender < handle
    methods(Abstract)
        sendEventToClient(obj, eventName, pvPairs)
    end
end