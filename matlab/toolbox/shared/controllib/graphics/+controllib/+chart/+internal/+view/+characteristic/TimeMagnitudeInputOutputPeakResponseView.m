classdef TimeMagnitudeInputOutputPeakResponseView < controllib.chart.internal.view.characteristic.TimeInputOutputCharacteristicView
    % this = controllib.chart.internal.view.characteristic.TimePeakResponseView(data)
    %
    % Copyright 2021 The MathWorks, Inc.
    
    %% Properties
    properties (SetAccess = protected)
        MagnitudePeakResponseMarkers
        MagnitudePeakResponseYLines

        PeakResponseXLines
    end
    
    %% Constructor
    methods
        function this = TimeMagnitudeInputOutputPeakResponseView(responseView,data)
            this@controllib.chart.internal.view.characteristic.TimeInputOutputCharacteristicView(responseView,data);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)
            this.MagnitudePeakResponseMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='TimePeakResponseScatter');
            this.PeakResponseXLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='TimePeakResponseXLine');
            set(this.PeakResponseXLines,LineStyle='-.',XData=[NaN NaN],YData=[NaN NaN])
            controllib.plot.internal.utils.setColorProperty(...
                this.PeakResponseXLines,"Color","--mw-graphics-colorNeutral-line-primary");
            this.MagnitudePeakResponseYLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='TimePeakResponseYLine');
            set(this.MagnitudePeakResponseYLines,LineStyle='-.',XData=[NaN NaN],YData=[NaN NaN])
            controllib.plot.internal.utils.setColorProperty(...
                this.MagnitudePeakResponseYLines,"Color","--mw-graphics-colorNeutral-line-primary");
        end

        function updateData(this,ko,ki,ka)
            data = this.Response.ResponseData.PeakResponse;

            m = this.MagnitudePeakResponseMarkers(ko,ki,ka);
            xl = this.PeakResponseXLines(ko,ki,ka);
            yl = this.MagnitudePeakResponseYLines(ko,ki,ka);

            conversionFcn = getTimeUnitConversionFcn(this,this.Response.ResponseData.TimeUnit,this.TimeUnit);
            peakTime = conversionFcn(data.Time{ka}(ko,ki));
            peakAmplitude = abs(data.Value{ka}(ko,ki));

            % Update markers
            m.XData = peakTime;
            m.YData = peakAmplitude;
            % Update X line
            xl.XData = [peakTime peakTime];
            xl.YData = [-1e20 peakAmplitude];
            % Update Y line
            yl.XData = [-1e20 peakTime];
            yl.YData = [peakAmplitude peakAmplitude];
        end

        function updateDataByLimits(this,ko,ki,ka)
            responseObjects = getResponseObjects(this.ResponseView,ko,ki,ka);
            responseLine = responseObjects{1}(this.ResponseLineIdx);
            ax = responseLine.Parent;

            if ~isempty(ax)
                m = this.MagnitudePeakResponseMarkers(ko,ki,ka);
                xl = this.PeakResponseXLines(ko,ki,ka);
                yl = this.MagnitudePeakResponseYLines(ko,ki,ka);

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
            this.MagnitudePeakResponseMarkers(ko,ki,ka).DataTipTemplate.DataTipRows = ...
                [nameDataTipRow; ioDataTipRow; peakAmplitudeRow; overshootRow; timeRow; customDataTipRows(:)];
        end

        function cbTimeUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        for ka = 1:this.Response.NResponses
                            this.MagnitudePeakResponseMarkers(ko,ki,ka).XData = conversionFcn(this.MagnitudePeakResponseMarkers(ko,ki,ka).XData);
                            this.PeakResponseXLines(ko,ki,ka).XData = conversionFcn(this.PeakResponseXLines(ko,ki,ka).XData);
                            this.MagnitudePeakResponseYLines(ko,ki,ka).XData(2) = conversionFcn(this.MagnitudePeakResponseYLines(ko,ki,ka).XData(2));

                            row = this.replaceDataTipRowLabel(this.MagnitudePeakResponseMarkers(ko,ki,ka),getString(message('Controllib:plots:strAtTime')),...
                                getString(message('Controllib:plots:strAtTime')) + " (" + this.TimeUnitLabel + ")");
                            this.MagnitudePeakResponseMarkers(ko,ki,ka).DataTipTemplate.DataTipRows(row).Value = ...
                                conversionFcn(this.MagnitudePeakResponseMarkers(ko,ki,ka).DataTipTemplate.DataTipRows(row).Value);
                        end
                    end
                end
            end
        end

        function c = getMarkerObjects_(this,ko,ki,ka)
            c = this.MagnitudePeakResponseMarkers(ko,ki,ka);
        end

        function l = getSupportingObjects_(this,ko,ki,ka)
            l = cat(3,this.PeakResponseXLines(ko,ki,ka),this.MagnitudePeakResponseYLines(ko,ki,ka));
        end
    end
end