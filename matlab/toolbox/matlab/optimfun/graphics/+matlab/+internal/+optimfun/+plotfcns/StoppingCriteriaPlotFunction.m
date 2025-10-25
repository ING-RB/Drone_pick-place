classdef StoppingCriteriaPlotFunction < matlab.internal.optimfun.plotfcns.BarPlotFunction
    % Stopping criteria plot implementation for built-in optimization plot functions
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2023 The MathWorks, Inc.

    methods (Access = public)

        function this = StoppingCriteriaPlotFunction(tag, isSupported, calculationFcn, optimValues, setupData)

            % Call superclass constructor
            this@matlab.internal.optimfun.plotfcns.BarPlotFunction(tag, isSupported, calculationFcn, optimValues, setupData);
        end
    end

    methods (Access = protected)

        function createPlot(this, setupData)

            % Call superclass method
            createPlot@matlab.internal.optimfun.plotfcns.BarPlotFunction(this, setupData);

            % Set to horizontal bar
            this.Plot_I.Horizontal = true;
        end

        function setupAxes(this, setupData)

            % Call superclass method
            setupAxes@matlab.internal.optimfun.plotfcns.BarPlotFunction(this, setupData);

            % Remove ylabel and set yticklabels instead
            ylabel(this.Axes, "");
            yticklabels(this.Axes, setupData.YTickLabelText);

            % Format x axis for percentage
            xtickformat(this.Axes, "percentage");
            xlim(this.Axes, [0, 100]);
        end

        function setDataTips(this, setupData)

            % Customize data tips
            this.Plot_I.DataTipTemplate.DataTipRows = flip(this.Plot_I.DataTipTemplate.DataTipRows);
            this.Plot_I.DataTipTemplate.DataTipRows(1) = dataTipTextRow(...
                setupData.YLabelText, setupData.YTickLabelText);
            this.Plot_I.DataTipTemplate.DataTipRows(2).Label = setupData.XLabelText;
            this.Plot_I.DataTipTemplate.DataTipRows(2).Format = "percentage";
        end
    end
end
