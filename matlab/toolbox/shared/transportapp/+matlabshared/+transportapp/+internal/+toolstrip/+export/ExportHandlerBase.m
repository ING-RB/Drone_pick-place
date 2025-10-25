classdef ExportHandlerBase < matlabshared.mediator.internal.Subscriber & ...
        matlabshared.mediator.internal.Publisher & ...
        matlabshared.transportapp.internal.utilities.ITestable & ...
        matlabshared.testmeasapps.internal.dialoghandler.DialogSource 

    % EXPORTHANDLERBASE handles the business logic for the Toolstrip Export
    % Section Controller class for operations that need to be performed
    % when user interacts with the View elements.
    % It contains logic that is common to Toolstrip Export Section
    % Controller classes for all Instrument Control Toolbox apps
    % (apps maintained by Instrument Control Toolbox).
    %
    % Logic contained - Initializing the workspace variable name for export,
    % Updating workspace variable name to valid name if user provided name was invalid,
    % Updating the workspace variable name after export operation completes,
    % Contains listeners and handlers for export operations - Exporting Communication
    % Log, Exporting selected row in Communication Log, Exporting Code Log.
    %
    % Client Export controller classes can create their own Export handler
    % class that inherits from this class to use the functionalities
    % mentioned above.

    % Copyright 2023-2024 The MathWorks, Inc.

    %% Hook methods
    methods
        function additionalSubscribeToMediatorPropertiesHook(~)
            % Can be used by apps to subscribe to additional observable
            % properties specific to that app.

            % Hook method - does nothing by default
        end

        function validateRowSelectedHook(~)
            % Can be used by apps to write app-specific code to validate
            % that a table row is selected.

            % Hook method - does nothing by default
        end

        function saveExportVariableHook(~, varName) %#ok<INUSD>
            % Can be used by apps to save the exported variable that
            % contains the data selected in the Communication Log table.

            % Hook method - does nothing by default
        end

        function saveValueToWorkspaceHook(~, varName) %#ok<INUSD>
            % Can be used by apps to save data selected in the
            % Communication Log table to the MATLAB workspace.

            % Hook method - does nothing by default
        end

        function showWarningMessageHook(~, warnObj) %#ok<INUSD>
            % Can be used by apps to write app-specific code for handling
            % warning messages.

            % Hook method - does nothing by default
        end

        function showErrorMessageHook(~, ex) %#ok<INUSD>
            % Can be used by apps to write app-specific code for handling
            % error messages.
            
            % Hook method - does nothing by default            
        end

        function validateTableNotEmptyHook(~)
            % Can be used by apps to write app-specific code to validate
            % non-empty Communication Log table.

            % Hook method - does nothing by default
        end

        function exportCodeLogPressed(obj, ~, ~)
            % Handler for when the "Export MATLAB Code" item is pressed.

            % Hook method - does nothing by default
        end
    end

    properties (SetObservable)
        ExportCommLog (1, 1) string
    end

    properties
        TransportName
    end

    properties (SetAccess = immutable)
        WorkspaceVarEditFieldName
    end

    properties (Constant)
        Constants = matlabshared.transportapp.internal.toolstrip.export.Constants
    end

    properties (Access = {?matlabshared.transportapp.internal.utilities.ITestable})
        % The handle to the ViewConfiguration instance containing the View.
        ViewConfiguration

        % Listeners for the View events
        ViewListeners = event.listener.empty

        % The list of MATLAB workspace variable names
        MATLABWorkspaceVariableList (1, :) string

        % The index number of the workspace variable. E.g. the number 1 in
        % mock_data1
        VariableNameSuffixIndex (1, 1) double {mustBeInteger, mustBePositive} = 1

        % For internal use, enable/disable the warning that the
        % Workspace Variable text needs to be updated to a new value as the
        % existing Workspace Variable text already exists as a MATLAB
        % Workspace variable.
        ShowWorkspaceVariableWarning (1, 1) logical = true

        % Flag to run the controller in production mode or unit-test mode
        % T: run the controller in production mode
        % F: run the controller in unit-test mode
        ProductionMode (1, 1) logical = true
    end

    properties (Dependent)
        View
    end

    %% Lifetime
    methods
        function obj = ExportHandlerBase(mediator, viewConfiguration, workspaceVarEditFieldName)
            arguments
                mediator matlabshared.mediator.internal.Mediator
                viewConfiguration matlabshared.transportapp.internal.utilities.viewconfiguration.IViewConfiguration
                workspaceVarEditFieldName (1, 1) string
            end
            obj@matlabshared.mediator.internal.Publisher(mediator);
            obj@matlabshared.mediator.internal.Subscriber(mediator);
            obj@matlabshared.testmeasapps.internal.dialoghandler.DialogSource(mediator);
            obj.ViewConfiguration = viewConfiguration;
            obj.WorkspaceVarEditFieldName = workspaceVarEditFieldName;

            obj.ProductionMode = isa(obj.ViewConfiguration, ...
                "matlabshared.transportapp.internal.utilities.viewconfiguration.ViewConfiguration");

            updateWorkspaceVariableList(obj);

            % Only for production mode
            if obj.ProductionMode
                obj.setupListeners();
            end
        end

        function delete(obj)
            delete(obj.ViewListeners);
        end
    end

    %% Implementing Subscriber Abstract methods
    methods
        function subscribeToMediatorProperties(obj, ~, ~)
            obj.subscribe('WorkspaceUpdated', ...
                @(src, event)obj.handleWorkspaceUpdated(event.AffectedObject.WorkspaceUpdated));
            obj.subscribe('ExportSuccessful', ...
                @(src, event)obj.updateWorkspaceVariableValueAfterExport());
            additionalSubscribeToMediatorPropertiesHook(obj);
        end
    end

    %% Listener Handler Functions
    methods (Access = {?matlabshared.transportapp.internal.utilities.ITestable})
        function workspaceVariableValueChanged(obj, ~, evt)
            % Handler for whenever a user changes the Workspace Variable
            % edit field value.

            newValTemp = string(evt.Data.NewValue);

            % Attempt to get a valid MATLAB variable name from the user
            % input. This does not change user input if the user input is
            % already a valid MATLAB variable name.
            newVal = ...
                matlab.lang.makeValidName(newValTemp, "Prefix", obj.TransportName);

            % If the new entry is "", newVal is converted to TransportName
            % by the matlab.lang.makeValidName function. TransportName
            % is the name of the transport, such as "serialport" or
            % "tcpclient". To avoid setting a variable name same as the
            % interface name, appending the VariableNameSuffix followed by
            % the VariableNameSuffixIndex to the name (i.e.
            % serialport_data<index>)
            if newVal == obj.TransportName
                newVal = newVal + obj.Constants.VariableNameSuffix + ...
                    string(num2str(obj.VariableNameSuffixIndex));
            end

            % Check if the Workspace variable entered is valid - i.e. it
            % does not match any other variable names in the MATLAB base
            % workspace. Get an updated Workspace Variable name from the
            % given user entered value.
            [newVal, index] = ...
                obj.getUpdatedWorkspaceVariableValue(obj.VariableNameSuffixIndex, newVal);
            obj.VariableNameSuffixIndex = index;

            if newVal ~= newValTemp
                % If the user's input was changed anyway, show a warning
                % message that their input was updated to a valid input.
                warnObj = matlabshared.testmeasapps.internal.dialoghandler.forms.WarningForm;
                warnObj.Identifier = "transportapp:toolstrip:export:InvalidMatlabVariableName";
                warnObj.Message = message(warnObj.Identifier, newVal).getString();
                showWarningMessageHook(obj, warnObj);
            end

            % Update the WorkspaceVariableEdit field value.
            obj.ViewConfiguration.setViewProperty(obj.WorkspaceVarEditFieldName, "Value", newVal);
        end

        function exportCommunicationLogPressed(obj, ~, ~)
            % Handler for when the "Export Communication Log" item is
            % pressed.
            try
                validateTableNotEmptyHook(obj);

                % Before exporting, ensure that the workspace variable is
                % valid, else update the Workspace Variable value.
                updateWorkspaceVariableValue(obj);

                % Send the Workspace Variable value to the Communication
                % Log table section to export the table contents.
                obj.ExportCommLog = ...
                    string(obj.ViewConfiguration.getViewProperty(obj.WorkspaceVarEditFieldName, "Value"));
            catch ex
                showErrorMessageHook(obj, ex);
            end
        end
    end

    methods
        function updateWorkspaceVariableValue(obj)
            % Ensure that there is no MATLAB Workspace variable that
            % matches the current Workspace Variable value. Update the
            % Workspace Variable value otherwise.

            editFieldValue = ...
                string(obj.ViewConfiguration.getViewProperty(obj.WorkspaceVarEditFieldName, "Value"));

            % Get the updated workspace variable value from the current
            % workspace variable value
            index = 1;
            [value, index] = obj.getUpdatedWorkspaceVariableValue(index);

            if index ~= 1
                obj.VariableNameSuffixIndex = index;
            end

            % Throw a warning that the workspace variable was changed
            % internally because of the same variable name existing in the
            % base MATLAB workspace.
            if obj.ShowWorkspaceVariableWarning && editFieldValue ~= value
                warnObj = matlabshared.testmeasapps.internal.dialoghandler.forms.WarningForm;
                warnObj.Identifier = ...
                    "transportapp:toolstrip:export:AlreadyExistingMatlabVariableName";
                warnObj.Message = ...
                    message(warnObj.Identifier, editFieldValue, value).getString();
                showWarningMessageHook(obj, warnObj);
            end
            obj.ViewConfiguration.setViewProperty(obj.WorkspaceVarEditFieldName, "Value", value);
        end

        function updateWorkspaceVariableValueAfterExport(obj)
            % After a successful export, update the workspace variable
            % value.

            % Ensure that the workspace Variable Warning does not get
            % thrown as we are making an expected update to the
            % WorkspaceVariableList.
            obj.ShowWorkspaceVariableWarning = false;
            cleanUp = onCleanup(@()resetShowWarning(obj));

            index = obj.VariableNameSuffixIndex;

            % Get the updated workspace variable value from the current
            % workspace variable value
            [newWorkspaceValue, index] = ...
                obj.getUpdatedWorkspaceVariableValue(index);

            obj.VariableNameSuffixIndex = index;
            obj.ViewConfiguration.setViewProperty(obj.WorkspaceVarEditFieldName, "Value", newWorkspaceValue);
        end

        function updateWorkspaceVariableList(obj)
            % Update the MATLABWorkspaceVariableList variable and check if the
            % Workspace Variable edit field needs to be updated. The
            % Workspace Variable edit field value will be updated if the
            % current workspace variable edit field value matches any of
            % the base MATLAB workspace variables.

            if obj.ProductionMode
                obj.MATLABWorkspaceVariableList = ...
                    sort(matlabshared.transportapp.internal.utilities.WorkspaceVariableHandler.getWorkspaceVariableNames());
            end
        end

        function resetShowWarning(obj)
            % Set the ShowWorkspaceVariableWarning back to its default
            % value.

            obj.ShowWorkspaceVariableWarning = true;
        end

        function exportSelectedRowPressed(obj, ~, ~)
            % Handler for when the "Export Selected Row" item is pressed.

            try
                validateTableNotEmptyHook(obj);
                validateRowSelectedHook(obj);

                % Before exporting, ensure that the workspace variable is
                % valid, else update the Workspace Variable value.
                updateWorkspaceVariableValue(obj);

                varName = ...
                    string(obj.ViewConfiguration.getViewProperty(obj.WorkspaceVarEditFieldName, "Value"));

                saveExportVariableHook(obj, varName);
                saveValueToWorkspaceHook(obj, varName);
            catch ex
                showErrorMessageHook(obj, ex);
            end
        end
    end

    %% Subscriber Handler Functions
    methods
        function handleWorkspaceUpdated(obj, workspaceUpdateInfo)
            % Handler for when the workspace variable is updated.

            arguments
                obj
                workspaceUpdateInfo matlabshared.transportapp.internal.utilities.forms.WorkspaceUpdateInfo
            end

            eventType = string(workspaceUpdateInfo.EventType);
            validEvents = [obj.Constants.WorkspaceCleared, obj.Constants.VariableDeleted, obj.Constants.VariableChanged, obj.Constants.VariableAdded];

            if any(eventType == validEvents)
                % If the Workspace Update Event is one of the categories
                % mentioned in validEvents above, update the Workspace
                % Variable List.

                updateWorkspaceVariableList(obj);
            end
        end
    end

    %% Initialization functions
    methods
        function setTransportName(obj, transportName)
            % Set the transport name for the app.

            obj.TransportName = transportName;
            setWorkspaceVariableName(obj);
        end

        function setWorkspaceVariableName(obj)
            % Set a valid Workspace Variable name in the
            % WorkspaceVarEditFieldName edit field.

            obj.ShowWorkspaceVariableWarning = false;
            cleanUp = onCleanup(@()resetShowWarning(obj));

            workspaceVariableName = obj.TransportName + obj.Constants.VariableNameSuffix ...
                + num2str(obj.VariableNameSuffixIndex);

            obj.ViewConfiguration.setViewProperty(obj.WorkspaceVarEditFieldName, "Value", workspaceVariableName);

            % If the default Workspace Variable value already exists in the
            % MATLAB workspace, update the Workspace Variable value.
            updateWorkspaceVariableValue(obj);
        end
    end

    %% Other Helper Functions
    methods (Access = {?matlabshared.transportapp.internal.utilities.ITestable})
        function [value, index] = getUpdatedWorkspaceVariableValue(obj, index, varargin)
            % Whenever there needs to be a change in the workspace variable
            % value, get an updated workspace variable name which is not
            % present in the current MATLAB workspace.

            if isempty(varargin)
                tempValue = ...
                    string(obj.ViewConfiguration.getViewProperty(obj.WorkspaceVarEditFieldName, "Value"));
            else
                tempValue = varargin{1};
            end

            updateWorkspaceVariableList(obj);

            % If the Workspace Variable is already present in the MATLAB
            % Workspace.
            while ismember(tempValue, obj.MATLABWorkspaceVariableList)

                % Find all occurrences of the suffix
                loc = strfind(tempValue, obj.Constants.VariableNameSuffix);

                % Suffix not found. Append the suffix plus index to the end of
                % the name and try again.
                if isempty(loc)
                    [tempValue, index] = resetTempValue(obj, tempValue);
                    continue
                end

                % Suffix found. Get the remaining text after the suffix and
                % see if this remaining text is a valid numeric value.
                loc = loc(end);
                lengthSuffix = strlength(obj.Constants.VariableNameSuffix);
                indexStr = str2double(extractAfter(tempValue, (loc + lengthSuffix - 1)));

                % Not numeric - append the suffix and index string to the
                % value and try again.
                if isnan(indexStr)
                    [tempValue, index] = resetTempValue(obj, tempValue);
                    continue
                end

                % Update the numeric value after the text by 1
                index = indexStr + 1;

                % Get the text before the suffix. E.g. "mock_data1" will
                % return "mock" if "_data" is the suffix.
                tempValue = extractBefore(tempValue, loc);

                % Using this new text, append the suffix and the new updated
                % index.
                tempValue = tempValue + obj.Constants.VariableNameSuffix + string(num2str(index));
            end
            value = tempValue;
        end

        % NESTED FUNCTION
        function [tempValue, index] = resetTempValue(obj, tempValue)
            % Create a new workspace variable value using the
            % VariableNameSuffix and the index number. Also, initialize the
            % index number to 1.

            index = 1;
            tempValue = tempValue + obj.Constants.VariableNameSuffix + string(num2str(index));
        end
    end

    %% Private Helper Functions
    methods (Access = private)
        function setupListeners(obj)
            % Set up listeners for the View events.

            obj.ViewListeners(end+1) = listener(obj.View, "WorkspaceVariableChanged", ...
                @(src, evt)obj.workspaceVariableValueChanged(src, evt));

            obj.ViewListeners(end+1) = listener(obj.View, "ExportSelectedRowPressed", ...
                @(src, evt)obj.exportSelectedRowPressed(src, evt));

            obj.ViewListeners(end+1) = listener(obj.View, "ExportCommLogPressed", ...
                @(src, evt)obj.exportCommunicationLogPressed(src, evt));

            obj.ViewListeners(end+1) = listener(obj.View, "ExportCodeLogPressed", ...
                @(src, evt)obj.exportCodeLogPressed(src, evt));
        end
    end

    %% Getters and Setters
    methods
        function value = get.View(obj)
            value = obj.ViewConfiguration.View;
        end
    end
end
