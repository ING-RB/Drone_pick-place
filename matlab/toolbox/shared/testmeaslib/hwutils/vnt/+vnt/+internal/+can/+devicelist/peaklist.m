function info = peaklist()
% peaklist Return information on available PEAK device channels.
%
%   INFO = PEAKLIST() returns information about available PEAK CAN devices as a table.
%
%   Example:
%       info = peaklist()

%   Copyright 2021-2022 The MathWorks Inc.

% Prepare the table column variables.
vendorColumn = string([]);
deviceColumn = string([]);
channelColumn = [];
deviceModelColumn = string([]);
protocolModeColumn = string([]);
serialNumberColumn = string([]);

% Create empty table using column variables.
info = table(vendorColumn, deviceColumn, channelColumn, deviceModelColumn, protocolModeColumn, serialNumberColumn, ...
    'VariableNames', {'Vendor' 'Device' 'Channel' 'DeviceModel' 'ProtocolMode' 'SerialNumber'});

% Define MATLAB converter and device plugin path for the Asyncio channel.
arch = computer('arch');
devicePath = fullfile(toolboxdir(fullfile('shared','testmeaslib','hwutils','vnt')), 'private', arch, 'peaklistplugin');
converterPath = fullfile(toolboxdir(fullfile('shared','testmeaslib','hwutils','vnt')), 'private', arch, 'devicelistpluginconverter');

% Reset any previous warnings, in case asyncio channel creation throws a warning.
lastwarn('');

% Catch asyncio Channel creation errors if the device drivers are not
% available and return empty info table if asyncio Channel creation errors out. 
try
    % Create the asyncio object for extracting channelInfo.
    asyncioChannel = matlabshared.asyncio.internal.Channel(devicePath, converterPath, Options=[], StreamLimits=[0, 0]);
catch
    % Return with empty table if the asyncio channel creation fails.
    return 
end

% Retrieve warning messages if any.
[warnMsg, ~] = lastwarn;

% Return empty table when unable to retrieve config data and create asyncio channel.
if ~isempty(warnMsg)
    return
end

% Assign details to table columns by extracting relevant data from the asyncio channel.
for ii = 1:numel(asyncioChannel.VendorDetails)
    vendorColumn(end+1,:) = asyncioChannel.VendorDetails{ii}; %#ok<AGROW>
    deviceColumn(end+1,:) = asyncioChannel.DeviceDetails{ii}; %#ok<AGROW>
    channelColumn(end+1,:) = asyncioChannel.ChannelDetails{ii}; %#ok<AGROW>
    deviceModelColumn(end+1,:) = asyncioChannel.DeviceModelDetails{ii}; %#ok<AGROW>
    protocolModeColumn(end+1,:) = asyncioChannel.ProtocolModeDetails{ii}; %#ok<AGROW>
    serialNumberColumn(end+1,:) = asyncioChannel.SerialNumberDetails{ii}; %#ok<AGROW>
end

% Create the return table with all of the device details.
info = table(vendorColumn, deviceColumn, channelColumn, deviceModelColumn, protocolModeColumn, serialNumberColumn, ...
    'VariableNames', {'Vendor' 'Device' 'Channel' 'DeviceModel' 'ProtocolMode' 'SerialNumber'});
end