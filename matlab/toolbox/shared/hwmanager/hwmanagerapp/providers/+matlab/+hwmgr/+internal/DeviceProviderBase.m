classdef DeviceProviderBase < handle & matlab.mixin.Heterogeneous
    % MATLAB.HWMGR.INTERNAL.DEVICEPROVIDERBASE - this is the base interface
    % class for providing hardware manager with hardware manager devices.
    
    % Copyright 2017-2023 The MathWorks, Inc.
        
    properties (SetAccess = {?matlab.hwmgr.internal.DeviceList, ?matlab.hwmgr.legacy.DeviceList}, GetAccess = public)
        % A list of devices that have been returned by this provider. This
        % list is updated and maintained by Hardware Manager. The list is
        % re-populated when hardware manager is refreshed.
        DevicesProvided
    end
    
    methods
        
        function devices = getDevicesAndInit(obj)
           devices = obj.getDevices();
           % Transpose to column array if returned as row from
           % provider
           if isrow(devices)
               devices = devices';
           end
           
           % Set the provider class name that created this device
           for i = 1:numel(devices)
               devices(i).ProviderClass = string(class(obj));
           end
        end
        
        function newDescriptors = getDeviceDescriptorsAndInit(obj)
            newDescriptors = obj.getDeviceParamDescriptors();
            
            % Transpose to column array if returned as row from
            % provider
            if isrow(newDescriptors)
                newDescriptors = newDescriptors';
            end
            
            % Set the provider on the descriptor so we can trace back
            % which provider it belongs to
            for i = 1:numel(newDescriptors)
                newDescriptors(i).Provider = obj;
            end
        end

        function configureDescriptors = getConfigureDescriptorsAndInit(obj)
            configureDescriptors = obj.getConfigureParamDescriptors();

            % Transpose to column array if returned as row from
            % provider
            if isrow(configureDescriptors)
                configureDescriptors = configureDescriptors';
            end

            % Set the provider on the descriptor so we can trace back
            % which provider it belongs to
            for i = 1:numel(configureDescriptors)
                configureDescriptors(i).Provider = obj;
            end
        end

        % Template method to return enumerable hardware manager devices
        function devices = getDevices(obj)
           devices = []; 
        end
        
        % Template method to return non-enumerable hardware manager device
        % parameter descriptors that return hardware manager devices
        function devParamDescriptors = getDeviceParamDescriptors(obj)
            devParamDescriptors = [];
        end

        % Template method to return hardware manager device
        % parameter descriptors that configure hardware manager devices
        function configParamDescriptors = getConfigureParamDescriptors(obj)
            configParamDescriptors = [];
        end
    end
    
    
    % Restricted methods to modify the devices provided list
    methods (Access = {?matlab.hwmgr.internal.DeviceList, ?matlab.hwmgr.legacy.DeviceList, ?matlab.hwmgr.internal.toolstrip.ParamTabHandler, ?hwmgr.test.internal.TestCase})
        function addToDevicesProvided(obj, devices)
            % This method will take an array of devices and add each device
            % to its parent provider's "DevicesProvided" list
            
            for i = 1:numel(devices)
                newDevice = devices(i);
                                
                % Add the new device to its parent provider's devices
                % provided list
                obj.DevicesProvided = [obj.DevicesProvided; newDevice];
            end
        end
        
        function removeFromDevicesProvided(obj, devices)
            % This method will take an array of devices and remove each
            % device from this provider's "DevicesProvided" list
            for i = 1:numel(devices)
                deviceToRemove = devices(i);
                deviceIdxToRemove = arrayfun(@(x)isequal(x,deviceToRemove), obj.DevicesProvided);
                obj.DevicesProvided(deviceIdxToRemove) = [];
            end
        end

        function updateInDevicesProvided(obj, devices)
            % This method will take an array of devices and update each
            % device from this provider's "DevicesProvided" list
            for i = 1:numel(devices)
                deviceToUpdate = devices(i);
                deviceIdxToUpdate = arrayfun(@(x)isequal(x,deviceToUpdate), obj.DevicesProvided);
                obj.DevicesProvided(deviceIdxToUpdate) = deviceToUpdate;
            end
        end

    end
    
end
