classdef BarPlotFunction < matlab.internal.optimfun.plotfcns.AbstractPlotFunction
    % Bar plot implementation for built-in optimization plot functions
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2022 The MathWorks, Inc.

    methods (Access = public)

        function this = BarPlotFunction(tag, isSupported, calculationFcn, optimValues, setupData)

            % Call superclass constructor
            this@matlab.internal.optimfun.plotfcns.AbstractPlotFunction(tag, isSupported, calculationFcn, optimValues, setupData);
        end
    end

    methods (Access = protected)

        function createPlot(this, setupData)

            % Create an "empty" bar plot
            data = this.EmptyData;
            this.Plot_I = bar(this.Axes, data, "EdgeColor", "none", "Tag", setupData.Tag);
        end

        function update_I(this, data)

            % For consistency, reshape data to a row vector
            data = reshape(data, 1, []);
            this.Plot_I.YData = data;
        end
    end
end
