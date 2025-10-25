classdef ScatterPlotFunction < matlab.internal.optimfun.plotfcns.AbstractPlotFunction
    % Scatter plot implementation for built-in optimization plot functions
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2023 The MathWorks, Inc.

    methods (Access = public)

        function this = ScatterPlotFunction(tag, isSupported, calculationFcn, optimValues, setupData)

            % Call superclass constructor
            this@matlab.internal.optimfun.plotfcns.AbstractPlotFunction(tag, isSupported, calculationFcn, optimValues, setupData);
        end
    end

    methods (Access = protected)

        function createPlot(this, setupData)

            % Create an "empty" scatter plot
            xData = [];
            yData = [];
            this.Plot_I = scatter(this.Axes, xData, yData, "filled", "Tag", setupData.Tag);
        end

        function update_I(this, data)

            % Set updated plot data
            this.Plot_I.set("XData", data(:, 1), "YData", data(:, 2));
        end
    end
end
