classdef BodeBoundaryRegionView < controllib.chart.internal.view.characteristic.FrequencyCharacteristicView & ...
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
        MagnitudeBoundaryRegionPatch
        PhaseBoundaryRegionPatch
    end

    properties (Access=private)
        InteractionMode_I = "default"
    end

    %% Constructor
    methods
        function this = BodeBoundaryRegionView(responseView,data)
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

    %% Public methods
    methods
        function setVisible(this,visible,optionalInputs)
            arguments
                this
                visible matlab.lang.OnOffSwitchState = this.Visible
                optionalInputs.InputVisible logical = true(1,this.Response.NColumns)
                optionalInputs.OutputVisible logical = true(this.Response.NRows,1)
                optionalInputs.ArrayVisible logical = true(1,this.Response.NResponses)
            end

            % Set visibility
            for kr = 1:this.Response.NRows
                for kc = 1:this.Response.NColumns
                    visibleFlag = visible & any(optionalInputs.ArrayVisible) & ...
                        optionalInputs.OutputVisible(kr) & optionalInputs.InputVisible(kc);
                    this.MagnitudeBoundaryRegionPatch(kr,kc).Visible = visibleFlag;
                    this.PhaseBoundaryRegionPatch(kr,kc).Visible = visibleFlag;
                end
            end
            this.Visible = visible;
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)
            this.MagnitudeBoundaryRegionPatch = createGraphicsObjects(this,"patch",this.Response.NRows,...
                this.Response.NColumns,1,HitTest="off",PickableParts="none",Tag='BodeBoundaryMagnitudePatch');
            set(this.MagnitudeBoundaryRegionPatch,FaceAlpha=0.3,EdgeAlpha=0.3);
            this.PhaseBoundaryRegionPatch = createGraphicsObjects(this,"patch",this.Response.NRows,...
                this.Response.NColumns,1,HitTest="off",PickableParts="none",Tag='BodeBoundaryPhasePatch');
            set(this.PhaseBoundaryRegionPatch,FaceAlpha=0.3,EdgeAlpha=0.3);
        end

        function updateData(this,ko,ki,~)
            data = getCharacteristics(this.Response.ResponseData,this.Type);
            responseObjects = getResponseObjects(this.ResponseView,ko,ki,1);
            phaseResponseLine = responseObjects{1}(2);
            frequencyConversionFcn = getFrequencyUnitConversionFcn(this,this.Response.FrequencyUnit,this.FrequencyUnit);
            magnitudeConversionFcn = getMagnitudeUnitConversionFcn(this,this.Response.MagnitudeUnit,this.MagnitudeUnit);
            phaseConversionFcn = getPhaseUnitConversionFcn(this,this.Response.PhaseUnit,this.PhaseUnit);
            f = frequencyConversionFcn(data.Frequency(:));

            % Update magnitude
            fmag = f;
            magnitudeUpperValue = magnitudeConversionFcn(data.UpperBoundaryMagnitude(:,ko,ki));
            magnitudeUpperValue = magnitudeUpperValue(:);
            idxNaNForMagnitude = find(isnan(magnitudeUpperValue));

            magnitudeLowerValue = magnitudeConversionFcn(data.LowerBoundaryMagnitude(:,ko,ki));
            magnitudeLowerValue = magnitudeLowerValue(:);
            idxNaNForMagnitude = [idxNaNForMagnitude; find(isnan(magnitudeLowerValue))];

            fmag(idxNaNForMagnitude) = [];
            magnitudeUpperValue(idxNaNForMagnitude) = [];
            magnitudeLowerValue(idxNaNForMagnitude) = [];

            this.MagnitudeBoundaryRegionPatch(ko,ki).XData = [fmag', fmag(end:-1:1)'];
            this.MagnitudeBoundaryRegionPatch(ko,ki).YData = [magnitudeUpperValue', magnitudeLowerValue(end:-1:1)'];

            % Update phase
            fphase = f;
            phaseUpperValue = phaseConversionFcn(data.UpperBoundaryPhase(:,ko,ki));
            phaseUpperValue = phaseUpperValue(:);
            idxNaNForPhase = find(isnan(phaseUpperValue));

            phaseLowerValue = phaseConversionFcn(data.LowerBoundaryPhase(:,ko,ki));
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

            this.PhaseBoundaryRegionPatch(ko,ki).XData = [fphase', fphase(end:-1:1)'];
            this.PhaseBoundaryRegionPatch(ko,ki).YData = [phaseUpperValue', phaseLowerValue(end:-1:1)'];

        end

        function cbFrequencyUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        this.MagnitudeBoundaryRegionPatch(ko,ki).XData = ...
                            conversionFcn(this.MagnitudeBoundaryRegionPatch(ko,ki).XData);
                        this.PhaseBoundaryRegionPatch(ko,ki).XData = ...
                            conversionFcn(this.PhaseBoundaryRegionPatch(ko,ki).XData);
                    end
                end
            end
        end

        function cbMagnitudeUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        this.MagnitudeBoundaryRegionPatch(ko,ki).YData = ...
                            conversionFcn(this.MagnitudeBoundaryRegionPatch(ko,ki).YData);
                    end
                end
            end
        end

        function cbPhaseUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        this.PhaseBoundaryRegionPatch(ko,ki).YData = ...
                            conversionFcn(this.PhaseBoundaryRegionPatch(ko,ki).YData);
                    end
                end
            end
        end

        function p = getResponseObjects_(this,ko,ki,~)
            p = [this.MagnitudeBoundaryRegionPatch(ko,ki);this.PhaseBoundaryRegionPatch(ko,ki)];
        end
    end
end