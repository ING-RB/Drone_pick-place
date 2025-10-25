function info = slrtlist()
% slrtlist Return information on available SLRT device channels.
%
%   INFO = SLRTLIST() returns information about available SLRT CAN devices as a table.
%
%   Example:
%       info = slrtlist()

%   Copyright 2021 The MathWorks Inc.

% Prepare the table column variables.
vendorColumn = string([]);
deviceColumn = string([]);
channelColumn = [];
deviceModelColumn = string([]);
protocolModeColumn = string([]);
serialNumberColumn = string([]);

try
    % Return empty table if the CANExplorer feature is not turned on in the SLRT feature file.
    if ~slrealtime.internal.feature('CANExplorer')
        info = table(vendorColumn, deviceColumn, channelColumn, deviceModelColumn, protocolModeColumn, serialNumberColumn, ...
            'VariableNames', {'Vendor' 'Device' 'Channel' 'DeviceModel' 'ProtocolMode' 'SerialNumber'});
        return;
    end
    % Query for SLRT targets.
    targets = slrealtime.Targets;
catch
    % Return empty table for SLRT devices, if SLRT is not available.
    info = table(vendorColumn, deviceColumn, channelColumn, deviceModelColumn, protocolModeColumn, serialNumberColumn, ...
        'VariableNames', {'Vendor' 'Device' 'Channel' 'DeviceModel' 'ProtocolMode' 'SerialNumber'});
    return;
end

% Assign SLRT channel details.
names = targets.getTargetNames();
for ii = 1:numel(names)
    vendorColumn(end+1,:) = "Simulink Real-Time"; %#ok<AGROW>
    deviceColumn(end+1,:) = string(names(ii)); %#ok<AGROW>
    channelColumn(end+1,:) = ii; %#ok<AGROW>
    deviceModelColumn(end+1,:) = ""; %#ok<AGROW>
    protocolModeColumn(end+1,:) = "CAN, CAN FD"; %#ok<AGROW>
    serialNumberColumn(end+1,:) = string(num2str(0)); %#ok<AGROW>
end

% Create the return table with all of the device details.
info = table(vendorColumn, deviceColumn, channelColumn, deviceModelColumn, protocolModeColumn, serialNumberColumn, ...
    'VariableNames', {'Vendor' 'Device' 'Channel' 'DeviceModel' 'ProtocolMode' 'SerialNumber'});
end