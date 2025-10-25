function addAppletDataToDevice(obj, appletData)
% This method will take the given applet data and add it to the device that
% matches the existing list of devices

%Copyright 2019 Mathworks Inc.

% Loop throught the device data. If the friendly name and the providers
% match just replace the existing device data with the device data from the
% applet runner, keeping the enumeration ID from the existing device data.
for i = 1:numel(obj.DeviceData)
    currDeviceData =  obj.DeviceData(i);
    if (currDeviceData.friendlyName == appletData.friendlyName) && ...
            (currDeviceData.provider == appletData.provider)
        appletData.enumerationId = obj.DeviceData(i).enumerationId;
        obj.DeviceData(i) = appletData;
        break;
    end
end
end