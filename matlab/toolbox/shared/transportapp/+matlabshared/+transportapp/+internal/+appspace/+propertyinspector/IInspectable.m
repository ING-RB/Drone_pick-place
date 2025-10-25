classdef (Abstract) IInspectable < handle
    %IINSPECTABLE contains abstract methods and properties that all
    %PropertyInspector Manager classes need to implement for supporting
    %Property Inspector functionalities in the shared_app infrastructure.

    % Copyright 2021 The MathWorks, Inc.

    methods (Abstract)

        connect(obj);
        disconnect(obj);

        % Launches the UI Inspector. "transportProxy" is the inspector
        % Proxy Mixin class type that the UI Inspector calls "inspect" on.
        inspectTransportProxy(obj, transportProxy);
    end
end