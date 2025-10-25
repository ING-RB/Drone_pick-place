function list = mobiledevlist
%MOBILEDEVLIST Obtain a list of mobile devices connected to MATLAB via MATLAB Mobile
%
%   DEVLIST = MOBILEDEVLIST returns a table containing a list of all devices with accessible
%   sensor data. The devices must be running MATLAB Mobile with the same
%   MathWorks account as this MATLAB session, and have remote sensor access enabled.
%   The table also indicates the connection status of each device.
%
%   See also MOBILEDEV

% Copyright 2021 The MathWorks, Inc.

try
    list = [];
    fullpathToUtility = which('mobilesensor.internal.MobileDevManager');
    if isempty(fullpathToUtility)
        % Support package not installed - Error.
        error(getString(message('MATLAB:hwstubs:general:spkgListNotInstalled', 'MATLAB Android Sensors or MATLAB iOS Sensors', '{''ML_ANDROID_SENSORS'', ''ML_APPLE_IOS_SENSORS''}')));
    else
        list = mobilesensor.internal.MobileDevManager.getMobileDeviceListImpl();
    end
catch e
    throwAsCaller(e);
end
end
