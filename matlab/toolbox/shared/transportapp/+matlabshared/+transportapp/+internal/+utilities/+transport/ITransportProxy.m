classdef (Abstract) ITransportProxy < handle
    %ITRANSPORTPROXY contains abstract properties and methods that all
    %TransportProxy classes need to implement.

    % Copyright 2020-2021 The MathWorks, Inc.

    properties (SetObservable, AbortSet, Abstract)
        % To be published via the mediator publisher to the Read Section
        % for Values Available.
        ObservableValuesAvailable
    end

    methods (Abstract)
        % Set the property into the property groups to be displayed in
        % the property inspector section.
        setProxyPropertyGroups(obj)
        
        % Perform actions before the Transport Proxy class is deleted.
        disconnect(obj)

        % Perform actions to set up the Transport Proxy class.
        connect(obj)
    end
end