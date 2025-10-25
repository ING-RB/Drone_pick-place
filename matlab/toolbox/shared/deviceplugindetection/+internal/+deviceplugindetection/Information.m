classdef Information < handle
% Information Data class for device plugin events.
%
%   An object of this class is passed to client subclasses of the device
%   plugin detection manager when a device has been detected as attached or
%   removed. It contains the available and relevant information for the
%   client subclasses to take action on the event.

% Copyright 2015 The MathWorks, Inc.

properties (SetAccess = 'private')
    % Event - The string type of the event indicating if the device was
    %   attached or removed.
    Event
    % Vendor - The string name/code of the vendor.
    Vendor
    % Device - The string name/code of the device.
    Device
    % DeviceType - A string indicating what form factor of device caused
    %   the event.
    DeviceType
    % ExtraInformation - Detailed information about the device. In the case
    %   of a USB device, this is the string descriptor.
    ExtraInformation
end

methods
    
    function obj = Information(event, vendor, device, deviceType, other)
    % Information Constructor for the class.
    
        % Load the class properties from the input.
        obj.Event = event;
        obj.Vendor = vendor;
        obj.Device = device;
        obj.DeviceType = deviceType;
        obj.ExtraInformation = other;
    end
    
end

end
