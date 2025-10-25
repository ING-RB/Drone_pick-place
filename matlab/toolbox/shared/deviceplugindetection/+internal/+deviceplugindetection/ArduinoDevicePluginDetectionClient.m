classdef ArduinoDevicePluginDetectionClient < internal.deviceplugindetection.Manager
    % ArduinoDevicePluginDetectionClient This class implements a client for hardware
    % plugin detection specific to Arduino Support Package.
    
    % Copyright 2016-2021 The MathWorks, Inc.
    
    properties (Constant)
        % VendorCodeMap - Container to map USB vendor codes(IDs) with actual names of the
        % vendors.
        VendorIDCodeMap = containers.Map;
        % ProductIDCodeMap - Container to map of Product IDs with actual product names.
        ProductIDCodeMap = containers.Map;
        % ProductIDToIgnore - Container to map of Product IDs with bootloader product names.
        ProductIDToIgnore = containers.Map;
        % PluginCallTimeLimit - The number of seconds needed to transpire before
        % subsequent device plugin events will be handled.
        PluginCallTimeLimit = 3;
    end
    
    methods (Static)
        function initVendorIDMap()
            % vendorMap - A map of Vendor names to their vendor Ids
            vendorMap = internal.deviceplugindetection.ArduinoDevicePluginDetectionClient.VendorIDCodeMap;
            % productMap - A map of product names to their product Ids
            productMap = internal.deviceplugindetection.ArduinoDevicePluginDetectionClient.ProductIDCodeMap;
            % productIgnoreMap - A map of product names to their product
            % Ids to be ignored
            productIgnoreMap = internal.deviceplugindetection.ArduinoDevicePluginDetectionClient.ProductIDToIgnore;
            
            filepath = fullfile(matlabroot, 'toolbox', 'shared', 'hwmanager', 'hwmanagerapp', 'devicedata', 'ArduinoDeviceData.JSON');
            txt = fileread(filepath);
            deviceDatabaseStruct = jsondecode(txt);
            vids = unique(upper(unique({deviceDatabaseStruct.vid})));
            
            for i=1:numel(vids)
                vendorMap(vids{i}) = 'Arduino';
            end
            
            
            for i=1:numel(deviceDatabaseStruct)
                if (contains(deviceDatabaseStruct(i).deviceName, 'bootloader'))
                    productIgnoreMap(deviceDatabaseStruct(i).pid) = deviceDatabaseStruct(i).deviceName;
                else
                    productMap(deviceDatabaseStruct(i).pid) = deviceDatabaseStruct(i).deviceName;
                end
            end
        end
        
        function out = devicePluginHandler(info)
            % devicePluginHandler Callback function for device plugin events.
            
            % Set variable to enable handler callback debouncing.
            persistent ArduinoDevicePluginDetectionClientCallTimeMap
            
            % Check EnableArduinoDPDM flag, which is a property of EnableArduino
            % singleton class
            if internal.deviceplugindetection.EnableArduinoHotPlug.getInstance.EnableArduinoDPDM
                % Map VendorID(keys) with vendor name(values)
                if isempty(internal.deviceplugindetection.ArduinoDevicePluginDetectionClient.VendorIDCodeMap.keys)
                    internal.deviceplugindetection.ArduinoDevicePluginDetectionClient.initVendorIDMap();
                end
                
                % Determine if the connected device is Arduino
                if isKey(internal.deviceplugindetection.ArduinoDevicePluginDetectionClient.VendorIDCodeMap, info.Vendor)
                    thisVendor = internal.deviceplugindetection.ArduinoDevicePluginDetectionClient.VendorIDCodeMap(info.Vendor);
                    % Determine if the connected device is Arduino
                    if isKey(internal.deviceplugindetection.ArduinoDevicePluginDetectionClient.VendorIDCodeMap, info.Vendor) ...
                            && isKey(internal.deviceplugindetection.ArduinoDevicePluginDetectionClient.ProductIDToIgnore, lower(info.Device))
                        out = internal.deviceplugindetection.Response.NotHandled;
                        return; % return immediately if found bootloader match.
                    end
                    
                    % Determine if the connected device ProductID is in the ProductIDCodeMap
                    if isKey(internal.deviceplugindetection.ArduinoDevicePluginDetectionClient.ProductIDCodeMap, lower(info.Device))
                        thisDevice = internal.deviceplugindetection.ArduinoDevicePluginDetectionClient.ProductIDCodeMap(lower(info.Device));
                    else
                        % If productid not found, then just append the vendor
                        % details alone
                        thisDevice = thisVendor;
                    end
                else
                    % If not found, then return as not handled as this is a device
                    % from a vendor that we do not support.
                    out = internal.deviceplugindetection.Response.NotHandled;
                    return; % return immediately on vendor mismatch.
                end
                
                % Execute a call debounce. Some devices for Arduino create multiple
                % plugin events, but we only want to handle one response per device
                % event.
                currentCall = datetime('now');
                if isempty(ArduinoDevicePluginDetectionClientCallTimeMap)
                    % If unset, set it with the time now for this vendor.
                    ArduinoDevicePluginDetectionClientCallTimeMap = containers.Map();
                    ArduinoDevicePluginDetectionClientCallTimeMap(info.Vendor) = currentCall;
                else
                    % Check if a call has already been registered for this vendor.
                    if ArduinoDevicePluginDetectionClientCallTimeMap.isKey(info.Vendor)
                        % Get the last call time.
                        lastCall = ArduinoDevicePluginDetectionClientCallTimeMap(info.Vendor);
                        % Check if only a small amount of time has transpired from
                        % the last call to this call.
                        if seconds(currentCall - lastCall) < internal.deviceplugindetection.ArduinoDevicePluginDetectionClient.PluginCallTimeLimit
                            % Do nothing and return.
                            out = internal.deviceplugindetection.Response.NotHandled;
                            return;
                        end
                    end
                    
                    % Update the call time to now.
                    ArduinoDevicePluginDetectionClientCallTimeMap(info.Vendor) = currentCall;
                end
                
                % Get the list of installed supported packages.
                installedProducts = matlabshared.supportpkg.getInstalled;
                isArduinoML = 0;
                isArduinoSL = 0;
                
                % Check for Arduino MATLAB and Simulink support packages.
                if ~isempty(installedProducts)
                    isArduinoML = any(strcmpi('MATLAB Support Package for Arduino Hardware', {installedProducts.Name}));
                    isArduinoSL = any(strcmpi('Simulink Support Package for Arduino Hardware', {installedProducts.Name}));
                end
                
                if isempty(installedProducts) || ~(isArduinoML || isArduinoSL)
                    % If both Arduino Simulink SPKG and MATLAB SPKG are not installed, then tell the user about it.
                    msg = message('deviceplugindetection:ArduinoMessages:BothArduinoSPKGNotInstalled', ...
                        thisDevice, 'ML_ARDUINO', 'ARDUINO');
                    fprintf(1, '%s', msg.getString);
                end
                
                if (isArduinoML && (~isArduinoSL))
                    % If only Arduino MATLAB sppkg is not installed, then tell the user about it.
                    docpath = fullfile(strrep(fullfile(arduinoio.internal.getDocMap), '\arduinoio.map', ''), 'index.html');
                    msg = message('deviceplugindetection:ArduinoMessages:OnlyArduinoMLInstalled', ...
                        thisDevice, ...
                        ['matlab:helpview(''', docpath, ''', ''-helpbrowser'')'],...
                        'ARDUINO');% ARDUINO is the basecode for Arduion SL to bring respective Add on page.
                    fprintf(1, '%s', msg.getString);
                end
                
                if (isArduinoSL && (~isArduinoML))
                    % If only Arduino Simulink sppkg is not installed, then tell the user about it.
                    msg = message('deviceplugindetection:ArduinoMessages:OnlyArduinoSLInstalled', ...
                        thisDevice, ...
                        'matlab:helpview(fullfile(codertarget.internal.arduinoert.getDocRoot,''index.html''),''-helpbrowser'')',...
                        'ML_ARDUINO');% ML_ARDUINO is the basecode for Arduion ML to bring respective Add on page.
                    fprintf(1, '%s', msg.getString);
                end
                
                if (isArduinoSL && isArduinoML)
                    % If both Arduino Simulink SPKG and MATLAB SPKG are installed, then tell the user about it.
                    docpath = fullfile(strrep(fullfile(arduinoio.internal.getDocMap), '\arduinoio.map', ''), 'index.html');
                    msg = message('deviceplugindetection:ArduinoMessages:BothArduinoSPKGInstalled', ...
                        thisDevice, ...
                        ['matlab:helpview(''', docpath, ''', ''-helpbrowser'')'],...
                        'matlab:helpview(fullfile(codertarget.internal.arduinoert.getDocRoot,''index.html''),''-helpbrowser'')');
                    fprintf(1, '%s', msg.getString);
                end
                
                % Return as handled.
                out = internal.deviceplugindetection.Response.Handled;
            end
        end

        function out = deviceRemovalHandler(info) %#ok<INUSD>
            % Stub no operation method to return event as handled.
            out = internal.deviceplugindetection.Response.HandledButContinue;
        end

    end% end static methods
end% end class
