classdef OutputAxesView < controllib.chart.internal.view.axes.SingleColumnAxesView
    
    %% Properties
    properties (Dependent, AbortSet, SetObservable)
        % NOutputs
        NOutputs
        % Chart output names
        OutputNames (:,1) string
        % Set output visibility : true | false
        OutputVisible (:,1) matlab.lang.OnOffSwitchState
        % Group axes and responses : "output" | "none"
        OutputGrouping (1,1) string
    end

    %% Constructor
    methods
        function this = OutputAxesView(chart,varargin)
            % Construct view
            arguments
                chart (1,1) controllib.chart.internal.foundation.OutputPlot
            end

            arguments (Repeating)
                varargin
            end
            this@controllib.chart.internal.view.axes.SingleColumnAxesView(chart,varargin{:});
        end
    end

    %% Public methods
    methods
        function updateResponseVisibility(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.OutputAxesView
                response (1,1) controllib.chart.internal.foundation.BaseResponse
            end
            responseView = getResponseView(this,response);
            updateVisibility(responseView,response.Visible & response.ShowInView,RowVisible=this.RowVisible(responseView.PlotRowIdx),...
                ArrayVisible=response.ArrayVisible);
        end
    end

    %% Get/Set
    methods
        % NOutputs
        function NOutputs = get.NOutputs(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.OutputAxesView
            end
            NOutputs = this.NRows;
        end 

        function set.NOutputs(this,NOutputs)
            arguments
                this (1,1) controllib.chart.internal.view.axes.OutputAxesView
                NOutputs (1,1) double {mustBePositive,mustBeInteger}
            end
            this.NRows = NOutputs;
        end

        % OutputNames
        function OutputNames = get.OutputNames(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.OutputAxesView
            end
            OutputNames = this.RowNames;
        end 

        function set.OutputNames(this,OutputNames)
            arguments
                this (1,1) controllib.chart.internal.view.axes.OutputAxesView
                OutputNames (:,1) string
            end
            this.RowNames = OutputNames;
        end

        % OutputVisible
        function OutputVisible = get.OutputVisible(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.OutputAxesView
            end
            OutputVisible = this.RowVisible;
        end 
        
        function set.OutputVisible(this,OutputVisible)
            arguments
                this (1,1) controllib.chart.internal.view.axes.OutputAxesView
                OutputVisible (:,1) matlab.lang.OnOffSwitchState
            end
            this.RowVisible = OutputVisible;
        end

        % OutputGrouping
        function OutputGrouping = get.OutputGrouping(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.OutputAxesView
            end
            OutputGrouping = this.RowGrouping;
        end 
        
        function set.OutputGrouping(this,OutputGrouping)
            arguments
                this (1,1) controllib.chart.internal.view.axes.OutputAxesView
                OutputGrouping (1,1) string {mustBeMember(OutputGrouping,["all","none"])}
            end
            this.RowGrouping = OutputGrouping;
        end
    end

    %% Protected methods
    methods (Access=protected)
        function outputLabels = generateStringForRowLabels(this)
            % Create and return output labels based on output names.
            % Output label is "To: Out(1)" where "Out(1)" is output name.
            outputLabels = this.RowNames;
            for k = 1:length(outputLabels)
                outputLabels(k) = "To: " + outputLabels(k);
            end
        end
    end
end