classdef ChannelClient < matlabshared.transportlib.internal.client.GenericClient
%CHANNELCLIENT - Internal Bluetooth channel client using shared transport

% Copyright 2020-2021 The MathWorks, Inc.
    
    % Bluetooth specific properties
    properties(Access = public)
        Name
        Address
        Channel
    end
    
    properties(Constant, Access = private)
        % Execute commands supported by AsyncIO plugin
        SET_TIMEOUT	   = "SetTimeout"

        % Name of the interface that will be provided to throw connect errors
        Interface = "bluetooth"
    end
    
    properties(Access = private)
        % Internal flag indicating whether device connection succeeds or
        % not in plugin
        ConnectSucceed = false
        
        %HasSaveWarningBeenIssued True if the saveobj method has been called.
        HasSaveWarningBeenIssued = false
    end
    
    %% Lifetime
    methods
        function obj = ChannelClient(callbackSource, varargin)
            % No identifier is provided, retrieve last connection information
            if nargin == 1
                info = matlab.bluetooth.internal.LastConnectionInfo.get;
                if isempty(info)
                    matlab.bluetooth.ChannelClient.throwError("MATLAB:bluetooth:bluetooth:noLastConnection");
                end
            else
            % Validate user provided identifier and channel
                identifier = varargin{1};
                info = matlab.bluetooth.ChannelClient.verifyIdentifier(identifier);
                
                % Validate channel number
                if nargin == 2
                    info.Channel = 1; % Default channel number
                else
                    info.Channel = varargin{2};
                    matlab.bluetooth.ChannelClient.verifyChannel(info.Channel);
                end
            end
            
            % Prepare and create shared client
            props = matlabshared.transportlib.internal.client.PropertiesFactory.getInstance("channel");
            output = matlab.bluetooth.internal.Factory.getChannelInfo;
            props.DevicePlugin        = output.DevicePlugin;
            props.ConverterPlugin     = output.ConverterPlugin;
            options = struct("Address", matlab.bluetooth.ChannelClient.addSeparator(info.Address), "Channel", uint8(info.Channel));
            props.AsyncIOOptions      = options;
            props.PrecisionRequired   = false;
            props.InterfaceName       = "bluetooth";
            props.InterfaceObjectName = "b";
            props.CallbackSource      = callbackSource;
            obj@matlabshared.transportlib.internal.client.GenericClient(props);
            
            % Verify common name-value pairs after generic client creation
            % to reuse validation logic
            if nargin > 3
                verifyNVPairs(obj, varargin{3:end});
            end
            
            % Finally connect after all input parameters are validated
            connect(obj);
            obj.ConnectSucceed = true;
            
            % Set write timeout in plugin to user settable Timeout property
            % value
            setPluginTimeout(obj, getProperty(obj, "Timeout"));
            
            % Store bluetooth specific information
            obj.Name    = info.Name;
            obj.Address = info.Address;
            obj.Channel = info.Channel;
            
            % Register connection
            connections = matlab.bluetooth.internal.ConnectionMap.getInstance;
            add(connections, obj.Address, obj.Channel);
        end
        
        function delete(obj)
            % Rollback actions only when device was successfully connected
            if ~obj.ConnectSucceed
                return
            end
            
            try
                disconnect(obj);
            catch e
                if string(e.identifier).startsWith("MATLAB:bluetooth:bluetooth:failedDisconnect")
                    throwAsCaller(e);
                end
            end
            % Wait briefly to allow system library to fully unwind
            % before the dll is unloaded to avoid crash
            pause(1);
            
            % Unregister connection
            connections = matlab.bluetooth.internal.ConnectionMap.getInstance;
            remove(connections, obj.Address);

            % Update last connection registry
            matlab.bluetooth.internal.LastConnectionInfo.set(obj.Name, obj.Address, obj.Channel);
        end
    end
    
    %% Disable save
    methods (Sealed, Hidden)
        function saveInfo = saveobj(obj)
            saveInfo = [];
            if obj.HasSaveWarningBeenIssued
                return
            end
            obj.HasSaveWarningBeenIssued = true;
            
            sWarningBacktrace = warning('off','backtrace');
            warning(message('MATLAB:bluetooth:bluetooth:nosave'));
            warning(sWarningBacktrace.state, 'backtrace');
        end
    end
    
    %% Public interface
    methods(Access = public)
        function setTimeout(obj, value)
            timeout = getProperty(obj, "Timeout");
            try
                % Set property Timeout
                setProperty(obj, "Timeout", value);
                % Impose Bluetooth specific restriction
                minTimeout = 1; % second
                if getProperty(obj, "Timeout") < minTimeout
                    matlab.bluetooth.ChannelClient.throwError("MATLAB:bluetooth:bluetooth:invalidTimeout", string(minTimeout));
                end
            catch e
                % Revert back to original value
                setProperty(obj, "Timeout", timeout);
                throwAsCaller(e);
            end
        end
        
        function setPluginTimeout(obj, value)
            % Set device plugin's timeout value to match with user settable
            % timeout
            options.Timeout = uint16(value);
            execute(obj, obj.SET_TIMEOUT, options);
        end
    end
    
    %% Validation methods
    methods(Static, Access = private)
        function info = verifyIdentifier(identifier)
            % Validate identifier, which is either name or address
            info = [];
            try
                validateattributes(identifier, {'string','char'}, {'scalartext'});
                identifier = string(identifier);
            catch
                matlab.bluetooth.ChannelClient.throwError("MATLAB:bluetooth:bluetooth:invalidIdentifierType");
            end
            
            % Convert xx:xx:xx:xx:xx:xx or xx-xx-xx-xx-xx-xx to xxxxxxxxxxxx
            if regexp(identifier, "([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}", "match") == identifier
                identifier = replace(identifier, ["-", ":"], "");
                identifier = upper(identifier);
            end
            
            % Check if a paired device with specified identifier exists
            try
                transport = matlab.bluetooth.internal.Factory.getListTransport;
                devices = getPairedDevices(transport);
            catch e
                switch string(e.identifier)
                    case {"MATLAB:bluetooth:bluetoothlist:noBluetoothAdapter", ...
                          "MATLAB:bluetooth:bluetoothlist:noBluetoothRadio", ...
                          "MATLAB:bluetooth:bluetoothlist:winBluetoothNotPoweredOn", ...
                          "MATLAB:bluetooth:bluetoothlist:macBluetoothPoweredOff"}
                        throwAsCaller(e);
                    otherwise
                        mExcept = matlabshared.transportlib.internal.client.GenericClient.throwConnectionError(matlab.bluetooth.ChannelClient.Interface,"MATLAB:bluetooth:bluetooth:failedGetPairedDevices");
                        throwAsCaller(mExcept);
                end
            end
            for device = devices
                % Compare case-insensitive
                if strcmpi(device.Name, identifier) || strcmpi(device.Address, identifier)
                    info.Name    = string(device.Name);
                    info.Address = string(device.Address);
                    break;
                end
            end
            if isempty(info)
                mExcept = matlabshared.transportlib.internal.client.GenericClient.throwConnectionError(matlab.bluetooth.ChannelClient.Interface,"MATLAB:bluetooth:bluetooth:invalidIdentifierValue", identifier);
                throwAsCaller(mExcept);
            end
            
            % Check if connection already exists in current MATLAB
            connections = matlab.bluetooth.internal.ConnectionMap.getInstance;
            channel = get(connections, info.Address);
            if ~isempty(channel)
                mExcept = matlabshared.transportlib.internal.client.GenericClient.throwConnectionError(matlab.bluetooth.ChannelClient.Interface,"MATLAB:bluetooth:bluetooth:connectionExists");
                throwAsCaller(mExcept);
            end
        end
        
        function verifyChannel(channel)
            % Validate server channel number
            try
                validateattributes(channel, {'numeric'}, {'scalar','integer','nonnegative','<=',255});
            catch
                matlab.bluetooth.ChannelClient.throwError("MATLAB:bluetooth:bluetooth:invalidChannel");
            end
        end
    end
    
    methods(Access = private)
        function verifyNVPairs(obj, varargin)
            p = inputParser;
            p.CaseSensitive = false;
            addParameter(p, "ByteOrder", "little-endian");
            addParameter(p, "Timeout", 10);
            try
                parse(p, varargin{:});
                setProperty(obj, "ByteOrder", p.Results.ByteOrder);
                setTimeout(obj, p.Results.Timeout);
            catch e
                throwAsCaller(e);
            end
        end
    end
    
    %% Helper method
    methods(Static, Access = private)
        function output = addSeparator(input)
            % Convert "98D331FB3B77" to "98:D3:31:FB:3B:77"
            for ii = strlength(input)-2:-2:2
                input = insertAfter(input, ii, ":");
            end
            output = input;
        end
        
        function throwError(id, varargin)
            throwAsCaller(MException(id, getString(message(id, varargin{:}))));
        end
    end
end

