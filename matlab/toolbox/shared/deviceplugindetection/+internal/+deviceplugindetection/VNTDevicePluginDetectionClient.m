classdef VNTDevicePluginDetectionClient < internal.deviceplugindetection.Manager
% VNTDevicePluginDetectionClient This class implements a client for hardware
% plugin detection specific to Vehicle Network Toolbox (VNT).

% Copyright 2015-2023 The MathWorks, Inc.

properties (Constant)
    % VendorCodeMap - A map of USB vendor codes to actual names of the
    %   vendors. NI is currently not supported by this feature.
    VendorCodeMap = containers.Map( ...
        {'0BFD', '1248', '0C72'}, ...
        {'Kvaser', 'Vector', 'PEAK-System'});
    
    % PluginCallTimeLimit - The number of seconds needed to transpire before
    %   subsequent device plugin events will be handled.
    PluginCallTimeLimit = 3;
end
    
methods
    
    function obj = VNTDevicePluginDetectionClient()
    % VNTDevicePluginDetectionClient Constructor.
    end
    
end

methods (Static)
    
    function out = devicePluginHandler(info)
    % devicePluginHandler Callback function for device plugin events.
    
        import internal.deviceplugindetection.VNTDevicePluginDetectionClient;
    
        % Set variable to enable handler callback debouncing.
        persistent VNTDevicePluginDetectionClientCallTimeMap

        % Determine the vendor for the device.
        if isKey(VNTDevicePluginDetectionClient.VendorCodeMap, info.Vendor)
            thisVendor = VNTDevicePluginDetectionClient.VendorCodeMap(info.Vendor);
        else
            % If not found, then return as not handled as this is a device
            % from a vendor that we do not support.
            out = internal.deviceplugindetection.Response.NotHandled;
            return;
        end
        
        % Execute a call debounce. Some devices for VNT create multiple plugin 
        % events, but we only want to handle one response per device event.
        currentCall = datetime('now');
        if isempty(VNTDevicePluginDetectionClientCallTimeMap)
            % If unset, set it with the time now for this vendor.
            VNTDevicePluginDetectionClientCallTimeMap = containers.Map();
            VNTDevicePluginDetectionClientCallTimeMap(info.Vendor) = currentCall;
        else
            % Check if a call has already been registered for this vendor.
            if VNTDevicePluginDetectionClientCallTimeMap.isKey(info.Vendor)
                % Get the last call time.
                lastCall = VNTDevicePluginDetectionClientCallTimeMap(info.Vendor);
                % Check if only a small amount of time has transpired from
                % the last call to this call.
                if seconds(currentCall - lastCall) < VNTDevicePluginDetectionClient.PluginCallTimeLimit
                    % Do nothing and return.
                    out = internal.deviceplugindetection.Response.NotHandled;
                    return;                
                end
            end
            
            % Update the call time to now.
            VNTDevicePluginDetectionClientCallTimeMap(info.Vendor) = currentCall;
        end
    
        % Get the list of installed products.
        products = ver;
        % Check if VNT is installed.
        if ~any(strcmpi('Vehicle Network Toolbox', {products.Name}))
            % If VNT is not installed, then tell the user about it.
            msg = message('deviceplugindetection:UserMessages:ProductNotInstalled', ...
                thisVendor, ...
                'Vehicle Network Toolbox', ...
                'VN');
            fprintf(1, '%s', msg.getString);
            
            % Return as handled to prevent further processing.
            out = internal.deviceplugindetection.Response.Handled;
            return;
        end
        
        % Issue a device identified message.
        msg = message('deviceplugindetection:UserMessages:DeviceIdentified', ...
            'Vehicle Network Toolbox', ...
            thisVendor, ...
            'matlab:canChannelList', ...
            'canChannelList');
        fprintf(1, '%s', msg.getString);
        
        % Return as handled.
        out = internal.deviceplugindetection.Response.Handled;
    end

    function out = deviceRemovalHandler(info) %#ok<INUSD> 
        % Stub no operation method to return event as handled.
        out = internal.deviceplugindetection.Response.HandledButContinue;
    end
    
end

end
