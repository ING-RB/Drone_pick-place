classdef BaseTransportProxy < internal.matlab.inspector.InspectorProxyMixin & ...
        matlabshared.transportapp.internal.utilities.transport.ITransportProxy & ...
        matlabshared.mediator.internal.Publisher & ...
        matlabshared.testmeasapps.internal.dialoghandler.DialogSource
    %BASETRANSPORTPROXY contains access to the Transport via the
    %InspectorProxyMixin. It is an inspectable class (i.e. can be inspected
    %by the property inspector) that exposes the public visible properties
    %of the transport. It creates and maintains the
    % 1. TransportAccessor instance for getting and setting common transport
    %properties
    % 2. CodeGenerator instance for generating MATLAB code for property
    % setters.

    % Copyright 2020-2023 The MathWorks, Inc.

    properties (Hidden)
        % The handle to the TransportAccessor instance. Used for getting and
        % setting properties on the transport.
        TransportAccessor

        % The handle to the CodeGenerator instance. Used for generating
        % MATLAB code for property setters.
        CodeGenerator

        % Listener for the TransportAccessor's NumDataAvailable property.
        DataAvailableListener
    end

    %% Abstract Properties
    properties (SetObservable, AbortSet, Hidden)
        % Published via the Publisher (to be used by the read section's
        % Values Available section)
        ObservableValuesAvailable
    end

    %% Other Hidden Properties
    properties (Hidden, Constant)

        %% Default values for property getters.
        DefaultNumericValue = 0
        DefaultByteOrder = "little-endian"
        DefaultTerminator = matlabshared.transportapp.internal.utilities.transport.TerminatorClass("LF", "LF")
    end

    properties (SetObservable, Hidden)
        % Flag that indicates that the server is disconnected. When this
        % flag is set to true, this will initiate the app close procedure
        % from SharedApp.m.
        ServerDisconnected (1, 1) logical = false
    end

    %% Class Properties To Be Displayed in Property Inspector
    properties (GetObservable, Dependent, SetAccess = private)
        NumBytesAvailable
    end

    properties (Dependent, SetObservable)
        Timeout
        ByteOrder internal.matlab.editorconverters.datatype.StringEnumeration
    end

    properties (Dependent, SetObservable)
        Terminator
    end

    %% Lifetime
    methods
        function obj = BaseTransportProxy(transport, mediator)
            arguments
                transport
                mediator matlabshared.mediator.internal.Mediator
            end
            obj@internal.matlab.inspector.InspectorProxyMixin(transport);
            obj@matlabshared.mediator.internal.Publisher(mediator);
            obj@matlabshared.testmeasapps.internal.dialoghandler.DialogSource(mediator);

            obj.TransportAccessor = matlabshared.transportapp.internal.utilities.transport.TransportAccessor(transport);
            obj.CodeGenerator = matlabshared.transportapp.internal.utilities.transport.CodeGenerator(mediator);
            obj.setProxyPropertyGroups();
        end

        function connect(obj)
            obj.TransportAccessor.connect();
            obj.DataAvailableListener = listener(obj.TransportAccessor, "ObservableDataAvailable", "PostSet", ...
                @(src, evt)obj.handlePropertyEvents(src, evt));

            % Attempt a get on the NumDataAvailable property. This will
            % fire the listener and will update ValuesAvailable on the read
            % section controller.
            obj.NumBytesAvailable;
        end

        function disconnect(obj)
            % Perform actions before the BaseTransportProxy class is
            % deleted.

            if isvalid(obj.DataAvailableListener)
                delete(obj.DataAvailableListener);
            end

            obj.TransportAccessor.disconnect();
        end

        function delete(obj)
            obj.CodeGenerator = [];
            obj.TransportAccessor = [];
        end
    end

    %% Getters and Setters
    methods
        %% Getters
        function val = get.Timeout(obj)
            val = matlabshared.transportapp.internal.utilities.transport.BaseTransportProxy.DefaultNumericValue;

            try
                if isvalid(obj) && ~obj.ServerDisconnected
                    val = obj.TransportAccessor.Timeout;
                end

            catch
                obj.handleServerDisconnected();
            end
        end

        function val = get.NumBytesAvailable(obj)
            val = matlabshared.transportapp.internal.utilities.transport.BaseTransportProxy.DefaultNumericValue;

            try
                if isvalid(obj) && ~obj.ServerDisconnected
                    val = obj.TransportAccessor.NumDataAvailable;
                end

            catch
                obj.handleServerDisconnected();
            end
        end

        function val = get.ByteOrder(obj)
            val = matlabshared.transportapp.internal.utilities.transport.BaseTransportProxy.DefaultByteOrder;
            try
                if isvalid(obj) && ~obj.ServerDisconnected
                    val = obj.TransportAccessor.ByteOrder;
                end

            catch
                obj.handleServerDisconnected();
            end
        end

        function val = get.Terminator(obj)
            val = ...
                matlabshared.transportapp.internal.utilities.transport.BaseTransportProxy.DefaultTerminator;
            try
                if isvalid(obj) && ~obj.ServerDisconnected
                    val = obj.TransportAccessor.Terminator;
                end
            catch
                obj.handleServerDisconnected();
            end
        end

        %% Setters
        function set.Terminator(obj, val)
            if obj.InternalPropertySet
                return
            end

            try
                setPropertyOnOriginalObject(obj, "Terminator", val);
            catch ex
                showErrorDialog(obj, ex);
            end
        end

        function set.Timeout(obj, val)
            if obj.InternalPropertySet
                return
            end
            try
                setPropertyOnOriginalObject(obj, "Timeout", val);
            catch ex
                showErrorDialog(obj, ex);
            end
        end

        function set.ByteOrder(obj, val)
            if obj.InternalPropertySet
                return
            end
            try
                setPropertyOnOriginalObject(obj, "ByteOrder", val);
            catch ex
                showErrorDialog(obj, ex);
            end
        end
    end

    %% Private Helpers
    methods (Access = private)
        function handlePropertyEvents(obj, ~, ~)
            % Set the Published ObservableNumBytesAvailable

            obj.ObservableValuesAvailable = obj.OriginalObjects.NumBytesAvailable;
        end
    end

    methods
        function setPropertyOnOriginalObject(obj, propertyName, propertyValue)
            % Set the property value on the transport accessor, and
            % generate associated MATLAB code log.

            arguments
                obj
                propertyName (1, 1) string
                propertyValue
            end

            obj.TransportAccessor.setPropertyOnOriginalObject(propertyName, propertyValue);

            if propertyName == "Terminator"
                obj.CodeGenerator.generateTerminatorCode(obj.OriginalObjects);
            else
                obj.CodeGenerator.generatePropertySetterCode(obj.OriginalObjects, propertyName);
            end

        end

        function handleServerDisconnected(obj)
            % When the server is disconnected, disable the
            % TransportAccessor and set the ServerDisconnected flag to
            % true. This will initiate the app close routine from
            % SharedApp.m

            if isvalid(obj.DataAvailableListener)
                delete(obj.DataAvailableListener);
            end

            obj.TransportAccessor.disconnect();
            obj.ServerDisconnected = true;
        end
    end

    %% Abstract Method Implementation - This function will be over-ridden by the child-classes
    methods
        function setProxyPropertyGroups(obj)
            % Set the property into the property groups to be displayed in
            % the property inspector section.

            g2 = obj.createGroup(message("transportapp:appspace:propertyinspector:PropertyInspectorCommunicationGroup").string, "", "");
            g2.addProperties("NumBytesAvailable");
            g2.addEditorGroup("Terminator");
            g2.addProperties("ByteOrder", "Timeout");
            g2.Expanded = true;
        end
    end
end
