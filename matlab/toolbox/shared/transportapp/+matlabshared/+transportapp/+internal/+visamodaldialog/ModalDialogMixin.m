classdef (Abstract) ModalDialogMixin < handle
    %MODALDIALOGMIXIN Contains the logic for launching and tearing down the
    % generate VISA resource modal dialog.

    % Copyright 2023 The MathWorks, Inc.

    properties
        % The handle to the ModalDialog instance
        ModalDialog

        % The listener for when the VisaConnectionAndIdentification
        % property on the Dialog controller is set.
        VisaIdentificationListener

        % The Visa Connection and Identification details after a test
        % connection event, or for the connection details being imported
        % from the Modal Dialog.
        VisaIdentificationForm

        % The handle to the Hardware Manager dialog parent.
        DialogParent
    end

    properties (Constant)
        TypeFcn = @(interfaceType) string(message("transportapp:visadevapp:" + interfaceType).getString)
    end

    properties (Dependent, SetAccess = immutable)
        Closeable
    end

    properties (Access = {?matlabshared.transportapp.internal.visamodaldialog.ModalDialogMixin, ...
            ?matlabshared.transportapp.internal.utilities.ITestable})
        % Flag to indicate whether running in unit test mode or production
        % mode.
        ProductionMode (1, 1) logical = true
    end

    methods
        function val = generateResourceNameValuesFcn(obj, paramMap)
            % Generate and create the modal dialog for resource string
            % generation.

            val = [];
            cleanup = onCleanup(@()obj.cleanupProperties);

            % Get the instance of the modal dialog to be created. The value
            % of ModalDialog is only set in this method. For all the other
            % methods, it is empty (this is taken care of by the onCleanup
            % method - cleanupProperties). We need to check whether the
            % value returned by the getModalDialogInstance is of type
            % IModalDialogFunctionality here - everywhere else in the
            % class, the value of ModalDialog is [].
            obj.ModalDialog = getModalDialogInstance(obj, paramMap);

            % Check for the ModalDialog to be of type
            % IModalDialogFunctionality, even if it is called from the
            % local nested getModalDialogInstance method. This is to ensure
            % that if a new dialog type is created and returned in the
            % future from getModalDialogInstance, it still needs to be of
            % type IModalDialogFunctionality for it to be useable by the
            % VisaDescriptor class.
            mustBeA(...
                obj.ModalDialog, "matlabshared.transportapp.internal.visamodaldialog.IModalDialogFunctionality");

            % Set the App busy.
            obj.setAppStateBusy();

            if obj.ProductionMode
                % Set the listener for whenever the confirm button is
                % pressed.
                obj.VisaIdentificationListener = listener(obj.ModalDialog.Controller, "VisaConnectionAndIdentification", ...
                    "PostSet", ...
                    @(src, evt)obj.visaConnectionPropertiesSetFcn(src, evt));

                % Bring up the modal dialog figure window for resource
                % generation.
                obj.ModalDialog.construct();

                % Wait for "Confirm", "Cancel", or the "x" button on the modal
                % dialog window.
                while ~obj.Closeable
                    pause(0.01);
                end

                % Once closeable, disable the listener.
                obj.VisaIdentificationListener.Enabled = false;
            end

            % Update the Visa Explorer modal tab with the values confirmed
            % from the modal dialog window.
            setIdentificationProperties(obj, paramMap);

            % Destroy the modal dialog window.
            obj.ModalDialog.teardown();

            %% NESTED FUNCTION
            function modalDialog = getModalDialogInstance(~, pMap)
                % Get the dialog type window type based on the Interface
                % Type selected by the user.

                import matlabshared.transportapp.internal.visamodaldialog.ModalDialogMixin
                interfaceType = string(pMap("Interface").NewValue);

                switch interfaceType
                    case ModalDialogMixin.getTypes("VXI11")
                        modalDialog = matlabshared.transportapp.internal.visamodaldialog.VXI11Dialog;
                    case ModalDialogMixin.getTypes("Socket")
                        modalDialog = matlabshared.transportapp.internal.visamodaldialog.SocketDialog;
                    case ModalDialogMixin.getTypes("HiSlip")
                        modalDialog = matlabshared.transportapp.internal.visamodaldialog.HiSlipDialog;
                end
            end
        end
    end

    methods (Access = {?matlabshared.transportapp.internal.visamodaldialog.ModalDialogMixin, ...
            ?matlabshared.transportapp.internal.utilities.ITestable})
        function setAppStateBusy(obj)
            % Get the app container handler and set it to busy.

            if obj.ProductionMode
                obj.DialogParent = getDialogParent(obj);
                obj.DialogParent.Busy = true;
            end
        end

        function cleanupProperties(obj)
            % Cleanup after the connection and test operations are done.

            if ~obj.ProductionMode
                return
            end

            obj.VisaIdentificationForm = [];
            obj.VisaIdentificationListener = [];
            obj.ModalDialog = [];

            if ~isempty(obj.DialogParent)
                obj.DialogParent.Busy = false;
            end
            obj.DialogParent = [];
        end

        function visaConnectionPropertiesSetFcn(obj, ~, evt)
            % Handler function for when the VisaConnectionAndIdentification
            % property is set.

            obj.VisaIdentificationForm = evt.AffectedObject.VisaConnectionAndIdentification;
        end
    end

    %% Getters and Setters
    methods
        function val = get.Closeable(obj)
            if isempty(obj.ModalDialog)
                throwAsCaller(MException(message("transportapp:visadevapp:EmptyModalDialog")));
            end

            val = obj.ModalDialog.Closeable;
        end
    end

    %% Private Static Helper Methods
    methods (Static)
        function types = getTypes(allTypes)
            types = [];
            for type = allTypes
                types = [types ...
                    matlabshared.transportapp.internal.visamodaldialog.ModalDialogMixin.TypeFcn(type)]; %#ok<*AGROW>
            end
        end
    end
end