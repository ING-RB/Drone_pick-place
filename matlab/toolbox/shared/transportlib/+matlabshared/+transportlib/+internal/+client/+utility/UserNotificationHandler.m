classdef UserNotificationHandler < handle
    %USERNOTIFICATIONHANDLER class throws custom warnings/errors.

    % Copyright 2019-2023 The MathWorks, Inc.

    properties
        % Name for interfaces. E.g.
        % "tcpclient", "serialport" and "udppport" (existing classes)
        % "visa", "bluetooth", etc (new interfaces)
        InterfaceName

        % Name of interface object used to throw custom
        % error/warning messages. E.g. "t" for "tcpclient", "u" for
        % "udpport", "b" for "bluetooth"
        InterfaceObjectName

        % Read warning doc link for no data in AsyncIO input buffer
        DocIDNoData

        % Read warning doc link for partial data in AsyncIO input buffer
        DocIDSomeData

        % Container where new error Ids and corresponding error messages
        % are stored
        ErrorRegistry matlabshared.transportlib.internal.client.utility.ErrorRegistry

        % Flag to set precision as compulsory for readbinblock and
        % writebinblock
        PrecisionRequired (1, 1) logical

        % Container where new error Ids and corresponding error messages
        % are stored
        WarningRegistry (1, 1) dictionary
    end

    properties (Access = private)
        % Contains the correct input argument syntax for all APIs.
        ValidInputArgsSyntax
    end

    %% Lifetime
    methods
        function obj = UserNotificationHandler(interfaceName, interfaceObjectName, errorRegistry, warningRegistry, precisionRequired)
            if ~isa(errorRegistry, "matlabshared.transportlib.internal.client.utility.ErrorRegistry")
                throw(MException(message("transportlib:utils:InvalidErrorRegistry")));
            end
            obj.InterfaceName = interfaceName;
            obj.InterfaceObjectName = interfaceObjectName;
            obj.PrecisionRequired = precisionRequired;

            if ~isscalar(obj.InterfaceName)
                [obj.DocIDNoData, obj.DocIDSomeData] = ...
                    instrument.internal.warningMessagesHelpers.getReadWarningDocLinks(obj.InterfaceName(1),obj.InterfaceName(2:end));
            else
                [obj.DocIDNoData, obj.DocIDSomeData] = ...
                    instrument.internal.warningMessagesHelpers.getReadWarningDocLinks(obj.InterfaceName);
            end
            obj.ErrorRegistry = errorRegistry;
            obj.WarningRegistry = warningRegistry;

            setValidInputArgsSyntax(obj);
        end
    end

    %% Helper Functions
    methods
        function editInputArgsSyntax(obj, name, value)
            % Make updates (add or edit) to the existing
            % ValidInputArgsSyntax registry.
            %
            % Name - Name of the function to add/edit, e.g. "read".
            %
            % Value - Function signature for the function being refered to in
            % "Name".

            arguments
                obj
                name (1, 1) string
                value (1, 1) string
            end

            obj.ValidInputArgsSyntax.(name) = value;
        end

        function val = getInputArgsSyntax(obj)
            % Get the ValidInputArgsSyntax struct containing method names
            % and their respective function signatures.

            val = obj.ValidInputArgsSyntax;
        end

        function displayReadWarning(obj, data, readType)
            % This helper function displays the read warning if a timeout
            % error occurs and the user gets some or no data from the transport.

            warningstr = '';
            warnData = 'nodata';
            docId = obj.DocIDNoData;

            % When some data is read
            if ~isempty(data)
                warnData = 'somedata';
                docId = obj.DocIDSomeData;
            end

            % Display the warning.
            warningstr = ...
                instrument.internal.warningMessagesHelpers.getReadWarning(warningstr, obj.InterfaceName(1), docId, warnData);
            warnState = warning('backtrace', 'off');
            oc = onCleanup(@()warning(warnState));

            warnID = getWarnID(obj, sprintf('transportlib:client:%sWarning', readType));
            warningstr = message(warnID, warningstr).getString;
            warning(warnID, warningstr);
        end

        function throwNarginErrorPlural(obj, funcName)
            % Throws incorrect input argument error message for multiple
            % correct syntaxes

            ex = MException(message...
                ('transportlib:client:IncorrectInputArgumentsPlural', ...
                funcName, obj.ValidInputArgsSyntax.(funcName)));
            throw(obj.translateErrorId(ex));
        end

        function throwNarginErrorSingular(obj, funcName)
            % Throws incorrect input argument error message for single
            % correct syntax

            ex = MException(message...
                ('transportlib:client:IncorrectInputArgumentsSingular', ...
                funcName, obj.ValidInputArgsSyntax.(funcName)));
            throw(obj.translateErrorId(ex));
        end

        function mExcept = translateErrorId(obj, mExcept)
            % Translates error Ids to custom error Ids in ErrorRegistry

            key = mExcept.identifier;
            if isKey(obj.ErrorRegistry.ErrorMap, key)
                errorVal = obj.ErrorRegistry.ErrorMap(key);
                mExcept = obj.getMException(errorVal, mExcept);
            end
        end
    end

    methods (Access = private)
        function mExcept = getMException(~, errorVal, mExcept)
            % Gets the custom exception from ErrorRegistry

            if errorVal.ID == ""
                return
            end
            id = errorVal.ID;
            msg = errorVal.MessageText;
            if msg == ""
                mExcept = MException(id, mExcept.message);
            else
                mExcept = MException(id, msg);
            end
        end

        function id = getWarnID(obj, id)
            % Converts the warning id if id matches any of the
            % WarningRegistry entries.

            arguments
                obj
                id (1, 1) string
            end

            if isKey(obj.WarningRegistry, id)
                id = obj.WarningRegistry(id);
            end
        end

        function setValidInputArgsSyntax(obj)
            % Set the ValidInputArgsSyntax property, which will be used to
            % show the correct syntax for the corresponding methods, if
            % these methods are invoked with the incorrect number of input
            % arguments.

            obj.ValidInputArgsSyntax = struct( ...
                "read", message("transportlib:utils:ReadSyntax", obj.InterfaceObjectName).getString, ...
                "readline", message("transportlib:utils:ReadlineSyntax", obj.InterfaceObjectName).getString, ...
                "readbinblock", message("transportlib:utils:ReadbinblockSyntax", obj.InterfaceObjectName).getString, ...
                "write", message("transportlib:utils:WriteSyntax", obj.InterfaceObjectName).getString, ...
                "writeline", message("transportlib:utils:WritelineSyntax", obj.InterfaceObjectName).getString, ...
                "writebinblock", message("transportlib:utils:WritebinblockSyntax", obj.InterfaceObjectName).getString, ...
                "configureCallback", message("transportlib:utils:ConfigureCallbackSyntax", obj.InterfaceObjectName).getString, ...
                "configureTerminator", message("transportlib:utils:ConfigureTerminatorSyntax", obj.InterfaceObjectName).getString, ...
                "flush", message("transportlib:utils:FlushSyntax", obj.InterfaceObjectName).getString, ...
                "writeread", message("transportlib:utils:WritereadSyntax", obj.InterfaceObjectName).getString);

            if obj.PrecisionRequired
                obj.ValidInputArgsSyntax.read = message("transportlib:utils:ReadPrecisionRequiredSyntax", obj.InterfaceObjectName).getString;
                obj.ValidInputArgsSyntax.write = message("transportlib:utils:WritePrecisionRequiredSyntax", obj.InterfaceObjectName).getString;
            end
        end
    end
end

