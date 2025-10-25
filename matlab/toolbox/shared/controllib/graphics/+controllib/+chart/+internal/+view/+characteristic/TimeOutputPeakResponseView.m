classdef TimeOutputPeakResponseView < controllib.chart.internal.view.characteristic.TimeOutputCharacteristicView
    % this = controllib.chart.internal.response.PeakResponseCharacteristic(data)
    %
    % Copyright 2021 The MathWorks, Inc.
    
    %% Properties
    properties (SetAccess = protected)
        RealPeakResponseMarkers
        ImaginaryPeakResponseMarkers
        PeakResponseXLines
        RealPeakResponseYLines
        ImaginaryPeakResponseYLines
    end
    
    %% Constructor
    methods
        function this = TimeOutputPeakResponseView(responseView,data)
            this@controllib.chart.internal.view.characteristic.TimeOutputCharacteristicView(responseView,data);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)
            this.RealPeakResponseMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                1,this.Response.NResponses,Tag='TimePeakResponseScatter');
            this.PeakResponseXLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                1,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='TimePeakResponseXLine');
            set(this.PeakResponseXLines,LineStyle='-.',XData=[NaN NaN],YData=[NaN NaN])
            controllib.plot.internal.utils.setColorProperty(...
                this.PeakResponseXLines,"Color","--mw-graphics-colorNeutral-line-primary");
            this.RealPeakResponseYLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                1,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='TimePeakResponseYLine');
            set(this.RealPeakResponseYLines,LineStyle='-.',XData=[NaN NaN],YData=[NaN NaN])
            controllib.plot.internal.utils.setColorProperty(...
                this.RealPeakResponseYLines,"Color","--mw-graphics-colorNeutral-line-primary");

            if any(~this.Response.IsReal)
                this.ImaginaryPeakResponseMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                    1,this.Response.NResponses,Tag='ImaginaryTimePeakResponseScatter');
                this.ImaginaryPeakResponseYLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                    1,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='TimePeakResponseYLine');
                set(this.ImaginaryPeakResponseYLines,LineStyle='-.',XData=[NaN NaN],YData=[NaN NaN])
                controllib.plot.internal.utils.setColorProperty(...
                    this.ImaginaryPeakResponseYLines,"Color","--mw-graphics-colorNeutral-line-primary");
            end
        end

        function updateData(this,ko,~,ka)
            data = this.Response.ResponseData;
            peakResponseData = data.PeakResponse;

            m = this.RealPeakResponseMarkers(ko,1,ka);
            xl = this.PeakResponseXLines(ko,1,ka);
            yl = this.RealPeakResponseYLines(ko,1,ka);

            conversionFcn = getTimeUnitConversionFcn(this,this.Response.ResponseData.TimeUnit,this.TimeUnit);
            peakTime = conversionFcn(peakResponseData.Time{ka}(ko,1));
            realPeakAmplitude = real(peakResponseData.Value{ka}(ko,1));
            % Update markers
            m.XData = peakTime;
            m.YData = realPeakAmplitude;
            % Update X line
            xl.XData = [peakTime peakTime];
            xl.YData = [-1e20 realPeakAmplitude];
            % Update Y line
            yl.XData = [-1e20 peakTime];
            yl.YData = [realPeakAmplitude realPeakAmplitude];

            if ~this.Response.IsReal(ka)
                imaginaryPeakAmplitude = imag(peakResponseData.Value{ka}(ko,1));
                mIm = this.ImaginaryPeakResponseMarkers(ko,1,ka);
                mIm.XData = peakTime;
                mIm.YData = imaginaryPeakAmplitude;

                ylIm = this.ImaginaryPeakResponseYLines(ko,1,ka);
                ylIm.XData = [-1e20 peakTime];
                ylIm.YData = [imaginaryPeakAmplitude, imaginaryPeakAmplitude];

                xl.YData = [-1e20 max(realPeakAmplitude,imaginaryPeakAmplitude)];
            end
        end

        function updateDataByLimits(this,ko,~,ka)
            responseObjects = getResponseObjects(this.ResponseView,ko,1,ka);
            responseLine = responseObjects{1}(this.ResponseLineIdx);
            ax = responseLine.Parent;
            
            if ~isempty(ax)
                m = this.RealPeakResponseMarkers(ko,1,ka);
                xl = this.PeakResponseXLines(ko,1,ka);
                yl = this.RealPeakResponseYLines(ko,1,ka);

                peakTime = xl.XData(1);
                xLim = ax.XLim;
                yLim = ax.YLim;
                valueLessThanLimits = peakTime < xLim(1);
                valueGreaterThanLimits = peakTime > xLim(2);
                m.UserData.ValueOutsideLimits = valueLessThanLimits || valueGreaterThanLimits;
                if valueLessThanLimits
                    % Value is less than lower x-limit of axes
                    x = xLim(1);
                    xData = responseLine.XData;
                    yData = responseLine.YData;
                    idx = find(xData >= xLim(1),1,'first');
                    if idx > 1
                        y = interp1(xData(idx-1:idx),yData(idx-1:idx),x);
                    else
                        y = yData(1);
                    end
                elseif valueGreaterThanLimits
                    % Value is greater than higher x-limit of axes
                    x = xLim(2);
                    xData = responseLine.XData;
                    yData = responseLine.YData;
                    idx = find(xData <= xLim(2),1,'last');
                    if idx < length(yData)
                        y = interp1(xData(idx:idx+1),yData(idx:idx+1),x);
                    else
                        y = yData(end);
                    end
                else
                    % Value is within x-limits
                    x = peakTime;
                    xData = responseLine.XData;
                    yData = responseLine.YData;
                    [~,idx] = min(abs(xData - x));
                    y = yData(idx);
                end
                m.XData = x;
                m.YData = y;
                xl.YData(1) = yLim(1);
                yl.XData(1) = xLim(1);
            end
        end

        function updateDataTips_(this,ko,ka,nameDataTipRow,outputDataTipRow,customDataTipRows)
            data = this.Response.ResponseData.PeakResponse;
            
            % Time
            timeConversionFcn = getTimeUnitConversionFcn(this,this.Response.TimeUnit,this.TimeUnit);
            timeRow = dataTipTextRow(getString(message('Controllib:plots:strAtTime')) + " (" + ...
                this.TimeUnitLabel + ")",timeConversionFcn(data.Time{ka}(ko,1)),'%0.3g');

            % Amplitude
            if this.Response.IsReal(ka)
                realPeakAmplitudeRow = dataTipTextRow(getString(message('Controllib:plots:strPeakDeviation')),...
                    real(data.Value{ka}(ko,1)),'%0.3g');
            else
                amplitudeString = [getString(message('Controllib:plots:strPeakDeviation')),...
                    ' (',getString(message('Controllib:plots:strReal')),')'];
                realPeakAmplitudeRow = dataTipTextRow(amplitudeString,...
                    real(data.Value{ka}(ko,1)),'%0.3g');
            end
            
            % Overshoot
            overshootRow = dataTipTextRow(getString(message('Controllib:plots:strOvershoot')) + " (%)", ...
                data.Overshoot{ka}(ko,1),'%0.3g');
            
            % Set DataTipRows
            this.RealPeakResponseMarkers(ko,1,ka).DataTipTemplate.DataTipRows = ...
                [nameDataTipRow; outputDataTipRow; realPeakAmplitudeRow; overshootRow; timeRow; customDataTipRows(:)];

            if ~this.Response.IsReal(ka)
                amplitudeString = [getString(message('Controllib:plots:strPeakDeviation')),...
                    ' (',getString(message('Controllib:plots:strImaginary')),')'];
                imaginaryPeakAmplitudeRow = dataTipTextRow(amplitudeString,...
                    imag(data.Value{ka}(ko,1)),'%0.3g');
                this.ImaginaryPeakResponseMarkers(ko,1,ka).DataTipTemplate.DataTipRows = ...
                    [nameDataTipRow; outputDataTipRow; imaginaryPeakAmplitudeRow; overshootRow; timeRow; customDataTipRows(:)];
            end
        end

        function cbTimeUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ko = 1:this.Response.NRows
                    for ka = 1:this.Response.NResponses
                        this.RealPeakResponseMarkers(ko,1,ka).XData = conversionFcn(this.RealPeakResponseMarkers(ko,1,ka).XData);
                        this.PeakResponseXLines(ko,1,ka).XData = conversionFcn(this.PeakResponseXLines(ko,1,ka).XData);
                        this.RealPeakResponseYLines(ko,1,ka).XData(2) = conversionFcn(this.RealPeakResponseYLines(ko,1,ka).XData(2));

                        row = this.replaceDataTipRowLabel(this.RealPeakResponseMarkers(ko,1,ka),getString(message('Controllib:plots:strAtTime')),...
                            getString(message('Controllib:plots:strAtTime')) + " (" + this.TimeUnitLabel + ")");
                        this.RealPeakResponseMarkers(ko,1,ka).DataTipTemplate.DataTipRows(row).Value = this.PeakResponseXLines(ko,1,ka).XData(1);

                        % For complex response
                        if ~this.Response.IsReal(ka)
                            this.ImaginaryPeakResponseMarkers(ko,1,ka).XData = ...
                                conversionFcn(this.ImaginaryPeakResponseMarkers(ko,1,ka).XData);
                            this.ImaginaryPeakResponseYLines(ko,1,ka).XData(2) = ...
                                conversionFcn(this.ImaginaryPeakResponseYLines(ko,1,ka).XData(2));
                        end
                    end
                end
            end
        end

        function c = getMarkerObjects_(this,ko,~,ka)
            c = this.RealPeakResponseMarkers(ko,1,ka);
            if ~this.Response.IsReal(ka)
                c = cat(3,c,this.ImaginaryPeakResponseMarkers(ko,1,ka));
            end
        end

        function l = getSupportingObjects_(this,ko,~,ka)
            l = cat(3,this.PeakResponseXLines(ko,1,ka),this.RealPeakResponseYLines(ko,1,ka));
            if ~this.Response.IsReal(ka)
                l = cat(3,l,this.ImaginaryPeakResponseYLines(ko,1,ka));
            end
        end
    end
end