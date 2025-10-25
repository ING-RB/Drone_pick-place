classdef SerialportProxy < matlabshared.transportapp.internal.utilities.transport.BaseTransportProxy
    %SERIALPORTPROXY contains the property inspector serial port property values,
    % and manages the getters and setters for the serial port
    % properties like BaudRate, DataBits, and StopBits.

    % Copyright 2021-2023 The MathWorks, Inc.

    properties (Dependent, SetAccess = private)
        Port
    end

    properties(Dependent, SetObservable)
        BaudRate internal.matlab.editorconverters.datatype.EditableStringEnumeration
        DataBits internal.matlab.editorconverters.datatype.StringEnumeration
        StopBits internal.matlab.editorconverters.datatype.StringEnumeration
        Parity internal.matlab.editorconverters.datatype.StringEnumeration
        FlowControl internal.matlab.editorconverters.datatype.StringEnumeration
    end

    properties (Hidden, Constant)
        BaudRateValues = ["1200","2400","4800","9600","14400","19200","38400", ...
            "57600","115200","230400","460800","500000","576000","921600","1000000"]
        DataBitsValues = ["5","6","7","8"]
        StopBitsValues = ["1","1.5","2"]
        ParityValues = ["none","even","odd"]
        FlowControlValues = ["none","hardware","software"]
    end

    %% Setters and Getters
    methods
        function val = get.Port(obj)
            val = obj.OriginalObjects.Port;
        end

        function set.BaudRate(obj, inspectorValue)
            if obj.InternalPropertySet
                return
            end

            if isa(inspectorValue, "internal.matlab.editorconverters.datatype.EditableStringEnumeration")
                val = inspectorValue.Value;
            else
                val = inspectorValue;
            end

            try
                obj.setPropertyOnOriginalObject("BaudRate", str2double(val));
            catch ex
               showErrorDialog(obj, ex);
            end
        end

        function val = get.BaudRate(obj)
            val = internal.matlab.editorconverters.datatype.EditableStringEnumeration(...
                string(obj.OriginalObjects.BaudRate), obj.BaudRateValues);
        end

        function set.DataBits(obj, inspectorValue)
            if obj.InternalPropertySet
                return
            end

            if isa(inspectorValue, "internal.matlab.editorconverters.datatype.StringEnumeration")
                val = inspectorValue.Value;
            else
                val = inspectorValue;
            end

            try
                obj.setPropertyOnOriginalObject("DataBits", str2double(val));
            catch ex
               showErrorDialog(obj, ex);
            end
        end

        function val = get.DataBits(obj)
            val = internal.matlab.editorconverters.datatype.StringEnumeration(...
                string(obj.OriginalObjects.DataBits), obj.DataBitsValues);
        end

        function set.StopBits(obj, inspectorValue)
            if obj.InternalPropertySet
                return
            end

            if isa(inspectorValue, "internal.matlab.editorconverters.datatype.StringEnumeration")
                val = inspectorValue.Value;
            else
                val = inspectorValue;
            end

            try
                obj.setPropertyOnOriginalObject("StopBits", str2double(val));
            catch ex
               showErrorDialog(obj, ex);
            end
        end

        function val = get.StopBits(obj)
            val = internal.matlab.editorconverters.datatype.StringEnumeration(...
                string(obj.OriginalObjects.StopBits), obj.StopBitsValues);
        end

        function set.Parity(obj, inspectorValue)
            if obj.InternalPropertySet
                return
            end

            if isa(inspectorValue, "internal.matlab.editorconverters.datatype.StringEnumeration")
                val = inspectorValue.Value;
            else
                val = inspectorValue;
            end

            try
                obj.setPropertyOnOriginalObject("Parity", string(val));
            catch ex
               showErrorDialog(obj, ex);
            end
        end

        function val = get.Parity(obj)
            val = internal.matlab.editorconverters.datatype.StringEnumeration(...
                obj.OriginalObjects.Parity, obj.ParityValues);
        end

        function set.FlowControl(obj, inspectorValue)
            if obj.InternalPropertySet
                return
            end

            if isa(inspectorValue, "internal.matlab.editorconverters.datatype.StringEnumeration")
                val = inspectorValue.Value;
            else
                val = inspectorValue;
            end

            try
                obj.setPropertyOnOriginalObject("FlowControl", string(val));
            catch ex
               showErrorDialog(obj, ex);
            end
        end

        function val = get.FlowControl(obj)
            val = internal.matlab.editorconverters.datatype.StringEnumeration(...
                obj.OriginalObjects.FlowControl, obj.FlowControlValues);
        end
    end

    %% Abstract Method Implementation
    methods
        function setProxyPropertyGroups(obj)
            % Set the properties into the property groups to be displayed in
            % the property inspector section.

            g1 = obj.createGroup(message("transportapp:serialportapp:PropertyInspectorConnectionGroup").string, "", "");
            g1.addProperties("Port", "BaudRate", "DataBits", "StopBits", "Parity", "FlowControl");
            g1.Expanded = true;

            setProxyPropertyGroups@matlabshared.transportapp.internal.utilities.transport.BaseTransportProxy(obj);
        end
    end
end
