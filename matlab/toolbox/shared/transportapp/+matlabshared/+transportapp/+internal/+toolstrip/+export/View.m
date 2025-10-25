classdef View < handle
    %VIEW is the Toolstrip export Section View Class. It creates all the
    %toolstrip export section UI Elements, and contains events for user
    %interactions with these UI elements.

    % Copyright 2021 The MathWorks, Inc.

    properties
        ToolstripTabHandle
        ExportSection

        WorkspaceVariableEditField
        ExportButton
        SelectedRowList
        CommLogList
        CodeList
    end

    properties (Constant)
        Constants = matlabshared.transportapp.internal.toolstrip.export.Constants
    end

    %% Lifetime
    methods
        function obj = View(toolstripTabHandle, ~)
            obj.ToolstripTabHandle = toolstripTabHandle;
            obj.createView();
            obj.setupEvents();
        end
    end

    %% Events that the Controller listens for
    events
        WorkspaceVariableChanged
        ExportSelectedRowPressed
        ExportCommLogPressed
        ExportCodeLogPressed
    end

    methods (Access = private)
        function createView(obj)
            import matlabshared.transportapp.internal.utilities.factories.ToolstripElementsFactory

            obj.ExportSection = obj.ToolstripTabHandle.addSection(obj.Constants.ExportSectionName);

            %% Column 1
            label = ToolstripElementsFactory.createLabel(obj.Constants.WorkspaceVariableLabelProps);

            obj.WorkspaceVariableEditField = ToolstripElementsFactory.createEditField ...
                (obj.Constants.WorkspaceVariableEditFieldProps);

            ToolstripElementsFactory.createAndAddColumn...
                (obj.ExportSection, obj.Constants.ExportColumns(1), [label, obj.WorkspaceVariableEditField]);

            %% Add Empty Column
            ToolstripElementsFactory.createAndAddColumn...
                (obj.ExportSection, obj.Constants.EmptyColumn, []);

            %% Column 2
            obj.ExportButton = ...
                ToolstripElementsFactory.createDropDownButton(obj.Constants.ExportButtonProps);

            % Create the 3 list items
            obj.SelectedRowList = ToolstripElementsFactory.createListItem(obj.Constants.ExportSelectedRowListProps);
            obj.CommLogList = ToolstripElementsFactory.createListItem(obj.Constants.ExportCommLogListProps);
            obj.CodeList = ToolstripElementsFactory.createListItem(obj.Constants.ExportCodeListProps);

            % Create the Popup List
            listItems = [obj.SelectedRowList, obj.CommLogList, obj.CodeList];
            popupList = ToolstripElementsFactory.createPopupList(listItems, struct.empty);

            % Assign the popup list to the ExportButton
            obj.ExportButton.Popup = popupList;

            % Create the toolstrip column with the ExportButton
            ToolstripElementsFactory.createAndAddColumn...
                (obj.ExportSection, obj.Constants.ExportColumns(2), obj.ExportButton);
        end

        function setupEvents(obj)
            obj.WorkspaceVariableEditField.ValueChangedFcn = @obj.handleWorkspaceVariableChanged;
            obj.SelectedRowList.ItemPushedFcn = @obj.handleSelectedRowPressed;
            obj.CommLogList.ItemPushedFcn = @obj.handleCommunicationLogPressed;
            obj.CodeList.ItemPushedFcn = @obj.handleCodeLogPressed;
        end
    end

    %% Helper functions
    methods
        function handleWorkspaceVariableChanged(obj, ~, evt)
            % Handler for when the Workspace Variable Edit field is
            % changed.
            evtData = matlabshared.transportapp.internal.utilities.EventData(evt.EventData);
            obj.notify("WorkspaceVariableChanged", evtData);
        end

        function handleSelectedRowPressed(obj, ~, ~)
            % Handler for when the "Export Selected Row" item is pressed.
            obj.notify("ExportSelectedRowPressed");
        end

        function handleCommunicationLogPressed(obj, ~, ~)
            % Handler for when the "Export Communication Log" item is
            % pressed.
            obj.notify("ExportCommLogPressed");
        end

        function handleCodeLogPressed(obj, ~, ~)
            % Handler for when the "Export Code Log" item is pressed.
            obj.notify("ExportCodeLogPressed");
        end
    end
end