classdef NicholsPeakResponseView < controllib.chart.internal.view.characteristic.FrequencyCharacteristicView & ...
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
        PeakResponseMarkers
    end

    properties (Access=private)
        InteractionMode_I = "default"
    end

    %% Constructor
    methods
        function this = NicholsPeakResponseView(responseView,data)
            this@controllib.chart.internal.view.characteristic.FrequencyCharacteristicView(responseView,data);
            this@controllib.chart.internal.foundation.MixInMagnitudeUnit(responseView.MagnitudeUnit);
            this@controllib.chart.internal.foundation.MixInPhaseUnit(responseView.PhaseUnit);
        end
    end

    %% Get/Set
    methods
        % InteractionMode        
        function InteractionMode = get.InteractionMode(this)
            InteractionMode = this.InteractionMode_I;
        end

        function set.InteractionMode(this,InteractionMode)
            switch InteractionMode
                case "default"          
                    set(this.PeakResponseMarkers,HitTest='on');
                otherwise
                    set(this.PeakResponseMarkers,HitTest='off');
            end
            this.InteractionMode_I = InteractionMode;
        end
    end
    
    %% Protected methods
    methods (Access = protected)
        function build_(this)
            this.PeakResponseMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='NicholsPeakResponseScatter');
        end

        function updateData(this,ko,ki,ka)
            data = this.Response.ResponseData;
            peakResponseData = data.NicholsPeakResponse;

            magnitudeConversionFcn = getMagnitudeUnitConversionFcn(this,this.Response.MagnitudeUnit,this.MagnitudeUnit);
            phaseConversionFcn = getPhaseUnitConversionFcn(this,this.Response.PhaseUnit,this.PhaseUnit);

            % Get data
            peakPhase = phaseConversionFcn(peakResponseData.Phase{ka}(ko,ki));
            peakMagnitude = magnitudeConversionFcn(peakResponseData.Magnitude{ka}(ko,ki));

            m = this.PeakResponseMarkers(ko,ki,ka);

            % Update markers
            m.XData = peakPhase;
            m.YData = peakMagnitude;
        end

        function updateDataByLimits(this,ko,ki,ka)
            data = this.Response.ResponseData;
            peakResponseData = data.NicholsPeakResponse;

            responseObjects = getResponseObjects(this.ResponseView,ko,ki,ka);
            responseLine = responseObjects{1}(this.ResponseLineIdx);
            ax = responseLine.Parent;

            m = this.PeakResponseMarkers(ko,ki,ka);

            magnitudeConversionFcn = getMagnitudeUnitConversionFcn(this,this.Response.MagnitudeUnit,this.MagnitudeUnit);
            phaseConversionFcn = getPhaseUnitConversionFcn(this,this.Response.PhaseUnit,this.PhaseUnit);

            peakPhase = phaseConversionFcn(peakResponseData.Phase{ka}(ko,ki));
            peakMagnitude = magnitudeConversionFcn(peakResponseData.Magnitude{ka}(ko,ki));

            [~,idx] = min(abs(responseLine.YData - peakMagnitude));
            phaseResponseValue = responseLine.XData(idx);
            if strcmp(this.PhaseUnit,'deg')
                n = round((peakPhase - phaseResponseValue)/360);
                offset = -360*n;
            else
                n = round((peakPhase - phaseResponseValue)/(2*pi));
                offset = -2*pi*n;
            end
            peakPhase = peakPhase+offset;
            
            xLim = ax.XLim;
            valueLessThanLimits = peakPhase < xLim(1);
            valueGreaterThanLimits = peakPhase > xLim(2);
            m.UserData.ValueOutsideLimits = valueLessThanLimits || valueGreaterThanLimits;

            % Update characteristic data based on responseHandle and parent axes
            if valueLessThanLimits
                % Phase is negative
                % idx = find(responseHandle.XData <= ax.XLim(1),1,'first');
                x = xLim(1);

                % Get Y Value
                [~,idx] = min(abs(responseLine.XData - x));
                y = responseLine.YData(idx);
            elseif valueGreaterThanLimits
                % Phase is negative
                x = xLim(2);

                % Get Y Value
                [~,idx] = min(abs(responseLine.XData - x));
                y = responseLine.YData(idx);
            else
                % Value is within x-limits
                x = peakPhase;
                [~,idx] = min(abs(responseLine.XData - x));
                y = responseLine.YData(idx);
            end
            m.XData = x;
            m.YData = y;
        end

        function updateDataTips_(this,ko,ki,ka,nameDataTipRow,ioDataTipRow,customDataTipRows)
            data = this.Response.ResponseData.NicholsPeakResponse;

            % Peak Gain Row
            magnitudeConversionFcn = getMagnitudeUnitConversionFcn(this,this.Response.MagnitudeUnit,this.MagnitudeUnit);
            peakGainRow = dataTipTextRow(getString(message('Controllib:plots:strPeakGain')) + ...
                " (" + this.MagnitudeUnitLabel + ")",magnitudeConversionFcn(data.Magnitude{ka}(ko,ki)),'%0.3g');

            % Frequency Row
            frequencyConversionFcn = getFrequencyUnitConversionFcn(this,...
                this.Response.FrequencyUnit,this.FrequencyUnit);
            frequencyRow = dataTipTextRow(...
                getString(message('Controllib:plots:strFrequency')) + " (" + this.FrequencyUnitLabel + ")",...
                frequencyConversionFcn(data.Frequency{ka}(ko,ki)),'%0.3g');

            this.PeakResponseMarkers(ko,ki,ka).DataTipTemplate.DataTipRows = [...
                nameDataTipRow; ioDataTipRow; peakGainRow; frequencyRow; customDataTipRows(:)];
        end

        function cbFrequencyUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        for ka = 1:this.Response.NResponses
                            % Update data tip
                            rowNum = this.replaceDataTipRowLabel(this.PeakResponseMarkers(ko,ki,ka),...
                                getString(message('Controllib:plots:strFrequency')),...
                                getString(message('Controllib:plots:strFrequency')) + ...
                                " (" + this.FrequencyUnitLabel + ")");
                            this.PeakResponseMarkers(ko,ki,ka).DataTipTemplate.DataTipRows(rowNum).Value = ...
                                conversionFcn(this.PeakResponseMarkers(ko,ki,ka).DataTipTemplate.DataTipRows(rowNum).Value);
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
                            this.PeakResponseMarkers(ko,ki,ka).XData = conversionFcn(this.PeakResponseMarkers(ko,ki,ka).XData);
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
                            this.PeakResponseMarkers(ko,ki,ka).YData = conversionFcn(this.PeakResponseMarkers(ko,ki,ka).YData);

                            % Update data tip
                            rowNum = this.replaceDataTipRowLabel(this.PeakResponseMarkers(ko,ki,ka),...
                                getString(message('Controllib:plots:strPeakGain')),...
                                getString(message('Controllib:plots:strPeakGain')) + ...
                                " (" + this.MagnitudeUnitLabel + ")");
                            this.PeakResponseMarkers(ko,ki,ka).DataTipTemplate.DataTipRows(rowNum).Value = ...
                                conversionFcn(this.PeakResponseMarkers(ko,ki,ka).DataTipTemplate.DataTipRows(rowNum).Value);
                        end
                    end
                end
            end
        end

        function c = getMarkerObjects_(this,ko,ki,ka)
            c = this.PeakResponseMarkers(ko,ki,ka);
        end
    end
end