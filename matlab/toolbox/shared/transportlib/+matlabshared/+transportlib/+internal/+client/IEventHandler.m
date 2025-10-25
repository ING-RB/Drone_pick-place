classdef (Abstract) IEventHandler < handle
    %IEVENTHANDLER Abstract class contains the abstract methods that every
    % IEventHandler type needs to implement.

    % Copyright 2019 The MathWorks, Inc.

    properties (Abstract)
        % The IFilterable, ITransport, and ITokenReader instance. This will
        % be the GenericTransport Instance
        Transport
    end

    methods
        % Callback function that gets fired when data is available to be
        % read on the AsyncIO Channel's input buffer.
        onDataReceived(obj, ~, ~)

        % Callback function that gets fired when data is written to the
        % AsyncIO Channel
        onDataWritten(obj, ~, ~)

        % Callback function that gets fired when a custom event occurs,
        % like a customError event. This can be set using AsyncIO channel's
        % sendCustomEvent function
        handleCustomEvent(obj, ~, eventData)

        % Set the Transport after creation of the EventHandler Class. This
        % should set the Transport property to the "transport" passed as an
        % input argument
        setTransport(obj, transport)
    end
end

