classdef HWManagerProviderTypes
    % Class defining hardware manager provider type enumerations.
    
    % Copyright 2017 MathWorks Inc.
    
    enumeration
        Device
        Applet
    end
    
    methods
        function out = isDeviceType(obj)
            out = isequal(matlab.hwmgr.internal.HWManagerProviderTypes.Device, obj);
        end
        
        function out = isAppletType(obj)
            out =  isequal(matlab.hwmgr.internal.HWManagerProviderTypes.Applet, obj);
        end
    end
    
end