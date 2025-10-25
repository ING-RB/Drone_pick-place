classdef OutputPlot < controllib.chart.internal.foundation.SingleColumnPlot
    % controllib.chart.internal.foundation.OutputPlot is a foundation class that is a node in the graphics
    % tree. All controls charts should subclass from this.
    %
    % h = OutputPlot(Name-Value)
    %
    %   NOutputs                number of outputs (used when SystemModels is not provided), default value is 1
    %   OutputNames             string array specifying output names (size must be consistent with NOutputs)
    %
    % Public properties:
    %   OutputVisible       matlab.lang.OnOffSwitchState vector for setting output visibility
    %   IOGrouping          string specifying how input/outputs are grouped together,
    %                       "none"|"outputs"
    %   OutputNames         string array for output names
    %
    % See controllib.chart.internal.foundation.AbstractPlot

    % Copyright 2023-2024 The MathWorks, Inc.

    %% Properties
    properties(Dependent, SetObservable, AbortSet)
        % Show or hide specific inputs/outputs
        OutputVisible
        OutputGrouping
        
        OutputNames
    end

    properties (Hidden, Dependent, SetAccess = private)
        NOutputs
        OutputLabels
    end

    %% Constructor
    methods
        function this = OutputPlot(optionalInputs,abstractPlotArguments)
            arguments
                optionalInputs.Options (1,1) plotopts.RespPlotOptions = controllib.chart.internal.foundation.OutputPlot.createDefaultOptions()
                abstractPlotArguments.?controllib.chart.internal.foundation.AbstractPlotOptionalInputs
            end
            abstractPlotArguments = namedargs2cell(abstractPlotArguments);
            this@controllib.chart.internal.foundation.SingleColumnPlot(abstractPlotArguments{:},...
                Options=optionalInputs.Options);
        end
    end

    %% Get/Set
    methods
        % NOutputs
        function NOutputs = get.NOutputs(this)
            NOutputs = this.NRows;
        end

        % OutputVisible
        function OutputVisible = get.OutputVisible(this)
            OutputVisible = this.RowVisible;
        end

        function set.OutputVisible(this,OutputVisible)
            this.RowVisible = OutputVisible;
        end

        % OutputGrouping
        function OutputGrouping = get.OutputGrouping(this)
            OutputGrouping = this.RowGrouping;
        end

        function set.OutputGrouping(this,OutputGrouping)
            this.RowGrouping = OutputGrouping;
        end

        % OutputNames
        function OutputNames = get.OutputNames(this)
            OutputNames = this.RowNames;
        end

        function set.OutputNames(this,OutputNames)
            this.RowNames = OutputNames;
        end

         % OutputLabels
        function OutputLabels = get.OutputLabels(this)
            OutputLabels = this.RowLabels;
        end
    end

    %% Protected methods
    methods (Access = protected)
        function createContextMenu(this)
            createContextMenu@controllib.chart.internal.foundation.SingleColumnPlot(this);
            % RowGrouping
            this.RowGroupingMenu.Text = getString(message('Controllib:plots:strOutputGrouping'));
            % RowSelector
            this.RowSelectorMenu.Text = getString(message('Controllib:plots:strOutputSelectorLabel'));
        end

        function buildFontsWidget(this)
            buildFontsWidget@controllib.chart.internal.foundation.SingleColumnPlot(this);
            this.FontsWidget.IOLabelsText = getString(message('Controllib:gui:strOutputLabelsLabel'));
        end

        function names = getStylePropertyGroupNames(this)
            % intentionally avoid names from SingleColumnPlot
            names = getStylePropertyGroupNames@controllib.chart.internal.foundation.AbstractPlot(this);
            names = [names,"OutputGrouping","OutputVisible"];
        end
    end

    methods (Static,Access=protected)    
        function names = getLimitPropertyGroupNames()
            % intentionally avoid names from SingleColumnPlot
            names = controllib.chart.internal.foundation.AbstractPlot.getLimitPropertyGroupNames();
            names = [names,"OutputLabels"];
        end

        function outputName = getDefaultRowNameForChannel(k)
            outputName = "Out(" + k + ")";
        end
    end
end