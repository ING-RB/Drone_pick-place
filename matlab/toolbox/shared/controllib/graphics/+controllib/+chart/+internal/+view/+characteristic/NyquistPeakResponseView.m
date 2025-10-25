classdef NyquistPeakResponseView < controllib.chart.internal.view.characteristic.FrequencyCharacteristicView
    % NyquistPeakResponseCharacteristic
    
    % Copyright 2021 The MathWorks, Inc.
    
    %% Properties
    properties (SetAccess = protected)
        PeakResponseMarkers
        PeakResponseLines
    end
    
    %% Constructor
    methods
        function this = NyquistPeakResponseView(responseView,data)
            this@controllib.chart.internal.view.characteristic.FrequencyCharacteristicView(responseView,data);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)
            this.PeakResponseMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='NyquistPeakResponseScatter');
            this.PeakResponseLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='NyquistPeakResponseLine');
            set(this.PeakResponseLines,LineStyle='-.',XData=[NaN NaN],YData=[NaN NaN])
            controllib.plot.internal.utils.setColorProperty(...
                this.PeakResponseLines,"Color","--mw-graphics-colorNeutral-line-primary");
        end

        function updateData(this,ko,ki,ka)
            data = this.Response.ResponseData;
            peakResponseData = data.NyquistPeakResponse;

            frequencyConversionFcn = getFrequencyUnitConversionFcn(this,this.Response.FrequencyUnit,this.FrequencyUnit);
            peakFrequency = frequencyConversionFcn(peakResponseData.Frequency{ka}(ko,ki));

            responseFrequency = frequencyConversionFcn(data.PositiveFrequency{ka});
            responseValue = data.PositiveFrequencyResponse{ka}(:,ko,ki);
            responseRealValue = real(responseValue(:));
            responseImaginaryValue = imag(responseValue(:));

            peakRealValue = this.scaledInterp1(responseFrequency,responseRealValue,peakFrequency);
            peakImaginaryValue = this.scaledInterp1(responseFrequency,responseImaginaryValue,peakFrequency);

            % Update markers
            this.PeakResponseMarkers(ko,ki,ka).XData = peakRealValue;
            this.PeakResponseMarkers(ko,ki,ka).YData = peakImaginaryValue;
            
            % Update Line
            this.PeakResponseLines(ko,ki,ka).XData = [0, peakRealValue];
            this.PeakResponseLines(ko,ki,ka).YData = [0, peakImaginaryValue];
        end

        function updateDataTips_(this,ko,ki,ka,nameDataTipRow,ioDataTipRow,customDataTipRows)
            data = this.Response.ResponseData.NyquistPeakResponse;

            % Peak Gain Row
            peakGainRow = dataTipTextRow(getString(message('Controllib:plots:strPeakGain')) + ...
                " (" + getString(message('Controllib:gui:strDB')) + ")",mag2db(data.Magnitude{ka}(ko,ki)),'%0.3g');

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

        function c = getMarkerObjects_(this,ko,ki,ka)
            c = this.PeakResponseMarkers(ko,ki,ka);
        end

        function l = getSupportingObjects_(this,ko,ki,ka)
            l = this.PeakResponseLines(ko,ki,ka);
        end
    end
end
