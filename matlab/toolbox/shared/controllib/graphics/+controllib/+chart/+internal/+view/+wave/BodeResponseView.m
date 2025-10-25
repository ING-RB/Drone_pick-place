classdef BodeResponseView < controllib.chart.internal.view.wave.MagnitudePhaseFrequencyResponseView
    % Bode Response

    % Copyright 2022-2024 The MathWorks, Inc.

    %% Constructor
    methods
        function this = BodeResponseView(response,bodeOptionalInputs,optionalInputs)
            arguments
                response (1,1) controllib.chart.response.BodeResponse
                bodeOptionalInputs.MinimumGainEnabled (1,1) logical = false
                bodeOptionalInputs.PhaseWrappingEnabled (1,1) logical = false
                bodeOptionalInputs.PhaseMatchingEnabled (1,1) logical = false
                bodeOptionalInputs.FrequencyScale (1,1) string = "log"
                optionalInputs.ColumnVisible (1,:) logical = true(1,response.NColumns);
                optionalInputs.RowVisible (:,1) logical = true(response.NRows,1);
                optionalInputs.ArrayVisible logical = response.ArrayVisible
            end
            magPhaseInputs = namedargs2cell(bodeOptionalInputs);
            optionalInputs = namedargs2cell(optionalInputs);
            this@controllib.chart.internal.view.wave.MagnitudePhaseFrequencyResponseView(response,...
                magPhaseInputs{:},optionalInputs{:});
            % build() is called in MagnitudePhaseFrequencyResponseView
        end
    end

    %% Protected methods
    methods (Access = protected)
        function updateResponseData(this,varargin)
            updateResponseData@controllib.chart.internal.view.wave.MagnitudePhaseFrequencyResponseView(...
                this,varargin{:});
            % Update data tip frequency row
            for ka = 1:this.Response.NResponses
                for kr = 1:this.Response.NRows
                    for kc = 1:this.Response.NColumns
                        if this.IsResponseDataTipsCreated
                            w = this.Response.ResponseData.Frequency{ka};
                            if this.Response.ResponseData.IsReal(ka)
                                w = [-flipud(w); w]; %#ok<AGROW>
                            end
                            this.replaceDataTipRowValue(this.MagnitudeResponseLines(kr,kc,ka),...
                                getString(message('Controllib:plots:strFrequency')),w);
                            this.replaceDataTipRowValue(this.PhaseResponseLines(kr,kc,ka),...
                                getString(message('Controllib:plots:strFrequency')),w);
                        end
                    end
                end
            end
        end

        function createCharacteristics(this,data)
            c = controllib.chart.internal.view.characteristic.BaseCharacteristicView.empty;
            % Peak Response
            if isprop(data,"BodePeakResponse") && ~isempty(data.BodePeakResponse)
                c = controllib.chart.internal.view.characteristic.BodePeakResponseView(this,data.BodePeakResponse);
            end
            % AllStabilityMargin
            if isprop(data,"AllStabilityMargin") && ~isempty(data.AllStabilityMargin)
                c = [c; controllib.chart.internal.view.characteristic.BodeStabilityMarginView(this,...
                    data.AllStabilityMargin)];
            end
            % MinimumStabilityMargin
            if isprop(data,"MinimumStabilityMargin") && ~isempty(data.MinimumStabilityMargin)
                c = [c; controllib.chart.internal.view.characteristic.BodeStabilityMarginView(this,...
                    data.MinimumStabilityMargin)];
            end
            % ConfidenceRegion
            if isprop(data,"ConfidenceRegion") && ~isempty(data.ConfidenceRegion)
                c = [c; controllib.chart.internal.view.characteristic.BodeConfidenceRegionView(this,...
                    data.ConfidenceRegion)];
            end
            this.Characteristics = c;
        end

        function createResponseDataTips_(this,ko,ki,ka,nameDataTipRow,ioDataTipRow,customDataTipRows)
            % Create data tip row for frequency and magnitude
            w = this.Response.ResponseData.Frequency{ka};
            if this.Response.ResponseData.IsReal(ka)
                w = [-flipud(w); w];
            end

            frequencyRow = dataTipTextRow(...
                getString(message('Controllib:plots:strFrequency')) + " (" + this.FrequencyUnitLabel + ")",...
                w,'%0.3g');
            magnitudeRow = dataTipTextRow(...
                getString(message('Controllib:plots:strMagnitude')) + " (" + this.MagnitudeUnitLabel + ")",...
                'YData','%0.3g');

            % Add to DataTipTemplate
            this.MagnitudeResponseLines(ko,ki,ka).DataTipTemplate.DataTipRows = ...
                [nameDataTipRow; ioDataTipRow; frequencyRow; magnitudeRow; customDataTipRows(:)];

            % Create data tip row for phase
            phaseRow = dataTipTextRow(...
                getString(message('Controllib:plots:strPhase')) + " (" + this.PhaseUnitLabel + ")",...
                'YData','%0.3g');

            % Add to DataTipTemplate
            this.PhaseResponseLines(ko,ki,ka).DataTipTemplate.DataTipRows = ...
                [nameDataTipRow; ioDataTipRow; frequencyRow; phaseRow; customDataTipRows(:)];
        end

        function updateFrequencyValueDataTip(this,conversionFcn)
            for ka = 1:this.Response.NResponses
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        magnitudeLine = this.MagnitudeResponseLines(ko,ki,ka);
                        idx = this.findDataTipRowIndexByLabel(magnitudeLine,...
                            getString(message('Controllib:plots:strFrequency')),FindExactMatch = false);
                        if ~isempty(idx)
                            dtRow = magnitudeLine.DataTipTemplate.DataTipRows(idx);
                            newValue = conversionFcn(dtRow.Value);
                            this.replaceDataTipRowValue(magnitudeLine,getString(message('Controllib:plots:strFrequency')),newValue);
                        end

                        phaseLine = this.PhaseResponseLines(ko,ki,ka);
                        idx = this.findDataTipRowIndexByLabel(phaseLine,...
                            getString(message('Controllib:plots:strFrequency')),FindExactMatch = false);
                        if ~isempty(idx)
                            dtRow = phaseLine.DataTipTemplate.DataTipRows(idx);
                            newValue = conversionFcn(dtRow.Value);
                            this.replaceDataTipRowValue(phaseLine,getString(message('Controllib:plots:strFrequency')),newValue);
                        end
                    end
                end
            end

        end
    end
end



