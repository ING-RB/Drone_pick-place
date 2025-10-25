classdef ExportHandler < matlabshared.transportapp.internal.toolstrip.export.ExportHandlerBase

    % EXPORTHANDLER handles the business logic for the Shared App
    % Toolstrip Export Section Controller class for operations that need to
    % be performed when user interacts with the View elements.

    % Copyright 2023 The MathWorks, Inc.

    properties (Access = {?matlabshared.transportapp.internal.utilities.ITestable})
        % The data in the Communication Log table row selected by the user.
        SelectedRowData

        % Flag for whether there is data to be exported from the table.
        TableEmpty (1, 1) logical = true
    end

    properties (SetObservable)
        ExportCodeLog (1, 1) logical = false
    end

    %% Lifetime
    methods
        function obj = ExportHandler(mediator, viewConfiguration)
            arguments
                mediator matlabshared.mediator.internal.Mediator
                viewConfiguration matlabshared.transportapp.internal.utilities.viewconfiguration.IViewConfiguration
            end
            obj@matlabshared.transportapp.internal.toolstrip.export.ExportHandlerBase(mediator, viewConfiguration, "WorkspaceVariableEditField");
        end
    end

    %% Hook methods
    methods
        function additionalSubscribeToMediatorPropertiesHook(obj)
            % Subscribe to additional observable properties.

            obj.subscribe('TableValue', ...
                @(src, event)obj.checkTableEmpty(event.AffectedObject.TableValue));
            obj.subscribe('SelectedRowData', ...
                @(src, event)obj.handleSelectedRowChanged(event.AffectedObject.SelectedRowData));
            obj.subscribe('ExportMenuItemPressed', ...
                @(src, event)obj.exportSelectedRowPressed());
        end

        function saveValueToWorkspaceHook(obj, varName)
            % Save data selected in the Communication Log table to the
            % MATLAB workspace.

            valueToExport = obj.SelectedRowData.Data;

            % Use the WorkspaceVariableHandler utility to save the
            % value to the MATLAB workspace.
            if obj.ProductionMode
                matlabshared.transportapp.internal.utilities.WorkspaceVariableHandler.setVariableInMatlabWorkspace ...
                    (varName, valueToExport);
            end

            % After a successful export, update the Workspace Variable
            % value to a valid value again.
            updateWorkspaceVariableValueAfterExport(obj);
        end

        function validateRowSelectedHook(obj)
            % Throw if no table row is selected.
            if isempty(obj.SelectedRowData)
                throw(MException(message("transportapp:toolstrip:export:SelectedRowEmpty")));
            end
        end

        function showWarningMessageHook(obj, warnObj)
            % Use matlabshared.testmeasapps.internal.dialoghandler.forms.WarningForm
            % to show warnings in app.
            showWarningDialog(obj, warnObj);
        end

        function showErrorMessageHook(obj, ex)
            % Use matlabshared.testmeasapps.internal.dialoghandler.forms.ErrorForm
            % to show errors in app.
            showErrorDialog(obj, ex);
        end

        function validateTableNotEmptyHook(obj)
            % Throw if the table is empty.
            if obj.TableEmpty
                throw(MException(message("transportapp:toolstrip:export:TableEmpty")));
            end
        end

        function exportCodeLogPressed(obj, ~, ~)
            % Handler for when the "Export MATLAB Code" item is pressed.
            obj.ExportCodeLog = true;
        end
    end

    %% Handlers
    methods
        function checkTableEmpty(obj, value)
            % Check whether the communication log table is empty.
            obj.TableEmpty = isempty(value);
        end

        function handleSelectedRowChanged(obj, value)
            % Handler for when the selected row of the communication log
            % table is changed.
            obj.SelectedRowData = value;
        end
    end
end