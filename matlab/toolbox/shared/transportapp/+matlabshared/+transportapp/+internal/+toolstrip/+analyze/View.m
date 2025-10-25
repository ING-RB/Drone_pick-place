classdef View < handle
    %VIEW is the Toolstrip Analyze Section View Class. It creates all the
    %toolstrip analyze section UI Elements, and contains events for user
    %interactions with these UI elements.

    % Copyright 2021 The MathWorks, Inc.

    properties
        ToolstripTabHandle
        AnalyzeSection
        PlotButton
        SignalAnalyzerButton
    end

    events
        PlotButtonPressed
        SignalAnalyzerButtonPressed
    end

    properties (Constant)
        Constants = matlabshared.transportapp.internal.toolstrip.analyze.Constants
    end

    %% Lifetime
    methods
        function obj = View(toolstripTabHandle, ~)
            obj.ToolstripTabHandle = toolstripTabHandle;
            obj.createView();
            obj.setupEvents();
        end
    end

    %% Helper methods
    methods (Access = protected)
        function createView(obj)
            import matlabshared.transportapp.internal.utilities.factories.ToolstripElementsFactory

            obj.AnalyzeSection = obj.ToolstripTabHandle.addSection(obj.Constants.AnalyzeSectionName);
            %% Column 1
            obj.PlotButton = ToolstripElementsFactory.createPushButton(obj.Constants.PlotButtonProps);
            ToolstripElementsFactory.createAndAddColumn...
                (obj.AnalyzeSection, obj.Constants.AnalyzeColumns(1), [obj.PlotButton]);

            %% Empty Column
            ToolstripElementsFactory.createAndAddColumn...
                (obj.AnalyzeSection, obj.Constants.EmptyColumn, []);

            %% Column 2
            obj.SignalAnalyzerButton = ToolstripElementsFactory.createPushButton(obj.Constants.SigAnButtonProps);
            ToolstripElementsFactory.createAndAddColumn...
                (obj.AnalyzeSection, obj.Constants.AnalyzeColumns(2), [obj.SignalAnalyzerButton]);
        end

        function setupEvents(obj)
            obj.PlotButton.ButtonPushedFcn = @obj.plotButtonPressedFcn;
            obj.SignalAnalyzerButton.ButtonPushedFcn = @obj.sigAnButtonPressedFcn;
        end
    end

    %% Event Callback Functions
    methods
        function plotButtonPressedFcn(obj, ~, ~)
            obj.notify("PlotButtonPressed");
        end

        function sigAnButtonPressedFcn(obj, ~, ~)
            obj.notify("SignalAnalyzerButtonPressed");
        end
    end
end