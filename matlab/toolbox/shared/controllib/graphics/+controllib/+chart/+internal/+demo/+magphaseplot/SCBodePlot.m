classdef SCBodePlot < controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot

    methods (Access=protected)
        function initialize(this)
            initialize@controllib.chart.internal.foundation.RowColumnPlot(this);
            this.Type = 'scbode';
            this.SynchronizeResponseUpdates = true;
            
            if this.MagnitudeVisible && this.PhaseVisible
                this.YLimits = repmat({[1 10];[1 10]},this.NRows,1);
                this.YLimitsMode = repmat({"auto"; "auto"},this.NRows,1);
                this.YLimitsFocus = repmat({[1 10];[1 10]},this.NRows,1);
                this.YLimitsFocusFromResponses = true;
            end

            build(this);
        end

        function view = createView_(this)            
            % Create View
            view = controllib.chart.internal.demo.magphaseplot.SCBodeAxesView(this);
        end

        function createCharacteristicOptions(this,~)
            % Characteristics are removed for purpose of this demo
            this.CharacteristicTypes = string.empty;
        end
    end    
end