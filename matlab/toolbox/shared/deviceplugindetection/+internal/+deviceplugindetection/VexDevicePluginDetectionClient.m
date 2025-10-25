classdef VexDevicePluginDetectionClient < internal.deviceplugindetection.Manager
    % VEXDevicePluginDetectionClient This class implements a client for
    % hardware plugin detection specific to VEX Support Package.
    
    % Copyright 2017-2021 The MathWorks, Inc.
    
    properties (Constant)
        %VendorIDCodeMap - Container to map USB vendor codes(IDs) with actual
        %names of the vendors.
        VendorIDCodeMap = containers.Map;
        % ProductIDCodeMap - Container to map of Product IDs with actual product names.
        ProductIDCodeMap = containers.Map;
        %PluginCallTimeLimit - The number of seconds needed to transpire
        %before subsequent device plugin events will be handled.
        PluginCallTimeLimit = 3;
    end
    
    methods
        
        function obj = VexDevicePluginDetectionClient()
            %VexDevicePluginDetectionClient constructor
        end
    end
    
    methods (Static)
        function initVendorIDMap()
            % vendorMap - A map of Vendor names to their vendor IDs
            vendorMap = internal.deviceplugindetection.VexDevicePluginDetectionClient.VendorIDCodeMap;
            vendorMap('04D8') = 'VEX'; %#ok<NASGU>
        end
        
        function initProductIDMap()
            % productMap - A map of product names to their product Ids
            productMap = internal.deviceplugindetection.VexDevicePluginDetectionClient.ProductIDCodeMap;
            productMap('000B') = 'EDR'; %#ok<NASGU>
        end
        
        function out = devicePluginHandler(info)
            % devicePluginHandler Callback function for device plugin events.
            
            % Set variable to enable handler callback debouncing.
            persistent VexDevicePluginDetectionClientCallTimeMap
            
            % Map VendorID(keys) with vendor name(values)
            if isempty(internal.deviceplugindetection.VexDevicePluginDetectionClient.VendorIDCodeMap.keys)
                internal.deviceplugindetection.VexDevicePluginDetectionClient.initVendorIDMap();
            end
            
            % Determine if the connected device is VEX
            if isKey(internal.deviceplugindetection.VexDevicePluginDetectionClient.VendorIDCodeMap,info.Vendor)
                thisVendor = internal.deviceplugindetection.VexDevicePluginDetectionClient.VendorIDCodeMap(info.Vendor);
            else
                % If not found, then return as not handled as this is a device
                % from a vendor that we do not support.
                out = internal.deviceplugindetection.Response.NotHandled;
                return;
            end
            
            % Map ProductID(keys) with vendor name(values)
            if isempty(internal.deviceplugindetection.VexDevicePluginDetectionClient.ProductIDCodeMap.keys)
                internal.deviceplugindetection.VexDevicePluginDetectionClient.initProductIDMap();
            end
            
            % Determine if the connected device ProductID is in the ProductIDCodeMap
            if isKey(internal.deviceplugindetection.VexDevicePluginDetectionClient.ProductIDCodeMap, info.Device)
                thisDevice = internal.deviceplugindetection.VexDevicePluginDetectionClient.ProductIDCodeMap(info.Device);
            else
                % If not found, then return as not handled as this product is not supported
                out = internal.deviceplugindetection.Response.NotHandled;
                return; % return immediately on vendor mismatch.
            end
            
            thisDevice = [thisVendor ' ' thisDevice];
            
            % Execute a call debounce. Some devices for VEX create multiple
            % plugin events, but we only want to handle one response per device
            % event.
            currentCall = datetime('now');
            if isempty(VexDevicePluginDetectionClientCallTimeMap)
                % If unset, set it with the time now for this vendor.
                VexDevicePluginDetectionClientCallTimeMap = containers.Map();
                VexDevicePluginDetectionClientCallTimeMap(info.Vendor) = currentCall;
            else
                % Check if a call has already been registered for this vendor.
                if VexDevicePluginDetectionClientCallTimeMap.isKey(info.Vendor)
                    % Get the last call time.
                    lastCall = VexDevicePluginDetectionClientCallTimeMap(info.Vendor);
                    % Check if only a small amount of time has transpired from
                    % the last call to this call.
                    if seconds(currentCall - lastCall) < internal.deviceplugindetection.VexDevicePluginDetectionClient.PluginCallTimeLimit
                        % Do nothing and return.
                        out = internal.deviceplugindetection.Response.NotHandled;
                        return;
                    end
                end
                
                % Update the call time to now.
                VexDevicePluginDetectionClientCallTimeMap(info.Vendor) = currentCall;
            end
            
            %Get the list of installed products
            products = ver;
            % Check if Simulink Coder is installed
            if ~any(strcmpi('Simulink Coder',{products.Name}))
                %If Simulink Coder is not installed, then tell the user
                %about it
                msg = message('deviceplugindetection:VexMessages:SLCoderNotInstalled', ...
                    thisDevice,...
                    'RT',...
                    'EC_VEX_MICRO');
                fprintf(1, '%s', msg.getString);
                
                % Return as handled to prevent further processing.
                out = internal.deviceplugindetection.Response.Handled;
                return;
            else
                % Get the list of installed supported packages.
                installedSupportPackages = matlabshared.supportpkg.getInstalled;
                if isempty(installedSupportPackages)
                    %If VEX Support Package is not installed, then tell the
                    %user about it.
                    msg = message('deviceplugindetection:VexMessages:VexSPNotInstalled',...
                        thisDevice, 'EC_VEX_MICRO');
                    fprintf(1, '%s', msg.getString);
                else
                    isVexSL = any(strcmpi('Simulink Coder Support Package for ARM Cortex-based VEX Microcontroller', {installedSupportPackages.Name}));
                    if (isVexSL)
                        %If VEX Support Package is installed, then tell the user
                        %about it.
                        msg = message('deviceplugindetection:VexMessages:VexSPInstalled',...
                            thisDevice,...
                            'matlab:codertarget.internal.helpView(''vexarmcortex'',''armcortexvex_index'')',...
                            'matlab:codertarget.internal.helpView(''vexarmcortex'',''armcortexvex_examples'')');
                        fprintf(1, '%s', msg.getString);
                    else
                        %If VEX Support Package is not installed, then tell the
                        %user about it.
                        msg = message('deviceplugindetection:VexMessages:VexSPNotInstalled',...
                            thisDevice, 'EC_VEX_MICRO');
                        fprintf(1, '%s', msg.getString);
                    end
                end
            end
            % Return as handled.
            out = internal.deviceplugindetection.Response.Handled;
        end

        function out = deviceRemovalHandler(info) %#ok<INUSD>
            % Stub no operation method to return event as handled.
            out = internal.deviceplugindetection.Response.HandledButContinue;
        end

    end
end
