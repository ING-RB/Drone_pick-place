classdef (Abstract) AbstractPlotFunction < handle & matlab.mixin.Heterogeneous
    % Define common behavior for built-in optimization plot functions
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2023 The MathWorks, Inc.

    properties (GetAccess = public, SetAccess = protected)

        % Hold a reference to the gca at the time of plot function
        % construction. This ensures all subsequent plot setup/tuning uses
        % the same axes
        Axes (1, 1) matlab.graphics.axis.Axes

        % Flag for whether the plot function is supported
        IsSupported (1, 1) logical

        % Function that accepts the optimValues struct and calculates the data to plot.
        CalculationFcn % (1, 1) function_handle
    end

    properties (GetAccess = public, SetAccess = protected, Transient, NonCopyable)

        % Underlying graphics object
        Plot_I  = []; % (1, 1) matlab.graphics.chart.primitive.Scatter, matlab.graphics.chart.primitive.Bar, ...
    end

    properties(Dependent)

        % Flag for whether the plot is available for update
        IsAvailableForUpdate (1, 1) logical
    end

    properties (Constant)

        % Reference data for setting up plots in an initial "empty" state
        EmptyData (1, :) double = NaN;
    end

    methods

        function tf = get.IsAvailableForUpdate(this)

            % To be available for update, the plot needs to be supported
            % and the underlying graphics object needs to be valid
            tf = this.IsSupported && isgraphics(this.Plot_I);
        end
    end

    methods (Access = public)

        function this = AbstractPlotFunction(tag, isSupported, calculationFcn, optimValues, setupData)

            % Add some positional arguments to setupData
            setupData.Tag = tag;
            setupData.IsSupported = isSupported;
            setupData.CalculationFcn = calculationFcn;

            % Setup the plot
            this.setup(setupData);

            % Update the plot for the initial optimValues
            this.update(optimValues);
        end

        function update(this, optimValues, varargin)

            % Quick return if the plot is not available for update
            if ~this.IsAvailableForUpdate
                return
            end

            % Calculate the data to plot
            data = this.CalculationFcn(optimValues, varargin{:});

            % Update the underlying graphics object
            this.update_I(data);
        end
    end

    methods (Access = protected)

        function setup(this, setupData)

            % Use the template pattern to setup the plot function.
            % "Shared" code is implemeneted in methods of this abstract
            % class, while concrete classes override/customize as needed.

            % Set object properties
            this.setProperties(setupData);

            % Create an initial "empty" plot
            this.createPlot(setupData);

            % Setup axes properties, like labels, grid visibility, etc.
            this.setupAxes(setupData);

            % Customize plot data tips
            this.setDataTips(setupData);
        end

        function setProperties(this, setupData)

            % Hold a reference to the current gca. This axes will used to plot.
            this.Axes = gca();

            % Set properties from setupData
            this.IsSupported = setupData.IsSupported;
            this.CalculationFcn = setupData.CalculationFcn;
        end

        function setupAxes(this, setupData)

            % Turn on axes grid
            grid on

            % Setup title/labels
            if this.IsSupported
                titleText = setupData.TitleText;
            else
                titleText = getString(message("MATLAB:optimfun:funfun:optimplots:UnsupportedFunction", setupData.Tag));
            end
            title(this.Axes, titleText);
            xlabel(this.Axes, setupData.XLabelText);
            ylabel(this.Axes, setupData.YLabelText);
        end

        function setDataTips(this, ~)

            % Call helper function so plot functions not using this
            % class-based infrastructure can have access
            matlab.internal.optimfun.plotfcns.setDataTips(this.Plot_I);
        end
    end

    methods (Abstract, Access = protected)

        % Create an initial "empty" plot
        createPlot(this, setupData);

        % Update the underlying Plot_I graphics object
        update_I(this, data);
    end
end
