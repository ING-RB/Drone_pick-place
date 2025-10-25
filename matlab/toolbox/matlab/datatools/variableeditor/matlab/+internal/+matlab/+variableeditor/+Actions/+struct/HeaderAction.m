classdef HeaderAction < internal.matlab.variableeditor.VEAction
    % HeaderAction is a the class that synchronizes all the header menu
    % checked items for struct like views and onActionExecute, toggles
    % column visibility.

    % Copyright 2020-2024 The MathWorks, Inc.

    properties(Constant)
        ActionType = 'HeaderAction'
    end

    methods
        % Initializes a HeaderActionBase, attaches callback listener on
        % 'this' Action
        function this = HeaderAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.struct.HeaderAction.ActionType;
            props.Checked = jsonencode(struct('Name', true));
            props.CheckedActionEnabled = jsonencode(struct('Name', false));
            props.Available = jsonencode(struct);
            props.Enabled = true;
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.ShowHideHeader;
        end

        % Action property 'Checked' is set by inspecting the TableMetaDataProp
        function UpdateActionState(this)
            focusedDoc = this.veManager.FocusedDocument;
            internal.matlab.datatoolsservices.logDebug("variableeditor::HeaderAction", "UpdateActionState");
            if ~isempty(focusedDoc) && ~isempty(focusedDoc.ViewModel) && ...
                    (isa(focusedDoc.ViewModel, 'internal.matlab.variableeditor.StructureViewModel') ||...
                    isa(focusedDoc.ViewModel, 'internal.matlab.desktop_workspacebrowser.DesktopWSBViewModel'))

                FieldColumnList = focusedDoc.ViewModel.FieldColumnList;
                internal.matlab.datatoolsservices.logDebug("variableeditor::HeaderAction", "UpdateActionState FCL Length: " + length(FieldColumnList));
                CheckedState = struct;
                fieldKeys = keys(FieldColumnList);
                for index = 1:length(fieldKeys)
                    fCol = FieldColumnList(fieldKeys{index});
                    CheckedState.(fCol.getHeaderName()) = fCol.Visible;
                end
                this.Checked = jsonencode(CheckedState);
            end
        end

        % Updates Available flag on headermenu checked item to toggle
        % column availability dynamically.
        function UpdateVisibleState(this, focusedDoc)
            arguments
                this
                focusedDoc = this.veManager.FocusedDocument
            end
            internal.matlab.datatoolsservices.logDebug("variableeditor::HeaderAction", "UpdateVisibleState");
            if ~isempty(focusedDoc)
                removedFields = focusedDoc.ViewModel.getRemovedFields();
                fieldColList = focusedDoc.ViewModel.FieldColumnList;
                internal.matlab.datatoolsservices.logDebug("variableeditor::HeaderAction", "UpdateVisibleState FCL Length: " + length(fieldColList));
                availableState = struct;
                for i=1:length(removedFields)
                    availableState.(removedFields{i}) = false;
                end
                for i=keys(fieldColList)
                    availableState.(fieldColList(i{:}).HeaderName) = true;
                end
                this.Available = jsonencode(availableState);
            end
        end
    end

    methods(Access='protected')
        % Callback to show or hide the header specified via the
        % TableMetaDataProp.
        function ShowHideHeader(this, actionInfo)
            isChecked = actionInfo.isChecked;
            headerName = actionInfo.menuID;
            focusedDoc = this.veManager.FocusedDocument;
            % Use API to toggle column visibility. This will create the
            % column if previously uncreated.
            focusedDoc.ViewModel.setColumnVisible(headerName, isChecked);
        end
    end
end