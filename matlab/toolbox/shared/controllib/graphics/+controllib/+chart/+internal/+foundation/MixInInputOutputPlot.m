classdef MixInInputOutputPlot < matlab.mixin.SetGet
    % controllib.chart.internal.foundation.MixInInputOutputPlot is a mixin
    % that adds I/O related properties and allows subclasses to override
    % the set/get methods to modify row/column related properties

    % Copyright 2024 The MathWorks, Inc.

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
        function this = MixInInputOutputPlot()
            mustBeA(this,'controllib.chart.internal.foundation.RowColumnPlot');
        end
    end

    %% Get/Set
    methods
        % NOutputs
        function NOutputs = get.NOutputs(this)
            NOutputs = getNOutputs_(this);
        end

        % NInputs
        function NInputs = get.NInputs(this)
            NInputs = getNInputs_(this);
        end

        % InputVisible
        function InputVisible = get.InputVisible(this)
            InputVisible = getInputVisible_(this);
        end

        function set.InputVisible(this,InputVisible)
            setInputVisible_(this,InputVisible);
        end

        % OutputVisible
        function OutputVisible = get.OutputVisible(this)
            OutputVisible = getOutputVisible_(this);
        end

        function set.OutputVisible(this,OutputVisible)
            setOutputVisible_(this,OutputVisible);
        end

        % IOGrouping
        function IOGrouping = get.IOGrouping(this)
            IOGrouping = getIOGrouping_(this);
        end

        function set.IOGrouping(this,IOGrouping)
            setIOGrouping_(this,IOGrouping);
        end

        % InputNames
        function InputNames = get.InputNames(this)
            InputNames = getInputNames_(this);
        end

        function set.InputNames(this,InputNames)
            setInputNames_(this,InputNames);
        end

        % OutputNames
        function OutputNames = get.OutputNames(this)
            OutputNames = getOutputNames_(this);
        end

        function set.OutputNames(this,OutputNames)
            setOutputNames_(this,OutputNames);
        end

        % InputLabels
        function InputLabels = get.InputLabels(this)
            InputLabels = getInputLabels_(this);
        end

        % OutputLabels
        function OutputLabels = get.OutputLabels(this)
            OutputLabels = getOutputLabels_(this);
        end
    end

    methods (Sealed,Access = protected)
        function propertyNames = getAdditionalStylePropertyGroupNames(this)
            propertyNames = ["IOGrouping","InputVisible","OutputVisible"];
        end
    end
    
    %% Protected methods
     methods (Access = protected)
       function NOutputs = getNOutputs_(this)
            NOutputs = this.NRows;
        end

        % NInputs
        function NInputs = getNInputs_(this)
            NInputs = this.NColumns;
        end

        % InputVisible
        function InputVisible = getInputVisible_(this)
            InputVisible = this.ColumnVisible;
        end

        function setInputVisible_(this,InputVisible)
            this.ColumnVisible = InputVisible;
        end

        % OutputVisible
        function OutputVisible = getOutputVisible_(this)
            OutputVisible = this.RowVisible;
        end

        function setOutputVisible_(this,OutputVisible)
            this.RowVisible = OutputVisible;
        end

       function V = getInputNames_(this)
          V = this.ColumnNames;
       end

       function setInputNames_(this,V)
          this.ColumnNames = V;
       end

       function V = getOutputNames_(this)
          V = this.RowNames;
       end

       function setOutputNames_(this,V)
          this.RowNames = V;
       end

       function V = getInputLabels_(this)
          V = this.ColumnLabels;
       end

       function setInputLabels_(this,V)
          this.ColumnLabels = V;
       end

       function V = getOutputLabels_(this)
          V = this.RowLabels;
       end

       function setOutputLabels_(this,V)
          this.RowLabels = V;
       end

       % IOGrouping
        function IOGrouping = getIOGrouping_(this)
            switch this.RowColumnGrouping
                case "rows"
                    IOGrouping = "outputs";
                case "columns"
                    IOGrouping = "inputs";
                otherwise
                    IOGrouping = this.RowColumnGrouping;
            end
        end

        function setIOGrouping_(this,IOGrouping)
            switch IOGrouping
                case "inputs"
                    this.RowColumnGrouping = "columns";
                case "outputs"
                    this.RowColumnGrouping = "rows";
                otherwise
                    this.RowColumnGrouping = IOGrouping;
            end
        end
    end
    %% Static Protected methods (sealed)
    methods (Sealed,Static,Access = protected)
        function ioGroupingText = getRowColumnGroupingMenuText()
            ioGroupingText = getString(message('Controllib:plots:strIOGrouping'));
        end

        function [inputText,outputText] = getRowColumnGroupingSubMenuText()
            inputText = getString(message('Controllib:plots:strInputs'));
            outputText = getString(message('Controllib:plots:strOutputs'));
        end

        function selectorMenuText = getRowColumnSelectorMenuText()
            selectorMenuText = getString(message('Controllib:plots:strIOSelectorLabel'));
        end

        function labelText = getFontsWidgetTextForInputOutputPlot()
            labelText = getString(message('Controllib:gui:strIONamesLabel'));
        end

        function rowName = getDefaultRowNameForChannel(k)
            rowName = "Out(" + k + ")";
        end

        function columnName = getDefaultColumnNameForChannel(k)
            columnName = "In(" + k + ")";
        end
    end
end