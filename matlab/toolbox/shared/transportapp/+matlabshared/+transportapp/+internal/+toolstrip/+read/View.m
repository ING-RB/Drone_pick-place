classdef View < matlabshared.transportapp.internal.toolstrip.read.IView
    %VIEW is the Toolstrip Read Section View Class. It creates all the
    %toolstrip read section UI Elements, and contains events for user
    %interactions with these UI elements.

    % Copyright 2021-2022 The MathWorks, Inc.

    properties
        ToolstripTabHandle
        ReadSection
        DataType
        DataFormat
        NumValuesToRead
        ValuesAvailable
        ReadButton
        FlushButton
    end

    properties (SetAccess = immutable)
        Constants
    end

    events
        DataFormatValueChanged
        DataTypeValueChanged
        ReadButtonPressed
        FlushButtonPressed
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

    %% Helper methods
    methods (Access = protected)
        function consts = getConstants(~)
            consts = matlabshared.transportapp.internal.toolstrip.read.Constants;
        end

        function createView(obj)
            import matlabshared.transportapp.internal.utilities.factories.ToolstripElementsFactory

            obj.ReadSection = obj.ToolstripTabHandle.addSection(obj.Constants.ReadSectionName);

            %% Column 1
            dataFormatLabel = ToolstripElementsFactory.createLabel(obj.Constants.DataFormatLabelProps);
            dataTypeLabel = ToolstripElementsFactory.createLabel(obj.Constants.DataTypeLabelProps);
            ToolstripElementsFactory.createAndAddColumn...
                (obj.ReadSection, obj.Constants.ReadColumn(1), [dataFormatLabel, dataTypeLabel]);

            ToolstripElementsFactory.createAndAddColumn...
                (obj.ReadSection, obj.Constants.BufferColumn, []);

            %% Column 2
            obj.DataFormat = ToolstripElementsFactory.createDropDown(obj.Constants.DataFormatDropDownOptions, obj.Constants.DataFormatDropDown);

            obj.DataType = ToolstripElementsFactory.createDropDown(obj.Constants.DataTypeDropDownOptions, obj.Constants.DataTypeDropDown);

            ToolstripElementsFactory.createAndAddColumn...
                (obj.ReadSection, obj.Constants.ReadColumn(2), [obj.DataFormat, obj.DataType]);

            %% Add Empty Column
            ToolstripElementsFactory.createAndAddColumn...
                (obj.ReadSection, obj.Constants.EmptyColumn, []);

            %% Column 3
            numValuesToReadLabel = ToolstripElementsFactory.createLabel(obj.Constants.NumValuesToReadLabelProps);
            valuesAvailableLabel = ToolstripElementsFactory.createLabel(obj.Constants.ValuesAvailableLabelProps);
            ToolstripElementsFactory.createAndAddColumn...
                (obj.ReadSection, obj.Constants.ReadColumn(3), [numValuesToReadLabel, valuesAvailableLabel]);

            ToolstripElementsFactory.createAndAddColumn...
                (obj.ReadSection, obj.Constants.BufferColumn, []);

            %% Column 4
            obj.NumValuesToRead = ToolstripElementsFactory.createEditField(obj.Constants.NumValuesToRead);

            obj.ValuesAvailable = ToolstripElementsFactory.createLabel(obj.Constants.ValuesAvailable);

            ToolstripElementsFactory.createAndAddColumn...
                (obj.ReadSection, obj.Constants.ReadColumn(4), [obj.NumValuesToRead, obj.ValuesAvailable]);

            %% Add Empty Column
            ToolstripElementsFactory.createAndAddColumn...
                (obj.ReadSection, obj.Constants.EmptyColumn, []);

            %% Column 5
            obj.ReadButton = ToolstripElementsFactory.createPushButton(obj.Constants.ReadButton);

            ToolstripElementsFactory.createAndAddColumn...
                (obj.ReadSection, obj.Constants.ReadColumn(5), obj.ReadButton);

            %% Add Empty Column
            ToolstripElementsFactory.createAndAddColumn...
                (obj.ReadSection, obj.Constants.EmptyColumn, []);

            %% Column 6
            obj.FlushButton = ToolstripElementsFactory.createPushButton(obj.Constants.FlushButton);
        end

        function setupEvents(obj)
            obj.DataFormat.ValueChangedFcn = @obj.dataFormatValueChangedFcn;
            obj.DataType.ValueChangedFcn = @obj.dataTypeValueChangedFcn;
            obj.ReadButton.ButtonPushedFcn = @obj.readButtonPressedFcn;
            obj.FlushButton.ButtonPushedFcn = @obj.flushButtonPressedFcn;
        end
    end

    %% Event Functions
    methods
        function dataFormatValueChangedFcn(obj, src, ~)
            evtData = matlabshared.transportapp.internal.utilities.EventData(src.SelectedItem);
            obj.notify("DataFormatValueChanged", evtData);
        end

        function dataTypeValueChangedFcn(obj, src, ~)
            evtData = matlabshared.transportapp.internal.utilities.EventData(src.SelectedItem);
            obj.notify("DataTypeValueChanged", evtData);
        end

        function readButtonPressedFcn(obj, ~, ~)
            obj.notify("ReadButtonPressed");
        end

        function flushButtonPressedFcn(obj, ~, ~)
            obj.notify("FlushButtonPressed");
        end
    end

    methods
        function addFlushButtonToToolstrip(obj)
            matlabshared.transportapp.internal.utilities.factories.ToolstripElementsFactory.createAndAddColumn...
                (obj.ReadSection, obj.Constants.ReadColumn(6), obj.FlushButton);
        end
    end
end
