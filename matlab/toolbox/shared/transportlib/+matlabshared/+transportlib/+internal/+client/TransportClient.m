classdef TransportClient < matlabshared.transportlib.internal.client.IClient
    %TRANSPORTCLIENT Client created for interfaces with existing internal tranports.
    % Example: serialport, tcpclient, udpport
    %
    % Contains the transport and does not require to create an AsyncIO
    % Channel as the tranport contains the AsyncIO Channel

    % Copyright 2019-2020 The MathWorks, Inc.

    properties
        % Used for reading and writing binary, ASCII and token data from the
        % AsyncIO Channel
        Transport
    end

    properties(Dependent)
        % Specifies the waiting time (in seconds) to complete
        % read and write operations.
        % Read/Write Access - Both
        % Accepted Values - Positive numeric values
        Timeout

        % For BytesAvailableFcnMode = "byte", the
        % number of bytes in the input buffer that
        % triggers BytesAvailableFcn.
        % Read/Write Access - Read-only
        BytesAvailableFcnCount
    end

    %% Lifetime
    methods
        function obj = TransportClient(clientProperties)

            % Throw if Transport is empty, or Transport
            % is not a ITransport, ITokenReader, and IFilterable
            if isempty(clientProperties.Transport) || ...
                    ~(isa(clientProperties.Transport, "matlabshared.transportlib.internal.ITransport") ...
                    && isa(clientProperties.Transport, "matlabshared.transportlib.internal.ITokenReader") && ...
                    isa(clientProperties.Transport, "matlabshared.transportlib.internal.IFilterable"))
                throw(MException(message("transportlib:client:InvalidTransportType")));
            end

            obj.Transport = clientProperties.Transport;
        end

        function delete(obj)
            obj.disconnect();
            obj.Transport = [];
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

        function value = get.Timeout(obj)
            value = obj.Transport.Timeout;
        end

        function set.Timeout(obj, value)
            obj.Transport.Timeout = value;
        end
    end

    %% API
    methods
        function connect(obj, varargin)
            % varargin: no additional arguments required for transport
            connect(obj.Transport);
        end

        function disconnect(obj)
            if isvalid(obj.Transport)
               disconnect(obj.Transport); 
            end
        end
    end

    %% Methods that throw an error when called.
    methods
        function execute(~, ~, ~)
            throwAsCaller(MException( ...
                message('transportlib:client:NotSupportedFunctionality', 'execute', 'TransportClient')));
        end

        function [] = getCustomProperty(~, ~)
            throwAsCaller(MException( ...
                message('transportlib:client:NotSupportedFunctionality', 'getCustomProperty', 'TransportClient')));
        end
    end

    %% Methods to be implemented in future
    methods
        function clearIncomingDataListener(~)
        end

        function setIncomingDataListener(~)
        end
    end
end
