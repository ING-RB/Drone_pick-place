function info = canFDChannelList()
% canFDChannelList Return information on available CAN FD device channels.
%
%   INFO = CANFDCHANNELLIST() returns information about available CAN FD devices as a table.
%
%   Example:
%       info = canFDChannelList()
% 
%   See also VNT.

% Copyright 2018 The MathWorks, Inc.

% Verify input arguments.
narginchk(0, 0);

% Call canChannelList.
info = canChannelList;

% Reduce the output table to contain only the entries that support CAN FD.
info = info(info.ProtocolMode.contains("FD"),:);
end
