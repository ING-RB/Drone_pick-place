classdef TcpclientApp < matlabshared.transportapp.internal.SharedApp
    %TCPCLIENTAPP creates a TCP/IP connection to a server/device using the
    % properties returned by the TcpclientDeviceProvider. It is also
    % responsible for creating toolstrip and appspace forms.

    % Copyright 2021-2022 The MathWorks, Inc.

    properties (Constant)
        % App display name label
        DisplayName = string(message("transportapp:tcpclientapp:AppDisplayName").getString)

        TransportName = "tcpclient"
        TransportInstance  = "tcpclientObj"
    end

    %% Abstract Method Implementation
    methods
        function toolstripForm = getToolstripForm(~,~)
            % Return the default toolstrip form.
            toolstripForm = matlabshared.transportapp.internal.utilities.forms.ToolstripForm;
            toolstripForm.ShowFlushButton = false;
        end

        function appspaceForm = getAppSpaceForm(~,~)
            % Return the updated appspace form for tcpclient app.
            appspaceForm = matlabshared.transportapp.internal.utilities.forms.AppSpaceForm;
            appspaceForm.ReadWarningIDs = ["transportlib:client:ReadlineWarning", ...
                "transportlib:client:ReadbinblockWarning"];
        end

        function transportProxy = getTransportProxy(obj)
            % Form a connection to the TCP/IP device specified by the user
            % using the device properties returned by the
            % TcpclientDeviceProvider. Also return the TcpclientProxy
            % instance created.

            % If the connection to the TCP/IP device is not successful,
            % then the app will not be launched.
            tcpclientObj = tcpclient(obj.TransportProperties.Address, ...
                str2double(obj.TransportProperties.Port), ...
                "ConnectTimeout", str2double(obj.TransportProperties.ConnectTimeout), ...
                "EnableTransferDelay", obj.TransportProperties.EnableTransferDelay);

            % Create the TcpclientProxy class and pass the instance of
            % tcpclient object to it.
            transportProxy = transportapp.tcpclient.internal.TcpclientProxy(tcpclientObj, obj.Mediator);
        end

        function [comment, code, varargout] = getConstructorCommentAndCode(obj)
            % Return the associated constructor comment and constructor
            % code for creation of the tcpclient instance.

            if obj.TransportProperties.EnableTransferDelay
                commentID = "transportapp:tcpclientapp:ConstructorComment";
                codeID = "transportapp:tcpclientapp:ConstructorCode";
            else
                commentID = "transportapp:tcpclientapp:ConstructorCommentTransferDelayFalse";
                codeID = "transportapp:tcpclientapp:ConstructorCodeTransferDelayFalse";
            end
            comment = string(message(commentID, obj.TransportInstance, obj.TransportProperties.Address, ...
                obj.TransportProperties.Port, obj.TransportProperties.ConnectTimeout).getString);
            code = string(message(codeID, obj.TransportInstance, obj.TransportProperties.Address, ...
                obj.TransportProperties.Port, obj.TransportProperties.ConnectTimeout).getString);

            varargout{1} = commentID;
            varargout{2} = codeID;
        end
    end

    %% Hook method implementation
    methods
        function tabName = getAppTabName(~)
            tabName = message("transportapp:tcpclientapp:AppDisplayName").getString;
        end
    end
end
