classdef (Abstract) ISharedApp < handle
    %ISHAREDAPP interface defines abstract methods and properties that
    %client classes inheriting from SharedApp need to implement.

    % Copyright 2020-2021 The MathWorks, Inc.

    properties (Abstract, Constant)
        % The name of the transport, e.g. "serialport", "tcpclient",
        % "udpport", etc
        TransportName (1, 1) string

        % The associated instance variable name for the transport e.g.
        % "sDevice" for serialport, "client" for tcpclient, etc
        TransportInstance (1, 1) string
    end

    methods (Abstract)
        % Create and return an instance of toolstrip form. 
        % e.g.
        % toolstripform =
        % matlabshared.transportapp.internal.toolstrip.Form;
        toolstripform = getToolstripForm(obj, hwmgrHandles)

        % Create and return an instance of appspace form.
        % e.g.
        % appspaceform =
        % matlabshared.transportapp.internal.appspace.Form;
        appspaceform = getAppSpaceForm(obj, hwmgrHandles)

        % Use the transportProperties to create a transport and establish
        % connection to the transport. The transport needs to be of type - 
        % internal.matlab.inspector.InspectorProxyMixin
        transport = getTransportProxy(obj)

        % Create and return the associated constructor comment and code for
        % the transport
        [comment, code] = getConstructorCommentAndCode(obj)
    end
end