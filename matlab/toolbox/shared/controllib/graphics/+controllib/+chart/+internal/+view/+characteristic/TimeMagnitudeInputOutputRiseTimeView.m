classdef TimeMagnitudeInputOutputRiseTimeView < controllib.chart.internal.view.characteristic.TimeInputOutputCharacteristicView
    % this = controllib.chart.internal.view.characteristic.TimePeakResponseView(data)
    %
    % Copyright 2021 The MathWorks, Inc.
    
    %% Properties
    properties (SetAccess = protected)
        RiseTimeHighXLines
        RiseTimeLowXLines

        RiseTimeMarkers
        RiseTimeYLines
    end

    %% Constructor
    methods
        function this = TimeMagnitudeInputOutputRiseTimeView(responseView,data)
            this@controllib.chart.internal.view.characteristic.TimeInputOutputCharacteristicView(responseView,data);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)   
            this.RiseTimeMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='TimeRiseTimeScatter');
            this.RiseTimeHighXLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='TimeRiseTimeXLineHigh');
            set(this.RiseTimeHighXLines,LineStyle='-.',XData=[NaN NaN],YData=[NaN NaN])
            controllib.plot.internal.utils.setColorProperty(...
                this.RiseTimeHighXLines,"Color","--mw-graphics-colorNeutral-line-primary");
            this.RiseTimeLowXLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='TimeRiseTimeXLineLow');
            set(this.RiseTimeLowXLines,LineStyle='-.',XData=[NaN NaN],YData=[NaN NaN])
            controllib.plot.internal.utils.setColorProperty(...
                this.RiseTimeLowXLines,"Color","--mw-graphics-colorNeutral-line-primary");
            this.RiseTimeYLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='TimeRiseTimeYLine');
            set(this.RiseTimeYLines,LineStyle='-.',XData=[NaN NaN],YData=[NaN NaN])
            controllib.plot.internal.utils.setColorProperty(...
                this.RiseTimeYLines,"Color","--mw-graphics-colorNeutral-line-primary");
        end

        function updateData(this,ko,ki,ka)
            data = this.Response.ResponseData.RiseTime;

            m = this.RiseTimeMarkers(ko,ki,ka);
            xl1 = this.RiseTimeHighXLines(ko,ki,ka);
            xl2 = this.RiseTimeLowXLines(ko,ki,ka);
            yl = this.RiseTimeYLines(ko,ki,ka);

            conversionFcn = getTimeUnitConversionFcn(this,this.Response.ResponseData.TimeUnit,this.TimeUnit);
            tLow = conversionFcn(data.TimeLow{ka}(ko,ki));
            tHigh = conversionFcn(data.TimeHigh{ka}(ko,ki));

            magnitudeValue = abs(data.Value{ka}(ko,ki));

            m.XData(end) = tHigh;
            m.YData(end) = magnitudeValue;
            % High XLines
            xl1.XData = [tHigh, tHigh];
            xl1.YData = [-1e20, magnitudeValue];
            % Low XLines
            xl2.XData = [tLow, tLow];                
            xl2.YData = [-1e20, magnitudeValue];
            % YLines
            yl.XData = [-1e20, tHigh];
            yl.YData = [magnitudeValue, magnitudeValue];
        end

        function updateDataByLimits(this,ko,ki,ka)
            responseObjects = getResponseObjects(this.ResponseView,ko,ki,ka);
            responseLine = responseObjects{1}(this.ResponseLineIdx);
            ax = responseLine.Parent;

            if ~isempty(ax)
                m = this.RiseTimeMarkers(ko,ki,ka);
                xl1 = this.RiseTimeHighXLines(ko,ki,ka);
                xl2 = this.RiseTimeLowXLines(ko,ki,ka);
                yl = this.RiseTimeYLines(ko,ki,ka);

                tHigh = xl1.XData(1);
                xLim = ax.XLim;
                yLim = ax.YLim;
                valueLessThanLimits = tHigh < xLim(1);
                valueGreaterThanLimits = tHigh > xLim(2);
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
                    x = tHigh;
                    xData = responseLine.XData;
                    yData = responseLine.YData;
                    [~,idx] = min(abs(xData - x));
                    y = yData(idx);
                end
                m.XData = x;
                m.YData = y;
                xl1.YData(1) = yLim(1);
                xl2.YData(1) = yLim(1);
                yl.XData(1) = xLim(1);
            end
        end

        function updateDataTips_(this,ko,ki,ka,nameDataTipRow,ioDataTipRow,customDataTipRows)
            data = this.Response.ResponseData.RiseTime;
            conversionFcn = getTimeUnitConversionFcn(this,this.Response.ResponseData.TimeUnit,this.TimeUnit);
            timeValue = conversionFcn(data.TimeHigh{ka}(ko,ki) - data.TimeLow{ka}(ko,ki));
            valueRow = dataTipTextRow(getString(message('Controllib:plots:strRiseTime')) + " (" + ...
                this.TimeUnitLabel + ")",timeValue,'%0.3g');
            this.RiseTimeMarkers(ko,ki,ka).DataTipTemplate.DataTipRows = ...
                [nameDataTipRow; ioDataTipRow; valueRow; customDataTipRows(:)];
        end

        function cbTimeUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        for ka = 1:this.Response.NResponses
                            this.RiseTimeMarkers(ko,ki,ka).XData = conversionFcn(this.RiseTimeMarkers(ko,ki,ka).XData);
                            this.RiseTimeLowXLines(ko,ki,ka).XData = conversionFcn(this.RiseTimeLowXLines(ko,ki,ka).XData);
                            this.RiseTimeHighXLines(ko,ki,ka).XData = conversionFcn(this.RiseTimeHighXLines(ko,ki,ka).XData);
                            this.RiseTimeYLines(ko,ki,ka).XData(2) = conversionFcn(this.RiseTimeYLines(ko,ki,ka).XData(2));

                            rowNum = this.replaceDataTipRowLabel(this.RiseTimeMarkers(ko,ki,ka),getString(message('Controllib:plots:strRiseTime')),...
                                getString(message('Controllib:plots:strRiseTime')) + " (" + this.TimeUnitLabel + ")");
                            this.RiseTimeMarkers(ko,ki,ka).DataTipTemplate.DataTipRows(rowNum).Value = ...
                                conversionFcn(this.RiseTimeMarkers(ko,ki,ka).DataTipTemplate.DataTipRows(rowNum).Value);
                        end
                    end
                end
            end
        end

        function c = getMarkerObjects_(this,ko,ki,ka)
            c = this.RiseTimeMarkers(ko,ki,ka);
        end

        function l = getSupportingObjects_(this,ko,ki,ka)
            l = cat(3,this.RiseTimeHighXLines(ko,ki,ka),...
                this.RiseTimeLowXLines(ko,ki,ka),...
                this.RiseTimeYLines(ko,ki,ka));
        end
    end
end