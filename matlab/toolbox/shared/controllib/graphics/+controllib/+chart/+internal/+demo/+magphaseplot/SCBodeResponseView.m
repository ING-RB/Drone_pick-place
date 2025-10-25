classdef SCBodeResponseView < controllib.chart.internal.view.wave.MagnitudePhaseFrequencyResponseView
    methods (Access = protected)
        function updateResponseData(this,optionalInputs)
            arguments
                this (1,1) controllib.chart.internal.view.wave.MagnitudePhaseFrequencyResponseView
                optionalInputs.UpdateArrows (1,1) logical = true
            end
            % Get unit conversion functions (system units are rad/model
            % TimeUnit, abs and rad)
            freqConversionFcn = getFrequencyUnitConversionFcn(this,this.Response.FrequencyUnit,this.FrequencyUnit);
            magConversionFcn = getMagnitudeUnitConversionFcn(this,this.Response.MagnitudeUnit,this.MagnitudeUnit);
            phaseConversionFcn = getPhaseUnitConversionFcn(this,this.Response.PhaseUnit,this.PhaseUnit);
            [~,nOutputs,~] = size(this.Response.ResponseData.Magnitude{1});
            for kr = 1:this.Response.NRows
                for ko = 1:this.Response.NColumns
                    for ka = 1:this.Response.NResponses
                        % Convert frequency, magnitude and phase
                        inputIdx = ceil(kr/nOutputs);
                        outputIdx = mod(kr-1,nOutputs)+1;
                        w = freqConversionFcn(this.Response.ResponseData.Frequency{ka});
                        mag = magConversionFcn(this.Response.ResponseData.Magnitude{ka}(:,outputIdx,inputIdx));
                        if this.PhaseWrappingEnabled && this.PhaseMatchingEnabled
                            ph = phaseConversionFcn(this.Response.ResponseData.WrappedAndMatchedPhase{ka}(:,outputIdx,inputIdx));
                        elseif this.PhaseWrappingEnabled
                            ph = phaseConversionFcn(this.Response.ResponseData.WrappedPhase{ka}(:,outputIdx,inputIdx));
                        elseif this.PhaseMatchingEnabled
                            ph = phaseConversionFcn(this.Response.ResponseData.MatchedPhase{ka}(:,outputIdx,inputIdx));
                        else
                            ph = phaseConversionFcn(this.Response.ResponseData.Phase{ka}(:,outputIdx,inputIdx));
                        end
                        if this.Response.ResponseData.IsReal(ka)
                            w = [-flipud(w);w]; %#ok<AGROW>
                            mag = [flipud(mag);mag]; %#ok<AGROW>
                            ph = [flipud(ph);ph]; %#ok<AGROW>
                        end
                        switch this.FrequencyScale
                            case "log"
                                if ~this.Response.ResponseData.IsReal(ka)
                                    w = abs(w);
                                    this.MagnitudePositiveArrows(kr,ko,ka).Visible = this.MagnitudeResponseLines(kr,ko,ka).Visible;
                                    this.MagnitudeNegativeArrows(kr,ko,ka).Visible = this.MagnitudeResponseLines(kr,ko,ka).Visible;
                                    this.PhasePositiveArrows(kr,ko,ka).Visible = this.PhaseResponseLines(kr,ko,ka).Visible;
                                    this.PhaseNegativeArrows(kr,ko,ka).Visible = this.PhaseResponseLines(kr,ko,ka).Visible;
                                else
                                    this.MagnitudePositiveArrows(kr,ko,ka).Visible = false;
                                    this.MagnitudePositiveArrows(kr,ko,ka).Visible = false;
                                    this.PhaseNegativeArrows(kr,ko,ka).Visible = false;
                                    this.PhaseNegativeArrows(kr,ko,ka).Visible = false;
                                end
                            case "linear"
                                this.MagnitudePositiveArrows(kr,ko,ka).Visible = false;
                                this.MagnitudePositiveArrows(kr,ko,ka).Visible = false;
                                this.PhaseNegativeArrows(kr,ko,ka).Visible = false;
                                this.PhaseNegativeArrows(kr,ko,ka).Visible = false;
                        end
                        this.MagnitudeResponseLines(kr,ko,ka).XData = w;
                        this.MagnitudeResponseLines(kr,ko,ka).YData = mag;
                        this.PhaseResponseLines(kr,ko,ka).XData = w;
                        this.PhaseResponseLines(kr,ko,ka).YData = ph;
                    end
                    if this.Response.IsDiscrete
                        nyFreq = freqConversionFcn(pi/abs(this.Response.Model.Ts));
                        set(this.MagnitudeNyquistLines(kr,ko,1),Value=nyFreq);
                        set(this.PhaseNyquistLines(kr,ko,1),Value=nyFreq);
                        set(this.MagnitudeNyquistLines(kr,ko,2),Value=-nyFreq);
                        set(this.PhaseNyquistLines(kr,ko,2),Value=-nyFreq);
                        visibilityFlag = any(arrayfun(@(x) x.Visible,this.MagnitudeResponseLines(kr,ko,:)),'all');
                        set(this.MagnitudeNyquistLines,Visible=visibilityFlag);
                        visibilityFlag = any(arrayfun(@(x) x.Visible,this.PhaseResponseLines(kr,ko,:)),'all');
                        set(this.PhaseNyquistLines,Visible=visibilityFlag);
                    else
                        set(this.MagnitudeNyquistLines,Visible=false);
                        set(this.PhaseNyquistLines,Visible=false);
                    end
                end
            end
            if optionalInputs.UpdateArrows
                updateArrows(this);
            end
        end
    end
end