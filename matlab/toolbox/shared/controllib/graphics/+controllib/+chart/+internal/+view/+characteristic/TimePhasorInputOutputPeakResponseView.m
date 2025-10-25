classdef TimePhasorInputOutputPeakResponseView < controllib.chart.internal.view.characteristic.TimeInputOutputCharacteristicView
    % this = controllib.chart.internal.view.characteristic.TimePeakResponseView(data)
    %
    % Copyright 2021 The MathWorks, Inc.
    
    %% Properties
    properties (SetAccess = protected)
        PeakResponseMarkers
        PeakResponseLines
    end
    
    %% Constructor
    methods
        function this = TimePhasorInputOutputPeakResponseView(responseView,data)
            this@controllib.chart.internal.view.characteristic.TimeInputOutputCharacteristicView(responseView,data);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)
            this.PeakResponseMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='TimePeakResponseScatter');
            this.PeakResponseLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='TimePeakResponseXLine');
            set(this.PeakResponseLines,LineStyle='-.',XData=[NaN NaN],YData=[NaN NaN])
            controllib.plot.internal.utils.setColorProperty(...
                this.PeakResponseLines,"Color","--mw-graphics-colorNeutral-line-primary");
        end

        function updateData(this,ko,ki,ka)
            data = this.Response.ResponseData.PeakResponse;

            m = this.PeakResponseMarkers(ko,ki,ka);
            l = this.PeakResponseLines(ko,ki,ka);

            realPeakAmplitude = real(data.Value{ka}(ko,ki));
            imaginaryPeakAmplitude = imag(data.Value{ka}(ko,ki));

            m.XData = realPeakAmplitude;
            m.YData = imaginaryPeakAmplitude;
            % Update line
            l.XData = [0 realPeakAmplitude];
            l.YData = [0 imaginaryPeakAmplitude];
        end

 
        function updateDataTips_(this,ko,ki,ka,nameDataTipRow,ioDataTipRow,customDataTipRows)
            data = this.Response.ResponseData.PeakResponse;
            
            % Time
            timeConversionFcn = getTimeUnitConversionFcn(this,this.Response.TimeUnit,this.TimeUnit);
            timeRow = dataTipTextRow(getString(message('Controllib:plots:strAtTime')) + " (" + ...
                this.TimeUnitLabel + ")",timeConversionFcn(data.Time{ka}(ko,ki)),'%0.3g');
            
            % Amplitude
            peakAmplitudeRow = dataTipTextRow(getString(message('Controllib:plots:strPeakDeviation')),...
                abs(data.Value{ka}(ko,ki)),'%0.3g');

            % Overshoot
            if this.Response.Type == "impulse"
                overshootRow = matlab.graphics.datatip.DataTipTextRow.empty;
            else
                overshootRow = dataTipTextRow(getString(message('Controllib:plots:strOvershoot')) + " (%)", ...
                    data.Overshoot{ka}(ko,ki),'%0.3g');
            end

            % Set DataTipRows
            this.PeakResponseMarkers(ko,ki,ka).DataTipTemplate.DataTipRows = ...
                [nameDataTipRow; ioDataTipRow; peakAmplitudeRow; overshootRow; timeRow; customDataTipRows(:)];
        end

        function cbTimeUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        for ka = 1:this.Response.NResponses
                            row = this.replaceDataTipRowLabel(this.PeakResponseMarkers(ko,ki,ka),getString(message('Controllib:plots:strAtTime')),...
                                getString(message('Controllib:plots:strAtTime')) + " (" + this.TimeUnitLabel + ")");
                            this.PeakResponseMarkers(ko,ki,ka).DataTipTemplate.DataTipRows(row).Value = ...
                                conversionFcn(this.PeakResponseMarkers(ko,ki,ka).DataTipTemplate.DataTipRows(row).Value);
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