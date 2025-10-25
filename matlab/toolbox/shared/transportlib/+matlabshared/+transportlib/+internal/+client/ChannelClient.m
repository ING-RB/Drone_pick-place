classdef ChannelClient < matlabshared.transportlib.internal.client.IClient
    %CHANNELCLIENT is the client for all implementations that do not
    % have an existing internal transport. This class creates the AsyncIO
    % Channel, creates the GenericTransport and passes in the AsyncIO
    % channel to the transport. It also creates the EventHandler class, to
    % handle asynchronous channel events, like data received or data
    % written from/to the AsyncIO Channel.

    % Copyright 2019-2023 The MathWorks, Inc.

    properties
        % The GenericTransport instance
        Transport

        % The AsyncIO Channel instance
        Channel

        % The EventHandler instance that handles asynchronous events in the
        % AsyncIO channel.
        EventHandler

        % The Timeout property for reads and writes.
        Timeout
    end

    properties(Dependent)
        % Dependent property to get and set the BytesAvailableEventCount
        % property on the Transport.
        BytesAvailableFcnCount
    end

    properties (Constant)
        % Default read/write timeout to 10 sec
        DefaultTimeout = 10
    end

    properties (GetAccess = private, SetAccess = protected)
        % Internal listener of the AsyncIOChannel used to trigger data
        % sent callback functions.
        SendCallbackListener

        % Internal listener of the AsyncIOChannel used to trigger error and
        % warning callback functions.
        CustomListener
    end

    %% Lifetime
    methods
        function obj = ChannelClient(clientProperties)

            if ~isempty(clientProperties.EventHandler)
                if ~isa(clientProperties.EventHandler, "matlabshared.transportlib.internal.client.IEventHandler")
                    throw(MException(message("transportlib:client:InvalidEventHandler")));
                end
                obj.EventHandler = clientProperties.EventHandler;
            else
                obj.EventHandler = matlabshared.transportlib.internal.client.EventHandler;
            end

            % Create the AsyncIO Channel, pass in the options.
            createChannel(obj, clientProperties);

            % Check if AsyncIO Channel timeout was provided and set channel
            % timeout. Else set the channel timeout to default value.
            if isfield(clientProperties.AsyncIOOptions, "Timeout")
                obj.Timeout = clientProperties.AsyncIOOptions.Timeout;
            else
                obj.Timeout = matlabshared.transportlib.internal.client.ChannelClient.DefaultTimeout;
            end

            obj.Transport = matlabshared.transportlib.internal.GenericTransport(obj.Channel, ...
                clientProperties.InterfaceName);

            % Pass the transport in to the EventHandler class.
            setTransport(obj.EventHandler, obj.Transport);

            % Create the event listeners for the Asyncio input stream and
            % output stream.
            createListeners(obj);
        end

        function delete(obj)

            % Clear the AsyncIO Listeners
            obj.clearListeners();

            disconnect(obj);
            obj.EventHandler = [];
            obj.Transport = [];
            obj.Channel = [];

        end
    end

    %% Getters and Setters
    methods
        function set.BytesAvailableFcnCount(obj, value)
            obj.Transport.BytesAvailableEventCount = value;
        end

        function value = get.BytesAvailableFcnCount(obj)
            value = obj.Transport.BytesAvailableEventCount;
        end

        function obj = set.Timeout(obj, value) %#ok<MCHV2>
            try
                validateattributes(value, {'double'}, {'scalar', 'nonnegative', 'finite', ...
                    'nonzero', 'nonempty'}, mfilename, 'Timeout');
            catch validationException
                throwAsCaller(validationException);
            end
            setChannelTimeout(obj, value);
            obj.Timeout = value;
        end
    end

    %% API
    methods
        function connect(obj, varargin)
            % Open the AsyncIO channel and connect to the GenericTransport
            narginchk(1, 2)
            
            if ~isempty(obj.Channel) && obj.Channel.isOpen()
                throwAsCaller(MException(message('transportlib:client:AlreadyConnectedError')));
            end
            
            try
                % g2259119
                if nargin == 2
                    openOptions = varargin{1};
                    validateattributes(openOptions, {'struct'}, {'scalar'}, mfilename, 'openOptions', 2);
                    open(obj.Channel, openOptions);
                else
                    open(obj.Channel);    
                end
                    
                connect(obj.Transport);
            catch ex
                throwAsCaller(ex)
            end
        end

        function disconnect(obj)
            % Close the AsyncIO channel and discconnect from the
            % GenericTransport

            try
                if ~isempty(obj.Channel)
                    close(obj.Channel);
                end
                disconnect(obj.Transport);
            catch ex
                throwAsCaller(ex)
            end
        end

        function value = getCustomProperty(obj, name)
            % Access custom properties on the AsyncIO Channel.

            value = obj.Channel.(name);
        end

        function execute(obj, command, options)
            % Call the execute method in AsyncIO.

            try
                obj.Channel.execute(command, options);
            catch ex
                throwAsCaller(ex);
            end
        end

        function clearIncomingDataListener(obj)
            % Clear the listener for the data received event.
            disconnectDataReceivedListener(obj.Transport);
        end

        function setIncomingDataListener(obj)
            % Set the listener for the data received event, if not already
            % enabled.

            if ~isDataReceivedListenerEnabled(obj.Transport)
                connectDataReceivedListener(obj.Transport, obj.Channel);
            end
        end
    end

    methods (Access = private)
        %% Helper functions

        function createChannel(obj, clientProperties)
            % Create the AsyncIO Channel.

            % Validate DevicePlugin and ConverterPlugin
            if ~validatePluginType(obj, clientProperties.DevicePlugin) ...
                    || ~validatePluginType(obj, clientProperties.ConverterPlugin)
                throw(MException(message ...
                    ('transportlib:client:EmptyPlugins')));
            end

            try
                % Create the AsyncIO Channel
                obj.Channel = matlabshared.asyncio.internal.Channel(clientProperties.DevicePlugin, ...
                    clientProperties.ConverterPlugin, ...
                    Options = clientProperties.AsyncIOOptions, ...
                    StreamLimits = [clientProperties.InputBufferSize, clientProperties.OutputBufferSize]);
            catch channelError
                mExc = MException(message("transportlib:client:InvalidPlugin", channelError.message));
                throwAsCaller(mExc);
            end
        end

        function setChannelTimeout(obj, value)
            % Sets the Timeout property on the Input and Output stream of
            % AsyncIO Channel.

            if ~isempty(obj.Channel)
                % Set the timeout for the input and output streams.
                obj.Channel.OutputStream.Timeout = value;
                obj.Channel.InputStream.Timeout = value;
            end
        end

        function createListeners(obj)
            % Add listeners to the AsyncIO Channel's asynchronous events,
            % like data written/data read/custom events.

            % Add an AsyncIO listener that calls the onDataWritten
            % function on EventHandler when data is written to the AsyncIO
            % channel (DataRead event).
            obj.SendCallbackListener = event.listener(...
                obj.Channel.OutputStream, ...
                'DataRead', ...
                @(src, evt)obj.EventHandler.onDataWritten(src, evt));

            % Add an AsyncIO listener that calls the handleCustomEvent
            % function on EventHandler when an asynchronous error event
            % occurs (Custom event).
            obj.CustomListener = event.listener(obj.Channel, ...
                'Custom', ...
                @(src, evt)obj.EventHandler.handleCustomEvent(src, evt));
        end

        function clearListeners(obj)
            % Clear the event listeners before closing out the AsyncIO
            % Channel.

            delete(obj.SendCallbackListener);
            delete(obj.CustomListener);

            obj.SendCallbackListener = [];
            obj.CustomListener = [];
        end

        function isValidPlugin = validatePluginType(~, plugin)
            % Validate that the plugins are strings and that they are not
            % empty

            isValidPlugin = isstring(plugin) && plugin ~= "";
        end
    end
end
