classdef EventData < event.EventData
%EventData    Data associated with hot-plug events.
%
%   Events published by an internal.hotplug.EventSource will be of this type.
%
%   EventData properties:
%
%   DeviceType - The device type (e.g. 'USB').
%   Vendor     - The vendor identifier (e.g. '2359').
%   Product    - The product identifier.
%   ExtraInfo  - Additional OS-specific information.
%   
%   See also internal.hotplug.EventSource

% Copyright 2010 The MathWorks, Inc.
% $Revision: 1.1.6.2 $  $Date: 2010/07/06 17:13:04 $
    
    properties(SetAccess = private, GetAccess = public)
        % DeviceType - A string that describes the device type (e.g. 'USB').
        DeviceType
        
        % Vendor - A string that identifies the vendor (e.g. '2359').
        Vendor
        
        % Product - A string that identifies the product or device.
        Product
        
        % ExtraInfo - A string that contains the entire OS-specific
        % information associated with the hot-plug event.
        ExtraInfo
    end
    
    methods
        %% Lifetime
        function obj = EventData(deviceType, vendor, product, extraInfo)
            obj.DeviceType = deviceType;
            obj.Vendor = vendor;
            obj.Product = product;
            obj.ExtraInfo = extraInfo;
        end
    end
end

