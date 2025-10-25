classdef InputOutputPlot < controllib.chart.internal.foundation.RowColumnPlot
    % controllib.chart.internal.foundation.AbstractPlot is a foundation class that is a node in the graphics
    % tree. All controls charts should subclass from this.
    %
    % h = InputOutputPlot(Name-Value)
    %
    %   NInputs                 number of inputs (used when SystemModels is not provided), default value is 1
    %   NOutputs                number of outputs (used when SystemModels is not provided), default value is 1
    %   InputNames              string array specifying input names (size must be consistent with NInputs)
    %   OutputNames             string array specifying output names (size must be consistent with NOutputs)
    %
    % Public properties:
    %   InputVisible        matlab.lang.OnOffSwitchState vector for setting input visibility
    %   OutputVisible       matlab.lang.OnOffSwitchState vector for setting output visibility
    %   IOGrouping          string specifying how input/outputs are grouped together,
    %                       "none"|"inputs"|"outputs"|"outputs"
    %   InputNames          string array for input names
    %   OutputNames         string array for output names
    %
    % See controllib.chart.internal.foundation.AbstractPlot

    % Copyright 2022-2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent, SetObservable, AbortSet)
        % Show or hide specific inputs/outputs
        InputVisible
        OutputVisible
        IOGrouping
        
        InputLabels    
        OutputLabels        
    end

    properties (Dependent, SetObservable, AbortSet, Hidden)
        InputNames
        OutputNames
    end

    properties (Hidden, Dependent, SetAccess = private)
        NInputs
        NOutputs        
    end

    %% Constructor
    methods
        function this = InputOutputPlot(optionalInputs,abstractPlotArguments)
            arguments
                optionalInputs.Options (1,1) plotopts.RespPlotOptions = controllib.chart.internal.foundation.InputOutputPlot.createDefaultOptions()
                abstractPlotArguments.?controllib.chart.internal.foundation.AbstractPlotOptionalInputs
            end
            abstractPlotArguments = namedargs2cell(abstractPlotArguments);
            this@controllib.chart.internal.foundation.RowColumnPlot(abstractPlotArguments{:},Options=optionalInputs.Options);
        end
    end

    %% Get/Set
    methods
        % NOutputs
        function NOutputs = get.NOutputs(this)
            NOutputs = this.NRows;
        end

        % NInputs
        function NInputs = get.NInputs(this)
            NInputs = this.NColumns;
        end

        % InputVisible
        function InputVisible = get.InputVisible(this)
            InputVisible = this.ColumnVisible;
        end

        function set.InputVisible(this,InputVisible)
            this.ColumnVisible = InputVisible;
        end

        % OutputVisible
        function OutputVisible = get.OutputVisible(this)
            OutputVisible = this.RowVisible;
        end

        function set.OutputVisible(this,OutputVisible)
            this.RowVisible = OutputVisible;
        end

        % IOGrouping
        function IOGrouping = get.IOGrouping(this)
            switch this.RowColumnGrouping
                case "rows"
                    IOGrouping = "outputs";
                case "columns"
                    IOGrouping = "inputs";
                otherwise
                    IOGrouping = this.RowColumnGrouping;
            end
        end

        function set.IOGrouping(this,IOGrouping)
            switch IOGrouping
                case "inputs"
                    this.RowColumnGrouping = "columns";
                case "outputs"
                    this.RowColumnGrouping = "rows";
                otherwise
                    this.RowColumnGrouping = IOGrouping;
            end
        end

        % InputNames
        function InputNames = get.InputNames(this)
            InputNames = this.ColumnNames;
        end

        function set.InputNames(this,InputNames)
            this.ColumnNames = InputNames;
        end

        % OutputNames
        function OutputNames = get.OutputNames(this)
            OutputNames = this.RowNames;
        end

        function set.OutputNames(this,OutputNames)
            this.RowNames = OutputNames;
        end

        % InputLabels
        function InputLabels = get.InputLabels(this)
            InputLabels = this.ColumnLabels;
        end

        % OutputLabels
        function OutputLabels = get.OutputLabels(this)
            OutputLabels = this.RowLabels;
        end
    end

    %% Protected methods
    methods (Access = protected)
        function createContextMenu(this)
            createContextMenu@controllib.chart.internal.foundation.RowColumnPlot(this);
            % RowColumnGrouping
            this.RowColumnGroupingMenu.Text = getString(message('Controllib:plots:strIOGrouping'));
            % RowColumnSubGrouping
            this.RowColumnGroupingSubMenu(3).Text = getString(message('Controllib:plots:strInputs'));
            this.RowColumnGroupingSubMenu(4).Text = getString(message('Controllib:plots:strOutputs'));
            % RowColumnSelector
            this.RowColumnSelectorMenu.Text = getString(message('Controllib:plots:strIOSelectorLabel'));
            
        end

        function buildFontsWidget(this)
            buildFontsWidget@controllib.chart.internal.foundation.RowColumnPlot(this);
            this.FontsWidget.IOLabelsText = getString(message('Controllib:gui:strIONamesLabel'));
        end 

        function names = getStylePropertyGroupNames(this)
            % intentionally avoid names from RowColumnPlot
            names = getStylePropertyGroupNames@controllib.chart.internal.foundation.AbstractPlot(this);
            names = [names,"IOGrouping","InputVisible","OutputVisible"];
        end
    end

    %% Static protected methods
    methods (Static,Access=protected)
        function names = getLimitPropertyGroupNames()
            % intentionally avoid names from RowColumnPlot
            names = controllib.chart.internal.foundation.AbstractPlot.getLimitPropertyGroupNames();
            names = [names,"InputLabels","OutputLabels"];
        end

        function rowName = getDefaultRowNameForChannel(k)
            rowName = "Out(" + k + ")";
        end

        function columnName = getDefaultColumnNameForChannel(k)
            columnName = "In(" + k + ")";
        end
    end
end