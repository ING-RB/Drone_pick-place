classdef DialogBuilder < controllib.ui.internal.dialog.AbstractDialog & handle
    %DIALOGBUILDER class is the generic View class that creates the
    %different dialog window types - Socket, VXI-11, and HiSLIP.

    % Copyright 2022-2023 The MathWorks, Inc.

    properties (Constant)
        % List of Edit Fields in the Resource Generation Section
        UserEditableEditFields (1, :) string = ["IPAddress", "DeviceID", ...
            "BoardNumber", "Port", "Identification"]

        ErrorTitle (1, 1) string = ...
            message("transportapp:utilities:ErrorDialogTitle", message("transportapp:visadevapp:DisplayName").getString).getString
    end

    properties (SetAccess = immutable)
        Constants
    end

    properties
        BaseGridLayout

        GenerateResourceNamePanel
        GenerateResourceNameUIGridLayout

        TestConnectionPanel
        TestConnectionUIGridLayout

        BoardNumberLabel
        BoardNumberEditField

        IPAddressLabel
        IPAddressEditField

        DeviceIDLabel
        DeviceIDEditField

        PortLabel
        PortEditField

        ResourceNameLabel
        ResourceNameEditField

        ConnectionMessage

        IdentificationLabel
        IdentificationEditField

        ModelLabel
        ModelEditField

        VendorIDLabel
        VendorIDEditField

        ConnectionStatusLabel
        ConnectionStatusTextArea

        GenerateResourceButton
        CancelButton
        ConfirmButton
        TestConnectionButton
    end

    properties (SetObservable)
        Closeable (1, 1) logical = false
    end

    events
        CancelButtonPushed
        TestConnectionButtonPushed
        ConfirmButtonPushed
        GenerateResourceButtonPushed
        ConfigurationValueChanged
    end

    methods
        function obj = DialogBuilder(constants)
            obj.Constants = constants;
        end
    end

    %% Builder Methods
    methods
        function createFigure(obj, resourceType)
            arguments
                obj
                resourceType (1, 1) string
            end
            import matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory
            import matlabshared.transportapp.internal.utilities.forms.AppSpaceGridLayout

            obj.show();
            obj.UIFigure.WindowStyle = "normal";
            obj.UIFigure.CloseRequestFcn = @obj.closeWindow;

            % Set the modal dialog handle to a persistent value that can
            % provide access to the dialog window outside of the class/app.
            matlabshared.transportapp.internal.visamodaldialog.getDialogHandle(obj.UIFigure);

            obj.CloseMode = "destroy";
            movegui(obj.UIFigure, "center");
            obj.UIFigure.Name = message("transportapp:visadevapp:FigureWindowName", resourceType).getString;
            obj.UIFigure.Position(3:4) = [obj.Constants.FigureWidth obj.Constants.FigureHeight];

            obj.BaseGridLayout = ...
                AppSpaceElementsFactory.createGridLayout(obj.UIFigure, obj.Constants.BaseGridLayoutProperties);
        end

        function createGenerateResourcePanel(obj)
            import matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory
            import matlabshared.transportapp.internal.utilities.forms.AppSpaceGridLayout

            obj.GenerateResourceNamePanel = AppSpaceElementsFactory.createPanel(...
                obj.BaseGridLayout, AppSpaceGridLayout(1, [1, 5]), obj.Constants.GenerateResourcePanelProperties);
            obj.GenerateResourceNameUIGridLayout = ...
                AppSpaceElementsFactory.createGridLayout(obj.GenerateResourceNamePanel, obj.Constants.GenerateResourcePanelGridLayoutProperties);
        end

        function createTestConnectionPanel(obj)
            import matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory
            import matlabshared.transportapp.internal.utilities.forms.AppSpaceGridLayout

            obj.TestConnectionPanel = AppSpaceElementsFactory.createPanel(...
                obj.BaseGridLayout, AppSpaceGridLayout(2, [1, 5]), obj.Constants.TestConnectionPanelProperties);
            obj.TestConnectionUIGridLayout = ...
                AppSpaceElementsFactory.createGridLayout(obj.TestConnectionPanel, obj.Constants.TestConnectionPanelGridLayoutProperties);
        end

        function createBoardNumber(obj, rowIndex)
            import matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory
            import matlabshared.transportapp.internal.utilities.forms.AppSpaceGridLayout

            if isempty(rowIndex)
                return
            end

            obj.BoardNumberLabel = AppSpaceElementsFactory.createLabel( ...
                obj.GenerateResourceNameUIGridLayout, AppSpaceGridLayout(rowIndex, 1), obj.Constants.BoardNumberLabelProperties);

            obj.BoardNumberEditField = AppSpaceElementsFactory.createEditField( ...
                obj.GenerateResourceNameUIGridLayout, AppSpaceGridLayout(rowIndex, [2, 5]), obj.Constants.BoardNumberEditFieldProperties);
        end

        function createIPAddress(obj, rowIndex)
            import matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory
            import matlabshared.transportapp.internal.utilities.forms.AppSpaceGridLayout

            if isempty(rowIndex)
                return
            end

            obj.IPAddressLabel = AppSpaceElementsFactory.createLabel( ...
                obj.GenerateResourceNameUIGridLayout, AppSpaceGridLayout(rowIndex, 1), obj.Constants.IPAddressLabelProperties);

            obj.IPAddressEditField = AppSpaceElementsFactory.createEditField( ...
                obj.GenerateResourceNameUIGridLayout, AppSpaceGridLayout(rowIndex, [2, 5]), obj.Constants.IPAddressEditFieldProperties);
        end

        function createDeviceID(obj, rowIndex)
            import matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory
            import matlabshared.transportapp.internal.utilities.forms.AppSpaceGridLayout

            if isempty(rowIndex)
                return
            end

            obj.DeviceIDLabel = AppSpaceElementsFactory.createLabel( ...
                obj.GenerateResourceNameUIGridLayout, AppSpaceGridLayout(rowIndex, 1), obj.Constants.DeviceIDLabelProperties);

            obj.DeviceIDEditField = AppSpaceElementsFactory.createEditField( ...
                obj.GenerateResourceNameUIGridLayout, AppSpaceGridLayout(rowIndex, [2, 5]), obj.Constants.DeviceIDEditFieldProperties);
        end

        function createPort(obj, rowIndex)
            import matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory
            import matlabshared.transportapp.internal.utilities.forms.AppSpaceGridLayout

            if isempty(rowIndex)
                return
            end

            obj.PortLabel = AppSpaceElementsFactory.createLabel( ...
                obj.GenerateResourceNameUIGridLayout, AppSpaceGridLayout(rowIndex, 1), obj.Constants.PortLabelProperties);

            obj.PortEditField = AppSpaceElementsFactory.createEditField( ...
                obj.GenerateResourceNameUIGridLayout, AppSpaceGridLayout(rowIndex, [2, 5]), obj.Constants.PortEditFieldProperties);
        end

        function createGenerateResourceButton(obj, rowIndex)
            import matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory
            import matlabshared.transportapp.internal.utilities.forms.AppSpaceGridLayout

            if isempty(rowIndex)
                return
            end

            obj.GenerateResourceButton = AppSpaceElementsFactory.createButton( ...
                obj.GenerateResourceNameUIGridLayout, AppSpaceGridLayout(rowIndex, [4, 5]), obj.Constants.GenerateButtonProperties);
        end

        function createResourceName(obj, rowIndex)
            import matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory
            import matlabshared.transportapp.internal.utilities.forms.AppSpaceGridLayout

            if isempty(rowIndex)
                return
            end

            obj.ResourceNameLabel = AppSpaceElementsFactory.createLabel( ...
                obj.GenerateResourceNameUIGridLayout, AppSpaceGridLayout(rowIndex, 1), obj.Constants.ResourceNameLabelProperties);

            obj.ResourceNameEditField = AppSpaceElementsFactory.createEditField( ...
                obj.GenerateResourceNameUIGridLayout, AppSpaceGridLayout(rowIndex, [2, 5]), obj.Constants.ResourceNameEditFieldProperties);
        end

        function createTestConnectionButton(obj)
            import matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory
            import matlabshared.transportapp.internal.utilities.forms.AppSpaceGridLayout

            obj.TestConnectionButton = AppSpaceElementsFactory.createButton( ...
                obj.TestConnectionUIGridLayout, AppSpaceGridLayout(2, [4, 5]), obj.Constants.TestConnectionButtonProperties);
        end

        function createConnectionMessage(obj)
            import matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory
            import matlabshared.transportapp.internal.utilities.forms.AppSpaceGridLayout

            obj.ConnectionMessage = AppSpaceElementsFactory.createLabel( ...
                obj.TestConnectionUIGridLayout, AppSpaceGridLayout(7, [2, 5]), obj.Constants.ConnectionMessageLabelProperties);
        end

        function createIdentification(obj)
            import matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory
            import matlabshared.transportapp.internal.utilities.forms.AppSpaceGridLayout

            obj.IdentificationLabel = AppSpaceElementsFactory.createLabel( ...
                obj.TestConnectionUIGridLayout, AppSpaceGridLayout(1, 1), obj.Constants.IdentificationLabelProperties);

            obj.IdentificationEditField = AppSpaceElementsFactory.createEditField( ...
                obj.TestConnectionUIGridLayout, AppSpaceGridLayout(1, [2, 5]), obj.Constants.IdentificationEditFieldProperties);
        end

        function createModel(obj)
            import matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory
            import matlabshared.transportapp.internal.utilities.forms.AppSpaceGridLayout

            obj.ModelLabel = AppSpaceElementsFactory.createLabel( ...
                obj.TestConnectionUIGridLayout, AppSpaceGridLayout(3, 1), obj.Constants.ModelLabelProperties);

            obj.ModelEditField = AppSpaceElementsFactory.createEditField( ...
                obj.TestConnectionUIGridLayout, AppSpaceGridLayout(3, [2, 5]), obj.Constants.ModelEditFieldProperties);
        end

        function createVendorID(obj)
            import matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory
            import matlabshared.transportapp.internal.utilities.forms.AppSpaceGridLayout

            obj.VendorIDLabel = AppSpaceElementsFactory.createLabel( ...
                obj.TestConnectionUIGridLayout, AppSpaceGridLayout(4, 1), obj.Constants.VendorIDLabelProperties);

            obj.VendorIDEditField = AppSpaceElementsFactory.createEditField( ...
                obj.TestConnectionUIGridLayout, AppSpaceGridLayout(4, [2, 5]), obj.Constants.VendorIDEditFieldProperties);
        end

        function createConnectionStatus(obj)
            import matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory
            import matlabshared.transportapp.internal.utilities.forms.AppSpaceGridLayout

            obj.ConnectionStatusLabel = AppSpaceElementsFactory.createLabel( ...
                obj.TestConnectionUIGridLayout, AppSpaceGridLayout([5, 6], 1), obj.Constants.ConnectionStatusLabelProperties);

            obj.ConnectionStatusTextArea = AppSpaceElementsFactory.createTextArea( ...
                obj.TestConnectionUIGridLayout, AppSpaceGridLayout([5, 6], [2, 5]), obj.Constants.ConnectionStatusTextAreaProperties);
        end

        function createCancelButton(obj)
            import matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory
            import matlabshared.transportapp.internal.utilities.forms.AppSpaceGridLayout

            obj.CancelButton = AppSpaceElementsFactory.createButton( ...
                obj.BaseGridLayout, AppSpaceGridLayout(3, 5), obj.Constants.CancelButtonProperties);
        end

        function createConfirmButton(obj)
            import matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory
            import matlabshared.transportapp.internal.utilities.forms.AppSpaceGridLayout

            obj.ConfirmButton = AppSpaceElementsFactory.createButton( ...
                obj.BaseGridLayout, AppSpaceGridLayout(3, 4), obj.Constants.ConfirmButtonProperties);
        end
    end

    %% Listeners and their handlers
    methods
        function createListeners(obj)
            % For buttons
            obj.CancelButton.ButtonPushedFcn = @obj.cancelButtonPushed;
            obj.TestConnectionButton.ButtonPushedFcn = @obj.testConnectionButtonPushed;
            obj.ConfirmButton.ButtonPushedFcn = @obj.confirmButtonPushed;
            obj.GenerateResourceButton.ButtonPushedFcn = @obj.generateResourceButtonPushed;

            % For edit fields
            for prop = obj.UserEditableEditFields
                propEditField = prop + "EditField";
                if ~isempty(obj.(propEditField))
                    obj.(propEditField).ValueChangedFcn = @(src, evt)obj.configurationValueChanged(src, evt, propEditField);
                end
            end
        end

        function cancelButtonPushed(obj, ~, ~)
            obj.notify("CancelButtonPushed");
        end

        function testConnectionButtonPushed(obj, ~, ~)
            obj.notify("TestConnectionButtonPushed");
        end

        function confirmButtonPushed(obj, ~, ~)
            obj.notify("ConfirmButtonPushed");
        end

        function generateResourceButtonPushed(obj, ~, ~)
            form = matlabshared.transportapp.internal.visamodaldialog.ResourceStringForm;
            for prop = obj.UserEditableEditFields
                propEditField = prop + "EditField";

                if propEditField == "IdentificationEditField" || isempty(obj.(propEditField))
                    continue
                end

                form.(prop) = string(obj.(propEditField).Value);
            end

            evtData = matlabshared.transportapp.internal.utilities.EventData(form);
            obj.notify("GenerateResourceButtonPushed", evtData);
        end

        function configurationValueChanged(obj, ~, evt, propEditField)
            data.OldValue = string(evt.PreviousValue);
            data.NewValue = string(evt.Value);
            data.EditFieldName = propEditField;
            evtData = matlabshared.transportapp.internal.utilities.EventData(data);
            obj.notify("ConfigurationValueChanged", evtData);
        end
    end

    %% Other methods
    methods
        function closeWindow(obj, ~, ~)
            obj.Closeable = true;
        end

        function showError(obj, msg)
            arguments
                obj
                msg (1, 1) string
            end
            uialert(obj.UIFigure, msg, obj.ErrorTitle);
        end
    end
end

