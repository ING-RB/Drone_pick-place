function echotcpip(varargin)
%ECHOTCPIP start or stop a TCP/IP echo server.
%
%     echotcpip('STATE',PORT) starts a TCP/IP server with port number,
%     PORT. STATE can only be 'on'.
%
%     echotcpip('STATE') stops the echo server. STATE can only be 'off'.
%
%     Example:
%         echotcpip("on", 4000);
%         t = tcpclient("localhost",4000);
%         write(t, uint8(1:5));
%         data = read(t, 5, "uint8")
%         echotcpip("off");
%
%     See also echoudp tcpclient

% Copyright 2019 The MathWorks, Inc.

if nargin == 0
    throwAsCaller(MException('instrument:echotcpip:invalidSyntaxState',...
        message('network:echotcpip:invalidSyntaxState').getString));
elseif nargin > 2
    throwAsCaller(MException('instrument:echotcpip:invalidSyntaxArgv',...
        message('network:echotcpip:invalidSyntaxArgv').getString));
end

% Convert the string input argument to char
varargin = instrument.internal.stringConversionHelpers.str2char(varargin);
state = varargin{1};
try
    state = validatestring(state,{'off', 'on'});
catch
    throwAsCaller(MException('instrument:echotcpip:invalidSyntaxStateBool',...
        message('network:echotcpip:invalidSyntaxStateBool').getString));
end

switch nargin

    % The state can only be "off". Error otherwise.
    case 1
        if strcmpi(state, 'on')
            throwAsCaller(MException('instrument:echotcpip:invalidSyntaxPort',...
                message('network:echotcpip:invalidSyntaxPort').getString));
        end

        % State is "off"
        try
            % Destroy the TCP/IP Echo Server
            matlabshared.network.internal.EchoServer. ...
                manageTransportLifetime("TCP","destroy");
        catch ex
            throwAsCaller(ex);
        end
    case 2

        % If nargin is 2, state can only be "on". Error otherwise
        if strcmpi(state, 'off')
            throw(MException('instrument:echotcpip:invalidSyntaxOff',...
                message('network:echotcpip:invalidSyntaxOff').getString));
        end
        portNumber = varargin{2};
        try
            % Create the TCP/IP Echo Server
            matlabshared.network.internal.EchoServer. ...
                manageTransportLifetime("TCP","create", portNumber);
        catch ex
            throwAsCaller(ex);
        end
end