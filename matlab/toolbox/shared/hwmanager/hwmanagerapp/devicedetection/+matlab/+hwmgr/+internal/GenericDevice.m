classdef GenericDevice < matlab.hwmgr.internal.Device
    % MATLAB.HWMGR.INTERNAL.GENERICDEVICE - Class for defining a Hardware
    % Manager generic USB device
    
    % Copyright 2018 Mathworks, Inc.
        
    methods
        function obj = GenericDevice(friendlyName)
            obj = obj@matlab.hwmgr.internal.Device(friendlyName);
        end

        function defaultInfo = getDefaultDisplayInfo(obj)
            defaultInfo = [];
        end
    end
end