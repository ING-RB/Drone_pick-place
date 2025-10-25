classdef BodeAxesView < controllib.chart.internal.view.axes.MagnitudePhaseFrequencyAxesView & ...
                        controllib.chart.internal.view.axes.MixInInputOutputAxesViewLabels
    % BodeView

    % Copyright 2021-2024 The MathWorks, Inc.

    %% Constructor
    methods
        function this = BodeAxesView(chart)
            arguments
                chart (1,1) controllib.chart.BodePlot
            end

            % Initialize FrequencyView and AbstractView
            this@controllib.chart.internal.view.axes.MagnitudePhaseFrequencyAxesView(chart);

            % Set BodeView properties
            this.FrequencyScale = chart.FrequencyScale;
            this.MagnitudeScale = chart.MagnitudeScale;
            this.PhaseWrappingEnabled = chart.PhaseWrappingEnabled;
            this.PhaseMatchingEnabled = chart.PhaseMatchingEnabled;
            this.MinimumGainEnabled = chart.MinimumGainEnabled;
            this.MinimumGainValue = chart.MinimumGainValue;
            
            build(this);
        end
    end

    %% Public methods
    methods
        function updateAxesGridSize(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BodeAxesView
            end
            updateAxesGridSize@controllib.chart.internal.view.axes.MagnitudePhaseFrequencyAxesView(this);
            setYLabelString(this);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function responseView = createResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BodeAxesView
                response (1,1) controllib.chart.response.BodeResponse
            end
            responseView = controllib.chart.internal.view.wave.BodeResponseView(response,...
                PhaseMatchingEnabled=this.PhaseMatchingEnabled,...
                PhaseWrappingEnabled=this.PhaseWrappingEnabled,...
                ColumnVisible=this.ColumnVisible(1:response.NColumns),...
                RowVisible=this.RowVisible(1:response.NRows),...
                FrequencyScale=this.FrequencyScale_I);
            responseView.FrequencyUnit = this.FrequencyUnit;
            responseView.MagnitudeUnit = this.MagnitudeUnit;
            responseView.PhaseUnit = this.PhaseUnit;
            responseView.FrequencyScale = this.FrequencyScale;            
        end

        function postParentResponseView(this,responseView)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BodeAxesView
                responseView (1,1) controllib.chart.internal.view.wave.MagnitudePhaseFrequencyResponseView
            end
            if any(~responseView.Response.IsReal(:)) || ...
                    (responseView.Response.ResponseData.IsFRD && ...
                     any(responseView.Response.ResponseData.Frequency{1} < 0))
                ax = getAxes(this);
                aspectRatio = ax(1).PlotBoxAspectRatio;
                updateArrows(responseView,AspectRatio=aspectRatio);
            end
        end

        function cbAxesGridXLimitsChanged(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BodeAxesView
            end
            cbAxesGridXLimitsChanged@controllib.chart.internal.view.axes.MagnitudePhaseFrequencyAxesView(this);
            ax = getAxes(this);
            aspectRatio = ax(1).PlotBoxAspectRatio;
            for k = 1:length(this.ResponseViews)
                if any(this.ResponseViews(k).CharacteristicTypes=="BodePeakResponse")
                    updateCharacteristic(this.ResponseViews(k),"BodePeakResponse");
                end
                updateArrows(this.ResponseViews(k),AspectRatio=aspectRatio);
            end
        end

        function cbAxesGridYLimitsChanged(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BodeAxesView
            end
            cbAxesGridYLimitsChanged@controllib.chart.internal.view.axes.MagnitudePhaseFrequencyAxesView(this);
            ax = getAxes(this);
            aspectRatio = ax(1).PlotBoxAspectRatio;
            for k = 1:length(this.ResponseViews)
                updateArrows(this.ResponseViews(k),AspectRatio=aspectRatio);
            end
        end

        function postUpdateCharacteristic(this,characteristicType,~)
            if characteristicType=="MinimumStabilityMargins" || characteristicType=="AllStabilityMargins" ||...
                    characteristicType=="ConfidenceRegion" || characteristicType=="BoundaryRegion"
                    updateFocus(this);
            end
        end        
    end
end