classdef Controller < matlabshared.mediator.internal.Publisher & ...
        matlabshared.mediator.internal.Subscriber & ...
        matlabshared.transportapp.internal.utilities.ITestable & ...
        matlabshared.transportapp.internal.toolstrip.read.IController & ...
        matlabshared.testmeasapps.internal.dialoghandler.DialogSource 

    % CONTROLLER is the controller class for the Read Section. It contains
    % business logic for operations that need to be performed when user
    % interacts with the View elements.

    % Copyright 2021-2023 The MathWorks, Inc.

    properties (Access = {?matlabshared.transportapp.internal.utilities.ITestable})
        ViewListeners = event.listener.empty
        NumBytesAvailable

        % The handle to the ViewConfiguration instance containing the View.
        ViewConfiguration
    end

    properties (Dependent)
        View
    end

    properties (SetAccess = immutable)
        Constants
        DataFormatDropDownOptions
    end

    properties (SetObservable)
        % Published here and subscribed to by the Properties Inspector
        % Manager.
        % This contains information about the read operation to be
        % performed, like the kind of read, the count of data to be read,
        % and the associated data type value.
        TransportData

        % Publish the write section data to the MATLABCodeGenerator.
        TransportDataCodeLog

        % Publish the read button pressed state
        ReadButtonPressed (1, 1) logical = false

        % Publish the flush state to the Properties Inspector Manager.
        FlushTransport (1, 1) logical = false

        % Publish a line of comment and code to the Code Log Section for
        % the flush command
        FlushCommentAndCode
    end

    %% Hook Methods - Override these methods in implementing read controller classes as needed.

    methods (Access = {?matlabshared.transportapp.internal.utilities.ITestable})
        function consts = getConstants(~)
            consts = matlabshared.transportapp.internal.toolstrip.read.Constants;
        end

        function ex = formatReadErrorHook(~, ex)
            % Override this hook method to customize error messages when a
            % read exception is thrown.
        end

        function newEx = getInvalidNumValuesToReadExceptionHook(~, ex)
            % Override this hook method to return a customized MException
            % when the "Num Values To Read" field has an invalid value.

            newEx = MException(ex.identifier, ...
                message("transportapp:toolstrip:read:NumValuesToReadInvalidType").string);
        end

        function value = getDataFormatDropdownOptions(obj)
            % Get all values for data format dropdown.

            value = obj.Constants.DataFormatDropDownOptions;
        end

        function type = getReadType(obj)
            % Get the read type based on the Data Format value.

            dataFormat = obj.ViewConfiguration.getViewProperty("DataFormat", "Value");
            switch dataFormat
                case obj.DataFormatDropDownOptions(1) % Binary
                    type = "Read";
                case obj.DataFormatDropDownOptions(2) % ASCII-Terminated Read
                    type = "ReadLine";
            end
        end

        function performDataFormatChangeOperations(obj, newDataFormat)
            % Perform the specific operations when the read data format is
            % changed.
            % If format = Binary
            %       1. Enable "Num Values to Read"
            %       2. Update the Data Type list and value
            %       3. Enable and update "Values Available" based on the
            %       selected Data Type
            %
            % If format = ASCII-Terminated String
            %       1. Disable "Num Values to Read"
            %       2. Update the Data Type list and value to string
            %       3. Disable and update "Values Available" to "N/A".

            switch string(newDataFormat)
                case obj.DataFormatDropDownOptions(1) % Binary

                    % 1. Enable "Num Values To Read" edit field.
                    obj.ViewConfiguration.setViewProperty("NumValuesToRead", "Enabled", true);

                    % 2. Update the data type dropdown list and select the
                    % first item of the dropdown list to be the selected
                    % data type.
                    dropdownValue = obj.Constants.AllPrecision;
                    obj.ViewConfiguration.addItemsToDropDownList("DataType", dropdownValue);
                    obj.ViewConfiguration.setViewProperty("DataType", "Value", dropdownValue(1));

                    % 3. Enable and update ValuesAvailable based on
                    % NumBytesAvailable
                    obj.ViewConfiguration.setViewProperty("ValuesAvailable", "Enabled", true);
                    obj.ViewConfiguration.setViewProperty("ValuesAvailable", "Text", ...
                        obj.getValuesAvailableFromBytesAvailable(dropdownValue(1)));

                case obj.DataFormatDropDownOptions(2) % ASCII-Terminated String

                    % 1. Disable "Num Values To Read" edit field.
                    obj.ViewConfiguration.setViewProperty("NumValuesToRead", "Enabled", false);

                    % 2. Update both the data type dropdown list and
                    % selected value to "string"
                    dropdownValue = obj.Constants.StringPrecision;
                    obj.ViewConfiguration.addItemsToDropDownList("DataType", dropdownValue);
                    obj.ViewConfiguration.setViewProperty("DataType", "Value", dropdownValue(1));

                    % 3. Disable "Values Available" and set Values
                    % Available to "N/A"
                    obj.ViewConfiguration.setViewProperty("ValuesAvailable", "Text", ...
                        obj.Constants.ValuesAvailableASCIITerminatedString);
                    obj.ViewConfiguration.setViewProperty("ValuesAvailable", "Enabled", false);
            end
        end

        function handleValuesAvailableChanged(obj, numBytesAvailable)
            % Handler for when the ObservableValuesAvailable object is set
            % in the Transport Proxy class.

            obj.NumBytesAvailable = numBytesAvailable;

            dataformatValue = obj.ViewConfiguration.getViewProperty("DataFormat", "Value");
            switch string(dataformatValue)
                case obj.DataFormatDropDownOptions(1) % Binary

                    % Update values available based on the Data type value.
                    precision = obj.ViewConfiguration.getViewProperty("DataType", "Value");
                    obj.ViewConfiguration.setViewProperty("ValuesAvailable", "Text", ...
                        getValuesAvailableFromBytesAvailable(obj, precision));

                case obj.DataFormatDropDownOptions(2) % ASCII-Terminated String
                    obj.ViewConfiguration.setViewProperty("ValuesAvailable", "Text", obj.Constants.ValuesAvailableASCIITerminatedString);
            end
        end
    end

    %% Lifetime
    methods
        function obj = Controller(mediator, viewConfiguration, ~)
            arguments
                mediator matlabshared.mediator.internal.Mediator
                viewConfiguration matlabshared.transportapp.internal.utilities.viewconfiguration.IViewConfiguration
                ~
            end

            obj@matlabshared.mediator.internal.Publisher(mediator);
            obj@matlabshared.mediator.internal.Subscriber(mediator);
            obj@matlabshared.testmeasapps.internal.dialoghandler.DialogSource(mediator);
            obj.ViewConfiguration = viewConfiguration;

            obj.Constants = getConstants(obj);
            obj.DataFormatDropDownOptions = getDataFormatDropdownOptions(obj);
            obj.ViewConfiguration.setViewProperty ...
                ("DataFormat", "Description", obj.DataFormatDropDownOptions(1));

            % Only for production mode
            if isa(obj.ViewConfiguration, ...
                    "matlabshared.transportapp.internal.utilities.viewconfiguration.ViewConfiguration")
                obj.setupListeners();
            end
        end

        function delete(obj)
            delete(obj.ViewListeners);
        end
    end

    %% Implement matlabshared.mediator.internal.Subscriber abstract methods
    methods
        function subscribeToMediatorProperties(obj, ~, ~)
            obj.subscribe('ObservableValuesAvailable', ...
                @(src, event)obj.handleValuesAvailableChanged(event.AffectedObject.ObservableValuesAvailable));

            obj.subscribe('ReadComplete', ...
                @(src, event)obj.handleReadButtonState(event.AffectedObject.ReadComplete));

            obj.subscribe('WriteButtonPressed', ...
                @(src, event)obj.handleReadButtonState(false));

            obj.subscribe('WriteComplete', ...
                @(src, event)obj.handleReadButtonState(true));
        end
    end

    %% Other helper methods
    methods (Access = {?matlabshared.transportapp.internal.utilities.ITestable})
        function setupListeners(obj)
            obj.ViewListeners(end+1) = listener(obj.View, "DataFormatValueChanged", ...
                @(src, evt)obj.dataFormatValueChanged(src, evt));

            obj.ViewListeners(end+1) = listener(obj.View, "DataTypeValueChanged", ...
                @(src, evt)obj.dataTypeValueChanged(src, evt));

            obj.ViewListeners(end+1) = listener(obj.View, "ReadButtonPressed", ...
                @(src, evt)obj.readButtonPressed(src, evt));

            obj.ViewListeners(end+1) = listener(obj.View, "FlushButtonPressed", ...
                @(src, evt)obj.flushButtonPressed(src, evt));
        end

        function setNumValuesToRead(obj, valuesAvailable)
            % If the numValuesToRead value is greater than valuesAvailable.

            if str2double(valuesAvailable) == 0
                obj.ViewConfiguration.setViewProperty("NumValuesToRead", "Value", "");
            else
                obj.ViewConfiguration.setViewProperty("NumValuesToRead", "Value", valuesAvailable);
            end
        end

        function valuesAvailable = getValuesAvailableFromBytesAvailable(obj, precision)
            % Based on the selected "Data Type" value, calculate the
            % values available.

            valuesAvailable = floor(obj.NumBytesAvailable/obj.Constants.DataTypeSize(precision));
            valuesAvailable = string(valuesAvailable);
        end
    end

    %% Listener Functions
    methods (Access = {?matlabshared.transportapp.internal.utilities.ITestable})
        function dataTypeValueChanged(obj, ~, evt)
            % Handler function when the read data type changes. This
            % applies for Binary format, as the "Values Available" needs to
            % be updated based on the data type selected, and "Num values
            % to Read", thereof.

            dataFormat = string( ...
                obj.ViewConfiguration.getViewProperty("DataFormat", "Value"));

            if dataFormat == obj.DataFormatDropDownOptions(1) % Binary
                precision = string(evt.Data);
                valuesAvailable = obj.getValuesAvailableFromBytesAvailable(precision);
                obj.ViewConfiguration.setViewProperty("ValuesAvailable", "Text", valuesAvailable);
            end
        end

        function dataFormatValueChanged(obj, ~, evt)
            % Handler function for the change in the Data Format value
            % changed.

            obj.ViewConfiguration.setViewProperty ...
                ("DataFormat", "Description", string(evt.Data));

            currentDataType = obj.ViewConfiguration.getViewProperty("DataType", "Value");
            obj.ViewConfiguration.clearDropDownItemsList("DataType");
            obj.ViewConfiguration.setViewProperty("NumValuesToRead", "Value", "");

            % Update the data type drop down values when the Data Format
            % value changes.
            obj.performDataFormatChangeOperations(evt.Data);

            % Maintain previous DataType setting if the value is supported
            % for the new DataFormat
            dataTypeOptions = obj.ViewConfiguration.getViewProperty("DataType", "Items");
            if ismember(currentDataType, dataTypeOptions)
                obj.ViewConfiguration.setViewProperty("DataType", "Value", currentDataType);
            end
        end

        function flushButtonPressed(obj,~, ~)
            % Handler for when the Flush Button is pressed.

            obj.FlushTransport = true;
            obj.FlushCommentAndCode = true;
        end

        function readButtonPressed(obj, ~, ~)
            % Handler for when the Read Button is pressed.

            try
                type = obj.getReadType();

                count = formatNumValuesToRead(obj);

                dataType = string(obj.ViewConfiguration.getViewProperty("DataType", "Value"));

                % Disable the Read button till the read completes.
                obj.ViewConfiguration.setViewProperty("ReadButton", "Enabled", false);
                obj.ReadButtonPressed = true;

                % Send the parameters for the data to be read.
                obj.TransportData = ...
                    matlabshared.transportapp.internal.utilities.forms.TransportData(type, count, dataType);

                obj.TransportDataCodeLog = ...
                    matlabshared.transportapp.internal.utilities.forms.TransportData(type, string(count), dataType);
            catch ex
                ex = formatReadErrorHook(obj, ex);
                showErrorDialog(obj, ex);
            end
        end

        function handleReadButtonState(obj, flag)
            % Handler for enabling or disabling the Read Button.

            obj.ViewConfiguration.setViewProperty("ReadButton", "Enabled", flag);
        end
    end

    methods(Access = protected)
        % Internal utilities. Access is protected so that subclasses may
        % override.

        function val = formatNumValuesToRead(obj)
                % Get "Num Values to Read" value based on values available.
                % For Values Available = 0, throw an error. For Values
                % Available > the new "Num Values to Read" value, set the
                % "Num Values to Read" value to Values Available and throw
                % an error.

                val = [];
                format = ...
                    string(obj.ViewConfiguration.getViewProperty("DataFormat", "Value"));

                % For ASCII-Terminated String Operation, return. Prevent accessing non-existing
                % values of the DataFormatDropDownOptions.
                if numel(obj.DataFormatDropDownOptions) > 1 && format == obj.DataFormatDropDownOptions(2)
                    return
                end

                valuesAvailable = ...
                    str2double(obj.ViewConfiguration.getViewProperty("ValuesAvailable", "Text"));

                numValuesToRead = ...
                    string(obj.ViewConfiguration.getViewProperty("NumValuesToRead", "Value"));
                if numValuesToRead == ""
                    val = performEmptyNumValuesToReadOperations(obj, valuesAvailable);
                    return
                end

                % There is some value entered in "Num Values to Read"
                try
                    val = str2double(numValuesToRead);
                    if isnan(val)
                        throw(MException(message("transportapp:toolstrip:read:NumValuesToReadInvalidType")));
                    end
                    validateattributes(val, "numeric", ["nonnegative", "integer", "scalar", "positive", "nonzero"]);
                catch ex
                    % Error occurred validating "Num Values to Read". Value
                    % to revert to depends on the value of
                    % "valuesAvailable"
                    if valuesAvailable == 0
                        obj.ViewConfiguration.setViewProperty("NumValuesToRead", "Value", "");
                    else
                        obj.ViewConfiguration.setViewProperty("NumValuesToRead", "Value", string(valuesAvailable));
                    end
                    newEx = getInvalidNumValuesToReadExceptionHook(obj, ex);
                    throw(newEx);
                end

                % Verified that Num Values to Read value is a valid numeric
                % entry. Verify that the Num Values to Read value is less
                % than Values Available.
                if val > valuesAvailable
                    throw(MException(message("transportapp:toolstrip:read:NotEnoughData")));
                end

                function numValToRead = performEmptyNumValuesToReadOperations(~, valuesAvailable)
                    % When "Num Values to Read" field is empty and the
                    % read button is pressed, do the necessary operations -
                    % 1. If Values Available is not 0, return valuesAvailable
                    % 2. If Values Available is 0, throw an error.

                    % If values available is not 0, read values available
                    if valuesAvailable ~= 0
                        numValToRead = valuesAvailable;
                    else
                        throw(MException(message("transportapp:toolstrip:read:NoData")));
                    end
                end
        end
    end

    %% Getters and Setters
    methods
        function value = get.View(obj)
            value = obj.ViewConfiguration.View;
        end
    end
end
