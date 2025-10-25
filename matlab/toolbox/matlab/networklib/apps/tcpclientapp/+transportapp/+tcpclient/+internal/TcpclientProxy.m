classdef TcpclientProxy < matlabshared.transportapp.internal.utilities.transport.BaseTransportProxy
    %TCPCLIENTPROXY contains the property inspector tcpclient property values,
    % and manages the getters for the tcpclient properties like
    % Address, Port, and Connect Timeout.

    % Copyright 2021-2022 The MathWorks, Inc.

    properties (Dependent, SetAccess = private)
        Address
        Port
        ConnectTimeout
        EnableTransferDelay internal.matlab.editorconverters.datatype.StringEnumeration
    end

    properties (Hidden, Constant)
        TransferDelayValues = ["true", "false"]
    end

    %% Getters
    methods
        function val = get.Address(obj)
            val = string(obj.OriginalObjects.Address);
        end

        function val = get.Port(obj)
            val = obj.OriginalObjects.Port;
        end

        function val = get.ConnectTimeout(obj)
            val = obj.OriginalObjects.ConnectTimeout;
        end

        function val = get.EnableTransferDelay(obj)
            val = internal.matlab.editorconverters.datatype.StringEnumeration(...
                string(obj.OriginalObjects.EnableTransferDelay), obj.TransferDelayValues);
        end
    end

    %% Abstract Method Implementation
    methods
        function setProxyPropertyGroups(obj)
            % Set the properties into the property groups to be displayed in
            % the property inspector section.

            g1 = obj.createGroup(message("transportapp:tcpclientapp:PropertyInspectorConnectionGroup").string, "", "");
            g1.addProperties("Address", "Port", "ConnectTimeout", "EnableTransferDelay");
            g1.Expanded = true;

            setProxyPropertyGroups@matlabshared.transportapp.internal.utilities.transport.BaseTransportProxy(obj);
        end
    end
end
