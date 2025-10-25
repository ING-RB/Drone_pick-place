classdef SCBodeAxesView < controllib.chart.internal.view.axes.MagnitudePhaseFrequencyAxesView
    % BodeView

    % Copyright 2021-2024 The MathWorks, Inc.

    %% Constructor
    methods
        function this = SCBodeAxesView(chart)
            arguments
                chart (1,1) controllib.chart.internal.demo.magphaseplot.SCBodePlot
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

    %% Protected methods
    methods (Access = protected)
        function responseView = createResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.demo.magphaseplot.SCBodeAxesView
                response (1,1) controllib.chart.response.BodeResponse
            end
            responseView = controllib.chart.internal.demo.magphaseplot.SCBodeResponseView(response,...
                PhaseMatchingEnabled=this.PhaseMatchingEnabled,...
                PhaseWrappingEnabled=this.PhaseWrappingEnabled,...
                FrequencyScale=this.FrequencyScale_I);
            responseView.FrequencyUnit = this.FrequencyUnit;
            responseView.MagnitudeUnit = this.MagnitudeUnit;
            responseView.PhaseUnit = this.PhaseUnit;
            responseView.FrequencyScale = this.FrequencyScale_I;            
        end

        function [frequencyFocus,magnitudeFocus,phaseFocus] = computeFocus(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.MagnitudePhaseFrequencyAxesView
                responses (:,1) controllib.chart.response.BodeResponse
            end
            frequencyFocus = repmat({[NaN NaN]},this.NRows,this.NColumns);
            magnitudeFocus = repmat({[NaN NaN]},this.NRows,this.NColumns);
            phaseFocus = repmat({[NaN NaN]},this.NRows,this.NColumns);
            if ~isempty(responses)
                data = [responses.ResponseData];
                
                % Get frequency focus
                minStabVisible =  isfield(this.CharacteristicsVisibility,'MinimumStabilityMargins') && this.CharacteristicsVisibility.MinimumStabilityMargins;
                allStabVisible =  isfield(this.CharacteristicsVisibility,'AllStabilityMargins') && this.CharacteristicsVisibility.AllStabilityMargins;
                [frequencyFocus_,frequencyUnit] = getCommonFrequencyFocus(data,this.FrequencyScale,...
                    MinimumStabilityMarginsVisible=minStabVisible,AllStabilityMarginsVisible=allStabVisible,ArrayVisible={responses.ArrayVisible});
                frequencyFocus(1:size(frequencyFocus_(:),1),1:size(frequencyFocus_(:),2)) = frequencyFocus_(:);
                
                % Get magnitude focus
                crVisible =  isfield(this.CharacteristicsVisibility,'ConfidenceRegion') && this.CharacteristicsVisibility.ConfidenceRegion;
                brVisible =  isfield(this.CharacteristicsVisibility,'BoundaryRegion') && this.CharacteristicsVisibility.BoundaryRegion;
                [magnitudeFocus_,magnitudeUnit] = getCommonMagnitudeFocus(data,frequencyFocus_,this.MagnitudeScale,...
                    ConfidenceRegionVisible=crVisible,BoundaryRegionVisible=brVisible,ArrayVisible={responses.ArrayVisible});

                % Get phase focus
                [phaseFocus_,phaseUnit] = getCommonPhaseFocus(data,frequencyFocus_,...
                    ConfidenceRegionVisible=crVisible,BoundaryRegionVisible=brVisible,ArrayVisible={responses.ArrayVisible},...
                    PhaseMatchingEnabled=this.PhaseMatchingEnabled,PhaseWrappingEnabled=this.PhaseWrappingEnabled);
                magnitudeFocus(1:size(magnitudeFocus_(:),1),1:size(magnitudeFocus_(:),2)) = magnitudeFocus_(:);
                phaseFocus(1:size(phaseFocus_(:),1),1:size(phaseFocus_(:),2)) = phaseFocus_(:);
                
                % Convert units
                frequencyConversionFcn = getFrequencyUnitConversionFcn(this,frequencyUnit,this.FrequencyUnit);
                magnitudeConversionFcn = getMagnitudeUnitConversionFcn(this,magnitudeUnit,this.MagnitudeUnit);
                phaseConversionFcn = getPhaseUnitConversionFcn(this,phaseUnit,this.PhaseUnit);
                for ko = 1:this.NRows
                    for ki = 1:this.NColumns
                        frequencyFocus{ko,ki} = frequencyConversionFcn(frequencyFocus{ko,ki});
                        magnitudeFocus{ko,ki} = magnitudeConversionFcn(magnitudeFocus{ko,ki});
                        phaseFocus{ko,ki} = phaseConversionFcn(phaseFocus{ko,ki});
                    end
                end
            end

            % Check minimum gain
            if this.MinimumGainEnabled
                for ko = 1:this.NRows
                    for ki = 1:this.NColumns
                        magnitudeFocus{ko,ki}(1) = this.MinimumGainValue;
                        if this.MinimumGainValue >= magnitudeFocus{ko,ki}(2)
                            magnitudeFocus{ko,ki}(2) = this.MinimumGainValue+10;
                        end
                    end
                end
            end
        end
    end
end