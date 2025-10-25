classdef AppletProviderBase < matlab.mixin.Heterogeneous
    % APPLETPROVIDERBASE - Base class for all Hardware Manager Applet
    % Provider implementations.
    % 
    % Hardware Manager clients use this class to inform Hardware Manager
    % about their applets. 
    %
    % Hardware Manager clients also use this class to inform Hardware
    % Manager which of the applets work for the currently selected device.
    
    % Copyright 2016-2020 Mathworks Inc.
    
    methods(Abstract, Access = public)
        appletList = getApplets(obj)
        appletList = getAppletsByDevice(obj, device)        
    end
    
    methods (Static)
        function applet = getHardwareSetupAppletByDevice(device)
            % Return the HardwareSetupApplet if the device is supported.
            validateattributes(device, {'matlab.hwmgr.internal.Device'}, {});
            applet = [];
            
            % The Hardware Setup Workflow class takes precedence
            if device.hasHardwareSetup
                applet = 'matlab.hwmgr.applets.internal.HardwareSetupApplet';
            end
        end
    end
end

