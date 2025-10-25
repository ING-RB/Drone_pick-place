classdef (Abstract) IClient < handle
    %ICLIENT interface contains abstract properties and methods to be
    % defined in TransportClient and ChannelClient classes.

    % Copyright 2019 The MathWorks, Inc.

    properties (Abstract)
        % For BytesAvailableFcnMode = "byte", the
        % number of bytes in the input buffer that
        % triggers BytesAvailableFcn.
        % Read/Write Access - Read-only
        BytesAvailableFcnCount

        % Specifies the waiting time (in seconds) to complete
        % read and write operations.
        % Read/Write Access - Both
        % Accepted Values - Positive numeric values
        Timeout

        % Used for reading and writing binary, ASCII and token data from the
        % AsyncIO Channel
        Transport
    end

    methods
        % Establish connection to Transport
        connect(obj)

        % Disconnect the connection to the Transport
        disconnect(obj)

        % Calls execute on an AsyncIO Channel
        execute(obj)

        % Getter for properties of an AsyncIO Channel
        getCustomProperty(obj)

        % Clears the onDataReceived event listener
        setIncomingDataListener(obj)

        % Sets the onDataReceived event listener
        clearIncomingDataListener(obj)
    end
end

