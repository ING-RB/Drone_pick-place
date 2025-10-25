classdef View < handle
    %VIEW is the Toolstrip Write Section View Class. It creates all the
    %toolstrip write section UI Elements, and contains events for user
    %interactions with these UI elements.

    % Copyright 2021-2022 The MathWorks, Inc.

    %% UI Elements
    properties (Access = {?matlabshared.transportapp.internal.utilities.viewconfiguration.IViewConfiguration,...
                          ?matlabshared.transportapp.internal.toolstrip.write.View})
        ToolstripTabHandle
        WriteSection
        DataFormat
        DataType
        CustomDataButton
        CustomDataEditField
        WorkspaceVariableButton
        WorkspaceVariableDropdown
        WriteButton
    end

    properties (SetAccess = immutable)
        Constants
    end

    %% Callback Events
    events
        DataFormatValueChanged
        RadioButtonValueChanged
        WriteButtonPressed
        CustomDataValueChanged
        WorkspaceVariableValueChanged
    end

    %% Lifetime
    methods
        function obj = View(toolstripTabHandle, ~)
            obj.ToolstripTabHandle = toolstripTabHandle;
            obj.Constants = getConstants(obj);
            obj.createView();
            obj.setupEvents();
        end
    end

    %% Hook Methods - Overriding clients for the View can supply a sepearate implementation if needed
    methods
        function consts = getConstants(~)
            consts = matlabshared.transportapp.internal.toolstrip.write.Constants;
        end
    end

    %% Helper Methods
    methods (Access = protected)
        function createView(obj)
            % Create the write section view UI elements. The order of
            % creation of columns matters as the createAndAddColumn adds
            % the new column to the right of the current column with the
            % contained UI elements.

            import matlabshared.transportapp.internal.utilities.factories.ToolstripElementsFactory

            obj.WriteSection = obj.ToolstripTabHandle.addSection ...
                (obj.Constants.WriteSectionName);

            %% WRITE SECTION Column 1
            dataFormatLabel = ToolstripElementsFactory.createLabel(obj.Constants.DataFormatLabelProps);
            dataTypeLabel = ToolstripElementsFactory.createLabel(obj.Constants.DataTypeLabelProps);

            ToolstripElementsFactory.createAndAddColumn...
                (obj.WriteSection, obj.Constants.WriteColumn(1), [dataFormatLabel, dataTypeLabel]);

            ToolstripElementsFactory.createAndAddColumn...
                (obj.WriteSection, obj.Constants.BufferColumn, []);
            %% WRITE SECTION Column 2
            obj.DataFormat = ToolstripElementsFactory.createDropDown(obj.Constants.DataFormatDropDownOptions, obj.Constants.DataFormatDropDown);

            obj.DataType = ToolstripElementsFactory.createDropDown(obj.Constants.DataTypeDropDownOptions, obj.Constants.DataTypeDropDown);

            ToolstripElementsFactory.createAndAddColumn...
                (obj.WriteSection, obj.Constants.WriteColumn(2), [obj.DataFormat, obj.DataType]);

            %% Add Empty Column
            ToolstripElementsFactory.createAndAddColumn...
                (obj.WriteSection, obj.Constants.EmptyColumn, []);

            %% WRITE SECTION Column 3
            radioButtonGroup = ToolstripElementsFactory.createButtonGroup(struct.empty);

            obj.CustomDataButton = ToolstripElementsFactory.createRadioButton(radioButtonGroup, obj.Constants.CustomDataButton);
            obj.WorkspaceVariableButton = ToolstripElementsFactory.createRadioButton(radioButtonGroup, obj.Constants.WorkspaceVariableButton);

            ToolstripElementsFactory.createAndAddColumn...
                (obj.WriteSection, obj.Constants.WriteColumn(3), [obj.CustomDataButton, obj.WorkspaceVariableButton]);

            %% WRITE SECTION Column 4
            obj.CustomDataEditField = ToolstripElementsFactory.createEditField(obj.Constants.CustomDataEditField);

            obj.WorkspaceVariableDropdown = ToolstripElementsFactory.createDropDown("", obj.Constants.WorkspaceVariableDropdown);

            ToolstripElementsFactory.createAndAddColumn...
                (obj.WriteSection, obj.Constants.WriteColumn(4), [obj.CustomDataEditField, obj.WorkspaceVariableDropdown]);

            %% Add Empty Column
            ToolstripElementsFactory.createAndAddColumn...
                (obj.WriteSection, obj.Constants.EmptyColumn, []);

            %% WRITE SECTION Column 5
            obj.WriteButton = ToolstripElementsFactory.createPushButton(obj.Constants.WriteButton);

            ToolstripElementsFactory.createAndAddColumn...
                (obj.WriteSection, obj.Constants.WriteColumn(5), obj.WriteButton);

        end

        function setupEvents(obj)
            % Setup the UI elements event callback handlers.

            obj.DataFormat.ValueChangedFcn = @obj.dataFormatValueChangedFcn;
            obj.CustomDataButton.ValueChangedFcn = @obj.customDataButtonValueChangedFcn;
            obj.WriteButton.ButtonPushedFcn = @obj.writeButtonPressedFcn;
        end
    end

    %% Event Callback Functions
    methods
        function dataFormatValueChangedFcn(obj, src, ~)
            evtData = matlabshared.transportapp.internal.utilities.EventData(src.SelectedItem);
            obj.notify("DataFormatValueChanged", evtData);
        end

        function customDataButtonValueChangedFcn(obj, src, ~)
            evtData = matlabshared.transportapp.internal.utilities.EventData(src.Selected);
            obj.notify("RadioButtonValueChanged", evtData);
        end

        function writeButtonPressedFcn(obj, ~, ~)
            obj.notify("WriteButtonPressed");
        end
    end
end