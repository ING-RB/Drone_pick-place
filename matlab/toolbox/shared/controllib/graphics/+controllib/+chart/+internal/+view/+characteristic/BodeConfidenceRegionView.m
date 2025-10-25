classdef BodeConfidenceRegionView < controllib.chart.internal.view.characteristic.FrequencyCharacteristicView & ...
                                              controllib.chart.internal.foundation.MixInMagnitudeUnit & ...
                                              controllib.chart.internal.foundation.MixInPhaseUnit
    % this = controllib.chart.internal.view.characteristic.TimePeakResponseView(data)
    %
    % Copyright 2021 The MathWorks, Inc.
    
    %% Properties
    properties (Dependent,AbortSet,SetObservable)
        InteractionMode
    end
    
    properties (SetAccess = protected)
        MagnitudeConfidenceRegionPatch
        PhaseConfidenceRegionPatch
    end

    properties (Access=private)
        InteractionMode_I = "default"
    end
    
    %% Constructor
    methods
        function this = BodeConfidenceRegionView(responseView,data)
            this@controllib.chart.internal.view.characteristic.FrequencyCharacteristicView(responseView,data);
            this@controllib.chart.internal.foundation.MixInMagnitudeUnit(responseView.MagnitudeUnit);
            this@controllib.chart.internal.foundation.MixInPhaseUnit(responseView.PhaseUnit);
            this.ResponseLineIdx = [1 2];
        end
    end

    %% Get/Set
    methods
        % InteractionMode        
        function InteractionMode = get.InteractionMode(this)
            InteractionMode = this.InteractionMode_I;
        end

        function set.InteractionMode(this,InteractionMode)
            this.InteractionMode_I = InteractionMode;
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)
            this.MagnitudeConfidenceRegionPatch = createGraphicsObjects(this,"patch",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,HitTest="off",PickableParts="none",Tag='BodeConfidenceMagnitudePatch');
            set(this.MagnitudeConfidenceRegionPatch,FaceAlpha=0.3,EdgeAlpha=0.3);
            this.PhaseConfidenceRegionPatch = createGraphicsObjects(this,"patch",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,HitTest="off",PickableParts="none",Tag='BodeConfidencePhasePatch');
            set(this.PhaseConfidenceRegionPatch,FaceAlpha=0.3,EdgeAlpha=0.3);
        end

        function updateData(this,ko,ki,ka)
            data = this.Response.ResponseData.ConfidenceRegion;
            if data.IsValid(ka)
                responseObjects = getResponseObjects(this.ResponseView,ko,ki,ka);
                phaseResponseLine = responseObjects{1}(2);
                frequencyConversionFcn = getFrequencyUnitConversionFcn(this,this.Response.FrequencyUnit,this.FrequencyUnit);
                magnitudeConversionFcn = getMagnitudeUnitConversionFcn(this,this.Response.MagnitudeUnit,this.MagnitudeUnit);
                phaseConversionFcn = getPhaseUnitConversionFcn(this,this.Response.PhaseUnit,this.PhaseUnit);
                f = frequencyConversionFcn(data.Frequency{ka}(:));

                % Update magnitude
                fmag = f;
                magnitudeUpperValue = magnitudeConversionFcn(data.UpperBoundaryMagnitude{ka}(:,ko,ki));
                magnitudeUpperValue = magnitudeUpperValue(:);
                idxNaNForMagnitude = find(isnan(magnitudeUpperValue));

                magnitudeLowerValue = magnitudeConversionFcn(data.LowerBoundaryMagnitude{ka}(:,ko,ki));
                magnitudeLowerValue = magnitudeLowerValue(:);
                idxNaNForMagnitude = [idxNaNForMagnitude; find(isnan(magnitudeLowerValue))];

                fmag(idxNaNForMagnitude) = [];
                magnitudeUpperValue(idxNaNForMagnitude) = [];
                magnitudeLowerValue(idxNaNForMagnitude) = [];

                this.MagnitudeConfidenceRegionPatch(ko,ki,ka).XData = [fmag', fmag(end:-1:1)'];
                this.MagnitudeConfidenceRegionPatch(ko,ki,ka).YData = [magnitudeUpperValue', magnitudeLowerValue(end:-1:1)'];

                % Update phase
                fphase = f;
                phaseUpperValue = phaseConversionFcn(data.UpperBoundaryPhase{ka}(:,ko,ki));
                phaseUpperValue = phaseUpperValue(:);
                idxNaNForPhase = find(isnan(phaseUpperValue));

                phaseLowerValue = phaseConversionFcn(data.LowerBoundaryPhase{ka}(:,ko,ki));
                phaseLowerValue = phaseLowerValue(:);
                idxNaNForPhase = [idxNaNForPhase; find(isnan(phaseLowerValue))];

                fphase(idxNaNForPhase) = [];
                phaseUpperValue(idxNaNForPhase) = [];
                phaseLowerValue(idxNaNForPhase) = [];
                for ii = 1:length(fphase)
                    [~,idx] = min(abs(phaseResponseLine.XData - fphase(ii)));
                    phaseResponseValue = phaseResponseLine.YData(idx);
                    phaseData = (phaseUpperValue(ii)+phaseLowerValue(ii))/2;
                    if strcmp(this.PhaseUnit,'deg')
                        m = round((phaseData - phaseResponseValue)/360);
                        offset = -360*m;
                    else
                        m = round((phaseData - phaseResponseValue)/(2*pi));
                        offset = -2*pi*m;
                    end
                    phaseUpperValue(ii) = phaseUpperValue(ii)+offset;
                    phaseLowerValue(ii) = phaseLowerValue(ii)+offset;
                end

                this.PhaseConfidenceRegionPatch(ko,ki,ka).XData = [fphase', fphase(end:-1:1)'];
                this.PhaseConfidenceRegionPatch(ko,ki,ka).YData = [phaseUpperValue', phaseLowerValue(end:-1:1)'];
            end
        end

        function cbFrequencyUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        for ka = 1:this.Response.NResponses
                            this.MagnitudeConfidenceRegionPatch(ko,ki,ka).XData = ...
                                conversionFcn(this.MagnitudeConfidenceRegionPatch(ko,ki,ka).XData);
                            this.PhaseConfidenceRegionPatch(ko,ki,ka).XData = ...
                                conversionFcn(this.PhaseConfidenceRegionPatch(ko,ki,ka).XData);
                        end
                    end
                end
            end
        end

        function cbMagnitudeUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        for ka = 1:this.Response.NResponses
                            this.MagnitudeConfidenceRegionPatch(ko,ki,ka).YData = ...
                                conversionFcn(this.MagnitudeConfidenceRegionPatch(ko,ki,ka).YData);
                        end
                    end
                end
            end
        end

        function cbPhaseUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        for ka = 1:this.Response.NResponses
                            this.PhaseConfidenceRegionPatch(ko,ki,ka).YData = ...
                                conversionFcn(this.PhaseConfidenceRegionPatch(ko,ki,ka).YData);
                        end
                    end
                end
            end
        end

        function p = getResponseObjects_(this,ko,ki,ka)
            p = [this.MagnitudeConfidenceRegionPatch(ko,ki,ka);this.PhaseConfidenceRegionPatch(ko,ki,ka)];
        end
    end
end