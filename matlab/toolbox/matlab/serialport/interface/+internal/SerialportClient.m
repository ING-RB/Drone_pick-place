classdef SerialportClient < matlabshared.transportlib.internal.client.GenericClient
    %SERIALPORTCLIENT is the GenericClient instance for the Serialport
    %interface. It helps internal.Serialport communicate with the underlying
    %Shared_Transport layer via GenericClient and allows a conduit for
    %performing reads, writes, flush, callback operations, and getting and
    %setting internal serial transport properties.

    %   Copyright 2023-2024 The MathWorks, Inc.

    properties (Constant)
        % Additional list of function names and their respective function
        % signatures to be passed along to the Shared_Transport"s
        % UserNotificationHandler.
        AdditionalInputArgsSyntax = dictionary( ...
            "getpinstatus", "serialport:serialport:GetPinStatusSyntax", ...
            "setDTR", "serialport:serialport:SetDTRSyntax", ...
            "setRTS", "serialport:serialport:SetRTSSyntax", ...
            "serialbreak", "serialport:serialport:SerialBreakSyntax" ...
            )
    end

    %% Lifetime
    methods
        function obj = SerialportClient(transportProps)
            obj@matlabshared.transportlib.internal.client.GenericClient(transportProps);
            objName = transportProps.InterfaceObjectName;

            % Add new entries to the Shared_Transport's function singature
            % syntax.
            for funcName = keys(obj.AdditionalInputArgsSyntax)'
                obj.UserNotificationHandler.editInputArgsSyntax(...
                    funcName, ...
                    message(obj.AdditionalInputArgsSyntax(funcName), objName).string);
            end

            obj.TranslateSetPropertyError = false;
        end
    end

    methods
        function status = getpinstatus(obj, varargin)
            %GETPINSTATUS Get the serial pin status.
            %
            % STATUS = GETPINSTATUS(OBJ) gets the serial pin status and
            % returns it as a struct to STATUS.
            %
            % Output Arguments:
            %   STATUS: 1x1 struct with the fields, ClearToSend,
            %   DataSetReady, CarrierDetect, and RingIndicator.
            %
            % Example:
            %      % Get the pin status
            %      status = getpinstatus(s);

            try
                narginchk(1, 1);
            catch %#ok<CTCH>
                obj.UserNotificationHandler.throwNarginErrorSingular("getpinstatus");
            end
            try
                status = getPinStatus(obj.Transport);
            catch ex
                throwAsCaller(ex);
            end
        end

        function setRTS(obj, varargin)
            %SETRTS Set/reset the serial RTS (Ready to Send) pin
            %
            % SETRTS(OBJ,FLAG) sets or resets the serial RTS pin, based
            % on the value of FLAG.
            %
            % Input Arguments:
            %   FLAG: Logical true or false. FLAG set to true sets the
            %   RTS pin, false resets it.
            %
            % Example:
            %      % Set the RTS pin
            %      setRTS(s,true);
            %
            %      % Reset the RTS pin
            %      setRTS(s,false);

            try
                narginchk(2, 2);
            catch %#ok<CTCH>
                obj.UserNotificationHandler.throwNarginErrorSingular("setRTS");
            end
            try
                flag = varargin{1};
                setRTS(obj.Transport, flag);
            catch ex
                throwAsCaller(ex);
            end
        end

        function setDTR(obj, varargin)
            %SETDTR Set/reset the serial DTR (Data Terminal Ready) pin
            %
            % SETDTR(OBJ, FLAG) sets or resets the serial DTR pin, based
            % on the value of FLAG.
            %
            % Input Arguments:
            %   FLAG: Logical true or false. FLAG set to true sets the
            %   DTR pin, false resets it.
            %
            % Example:
            %      % Set the DTR pin
            %      setDTR(s, true);
            %
            %      % Reset the RTS pin
            %      setDTR(s, false);

            try
                narginchk(2, 2);
            catch %#ok<CTCH>
                obj.UserNotificationHandler.throwNarginErrorSingular("setDTR");
            end

            try
                flag = varargin{1};
                setDTR(obj.Transport, flag);
            catch ex
                throwAsCaller(ex);
            end
        end

        function serialbreak(obj, varargin)
            % SERIALBREAK Send a serial break signal
            %
            % serialbreak(OBJ,TIME) sends a serial break signal by setting
            % the transmit pin (TXD) to high for the duration specified by
            % TIME in milliseconds.
            %
            % Input Arguments:
            % TIME: Positive integer that specifies the duration of the
            % serial break signal in milliseconds.
            %
            % Example:
            %      Send a serial break to the device
            %      serialbreak(s, time);

            try
                narginchk(2,2);
            catch %#ok<CTCH>
                obj.UserNotificationHandler.throwNarginErrorSingular("serialbreak");
            end

            try
                serialbreak(obj.Transport, varargin{1});
            catch ex
                throwAsCaller(ex);
            end
        end
    end

    %% Implementing Hook methods from GenericClient
    methods (Access = protected)
        function bytesAvailableFcnModeValidationHook(~, mode)
            validateattributes(mode, "char", "nonempty", "configureCallback", "mode", 2);
        end

        function bytesAvailableFcnCountValidationHook(~, count)
            validateattributes(count, "numeric", ["scalar", "nonzero", "positive", "integer", ...
                "finite"], "serialport", "BytesAvailableFcnCount");
        end

        function flushInputValidationHook(~, buffer)
            validateattributes(buffer, ["char", "string"], "nonempty", "flush", "buffer", 2);
        end

        function dataAvailableInfo = byteAvailableInfoHook(~, ~, evt)
            dataAvailableInfo = instrument.internal.DataAvailableInfo(evt.Count, evt.AbsTime);
        end

        function dataAvailableInfo = terminatorAvailableInfoHook(~, ~, evt)
            dataAvailableInfo = instrument.internal.DataAvailableInfo(evt.Count, evt.AbsTime);
        end

        function msg = getCustomErrorOccurredMessageHook(obj, ex)
            arguments
                obj
                ex (1, 1) matlabshared.transportlib.internal.ErrorInfo
            end

            if ex.ID == "seriallib:serial:lostConnectionState"
                msg = message("serialport:serialport:ConnectionLost").string();
            else
                msg = getCustomErrorOccurredMessageHook ...
                    @matlabshared.transportlib.internal.client.GenericClient(obj, ex);
            end
        end
    end

    methods (Hidden, Access = ...
            {?internal.Serialport, ?instrument.internal.ITestable})
        function accessErrorCallbackFunction(obj, src, ex)
            % For testing purpose only, call the protected
            % "errorCallbackFunction" from Generic Client.

            errorCallbackFunction(obj, src, ex);
        end
    end
end
