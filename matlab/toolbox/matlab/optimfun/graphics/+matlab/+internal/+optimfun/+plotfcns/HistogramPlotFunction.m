classdef HistogramPlotFunction < matlab.internal.optimfun.plotfcns.AbstractPlotFunction
    % Histogram plot implementation for built-in optimization plot functions.
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2023 The MathWorks, Inc.

    methods (Access = public)

        function this = HistogramPlotFunction(tag, isSupported, calculationFcn, optimValues, setupData)

            % Call superclass constructor
            this@matlab.internal.optimfun.plotfcns.AbstractPlotFunction(tag, isSupported, calculationFcn, optimValues, setupData);
        end
    end

    methods (Access = protected)

        function createPlot(this, setupData)

            % Create an "empty" histogram plot
            data = this.EmptyData;
            this.Plot_I = histogram(this.Axes, data, "BinMethod", setupData.BinMethod, "Tag", setupData.Tag);
        end

        function setupAxes(this, setupData)

            % Call superclass method
            setupAxes@matlab.internal.optimfun.plotfcns.AbstractPlotFunction(this, setupData);

            % Tight axes for histograms
            axis tight
        end

        function setDataTips(this, setupData)

            % Customize data tips
            if strcmp(setupData.BinMethod, "integers")
                this.Plot_I.DataTipTemplate.DataTipRows(2).Value = @(~,y) mean(y);
            end
            this.Plot_I.DataTipTemplate.DataTipRows = flip(this.Plot_I.DataTipTemplate.DataTipRows);

            % Call superclass method
            setDataTips@matlab.internal.optimfun.plotfcns.AbstractPlotFunction(this, setupData);
        end

        function update_I(this, data)

            % For consistency, reshape data to a row vector
            data = reshape(data, 1, []);
            this.Plot_I.Data = data;
        end
    end
end
