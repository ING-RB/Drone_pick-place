classdef EventHandler < matlabshared.transportlib.internal.client.IEventHandler

    %EVENTHANDLER contains the helper functions that are invoked during an
    % AsyncIO asynchronous event, like data being written to the AsyncIO
    % Channel and handling other custom events, like custom Error calls,
    % from the AsyncIO channel.

    % Copyright 2019-2023 The MathWorks, Inc.

    properties(Dependent, SetAccess = private)
        % User specified callback function that gets invoked when data was
        % written to the AsyncIO Channel.
        BytesWrittenFcn
    end

    properties
        % The GenericTransport instance.
        Transport
    end

    properties(Dependent, Hidden)
        % Handle to the AsyncIO Channel.
        Channel
    end

    %% Getters and Setters
    methods
        function data = get.BytesWrittenFcn(obj)
            data = obj.Transport.BytesWrittenFcn;
        end

        function val = get.Channel(obj)
           val = getChannel(obj.Transport);
        end
    end

    %% Lifetime
    methods
        function delete(obj)
            obj.Transport = [];
        end
    end

    %% API
    methods
        function setTransport(obj, transport)
            % Set the Transport to the instance of GenericTransport.

            if ~isa(transport, "matlabshared.transportlib.internal.ITransport") ...
                    && ~isa(transport, "matlabshared.transportlib.internal.ITokenReader") ...
                    && ~isa(transport, "matlabshared.transportlib.internal.IFilterable")
                throw(MException(message("transportlib:client:InvalidTransportType")));
            end
            obj.Transport = transport;
        end
    end

    %% API related Callback Functions
    methods
        function onDataWritten(obj, ~, ~)
            % Callback function that gets triggered when data was written
            % to the AsyncIO Channel.
            if isempty(obj.BytesWrittenFcn)
                return
            end

            % Notify any listeners with the amount of space available. If
            % no space is available to write, don't send the event.
            space = obj.Channel.OutputStream.SpaceAvailable;
            if space > 0
                obj.BytesWrittenFcn(obj,...
                    matlabshared.transportlib.internal.DataWrittenInfo(space));
            end
        end

        function handleCustomEvent(obj, ~, eventData)
            % Callback function for asynchronous errors from the AsyncIO
            % plug-in, such as a lost connection. By default,
            % handleCustomEvent only handles ErrorEvents.

            errorId = eventData.Data.ErrorID;
            errorFcn = obj.Transport.ErrorOccurredFcn;

            % If a callback function is assigned, call it otherwise
            % error.
            if ~isempty(errorFcn)
                errorFcn(obj.Transport, ...
                    matlabshared.transportlib.internal.ErrorInfo(eventData.Data.ErrorID,...
                    eventData.Data.ErrorMessage));
            else
                error(errorId,message(errorId).getString());
            end
        end
    end
end
