function info = canChannelList(options)
% canChannelList Return information on available CAN device channels.
%
%   INFO = CANCHANNELLIST() returns information about available CAN devices as a table.
%
%   Example:
%       info = canChannelList()
% 
%   See also VNT.

% Copyright 2017-2023 The MathWorks, Inc.

arguments
    options.GetSLRTDevices (1,1) logical = false
end

% Retrieve available MathWorks device channel details.
mathworksListTable = vnt.internal.can.devicelist.mathworkslist;

% Retrieve available Vector device channel details.
vectorListTable = vnt.internal.can.devicelist.vectorlist;

% Retrieve available PEAK-System device channel details.
peakListTable = vnt.internal.can.devicelist.peaklist;

% Retrieve available Kvaser device channel details.
kvaserListTable = vnt.internal.can.devicelist.kvaserlist;

% Retrieve available NI-XNET device channel details.
niListTable = vnt.internal.can.devicelist.nilist;

% Retrieve available SocketCAN device channel details.
socketCANListTable = vnt.internal.can.devicelist.socketcanlist;

% Retrieve available SLRT device channel details.
if options.GetSLRTDevices
    slrtListTable = vnt.internal.can.devicelist.slrtlist;
    % Create the return table with all of the device details.
    info = [mathworksListTable; slrtListTable; vectorListTable; peakListTable; kvaserListTable; niListTable; socketCANListTable];
    return;
end

% Create the return table with all of the device details.
info = [mathworksListTable; vectorListTable; peakListTable; kvaserListTable; niListTable; socketCANListTable];
end