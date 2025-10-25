classdef SerialportApp < matlabshared.transportapp.internal.SharedApp
    %SERIALPORTAPP creates a serialport connection using the properties
    % returned by the SerialportDeviceProvider. It is also responsible for
    % creating toolstrip and appspace forms.

    % Copyright 2021-2022 The MathWorks, Inc.

    properties (Constant)
        % App display name label
        DisplayName = string(message("transportapp:serialportapp:AppDisplayName").getString)
        
        TransportName = "serialport"
        TransportInstance  = "serialportObj"
    end

    %% Abstract Method Implementation
    methods
        function toolstripForm = getToolstripForm(~,~)
            % Return the default toolstrip form.
            toolstripForm = matlabshared.transportapp.internal.utilities.forms.ToolstripForm;
            toolstripForm.ShowFlushButton = false;
        end

        function appspaceForm = getAppSpaceForm(~,~)
            % Return the default appspace form.
            appspaceForm = matlabshared.transportapp.internal.utilities.forms.AppSpaceForm;
            appspaceForm.ReadWarningIDs = ["serialport:serialport:ReadWarning", "serialport:serialport:ReadlineWarning", ...
                "serialport:serialport:ReadbinblockWarning"];
        end

        function transportProxy = getTransportProxy(obj)
            % Form a connection to the first available serial port or the
            % serial port selected by the user and return the
            % SerialportProxy instance.

            % Create a serialport instance using the device properties
            % returned by the device provider.
            % If the port is available, then this operation will be
            % successful.
            % If the port is busy, then this operation will fail
            % and the app will not be launched for the busy device.
            serialportObj = serialport(obj.TransportProperties.Port, obj.TransportProperties.BaudRate);

            % Create the SerialportProxy class and pass the instance of
            % serialport object to it.
            transportProxy = transportapp.serialport.internal.SerialportProxy(serialportObj, obj.Mediator);

            %% TO-DO
            % g2298118
            % 1. Show status of device card as "Connected"
            %    when serialportObj creation is successful.
            % 2. Show status of device card as "Busy - cannot connect" when
            %    when serialportObj creation fails.
        end

        function [comment, code] = getConstructorCommentAndCode(obj)
            % Return the associated constructor comment and constructor
            % code for creation of the serialport instance.

            comment = string(message("transportapp:serialportapp:ConstructorComment", ...
                obj.TransportInstance, obj.TransportProperties.Port).getString);
            code = string(message("transportapp:serialportapp:ConstructorCode", ...
                obj.TransportInstance, obj.TransportProperties.Port).getString);
        end
    end

    %% Hook method implementation
    methods
        function tabName = getAppTabName(~)
            tabName = message("transportapp:serialportapp:AppDisplayName").getString;
        end
    end
end
