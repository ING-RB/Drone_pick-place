function info = mathworkslist()
% mathworkslist Return information on available MathWorks device channels.
%
%   INFO = MATHWORKSLIST() returns information about available MathWorks CAN devices as a table.
%
%   Example:
%       info = mathworkslist()

%   Copyright 2021 The MathWorks Inc.

% Prepare the table column variables.
vendorColumn = string([]);
deviceColumn = string([]);
channelColumn = [];
deviceModelColumn = string([]);
protocolModeColumn = string([]);
serialNumberColumn = string([]);

% Extract installed version information.
versionInfo = ver;
% Create cell array of installed toolboxes.
toolboxArray = {versionInfo.Name};
% Search for VNT installation.
isVNTInstalled = any(strcmp(toolboxArray, 'Vehicle Network Toolbox'));

if (~isVNTInstalled)
    % Create and return empty table if VNT toolbox is not installed.
    info = table(vendorColumn, deviceColumn, channelColumn, deviceModelColumn, protocolModeColumn, serialNumberColumn, ...
        'VariableNames', {'Vendor' 'Device' 'Channel' 'DeviceModel' 'ProtocolMode' 'SerialNumber'});
    return
end

% Assign MathWorks virtual channel details.
for ii = 1:2
    vendorColumn(end+1,:) = "MathWorks"; %#ok<AGROW>
    deviceColumn(end+1,:) = "Virtual 1"; %#ok<AGROW>
    channelColumn(end+1,:) = ii; %#ok<AGROW>
    deviceModelColumn(end+1,:) = "Virtual"; %#ok<AGROW>
    protocolModeColumn(end+1,:) = "CAN, CAN FD"; %#ok<AGROW>
    serialNumberColumn(end+1,:) = "0"; %#ok<AGROW>
end

% Create the return table with all of the device details.
info = table(vendorColumn, deviceColumn, channelColumn, deviceModelColumn, protocolModeColumn, serialNumberColumn, ...
    'VariableNames', {'Vendor' 'Device' 'Channel' 'DeviceModel' 'ProtocolMode' 'SerialNumber'});
end