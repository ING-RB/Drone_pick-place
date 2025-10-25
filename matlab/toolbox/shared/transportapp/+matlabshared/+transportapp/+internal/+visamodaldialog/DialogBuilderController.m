classdef DialogBuilderController < matlabshared.transportapp.internal.visamodaldialog.IControllerFunctionalities
    %DIALOGBUILDERCONTROLLER is the controller class that contains the
    %operations that need to happen on the View.

    % Copyright 2022-2024 The MathWorks, Inc.

    properties
        ViewConfiguration
        ViewListeners = event.listener.empty
        Closeable = false
        ErrorObj

        VisaIdentifier
    end

    properties (SetAccess = immutable, GetAccess = private)
        % Flag that specifies whether we are in production mode or unit
        % test mode.
        %
        % true - Production Mode
        %
        % false - Unit Test Mode
        ProductionMode (1, 1) logical
    end

    properties (Constant)
        % Names of View Edit fields that hold string type values.
        StringTypeEditFieldNames (1, :) string = ["IPAddressEditField", "IdentificationEditField"]

        ConnectionFailedColor = "--mw-color-error"
        ConnectionSuccessfulColor = "--mw-color-success"
    end

    properties (SetObservable)
        VisaConnectionAndIdentification
    end

    methods
        function obj = DialogBuilderController(viewConfiguration)
            arguments
                viewConfiguration matlabshared.transportapp.internal.utilities.viewconfiguration.IViewConfiguration
            end

            obj.ViewConfiguration = viewConfiguration;
            obj.ProductionMode = isa(viewConfiguration, "matlabshared.transportapp.internal.visamodaldialog.DialogBuilderController");
        end
    end

    methods
        function setupListeners(obj, form)
            view = obj.ViewConfiguration.View;
            obj.ViewListeners(end+1) = listener(view, "ConfirmButtonPushed", ...
                @(src, evt)obj.confirmButtonPressed(src, evt));

            obj.ViewListeners(end+1) = listener(view, "CancelButtonPushed", ...
                @(src, evt)obj.enableCloseable(src, evt));

            obj.ViewListeners(end+1) = listener(view, "TestConnectionButtonPushed", ...
                @(src, evt)obj.testConnectionButtonPressed(src, evt));

            obj.ViewListeners(end+1) = listener(view, "GenerateResourceButtonPushed", ...
                form.GenerateResourceFcnHandle);

            obj.ViewListeners(end+1) = listener(view, "ConfigurationValueChanged", ...
                @(src, evt)obj.resourceConfigurationChanged(src, evt));

            obj.ViewListeners(end+1) = listener(view, "Closeable", ...
                'PostSet', @(src,event)obj.enableCloseable());
        end
    end

    methods
        function populateResourceString(obj, val)
            arguments
                obj
                val (1, 1) string
            end
            obj.ViewConfiguration.setViewProperty("ResourceNameEditField", "Value", val);
        end

        function setFieldEnableDisableState(obj, state)
            % Helper function to either enable/disable the modal window
            % elements.

            view = obj.getView();

            allEditFields = matlabshared.transportapp.internal.visamodaldialog.DialogBuilder.UserEditableEditFields + "EditField";
            allButtons = ["TestConnectionButton", "GenerateResourceButton", "CancelButton"];
            allFields = [allEditFields, allButtons];
            for field = allFields
                if ~isempty(view.(field))
                    obj.ViewConfiguration.setViewProperty(field, "Enable", state);
                end
            end
        end

        function setTestConnectionDisableState(obj)
            % Disable all modal window elements when a test connection is
            % to start.

            obj.setFieldEnableDisableState("off");
        end

        function resetTestConnectionDisableState(obj)
            % Enable all modal window elements when a test connection event
            % is done.

            obj.VisaIdentifier = [];
            obj.setFieldEnableDisableState("on");
        end

        function testConnectionButtonPressed(obj, ~, ~)
            % Handler function for when the test connection button is
            % pressed.

            cleanup = onCleanup(@()obj.resetTestConnectionDisableState);
            obj.setTestConnectionDisableState();
            obj.clearValidateAndTestSection();

            % Pause(0) is needed for the section's enable/disable state to
            % be updated.
            %
            % NOTE: This is only needed for Production Mode where there are
            % UI elements involved. For the Unit Test Mode, the UI elements
            % are mocked out, so no pause needed.
            if obj.ProductionMode
                pause(0);
            end

            resourceStringName = message("transportapp:visadevapp:ResourceName").string;
            resourceStringValue = ...
                string(obj.ViewConfiguration.getViewProperty("ResourceNameEditField", "Value"));

            identificationStringName = message("transportapp:visadevapp:IdentificationName").string;
            identificationStringValue = ...
                string(obj.ViewConfiguration.getViewProperty("IdentificationEditField", "Value"));

            try
                % Verify if any of the edit field values are empty.

                allNames = [resourceStringName, identificationStringName];
                allValues = [resourceStringValue, identificationStringValue];
                validateNonEmptyEditableField(obj, allNames, allValues);
            catch ex
                setErrorObj(obj, ex);
                return
            end

            if isempty(obj.VisaIdentifier)
                obj.VisaIdentifier = transportapp.visadev.internal.VisadevIdentification;
            end

            id = obj.VisaIdentifier.identify(resourceStringValue, identificationStringValue);

            if ~isempty(id.Error)
                connectionFailedViewUpdates(obj, id);
                return
            end

            % Connection Successful
            connectionSuccessfulViewUpdates(obj, id);

            %% NESTED FUNCTION
            function validateNonEmptyEditableField(~, names, values)
                % Throw if any of the edit field values are empty.

                for i = 1 : length(names)
                    name = names(i);
                    value = values(i);

                    if value == ""
                        mEx = MException(message("transportapp:visadevapp:EmptyTestField", name));
                        throwAsCaller(mEx);
                    end
                end
            end

            %% NESTED FUNCTION
            function connectionFailedViewUpdates(obj, id)
                % Handler for a failed connection connection section
                % update.

                msg = string(message("transportapp:visadevapp:ConnectionFailedLabelName").getString);
                obj.ViewConfiguration.setViewPropertyForTheming("ConnectionMessage", "FontColor", obj.ConnectionFailedColor);
                obj.ViewConfiguration.setViewProperty("ConnectionMessage", "Text", msg);

                msg = string(message("transportapp:visadevapp:ConnectionFailed", id.Error.message).getString);
                obj.ViewConfiguration.setViewProperty("ConnectionStatusTextArea", ...
                    "Value", msg);
            end

            %% NESTED FUNCTION
            function connectionSuccessfulViewUpdates(obj, id)
                % Handler for a successful connection connection section
                % update.

                msg = string(message("transportapp:visadevapp:ConnectionSuccessLabelName").getString);
                obj.ViewConfiguration.setViewPropertyForTheming("ConnectionMessage", "FontColor", obj.ConnectionSuccessfulColor);
                obj.ViewConfiguration.setViewProperty("ConnectionMessage", "Text", msg);

                % Update Model, Vendor ID, and Connection Status

                if id.IdentificationResponse == ""
                    % If the connection was successful but the
                    % identification failed, add that information to the
                    % connection status text.
                    identicationResponse = message( ...
                        "transportapp:visadevapp:ConnectionSuccessfulIdentificationFailed").string;
                else
                    % If both connection and identification were
                    % successful, add the instrument response to the
                    % identification command to the connection status text.
                    identicationResponse = id.IdentificationResponse;
                end
                msg = message("transportapp:visadevapp:ConnectionSuccessful").string + newline + ...
                    identicationResponse;

                obj.ViewConfiguration.setViewProperty("ConnectionStatusTextArea", "Value", msg);
                obj.ViewConfiguration.setViewProperty("VendorIDEditField", "Value", id.Vendor);
                obj.ViewConfiguration.setViewProperty("ModelEditField", "Value", id.Model);

                % Enable the "Confirm Button"
                obj.ViewConfiguration.setViewProperty("ConfirmButton", "Enable", "on");
            end
        end

        function clearValidateAndTestSection(obj)
            % When any changes are made to the Generate Resource String
            % section or when the Test Connection button is pressed, clear
            % existing values for the Test Connection Section.

            viewProps = ...
                ["ModelEditField", "VendorIDEditField", "ConnectionStatusTextArea"];
            for prop = viewProps
                obj.ViewConfiguration.setViewProperty(prop, "Value", "");
            end
            obj.ViewConfiguration.setViewProperty("ConnectionMessage", "Text", "");
            obj.ViewConfiguration.setViewProperty("ConnectionMessage", "FontColor", "black");
        end

        function resourceConfigurationChanged(obj, ~, evt)
            % Handler function for when any of the Generate Resource String
            % section or Identification Edit field value changes.

            newVal = evt.Data.NewValue;
            oldVal = evt.Data.OldValue;
            editFieldName = evt.Data.EditFieldName;

            % Remove quotes from around the string.
            newVal = replace(newVal, ["'", """"], "");

            % Remove trailing and leading whitespaces
            newVal = strip(newVal);

            if newVal == oldVal
                % Need to reset the field to the old value if the new value
                % is just extra spaces or quotes around the old value.
                obj.ViewConfiguration.setViewProperty(editFieldName, "Value", oldVal);
                return
            end

            % Validate Resource
            try
                obj.validateNewValue(editFieldName, newVal)
            catch ex

                % Errored - set value back to the old value (the previous
                % known good value).
                obj.ViewConfiguration.setViewProperty(editFieldName, "Value", oldVal);

                % Show the error Dialog
                obj.setErrorObj(ex);

                % Do not erase other existing modal values by early return.
                return
            end

            % Set the new value
            obj.ViewConfiguration.setViewProperty(editFieldName, "Value", newVal);

            % Clear resource name
            clearResourceNameEditField(obj, editFieldName);
            
            % Clear all fields for validate and test section
            clearValidateAndTestSection(obj);

            % Disable the "Confirm Button"
            obj.ViewConfiguration.setViewProperty("ConfirmButton", "Enable", "off");

            %% NESTED FUNCTION
            function clearResourceNameEditField(obj, editFieldName)
                % Clear the resource name edit field for all edit field
                % changes, except the IdentificationEditField.

                if editFieldName ~= "IdentificationEditField"
                    obj.ViewConfiguration.setViewProperty("ResourceNameEditField", "Value", "");
                end
            end
        end

        function validateNewValue(obj, editFieldName, newVal)
            % Check that the new edit field value is valid.

            arguments
                obj
                editFieldName (1, 1) string
                newVal (1, 1) string
            end

            % No further validation needed if edit field is string-valued -
            % e.g. IP Address, or if the newVal is ""
            if isStringEditField(obj, editFieldName) || newVal == ""
                return
            end

            editFieldFriendlyName = obj.getFriendlyNameForEditField(editFieldName);
            newVal = str2double(newVal);
            if isnan(newVal)
                throwAsCaller(MException(message("transportapp:visadevapp:ValueMustBePositiveInteger", editFieldFriendlyName)));
            end

            try
                validateattributes(newVal, "numeric", ["nonnegative", "integer", "finite"], "", editFieldFriendlyName);
            catch
                throwAsCaller(MException(message("transportapp:visadevapp:ValueMustBePositiveInteger", editFieldFriendlyName)));
            end

            %% NESTED FUNCTION
            function val = isStringEditField(obj, editFieldName)
                % IPAddressEditField and IdentificationEditField are the
                % only string-valued edit field. The rest (for
                % BoardNumber, Port, or DeviceID) are all numeric-valued.

                val = any(editFieldName == obj.StringTypeEditFieldNames);
            end
        end

        function enableCloseable(obj, ~, ~)
            % Handler that allows closing of the modal dialog window. Sets
            % the Closeable flag to true.

            obj.Closeable = true;
        end

        function val = getFriendlyNameForEditField(~, editFieldName)
            % Get the valid user-facing name for the edit field value.

            editFieldName = editFieldName + "Name";
            editFieldName = replace(editFieldName, "EditField", "");
            val = string(message("transportapp:visadevapp:" + editFieldName).getString);
        end

        function confirmButtonPressed(obj, ~, ~)
            % Handler for when the Confirm button is pressed.

            obj.VisaConnectionAndIdentification = getVisaConnectionIdentification(obj);
            enableCloseable(obj);

            %% NESTED FUNCTION
            function form = getVisaConnectionIdentification(obj)
                % Create a form class containing information about the
                % successful connection - The ResourceName used for
                % testing, the model, and the vendor ID.

                form = matlabshared.transportapp.internal.visamodaldialog.ConnectionIdentificationForm;
                form.ResourceName = obj.ViewConfiguration.getViewProperty("ResourceNameEditField", "Value");
                form.Model = obj.ViewConfiguration.getViewProperty("ModelEditField", "Value");
                form.Vendor = obj.ViewConfiguration.getViewProperty("VendorIDEditField", "Value");
                form.Identification = obj.ViewConfiguration.getViewProperty("IdentificationEditField", "Value");
            end
        end

        function view = getView(obj)
            % Get the view from the View Configuration instance.
            view = obj.ViewConfiguration.View;
        end

        function close(obj)
            % Close the view.
            view = obj.getView();

            % Close the UI Figure instance of the view.
            view.close();
        end

        function construct(obj, form)
            % Construct the different view elements.
            arguments
                obj
                form (1, 1) matlabshared.transportapp.internal.visamodaldialog.DialogBuilderForm
            end
            builder = obj.getView();
            builder.createFigure(form.ResourceType);

            builder.createGenerateResourcePanel();
            builder.createTestConnectionPanel();

            % Generate Resource Section
            builder.createBoardNumber(form.BoardNumberRowIndex);
            builder.createIPAddress(form.IPAddressRowIndex);
            builder.createDeviceID(form.DeviceIDRowIndex);
            builder.createPort(form.PortRowIndex);

            builder.createGenerateResourceButton(form.GenerateResourceRowIndex);
            builder.createResourceName(form.ResourceNameRowIndex);

            % Test Connection Section
            builder.createIdentification();
            builder.createTestConnectionButton();
            builder.createConnectionMessage();
            builder.createModel();
            builder.createVendorID();
            builder.createConnectionStatus();

            builder.createCancelButton();
            builder.createConfirmButton();

            builder.createListeners();
        end

        function setErrorObj(obj, errorObj)
            obj.ErrorObj = errorObj;

            view = obj.getView();
            showError(view, errorObj.message);
        end
    end
end
