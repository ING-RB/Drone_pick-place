classdef (Abstract) RemoteProvider < handle
    % Abstract Provider class to allow client-server communication

    % Copyright 2019-2024 The MathWorks, Inc.

    properties (Abstract)
        Channel;
    end

    methods (Abstract)
        % This method is called by the manager, document and view to set up listeners on
        % them for client events.
        setUpProviderListeners(this, obj)

        % handles the events received from the client on the manager, document and view
        handleEventFromClient(this, obj)

        % handles the events received from the client on the manager, document and view
        dispatchEventToClient(this, obj)

        % handles property set events received from the client
        handlePropertySetFromClient(this, obj)

        % sets properties on the manager, document and view and communicates it to the client
        setPropertyOnClient(this, obj)

        % adds a new child document to the manager
        addDocument(this, obj)

        % adds a new child view to the document
        addView(this, obj)

        delete(this, obj)
    end
end
