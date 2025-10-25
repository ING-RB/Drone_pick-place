classdef Manager < handle
% Manager Manages device plugin events and responses.
%
%   This class is a top level class for operating device plugin
%   detection and response handling. It leverages low-level device
%   detection capability to dispatch notices to linked products on
%   plugin and removal events.
%
%   Products register with this feature by creating a local subclass of the
%   plugin manager class and implementing handler methods:
%       devicePluginHandler - Responds to plugin events.
%       deviceRemovalHandler - Responds to removal events.
%
%   Both of these functions take an information input, which is an object
%   of type of information related to the device and event. This information includes
%       Event - An indication if the device was added or removed.
%       Vendor - The vendor ID of the device. For USB devices, this is a
%           hexadecimal value.
%       Device - The device ID of the device. For USB devices, this is a
%           hexadecimal value.
%       DeviceType - The form factor of the device, such as "USB".
%       ExtraInfo - Any potentially valuable extra information. For USB
%           devices, this is the full undecoded USB device identification
%           string.
%
%   In the handler methods, products are expected to verify if a given
%   device is of interest to them. If not, they take no additional action
%   and return immediately. If so, they may take whatever action is
%   pertinent to assisting the user in the most appropriate way.

% Copyright 2015-2023 The MathWorks, Inc.

properties (SetAccess = 'private')
    % USBDetectorObject - Property to hold the PnPEventBridge object, which is the
    % low level detector for USB plugin/removal events.
    USBDetectorObject
    % USBDetectorPluginListener - Listener attached to the hotplug object
    % used to respond to USB plugin events.
    USBDetectorPluginListener
    % USBDetectorRemovalListener - Listener attached to the hotplug object
    % used to respond to USB removal events.
    USBDetectorRemovalListener
    
    % SubClasses - A cell array of names of the subclasses of the
    % plugin manager class.
    SubClasses = cell(0);
    % SubClassesRegistered - Boolean tracking if subclasses have been
    % identified.
    SubClassesRegistered = false;
    
    % DEVICE_PLUGIN_FUNCTION_NAME Name of the device plugin handler function
    % expected in the subclasses.
    DEVICE_PLUGIN_FUNCTION_NAME = 'devicePluginHandler';
    % DEVICE_REMOVAL_FUNCTION_NAME Name of the device removal handler function
    % expected in the subclasses.
    DEVICE_REMOVAL_FUNCTION_NAME = 'deviceRemovalHandler';
end

methods
    
    function reset(obj)
    % reset Perform external reset of the manager.
    %
    %   This method is provided to allow external clients to trigger an
    %   internal reset of the plugin manager.
    
        % Update the found clients by searching again for subclasses with
        % handler methods.
        obj.updateSubClasses();
    end
    
end

methods (Hidden)
    
    function usbDeviceInsertedCallback(obj, info)
    % usbDeviceInsertedCallback Callback for USB device plugin events.
    %
    %   This method is used as a listener callback function attached to a
    %   hotplug object. It is invoked on plugin of a USB device to the
    %   system. It serves as a dispatcher to the handler functions for USB
    %   device plugin detection.
    
        % Register the subclasses if this has not yet been done.
        if ~obj.SubClassesRegistered
            % Find the subclasses.
            obj.updateSubClasses();
        end
        
        % Translate the EventData object into our object.
        infoObj = internal.deviceplugindetection.Information( ...
            info.EventName, ...
            info.Vendor, ...
            info.Product, ...
            info.DeviceType, ...
            info.ExtraInfo); %#ok<NASGU>
        
        % Call to the downstream plugin handlers for processing.
        for ii = 1:numel(obj.SubClasses)
            try
                % Make the subclass call to the static method on each.
                response = eval([obj.SubClasses{ii} ...
                    '.' obj.DEVICE_PLUGIN_FUNCTION_NAME '(infoObj)']);
            catch
                % Do not allow a plugin client to fail. In the case of an
                % errant client, we want to suppress the failure from the
                % user and from stopping subsequent processing of other
                % clients. Fix the response as not handled.
                response = internal.deviceplugindetection.Response.NotHandled;
            end
            
            % Stop processing if a client subclass has reported full
            % handling of the device event.
            if response == internal.deviceplugindetection.Response.Handled
                break;
            end
        end
    end

    function usbDeviceRemovedCallback(obj, info)
    % usbDeviceRemovedCallback Callback for USB device removal events.
    %
    %   This method is used as a listener callback function attached to a
    %   hotplug object. It is invoked on removal of a USB device from the
    %   system. It serves as a dispatcher to the handler functions for USB
    %   device removal detection.

        % Register the subclasses if this has not yet been done.
        if ~obj.SubClassesRegistered
            % Find the subclasses.
            obj.updateSubClasses();
        end
        
        % Translate the EventData object into our object.
        infoObj = internal.deviceplugindetection.Information( ...
            info.EventName, ...
            info.Vendor, ...
            info.Product, ...
            info.DeviceType, ...
            info.ExtraInfo); %#ok<NASGU>

        % Call to the downstream removal handlers for processing.
        for ii = 1:numel(obj.SubClasses)
            try
                % Make the subclass call to the static method on each.
                response = eval([obj.SubClasses{ii} ...
                    '.' obj.DEVICE_REMOVAL_FUNCTION_NAME '(infoObj)']);
            catch
                % Do not allow a plugin client to fail. In the case of an
                % errant client, we want to suppress the failure from the
                % user and from stopping subsequent processing of other
                % clients. Fix the response as not handled.
                response = internal.deviceplugindetection.Response.NotHandled;
            end
            
            % Stop processing if a client subclass has reported full
            % handling of the device event.
            if response == internal.deviceplugindetection.Response.Handled
                break;
            end
        end
    end

end

methods (Access = 'private')

    function obj = Manager()
    % DevicePluginManager Constructor for the class.
    
        % Create a PnPEventBridge object from which to receive USB event
        % notifications.
        obj.USBDetectorObject = matlabshared.internal.PnPEventBridge();
        
        % Create a listener on the USB hotplug object for device plugin.
        obj.USBDetectorPluginListener = addlistener( ...
            obj.USBDetectorObject, ...
            'DeviceAdded', ...
            @(source, info) obj.usbDeviceInsertedCallback(info));

        % Create a listener on the USB hotplug object for device removal.
        obj.USBDetectorRemovalListener = addlistener( ...
            obj.USBDetectorObject, ...
            'DeviceRemoved', ...
            @(source, info) obj.usbDeviceRemovedCallback(info));
    end
    
    function updateSubClasses(obj)
    % updateSubClasses Checks and refreshes client subclasses.
    %
    %   This method is used to sweep the package/object hierarchy and
    %   update the list of found subclasses. These are the classes that are
    %   called to on device events.
    
    
        % Clear the class file references from MATLAB so that any status    
        % changes are properly reflected on the new search for subclasses.
        for ii = 1:numel(obj.SubClasses)
            % Get the subclass name to process it.
            temp = obj.SubClasses{ii};
            % Remove the package name from the class name as clear does not
            % work on fully qualified package names.
            temp = regexprep(temp,'internal.deviceplugindetection.','');
            % Clear the class file from MATLAB.
            eval(sprintf('clear %s', temp));
        end
    
        % Clear the existing properties.
        obj.SubClasses = cell(0);
        
        % Get all of the subclasses of this plugin manager class.
        subClasses = internal.findSubClasses( ...
            'internal.deviceplugindetection', ...
            'internal.deviceplugindetection.Manager', ...
            true);
        
        % Process each of the subclasses.
        for ii = 1:numel(subClasses)
            % Register this subclass to be called.
            obj.SubClasses{end+1} = subClasses{ii}.Name;
        end
        
        % Set the subclasses as registered.
        obj.SubClassesRegistered = true;
    end
    
end

methods (Static)
       
    function obj = getInstance()
    % getInstance Gets the single instance of the manager class.
    %
    %   This function is used to create, hold, and reference the singleton
    %   instance of the device plugin manager.
    
        % Lock this function to keep the manager in memory.
        mlock;
    
        % Storage for the singleton object.
        persistent devicePluginManagerInstance;
        
        % Instantiate the object if it does not already exist within
        % the persistent variable.
        if isempty(devicePluginManagerInstance)
            devicePluginManagerInstance = internal.deviceplugindetection.Manager();
        end
        
        % Return the singleton object.
        obj = devicePluginManagerInstance;
    end
    
    function unlockManager()
    % unlockManager Unlocks the manager function to allow clearing from memory.
    %
    %   This function provides a mechanism whereby the device plugin 
    %   detection manager can be unlocked and cleared from memory.
        
        % Unlock the singleton instance function for the manager.
        munlock;
        munlock('internal.deviceplugindetection.Manager.getInstance');
    end
        
end

end
