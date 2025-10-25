classdef View < handle
    %VIEW is the Toolstrip Communication Log Section View Class. It creates
    %all the toolstrip section UI Elements, and contains events for
    %user interactions with these UI elements.

    % Copyright 2021 The MathWorks, Inc.

    properties
        ToolstripTabHandle
        CommunicationLogSection
        DisplayDropDown
        ClearLogButton
    end

    events
       DisplayValueChanged
       ClearLogButtonPressed
    end

    properties (Constant)
        Constants = matlabshared.transportapp.internal.toolstrip.communicationlog.Constants
    end

    %% Lifetime
    methods
        function obj = View(toolstripTabHandle, ~)
            obj.ToolstripTabHandle = toolstripTabHandle;
            obj.createView();
            obj.setupEvents();
        end
    end

    %% Helper Functions
    methods(Access = private)
        function createView(obj)
            import matlabshared.transportapp.internal.utilities.factories.ToolstripElementsFactory

            obj.CommunicationLogSection = obj.ToolstripTabHandle.addSection(obj.Constants.CommunicationLogSectionName);

            %% Column 1
            displayLabel = ToolstripElementsFactory.createLabel(obj.Constants.DisplayLabelProps);
            obj.DisplayDropDown = ToolstripElementsFactory.createDropDown(obj.Constants.DisplayDropDownOptions, obj.Constants.DisplayDropDownProps);
            ToolstripElementsFactory.createAndAddColumn...
                (obj.CommunicationLogSection, obj.Constants.CommunicationLogColumns(1) , [displayLabel, obj.DisplayDropDown]);

            %% Empty Column
            ToolstripElementsFactory.createAndAddColumn...
                (obj.CommunicationLogSection, obj.Constants.EmptyColumn, []);

            %% Column 2
            obj.ClearLogButton = ToolstripElementsFactory.createPushButton(obj.Constants.ClearLogButtonProps);
            ToolstripElementsFactory.createAndAddColumn...
                (obj.CommunicationLogSection, obj.Constants.CommunicationLogColumns(2), [obj.ClearLogButton]);
        end

        function setupEvents(obj)
            obj.DisplayDropDown.ValueChangedFcn = @obj.displayValueChangedFcn;
            obj.ClearLogButton.ButtonPushedFcn = @obj.clearLogButtonPressedFcn;
        end
    end

    %% Event Callback Functions
    methods
        function displayValueChangedFcn(obj, src, ~)
            evtData = matlabshared.transportapp.internal.utilities.EventData(src.SelectedItem);
            obj.notify("DisplayValueChanged", evtData);
        end

        function clearLogButtonPressedFcn(obj, ~, ~)
            obj.notify("ClearLogButtonPressed");
        end
    end
end