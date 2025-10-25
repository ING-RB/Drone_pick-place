classdef Controller < matlabshared.mediator.internal.Publisher & ...
        matlabshared.mediator.internal.Subscriber & ...
        matlabshared.transportapp.internal.utilities.ITestable & ...
        matlabshared.transportapp.internal.toolstrip.write.IController & ...
        matlabshared.testmeasapps.internal.dialoghandler.DialogSource 
    %CONTROLLER is the controller class for the Write Section. It contains
    % business logic for operations that need to be performed when user
    % interacts with the View elements.

    % Copyright 2021-2024 The MathWorks, Inc.

    properties (Access = {?matlabshared.transportapp.internal.utilities.ITestable})
        ViewListeners = event.listener.empty

        % The handle to the ViewConfiguration instance containing the View.
        ViewConfiguration

        % A containers.Map value that contains valid variable names to be
        % shown under the "Workspace Variable" dropdown. It contains 2 keys
        % "Binary" and "ASCII-Terminated String", and the values for each
        % key contains the associated workspace variable names that apply
        % to it.
        WorkspaceVariableList

        % Contains the last Workspace Variable value used to update the
        % Workspace Variable dropdown value. It is used to update the
        % Workspace Variable dropdown value when the dropdown value has
        % been changed (e.g. when there is a change in the MATLAB workspace
        % variable), but the Workspace Variable name that was originally
        % set is still a valid entry for the Workspace Variable name.
        LatestWorkspaceVariable (1, 1) string

        % The dropdown values for the Data Format dropdown UI element.
        DataFormatDropDownOptions (1,:) string

        % Flag that shows that when attempting to do a write as a numeric
        % value using the WriteData field, the value correctly evaluates to
        % a valid value.
        % E.g. evaluating the write data entry [1:10 as a
        % "uint8" errors being an invalid MATLAB command, and the data is
        % sent as a string "[1:10". The ValidNumericDataEval flag is false
        % for this case.
        % However, if the value is written as [1:10] and the
        % data type is "uint8", this evaluates successfully to 1, 2, ...
        % 10. The ValidNumericDataEval flag is true for this case.
        %
        % Only the following types are valid -
        %    1. Scalar string
        %    2. 1xn or nx1 numeric values
        %    3. 1xn char
        ValidNumericDataEval (1, 1) logical = true

        % Flag that indicates whether data is written from the Workspace
        % Variable or from the "Write Data" value. false - Write Data value
        % is being written. true - Workspace Variable value is being
        % written.
        WorkspaceVariableWrite (1, 1) logical = false

        % Flag that states that there is a string value in the "Enter Data"
        % edit field enclosed within double-quotes
        EnclosingDoubleQuotes (1, 1) logical = false
    end

    properties (SetAccess = immutable)
        Constants
    end

    properties (Dependent)
        View
    end

    properties (SetObservable)
        % Published here and subscribed to by the Properties Inspector
        % Manager.
        % This contains information about the write operation to be
        % performed, like the kind of write, the data to be written, and
        % the associated precision value.
        TransportData = ...
            matlabshared.transportapp.internal.utilities.forms.TransportData.empty

        % Publish a comment to the codelog
        Comment

        % Publish the write section data to the MATLABCodeGenerator.
        TransportDataCodeLog

        % Publish the write button pressed state.
        WriteButtonPressed (1, 1) logical = false
    end

    properties (Constant)
        WriteLineType = "WriteLine"
        WriteType = "Write"
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

            % Set the constants and the dataformat dropdown options
            obj.Constants = obj.getConstants();
            obj.DataFormatDropDownOptions = obj.getDataFormatDropdownOptions();
            obj.ViewConfiguration.setViewProperty ...
                ("DataFormat", "Description", obj.DataFormatDropDownOptions(1));

            % Populate the WorkspaceVariableList and set the workspace
            % variable dropdown.
            setupWorkspaceVariableList(obj);

            % Set Data Type dropdown value
            setDataTypeDropDown(obj);

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

    %% Hook Methods - Override these methods in implementing write controller classes as needed.
    methods(Access = {?matlabshared.transportapp.internal.utilities.ITestable})
        function consts = getConstants(~)
            consts = matlabshared.transportapp.internal.toolstrip.write.Constants;
        end

        function value = getDataFormatDropdownOptions(obj)
            % Get all values for data format dropdown.

            value = obj.Constants.DataFormatDropDownOptions;
        end

        function val = getTransportData(~, type, data, dataTypeValue)
            val = matlabshared.transportapp.internal.utilities.forms.TransportData(type, data, dataTypeValue);
        end

        function precision = getPrecisionForDropDownOption(obj, dataFormat)
            % Return precision values for the dropdown based on the
            % dataformat value.

            precision = [];
            if dataFormat == obj.DataFormatDropDownOptions(1) % Binary
                precision = obj.Constants.AllPrecision;
            elseif dataFormat == obj.DataFormatDropDownOptions(2) % ASCII-Terminated String
                precision = obj.Constants.ASCIITerminatedPrecision;
            end
        end

        function populateWorkspaceVariableList(obj, varList)
            % Populate the Workspace Variable Dropdown list with a list of
            % valid variable names.

            arguments
                obj matlabshared.transportapp.internal.toolstrip.write.Controller
                varList matlabshared.transportapp.internal.utilities.forms.WorkspaceVariableInfo
            end

            import matlabshared.transportapp.internal.utilities.forms.WorkspaceTypeEnum
            for var = varList

                switch var.Type
                    case WorkspaceTypeEnum.Numeric

                        % Add the value to the drop down list for "Binary"
                        obj.addNewValueToWorkspaceVariableList(obj.DataFormatDropDownOptions(1), var.Name);

                    case {WorkspaceTypeEnum.String, WorkspaceTypeEnum.Char}

                        % Add the variable name to the drop down list for
                        % "Binary" and "ASCII-Terminated String"
                        obj.addNewValueToWorkspaceVariableList(obj.DataFormatDropDownOptions, var.Name);
                end
            end
        end

        function type = getWriteType(obj)
            % Derive the Write Type based on the Data Format dropdown
            % value.

            dataFormatValue = string(obj.ViewConfiguration.getViewProperty("DataFormat", "Value"));
            if dataFormatValue == obj.DataFormatDropDownOptions(1) % Binary
                type = obj.WriteType;
            else
                type = obj.WriteLineType;
            end
        end
    end

    %% Implementing Subscriber Abstract methods
    methods
        function subscribeToMediatorProperties(obj, ~, ~)
            obj.subscribe('WorkspaceUpdated', ...
                @(src, event)obj.handleWorkspaceUpdated(event.AffectedObject.WorkspaceUpdated));

            obj.subscribe('WriteComplete', ...
                @(src, event)obj.handleWriteButtonState(event.AffectedObject.WriteComplete));

            obj.subscribe('ReadButtonPressed', ...
                @(src, event)obj.handleWriteButtonState(false));

            obj.subscribe('ReadComplete', ...
                @(src, event)obj.handleWriteButtonState(true));
        end
    end

    %% Listener Functions
    methods (Access = {?matlabshared.transportapp.internal.utilities.ITestable})
        function dataFormatValueChanged(obj, ~, evt)
            % Handler function whenever users select a different data write
            % format - Binary, or ASCII-Terminated String.

            obj.ViewConfiguration.setViewProperty("DataFormat", "Description", string(evt.Data));
            setDataTypeDropDown(obj, string(evt.Data));
            setWorkspaceVariableDropdown(obj);
            setWorkspaceVariableValue(obj);
        end

        function radioButtonValueChanged(obj, ~, evt)
            % Handler function for when the user switches between "Enter
            % Data" and "Workspace Variable". Based on the selected option,
            % enable or disable the "Enter Data" edit field and the
            % Workspace Variable dropdown list. NOTE - only one of these is
            % enabled at a time.

            flag = evt.Data;
            obj.ViewConfiguration.setViewProperty("CustomDataEditField", "Enabled", flag);
            obj.ViewConfiguration.setViewProperty("WorkspaceVariableDropdown", "Enabled", ~flag);

            setDataTypeDropDown(obj);
        end

        function writeButtonPressed(obj, ~, ~)
            % Handler function for when the Write Button is pushed.

            % Check if the user selected option, Enter Data or Workspace
            % Variable, is empty.
            try
                cleanup = onCleanup(@obj.resetWriteButtonPressedFlags);
                if isWriteEmpty(obj)
                    throw(MException(message("transportapp:toolstrip:write:WriteEmpty")));
                end

                % Get the type of write being performed - write, writeline.
                type = getWriteType(obj);

                % Get the data to be written, from Enter Data or Workspace
                % Variable, whichever is selected by the user.
                data = getWriteData(obj);

                % Get the user-specified precision value.
                dataTypeValue = string(obj.ViewConfiguration.getViewProperty("DataType", "Value"));

                % Get the transport data to be sent to the property
                % inspector manager to be written.
                transportData = getTransportData(obj, type, data, dataTypeValue);

                % Disable the Write button till the write completes.
                obj.ViewConfiguration.setViewProperty("WriteButton", "Enabled", false);
                obj.WriteButtonPressed = true;

                % Send the transport action information to the subscriber for
                % this published property. This property is subscribed to
                % by the PropertyInspector Manager which will handle the
                % write operation.
                obj.TransportData = transportData;

                if obj.WorkspaceVariableWrite
                    fieldName = "WorkspaceVariableDropdown";
                else
                    fieldName = "CustomDataEditField";
                end
                data = string(obj.ViewConfiguration.getViewProperty(fieldName, "Value"));
                obj.generateWriteCode(type, data, dataTypeValue);
            catch ex
                showErrorDialog(obj, ex);
            end
        end

        function handleWorkspaceUpdated(obj, varUpdateForm)
            % Handler for when there is a change in the MATLAB Workspace
            % Variables list.

            arguments
                obj
                varUpdateForm matlabshared.transportapp.internal.utilities.forms.WorkspaceUpdateInfo
            end

            switch varUpdateForm.EventType
                case obj.Constants.WorkspaceCleared
                    % Reset the WorkspaceVariableList containers.Map
                    obj.resetWorkspaceVariableList();

                    % Clear the current value of the dropdown
                    obj.ViewConfiguration.setViewProperty("WorkspaceVariableDropdown", "Value", "");

                    % Clear the items in the dropdown list
                    obj.ViewConfiguration.clearDropDownItemsList("WorkspaceVariableDropdown");

                case obj.Constants.VariableDeleted
                    % Remove all occurrences of the variable name from the
                    % dropdown list.
                    obj.removeValueFromWorkspaceVariableList ...
                        (obj.DataFormatDropDownOptions, varUpdateForm.ChangedVariableNames);

                case {obj.Constants.VariableChanged, obj.Constants.VariableAdded}
                    % Remove the variable names from both the dropdown list
                    % for Binary and ASCII terminated string
                    if isscalar(varUpdateForm.ChangedVariableNames) ...
                            && varUpdateForm.ChangedVariableNames == ""
                        return
                    end

                    obj.removeValueFromWorkspaceVariableList ...
                        (obj.DataFormatDropDownOptions, varUpdateForm.ChangedVariableNames);

                    % Parse the new variables changed again to get their
                    % updated types.
                    varType = ...
                        matlabshared.transportapp.internal.utilities.WorkspaceVariableHandler.parse(varUpdateForm.ChangedVariableNames);

                    % Based on the updated type, assign the values to the
                    % dropdown list for "Binary" and "ASCII-Terminated
                    % String" as applicable.
                    obj.populateWorkspaceVariableList(varType);
                otherwise
                    return
            end

            % Set the workspace variable dropdown based on the updated
            % WorkspaceVariableList and update the current value of the
            % Workspace Variable drop down list.
            setWorkspaceVariableDropdown(obj);
            setWorkspaceVariableValue(obj);
        end

        function handleWriteButtonState(obj, flag)
            % Handler for enabling or disabling the Write Button.

            obj.ViewConfiguration.setViewProperty("WriteButton", "Enabled", flag);
        end

        function setupListeners(obj)
            % Set up listeners for the event notifications from the view
            % class.
            obj.ViewListeners(end+1) = listener(obj.View, "DataFormatValueChanged", ...
                @(src, evt)obj.dataFormatValueChanged(src, evt));

            obj.ViewListeners(end+1) = listener(obj.View, "RadioButtonValueChanged", ...
                @(src, evt)obj.radioButtonValueChanged(src, evt));

            obj.ViewListeners(end+1) = listener(obj.View, "WriteButtonPressed", ...
                @(src, evt)obj.writeButtonPressed(src, evt));
        end
    end

    %% Other Helper Methods
    methods (Access = {?matlabshared.transportapp.internal.utilities.ITestable})
        function setDataTypeDropDown(obj, varargin)
            % Whenever there is a change in the Data Format, make the
            % corresponding changes to the Data Type dropdown list.

            narginchk(1, 2);
            if nargin == 1
                dataFormatValue = ...
                    string(obj.ViewConfiguration.getViewProperty("DataFormat", "Value"));
            else
                dataFormatValue = varargin{1};
            end

            currentPrecisionValue = string(obj.ViewConfiguration.getViewProperty("DataType", "Value"));

            % Clear the current dropdown list for data types.
            obj.ViewConfiguration.clearDropDownItemsList("DataType");

            % Get the appropriate datatype/precision dropdown list for
            % the data format value.
            precision = obj.getPrecisionForDropDownOption(dataFormatValue);

            % Update the dropdown list and default value.
            obj.ViewConfiguration.addItemsToDropDownList("DataType", precision);

            if obj.ViewConfiguration.getViewProperty("CustomDataEditField", "Enabled") && ...
                    obj.ViewConfiguration.getViewProperty("DataFormat", "Value") == obj.DataFormatDropDownOptions(1)
                precision = remove64bitForEnterData(obj, precision);
            end

            if ~ismember(currentPrecisionValue, precision)
                newPrecision = precision(1);
            else
                newPrecision = currentPrecisionValue;
            end

            obj.ViewConfiguration.setViewProperty("DataType", "Value", newPrecision);

            % NESTED FUNCTION
            function allPrecision = remove64bitForEnterData(obj, allPrecision)
                % For Data Format = Binary and "Enter Data" edit field text
                % option selected, remove int64 and uint64 from the
                % dropdown list. The only possible way of writing uint64
                % and int64 data is by importing a MATLAB workspace
                % variable using the Workspace Variable dropdown value.

                allPrecision(contains(allPrecision, ["uint64", "int64"])) = [];

                obj.ViewConfiguration.clearDropDownItemsList("DataType");
                obj.ViewConfiguration.addItemsToDropDownList("DataType", allPrecision);
            end
        end

        function setWorkspaceVariableDropdown(obj)
            % Set the appropriate drop down values. This needs to happen
            % whenever there is a change in the
            % 1. MATLAB workspace
            % 2. Write Format - Binary or ASCII
            % 3. Radio button change between Custom Data and Workspace
            %    Variable

            obj.LatestWorkspaceVariable = ...
                string(obj.ViewConfiguration.getViewProperty("WorkspaceVariableDropdown", "Value"));

            dataFormatValue = string(obj.ViewConfiguration.getViewProperty("DataFormat", "Value"));
            obj.ViewConfiguration.clearDropDownItemsList("WorkspaceVariableDropdown");
            obj.ViewConfiguration.addItemsToDropDownList("WorkspaceVariableDropdown", obj.WorkspaceVariableList(dataFormatValue));
        end

        function generateWriteCode(obj, action, value, precision)
            % Generate the MATLAB code log entry for the Workspace Variable
            % write.

            % For workspace variable being written.
            if obj.WorkspaceVariableWrite
                obj.Comment = string(message("transportapp:toolstrip:write:DefineWorkspaceVariable", value).getString());
                obj.TransportDataCodeLog = ...
                    matlabshared.transportapp.internal.utilities.forms.TransportData(action, value, precision);
                return
            end

            % For Write Data entries

            % Remove the double-quotes around the write data entry, if
            % present.
            if obj.EnclosingDoubleQuotes
                value = value.extractBetween(2, value.strlength()-1);
            end

            % Add extra double quotes around the write data if needed. This
            % is needed for string/char type writes.
            if needDoubleQuotesAroundData(obj, action, precision)
                value = """" + value + """";
            else
                % The data being written is numeric.
                value = getNumericGenerateCodeData(obj, value);
            end

            obj.TransportDataCodeLog = ...
                getTransportData(obj, action, value, precision);
        end

        function flag = needDoubleQuotesAroundData(obj, action, precision)
            % Flag that checks whether additional double-quotes are needed
            % to enclose the data, based on the write type and precision.
            % This is needed only for custom data writes - workspace
            % variable writes never require additional quotes.
            %
            % Additional quotes are needed around the data for the following write
            % conditions:
            % 1. If a writeline is being performed using the Write Data field,
            %    e.g. writeline(s, "hello");
            % 2. If a write is being performed and the precision is an
            %    ASCII type or failed to evaluate to a correct value using
            %    numeric precision, so the data is being sent as a char.
            asciiPrecision = precision == "char" || precision == "string";

            actionIsWrite = action == obj.WriteType;
            actionIsWriteLine = action == obj.WriteLineType;

            flag =  actionIsWriteLine || ...
                actionIsWrite && (asciiPrecision || ~obj.ValidNumericDataEval);
        end

        function value = getNumericGenerateCodeData(~, value)
            % For numeric values, check if the data evaluates to a valid
            % value, else put the numeric data inside the "[]". This is
            % needed if write data is for example, an array, "1 2 3 4 5"
            % and the precision is numeric.
            % There is also the possibility of having ";" after numeric
            % writes, like [1:10];;;; which evaluates similar to [1:10].
            % For such cases, remove all the ";" at the end of the write
            % data for code generation purposes.

            try
                data = eval(value); %#ok<NASGU>
            catch
                value = "["  + value + "]";
            end

            while endsWith(value, ";")
                value = value.extractBefore(value.strlength);
            end
        end

        function resetWriteButtonPressedFlags(obj)
            % Cleanup method for writeButtonPressed method.

            obj.ValidNumericDataEval = true;
            obj.EnclosingDoubleQuotes = false;
        end

        function setWorkspaceVariableValue(obj)
            % If the Workspace Variable dropdown list for the particular
            % data format is not empty, set it to the
            % LatestWorkspaceVariable value if applicable or set it to the
            % first entry in the dropdown.

            dataFormatValue = string(obj.ViewConfiguration.getViewProperty("DataFormat", "Value"));
            dropDownValues = obj.WorkspaceVariableList(dataFormatValue);

            if isempty(dropDownValues)
                obj.ViewConfiguration.setViewProperty("WorkspaceVariableDropdown", "Value", "");
                return
            end

            % Set the Workspace Variable value to LatestWorkspaceVariable
            % if LatestWorkspaceVariable is still a valid entry for the
            % selected Data Format, else set it to the first entry of the
            % Workspace Variable dropdown options.
            if ismember(obj.LatestWorkspaceVariable, dropDownValues)
                obj.ViewConfiguration.setViewProperty("WorkspaceVariableDropdown", "Value", obj.LatestWorkspaceVariable);
            else
                obj.ViewConfiguration.setViewProperty("WorkspaceVariableDropdown", "Value", dropDownValues(1));
                obj.LatestWorkspaceVariable = dropDownValues(1);
            end
        end

        function setupWorkspaceVariableList(obj)
            % When creating the write section controller for the first time,
            % populate the WorkspaceVariableDropDownList containers.Map.

            import matlabshared.transportapp.internal.utilities.WorkspaceVariableHandler

            % Get all workspace variables
            allVariables = WorkspaceVariableHandler.getWorkspaceVariableNames();

            % Get the variable names and associated types for the workspace
            % variables.
            parsedVariableList = WorkspaceVariableHandler.parse(allVariables);

            obj.resetWorkspaceVariableList();

            % Populate the Workspace Variable Dropdown list with valid
            % variable names.
            obj.populateWorkspaceVariableList(parsedVariableList);

            % Assign the dropdown options and values
            obj.setWorkspaceVariableDropdown();
            obj.setWorkspaceVariableValue();

            % Disable the WorkspaceVariableDropdown
            obj.ViewConfiguration.setViewProperty("WorkspaceVariableDropdown", "Enabled", false);
        end

        function writeEmpty = isWriteEmpty(obj)
            % For whichever is enabled (Enter Data or Workspace Variable),
            % check whether there is any data to write.

            customDataSelectedAndEmpty = obj.ViewConfiguration.getViewProperty("WorkspaceVariableDropdown", "Enabled") && ...
                isempty(obj.ViewConfiguration.getViewProperty("WorkspaceVariableDropdown", "Value"));

            workspaceVariableSelectedAndEmpty = obj.ViewConfiguration.getViewProperty("CustomDataEditField", "Enabled") && ...
                isempty(obj.ViewConfiguration.getViewProperty("CustomDataEditField", "Value"));

            writeEmpty = customDataSelectedAndEmpty || workspaceVariableSelectedAndEmpty;
        end

        function data = getWriteData(obj)
            % Get the final data to be written.

            % If the Enter Data field is enabled, get the Enter Field
            % data, else evaluate and get the MATLAB Workspace Variable
            % data value.
            if obj.ViewConfiguration.getViewProperty("CustomDataEditField", "Enabled")
                data = getCustomData(obj);
                obj.WorkspaceVariableWrite = false;
            else
                % Evaluate workspace variable value.
                data = evalin("base", ...
                    obj.ViewConfiguration.getViewProperty("WorkspaceVariableDropdown", "Value"));
                obj.WorkspaceVariableWrite = true;
            end
        end

        function data = getCustomData(obj)
            % Evaluate and get the Enter Data value to be written.

            % NOTE - data is a "char" value by default.
            data = obj.ViewConfiguration.getViewProperty("CustomDataEditField", "Value");

            % If the data is to be written as a numeric value,
            % perform additional operations to get the data to be
            % written. Else, return the data back as a "char"
            % value.
            if isNumericData(obj)
                data = parseNumericData(obj, data);
            else
                data = parseASCIIData(obj, data);
            end

            if ~isnumeric(data) && contains(string(data), """")
                obj.EnclosingDoubleQuotes = false;
                throw(MException(message("transportapp:toolstrip:write:DoubleQuotesString")));
            end
        end

        function flag = isNumericData(obj)
            % Check whether the data type of the write is a
            % numeric type.

            flag = any(string(obj.ViewConfiguration.getViewProperty("DataType", "Value")) == ...
                obj.Constants.NumericPrecision);
        end

        function data = parseASCIIData(obj, data)
            % If data is ASCII and is enclosed within double-quotes, remove
            % the double-quotes.

            data = string(data);
            if data.startsWith("""") && data.endsWith("""") && data.strlength > 1

                % Remove the starting and ending quotes
                data = data.extractBetween(2, data.strlength()-1);
                obj.EnclosingDoubleQuotes = true;
            end
        end

        function sharedAppWriteControllerData = parseNumericData(obj, sharedAppWriteControllerData)
            % For potential numeric data types, evaluate the data to be
            % written. sharedAppWriteControllerData is the data value in
            % the Custom Data edit field. This function is invoked whenever
            % the "Data Format" value is a numeric precision. But the data
            % value itself is not numeric, but is a char.
            %
            % The logic is -
            %     1. If the data format is numeric, try to do an eval on
            %     the "Write Data" value provided. e.g. Write data value
            %     1:10 will evaluate to give the numbers 1-10.
            %
            %     2. If the eval fails, that means that the "Write Data"
            %     did not evaluate to a numeric value. So the content of
            %     the Write Data field is char/string type. e.g. hello, or
            %     foo.
            %
            %     3. If the eval was successful, that could also mean that
            %     the "Write Data" text evaluated to something which was
            %     not numeric. E.g. Let us consider having a function on
            %     the MATLAB path called "createStruct" that returns an
            %     empty struct. When createStruct is specified as the
            %     "Write Data" value, the eval succeeds but we get a struct
            %     back. There needs to be an additional check using the
            %     "validateWriteData" function to see if the final
            %     write data is a valid data to be written.

            tempsharedAppControllerData = string(sharedAppWriteControllerData);

            % To do a numeric eval, append "[" and "]" to the
            % beginning and end of the
            % sharedAppWriteControllerData value.
            if ~tempsharedAppControllerData.startsWith("[") && ...
                    ~tempsharedAppControllerData.endsWith("]")
                tempsharedAppControllerData = "[" + tempsharedAppControllerData + "]";
            end

            try
                % Try to do a numeric eval. This should work
                % for any numeric values, like [1:10]
                sharedAppWriteControllerData = eval(tempsharedAppControllerData);
            catch
                % Eval failed, meaning potentially non-numeric
                % data in the data section. Keep the data as is
                % (as a char array).
                obj.ValidNumericDataEval = false;
            end
            % This check is needed as the eval on the earlier line
            % might be evaluating a MATLAB function that returns back
            % incorrect data types/sizes.
            validateWriteData(obj, sharedAppWriteControllerData);
        end

        function validateWriteData(~, data)
            % Validate that the final data to be written is valid.
            % Only the following types are valid -
            %    1. Scalar string
            %    2. 1xn or nx1 numeric values
            %    3. 1xn char

            if isstring(data)
                if ~isscalar(data)
                    throw(MException(message("transportapp:toolstrip:write:WriteIncompatibleStringSize")));
                end
                return
            end

            if ischar(data) || (isnumeric(data) && isreal(data))
                rowSize = size(data, 1);
                columnSize = size(data, 2);

                % Throw for invalid char/numeric sizes, or for empty data.
                if isempty(data) || (rowSize > 1 && columnSize > 1)
                    throw(MException(message("transportapp:toolstrip:write:WriteIncompatibleSize")));
                end
                return
            end

            % Throw for all other sizes.
            throw(MException(message("transportapp:toolstrip:write:WriteInvalidType")));
        end
    end

    %% containers.Map Update Helper Methods
    methods (Access = {?matlabshared.transportapp.internal.utilities.ITestable})
        function resetWorkspaceVariableList(obj)
            keySet = obj.DataFormatDropDownOptions;
            valueSet = {string.empty, string.empty};
            obj.WorkspaceVariableList = containers.Map(keySet, valueSet);
        end

        function addNewValueToWorkspaceVariableList(obj, keySet, newVal)
            % Add a single new value to the given keys for
            % WorkspaceVariableList

            for key = keySet
                valSet = obj.WorkspaceVariableList(key);
                valSet(end+1) = newVal; %#ok<AGROW>
                valSet = sort(valSet);
                obj.WorkspaceVariableList(key) = valSet;
            end
        end

        function removeValueFromWorkspaceVariableList(obj, keyVal, variableNamesToRemove)
            % Remove the given variableNames from the valueSet for the
            % specified keys.

            variableNamesToRemove = sort(variableNamesToRemove);

            for key = keyVal
                valSet = obj.WorkspaceVariableList(key);

                if isempty(valSet)
                    continue
                end

                % Find all indices of valueSet that contain
                % variableNamesToRemove
                [~, idx] = intersect(valSet, variableNamesToRemove);

                if isempty(idx)
                    continue
                end

                % Remove these indices from the valSet and update the key
                % with the updated valueSet.
                valSet(idx') = [];
                obj.WorkspaceVariableList(key) = valSet;
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
