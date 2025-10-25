classdef ChannelProperties < matlabshared.transportlib.internal.client.ClientProperties
    %CHANNELPROPERTIES - Options used by GenericClient to create a ChannelClient.

    % Copyright 2019 The MathWorks, Inc.

    properties
        % Stores the full name of the AsyncIO device plugin.
        DevicePlugin (1, 1) string

        % Stores the full name of the AsyncIO converter plugin.
        ConverterPlugin (1, 1) string

        % Contains callback functions which are fired when data is written
        % to an AsyncIO Channel or when data is recieved from an AsyncIO Channel.
        % Also supports callback functions for custom events in AsyncIO
        % Channel. The EventHandler class can be empty or needs to be of type
        % matlabshared.transportlib.internal.client.IEventHandler
        EventHandler

        % Options needed to create an AsyncIO channel
        AsyncIOOptions (1, 1) struct

        % Specifies the total number of bytes read from the transport that
        % can be stored in the AsyncIO input buffer.
        % Default is Inf
        InputBufferSize = inf

        % Specifies the total number of bytes that can be stored
        % in the AsyncIO output buffer for writing to the
        % transport.
        % Default is Inf
        OutputBufferSize = inf
    end
end

