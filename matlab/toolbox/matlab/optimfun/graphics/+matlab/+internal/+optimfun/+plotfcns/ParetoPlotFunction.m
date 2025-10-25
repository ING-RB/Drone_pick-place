classdef ParetoPlotFunction < matlab.internal.optimfun.plotfcns.ScatterPlotFunction
    % Pareto plot implementation for built-in optimization plot functions
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2023-2024 The MathWorks, Inc.

    methods (Static, Access = public)

        function this = ParetoPlotFunction(tag, isSupported, calculationFcn, optimValues, setupData)

            % Call superclass constructor
            this@matlab.internal.optimfun.plotfcns.ScatterPlotFunction(tag, isSupported, calculationFcn, optimValues, setupData);
        end
    end

    methods (Access = protected)

        function createPlot(this, setupData)

            % Call superclass method
            createPlot@matlab.internal.optimfun.plotfcns.ScatterPlotFunction(this, setupData);

            % Account for 3d
            if setupData.Is3D
                this.Plot_I.set("ZData", [], "MarkerFaceAlpha", 0.6);
            end
        end

        function setupAxes(this, setupData)

            % Call superclass method
            setupAxes@matlab.internal.optimfun.plotfcns.ScatterPlotFunction(this, setupData);

            % Account for 3d
            if setupData.Is3D
                zlabel(this.Axes, setupData.ZLabelText);
                view(this.Axes, 3);
            end
        end

        function setDataTips(this, setupData)

            % Call superclass method
            setDataTips@matlab.internal.optimfun.plotfcns.ScatterPlotFunction(this, setupData);

            % Add a data tip for the solution index number
            this.Plot_I.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow(...
                getString(message("globaloptim:psplotcommon:IndexDatatipLabel")), []);
        end

        function update_I(this, data)

            % Always add an extra dimension of zeros to ensure at least 3D data,
            % then plot first 3 dimensions. This prevents checking is3D()
            % every update. No harm in setting ZData to zeros for 2D plots.
            nData = size(data, 1);
            data = [data, zeros(nData, 1)];
            this.Plot_I.set("XData", data(:, 1), "YData", data(:, 2), "ZData", data(:, 3));

            % Reset solution index number data tip values
            this.Plot_I.DataTipTemplate.DataTipRows(end).Value = 1:nData;
        end
    end
end
