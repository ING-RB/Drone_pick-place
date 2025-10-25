classdef AppletClosingReason 
    %AppletClosingReason List of reasons why an applet might
    %be closed. This can be used by the applet to display a custom message
    %to the user.
    
    % Copyright 2017-2018 The MathWorks, Inc.
    
    enumeration
        % The main Hardware Manager window is being closed.
        AppClosing
        
        % The user has selected a new device
        DeviceChange
        
        % The user is refreshing the hardware list.
        RefreshHardware
        
        % The reason for the closing is unknown.
        Unknown
        
        % There was an error while running the app
        AppError
        
        % User requested applet close.
        CloseRunningApplet
        
        % User wants to remove the device card from device list
        DeviceRemove
    end
    
    methods
        function appError = isAppError(obj) 
           appError = isequal(obj, matlab.hwmgr.internal.AppletClosingReason.AppError);
        end
        
        function appClosing = isAppClosing(obj) 
           appClosing = isequal(obj, matlab.hwmgr.internal.AppletClosingReason.AppClosing);
        end
        
        function deviceChange = isDeviceChange(obj) 
           deviceChange = isequal(obj, matlab.hwmgr.internal.AppletClosingReason.DeviceChange);
        end
        
        function refreshHardware = isRefreshHardware(obj) 
           refreshHardware = isequal(obj, matlab.hwmgr.internal.AppletClosingReason.RefreshHardware);
        end
        
        function unknown = isUnknown(obj) 
           unknown = isequal(obj, matlab.hwmgr.internal.AppletClosingReason.Unknown);
        end
        
        function appletClose = isCloseRunningApplet(obj)
            appletClose = isequal(obj, matlab.hwmgr.internal.AppletClosingReason.CloseRunningApplet);
        end
        
        function deviceRemove = isDeviceRemove(obj)
            deviceRemove = isequal(obj, matlab.hwmgr.internal.AppletClosingReason.DeviceRemove);
        end
    end
end

