classdef ScalarScatterPlotFunction < matlab.internal.optimfun.plotfcns.ScatterPlotFunction
    % Scalar scatter plot implementation for built-in optimization plot functions
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2023 The MathWorks, Inc.

    properties (GetAccess = public, SetAccess = protected)

        % Plot title catalog message should have 1 hole for printing current value
        TitleMessageCatalogID (1, 1) string
    end

    methods (Static, Access = public)

        function this = ScalarScatterPlotFunction(tag, isSupported, calculationFcn, optimValues, setupData)

            % Call superclass constructor
            this@matlab.internal.optimfun.plotfcns.ScatterPlotFunction(tag, isSupported, calculationFcn, optimValues, setupData);
        end
    end

    methods (Access = protected)

        function setProperties(this, setupData)

            % Call superclass method
            setProperties@matlab.internal.optimfun.plotfcns.ScatterPlotFunction(this, setupData);

            % Set corresponding properties from setupData
            this.TitleMessageCatalogID = setupData.TitleMessageCatalogID;
        end

        function setupAxes(this, setupData)

            % Call superclass method
            setupAxes@matlab.internal.optimfun.plotfcns.ScatterPlotFunction(this, setupData);

            % Enforce min x limit of 0
            xlim(this.Axes, [0, Inf]);
        end

        function update_I(this, data)

            % Append new data and update plot title
            xData = data(1);
            yData = data(2);
            newX = [this.Plot_I.XData, xData];
            newY = [this.Plot_I.YData, yData];
            this.Plot_I.set("XData", newX, "YData", newY);
            title(this.Axes, getString(message(this.TitleMessageCatalogID, num2str(data(end),'%g'))));
        end
    end
end
