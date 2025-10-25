classdef Manager < matlabshared.mediator.internal.Publisher & ...
        matlabshared.mediator.internal.Subscriber & ...
        matlabshared.transportapp.internal.utilities.ITestable & ...
        matlabshared.testmeasapps.internal.dialoghandler.DialogSource & ...
        matlabshared.transportapp.internal.appspace.propertyinspector.IInspectable

    %MANAGER contains the property inspector section and manages all
    %transport interactions like read and write for the app.

    % Copyright 2020-2023 The MathWorks, Inc.

    properties
        PropertyInspector
        ReadWarningIDs
    end

    properties (Dependent, SetAccess = private)
        Transport
    end

    properties(SetObservable)
        % The Complete Flags are for denoting to the subscriber read and
        % write sections controllers that the read/write/query operation
        % has been completed. This allows the controller classes to
        % re-enable the disabled read/write/query button.

        WriteComplete (1, 1) logical = true
        ReadComplete (1, 1) logical = true
        QueryComplete (1, 1) logical = true

        % Published here and subscribed to by the Communication Log table
        % controller. This contains information that gets displayed in the
        % Communication Log Table.
        CommunicationLogData = ...
            matlabshared.transportapp.internal.utilities.forms.TableRowData.empty
    end

    properties
        Constants
    end

    %% GENERAL HOOK METHODS
    methods
        function consts = getConstants(~)
            consts = matlabshared.transportapp.internal.appspace.propertyinspector.Constants;
        end
    end

    %% HOOK METHODS for TRANSPORT COMMUNICATION (read, write, etc.)
    methods
        function readHook(obj, transportData, errorRow)
            try
                data = read(obj.Transport, transportData.Value, transportData.DataType);

                obj.CommunicationLogData = getCommunicationLogData(obj, transportData.Action, data, ...
                    transportData.DataType, errorRow);
            catch ex
                handleError(obj, ex, transportData.Action);
            end
        end

        function readlineHook(obj, transportData, errorRow)
            try
                data = readline(obj.Transport);

                obj.CommunicationLogData = getCommunicationLogData(obj, transportData.Action, data, ...
                    transportData.DataType, errorRow);
            catch ex
                handleError(obj, ex, transportData.Action);
            end
        end

        function readbinblockHook(obj, transportData, errorRow)
            try
                data = readbinblock(obj.Transport, transportData.DataType);
                obj.CommunicationLogData = getCommunicationLogData(obj, transportData.Action, data, ...
                    transportData.DataType, errorRow);
            catch ex
                handleError(obj, ex, transportData.Action);
            end
        end

        function writeHook(obj, transportData, errorRow)
            try
                write(obj.Transport, transportData.Value, transportData.DataType);

                writeData = getWriteData(obj, transportData.Value, transportData.DataType);
                obj.CommunicationLogData = getCommunicationLogData(obj, transportData.Action, writeData, ...
                    transportData.DataType, errorRow);
            catch ex
                handleError(obj, ex, transportData.Action);
            end
        end

        function writelineHook(obj, transportData, errorRow)
            try
                writeline(obj.Transport, transportData.Value);

                obj.CommunicationLogData = getCommunicationLogData(obj, transportData.Action, string(transportData.Value), ...
                    transportData.DataType, errorRow);
            catch ex
                handleError(obj, ex, transportData.Action);
            end
        end

        function writebinblockHook(obj, transportData, errorRow)
            try
                headerExists = matlabshared.transportapp.internal.utilities.TransportDataValidator. ...
                    binblockHeaderExists(transportData);
                if headerExists
                    header = transportData.UserData.Header;
                else
                    header = '';
                end

                writebinblock(obj.Transport, transportData.Value, transportData.DataType, header);
                writeData = getWriteData(obj, transportData.Value, transportData.DataType);
                obj.CommunicationLogData = getCommunicationLogData(obj, transportData.Action, writeData, ...
                    transportData.DataType, errorRow);
            catch ex
                handleError(obj, ex, transportData.Action);
            end
        end

        function queryHook(obj, transportData, errorRow)
            try
                % Populate the Communication Log with the initial query
                % prompt. This way, even if writeread fails, the user will
                % still be presented with a row indicating that a write was
                % attempted.
                obj.CommunicationLogData = getCommunicationLogData(...
                    obj, transportData.Action, transportData.Value, transportData.DataType, errorRow);

                data = writeread(obj.Transport, transportData.Value);

                % If the writeread was successful, add an additional row
                % to the Communication Log with the data read from the
                % transport object.
                obj.CommunicationLogData =  getCommunicationLogData(...
                    obj, "", data, class(data), errorRow);
            catch ex
                % If an error occurs with writeread, the error row should be
                % the second row after the initial row representing the
                % query prompt. Populate the error row's action with "" to
                % maintain consistency with a successful writeread
                % operation.

                handleError(obj, ex, "");
            end
        end
    end

    methods
        function obj = Manager(form, propInspector, ~)
            arguments
                form matlabshared.transportapp.internal.utilities.forms.AppSpaceForm
                propInspector
                ~
            end
            obj@matlabshared.mediator.internal.Publisher(form.Mediator);
            obj@matlabshared.mediator.internal.Subscriber(form.Mediator);
            obj@matlabshared.testmeasapps.internal.dialoghandler.DialogSource(form.Mediator);
            obj.Constants = obj.getConstants();

            % Register editor classes needed by the Terminator property of
            % the Property Inspector section.
            obj.registerTerminatorClasses();

            obj.PropertyInspector = propInspector;
            obj.ReadWarningIDs = form.ReadWarningIDs;
        end

        function inspectTransportProxy(obj, transportProxy)
            % Assign the transportProxy to the Properties Inspector and
            % start the property inspector.
            obj.PropertyInspector.inspect(transportProxy);
        end

        function connect(obj)
            obj.PropertyInspector.InspectedObjects.connect();
            obj.PropertyInspector.ErrorFcn = @obj.handlePropertySetterError;
        end

        function disconnect(obj)

            if isvalid(obj.PropertyInspector.InspectedObjects) ...
                    && ~isempty(obj.PropertyInspector.InspectedObjects)
                obj.PropertyInspector.InspectedObjects.disconnect();
                obj.PropertyInspector.ErrorFcn = function_handle.empty;
            end
        end

        function delete(obj)
            % Clear the property inspector instance and its owned transport
            % instance. Manual deletion of the OriginalObjects and
            % InspectedObjects is needed, else the resource is not cleared
            % properly by the Property Inspector.

            % Delete the underlying transport instance.
            delete(obj.PropertyInspector.InspectedObjects.OriginalObjects);

            % Delete the transport proxy class.
            delete(obj.PropertyInspector.InspectedObjects);

            % Delete the Property Inspector instance.
            delete(obj.PropertyInspector);
        end
    end

    %% Implementing Subscriber Abstract methods
    methods
        function subscribeToMediatorProperties(obj, ~, ~)
            obj.subscribe('TransportData', ...
                @(src, event)obj.performTransportAction(event.AffectedObject.TransportData));

            obj.subscribe('FlushTransport', ...
                @(src, event)obj.performFlush());
        end
    end

    %% Getters and Setter
    methods
        function value = get.Transport(obj)
            if ~isempty(obj.PropertyInspector) && isvalid(obj.PropertyInspector)
                value = obj.PropertyInspector.InspectedObjects.OriginalObjects;
            end
        end
    end

    %% Subscriber Handler Methods
    methods (Access = {?matlabshared.transportapp.internal.utilities.ITestable})

        function performFlush(obj)
            % Perform a flush operation on the transport.

            try
                flush(obj.Transport);
            catch ex
                showErrorDialog(obj, ex);
            end
        end

        function performTransportAction(obj, transportData)
            arguments
                obj
                transportData matlabshared.transportapp.internal.utilities.forms.TransportData
            end

            originalWarningState = warning;

            % Ensure that the cleanup code restores the original warning
            % state.
            cleanup = onCleanup(@()obj.handleWarning(originalWarningState));

            errorRow = false;

            % Turn warnings off so that we do not show warnings on the
            % MATLAB Command Line. Also, reset last warning.
            warning("off");
            lastwarn('', '');

            % Perform the action on the transport. CommunicationLogData
            % is a form.TableRowData entry that transfers the transport action
            % details to the appspace Communication Log section.
            switch transportData.Action
                case "Read"
                    readHook(obj, transportData, errorRow);
                    obj.ReadComplete = true;

                case "ReadLine"
                    readlineHook(obj, transportData, errorRow);
                    obj.ReadComplete = true;

                case "ReadBinblock"
                    readbinblockHook(obj, transportData, errorRow);
                    obj.ReadComplete = true;

                case "Write"
                    writeHook(obj, transportData, errorRow);
                    obj.WriteComplete = true;
                    obj.QueryComplete = true;

                case "WriteLine"
                    writelineHook(obj, transportData, errorRow);
                    obj.WriteComplete = true;
                    obj.QueryComplete = true;

                case "WriteBinblock"
                    writebinblockHook(obj, transportData, errorRow);
                    obj.WriteComplete = true;
                    obj.QueryComplete = true;

                case "WriteRead"
                    queryHook(obj, transportData, errorRow);
                    obj.QueryComplete = true;
                    obj.WriteComplete = true;
            end
        end

        function handleWarning(obj, originalWarningState, varargin)
            % Show warning dialog for a valid warning and restore the
            % warning id to the previous state.

            cleanup = ...
                onCleanup(@()restoreOriginalWarningState(obj, originalWarningState));

            % Get the warning, if any, from the read/write operations.
            if isempty(varargin)
                [warnMsg, warnID] = lastwarn();
            else
                % varargin is used for passing in custom warnMsg and warnID
                % for unit testing.
                warnMsg = varargin{1};
                warnID = varargin{2};
            end

            if isValidWarning(obj, warnMsg, string(warnID))
                warnObj = matlabshared.testmeasapps.internal.dialoghandler.forms.WarningForm;
                warnObj.Identifier = string(warnID);
                warnObj.Message = message("transportapp:appspace:propertyinspector:TimeoutWarning").getString;
                showWarningDialog(obj, warnObj);
            end

            % NESTED FUNCTION
            function flag = isValidWarning(obj, warnMsg, warnID)
                % Check if there is a valid warning that we show. The
                % warning ID, if not empty, needs to be one of
                % ReadWarningIDs provided by the client app.

                flag = ...
                    ~isempty(warnMsg) && ismember(warnID, obj.ReadWarningIDs);
            end

            % NESTED FUNCTION
            function restoreOriginalWarningState(~, originalWarningState)
                warning(originalWarningState);
            end
        end

        function handlePropertySetterError(obj, ~, errInfo)
            % For any invalid data value error from the property inspector,
            % display the error dialog.

            mExcept = MException ...
                (message("transportapp:appspace:propertyinspector:InvalidPropertyValue", errInfo.property, errInfo.message));
            showErrorDialog(obj, mExcept);
        end

        function handleError(obj, ex, action)
            % When an error occurs performing a transport action, show the
            % error dialog and create the necessary communication log entry
            % to be displayed in the Communication Log table.

            showErrorDialog(obj, ex);

            % Prepare an Error row in the Communication Log table. Because
            % this is an error row, the last input argument to
            % getCommunicationLogData "true" is to denote this.
            obj.CommunicationLogData = ...
                getCommunicationLogData(obj, action, obj.Constants.ErrorText, obj.Constants.ErrorDataType, true);
        end

        function tableRowData = getCommunicationLogData(obj, action, data, dataType, errorRow)
            % Create a communication log table entry form (of type
            % form.TableRowData) based on the transport action performed.

            import matlabshared.transportapp.internal.appspace.propertyinspector.Manager
            time = string(datetime);

            % If an error happened, send an error row to the communication
            % log.
            if errorRow
                sizeData = obj.Constants.ErrorSize;
                tableRowData = Manager.createTableRowData(action, data, sizeData, dataType, time, errorRow);
                return
            end

            % If the data type for the transport action is string, the size
            % must be 1x1.
            if string(dataType) == "string"
                sizeData = [1, 1];
            else

                % If the data content itself is a string but the data type was
                % something else. This will happen when a workspace variable is
                % a string type, but the data format used for writing was
                % numeric (like uint8).
                if string(class(data)) == "string"
                    sizeData = [1, data.strlength()];
                else
                    sizeData = size(data);
                end
            end
            tableRowData = ...
                Manager.createTableRowData(action, data, sizeData, dataType, time, errorRow);
        end
    end

    methods (Access = {?matlabshared.transportapp.internal.utilities.ITestable})
        function registerTerminatorClasses(~)
            % This is needed before creating the property inspector
            % section. It registers the classes needed for rendering and
            % using the Terminator Rich Text Popup.

            terminatorClass = ...
                "matlabshared.transportapp.internal.utilities.transport.TerminatorClass";
            terminatorEditor = ...
                "matlabshared.transportapp.internal.utilities.transport.TerminatorEditor";
            textBoxEditor = ...
                "rendererseditors/editors/ArrayOfValuesTextBoxEditor";

            internal.matlab.inspector.peer.InspectorFactory.registerInPlaceEditor ...
                (terminatorClass, textBoxEditor);

            internal.matlab.inspector.peer.InspectorFactory.registerRenderer ...
                (terminatorClass, textBoxEditor);

            internal.matlab.inspector.peer.InspectorFactory.registerEditorConverter ...
                (terminatorClass, terminatorEditor);
        end

        function writeData = getWriteData(obj, writeData, dataType)
            % Cast the data written into the data type that was used
            % for writing. This is done to give an accurate
            % representation of the data written in the Communication
            % Log table.
            %
            % E.g. Writing [126, 127, 128] as int8 should be
            % represented as [126, 127, 127] in the Communication log
            % table as the max int8 value is 127.

            if dataType == "string"
                writeData = handleStringDataType(obj, writeData);
                return
            end

            if isstring(writeData)
                writeData = char(writeData);
            end
            writeData = cast(writeData, dataType);

            % For the data to show up as doubles in the exported row, or
            % exported communication log timetable. NOTE - It is
            % potentially unsafe to convert uint64 and int64 to double
            % (loss of data). So the exported data for uint64 and int64
            % will be displayed as is, without being converted to
            % doubles.
            if isnumeric(writeData) && ~contains(dataType, ["uint64", "int64"])
                writeData = double(writeData);
            end

            % NESTED FUNCTION
            function data = handleStringDataType(~, data)
                if isnumeric(data)
                    data = string(char(data));
                else
                    data = join(string(data), " ");
                end
            end
        end
    end

    %% Factory method for creating and populating a form.TableRowData
    methods (Static)
        function tableRowData = createTableRowData(action, data, sizeData, dataType, time, errorRow)
            % Create a form.TableRowData instance that contains the transport
            % action details. This instance will be used to populate the
            % communication log table.

            tableRowData = matlabshared.transportapp.internal.utilities.forms.TableRowData;
            tableRowData.Action = action;
            tableRowData.Data = data;
            tableRowData.Size = sizeData;
            tableRowData.DataType = dataType;
            tableRowData.Time = time;
            tableRowData.ErrorRow = errorRow;
        end
    end
end
