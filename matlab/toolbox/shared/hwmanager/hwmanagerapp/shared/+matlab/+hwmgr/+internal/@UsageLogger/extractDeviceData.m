function out = extractDeviceData(device, uuid, appletName, appletConstructor, runResult, runErrMsg)
% UsageLogger class method to return a struct with the device data to be
% logged.

% Note that this static method only extracts properties of the
% device that are going to be logged, however, this may not be all that
% will be logged for that particular device. For example, the provider name
% is not a property of the device, but may be logged.

% Copyright 2019-2021 The MathWorks, Inc.


% Check the input
validateattributes(device, {'matlab.hwmgr.internal.Device'}, {'scalar', 'nonempty'});

% Create output struct with no fields - will be added dynamically
out = struct();

% Set the input data
out.enumerationId = uuid;
out.appletName = appletName;
out.appletConstructor = appletConstructor;
out.runResult = runResult;
out.runErrMsg = runErrMsg;

% These are the fields from the device properties that will be extracted
% from the device object. Note that the field names are camelCased but the
% property names are not. This is because the DDUX guidelines stipulate
% that individual key strings are to be camelCased.

fieldNames = ["friendlyName", ...
              "vendorId", ...
              "deviceId", ...
              "isNonEnumerable", ...
              "provider"];

propNames = ["FriendlyName", ...
             "VendorID", ...
             "DeviceID", ...
             "IsNonEnumerable", ...
             "ProviderClass"];


for i = 1:numel(fieldNames)
    out.(fieldNames(i)) = device.(propNames(i));
end

% If the device is non-enumerable, the usage data logged will point to
% the device descriptor responsible for providing the device, otherwise
% it points to the device provider class that enumerated the device
if device.IsNonEnumerable
    out.provider = string(device.Descriptor);
    out.isNonEnumerable = "true";
else
    out.provider = device.ProviderClass;
    out.isNonEnumerable = "false";
end
