classdef TimeMagnitudeInputOutputSettlingTimeView < controllib.chart.internal.view.characteristic.TimeInputOutputCharacteristicView
    % this = controllib.chart.internal.view.characteristic.TimePeakResponseView(data)
    %
    % Copyright 2021 The MathWorks, Inc.
    
    %% Properties
    properties (SetAccess = protected)
        SettlingTimeMarkers
        SettlingTimeUpperYLines
        SettlingTimeLowerYLines
        SettlingTimeXLines
    end

    %% Constructor
    methods
        function this = TimeMagnitudeInputOutputSettlingTimeView(responseView,data)
            this@controllib.chart.internal.view.characteristic.TimeInputOutputCharacteristicView(responseView,data);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)
            this.SettlingTimeMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='TimeSettlingTimeScatter');
            this.SettlingTimeXLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='TimeSettlingTimeXLine');
            set(this.SettlingTimeXLines,LineStyle='-.',XData=[NaN NaN],YData=[NaN NaN])
            controllib.plot.internal.utils.setColorProperty(...
                this.SettlingTimeXLines,"Color","--mw-graphics-colorNeutral-line-primary");
            this.SettlingTimeUpperYLines = createGraphicsObjects(this,"constantLine",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='TimeSettlingTimeYLineHigh');
            set(this.SettlingTimeUpperYLines,LineStyle='-.',InterceptAxis='y')
            controllib.plot.internal.utils.setColorProperty(...
                this.SettlingTimeUpperYLines,"Color","--mw-graphics-colorNeutral-line-primary");
            this.SettlingTimeLowerYLines = createGraphicsObjects(this,"constantLine",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='TimeSettlingTimeYLineLow');
            set(this.SettlingTimeLowerYLines,LineStyle='-.',InterceptAxis='y')
            controllib.plot.internal.utils.setColorProperty(...
                this.SettlingTimeLowerYLines,"Color","--mw-graphics-colorNeutral-line-primary");
        end

        function updateData(this,ko,ki,ka)
            data = this.Response.ResponseData.SettlingTime;

            m = this.SettlingTimeMarkers(ko,ki,ka);
            xl = this.SettlingTimeXLines(ko,ki,ka);
            yl1 = this.SettlingTimeUpperYLines(ko,ki,ka);
            yl2 = this.SettlingTimeLowerYLines(ko,ki,ka);

            conversionFcn = getTimeUnitConversionFcn(this,this.Response.ResponseData.TimeUnit,this.TimeUnit);
            settlingTime = conversionFcn(data.Time{ka}(ko,ki));
            magnitudeValue = abs(data.Value{ka}(ko,ki));

            % Marker
            m.XData(end) = settlingTime;
            m.YData(end) = magnitudeValue;
            % XLines
            xl.XData = [settlingTime, settlingTime];
            xl.YData = [-1e20, magnitudeValue];
            
            % Upper and Lower Y Lines (do not show for complex)
            if this.Response.IsReal(ka)
                yl1.Value = data.UpperValue{ka}(ko,ki);
                yl2.Value = data.LowerValue{ka}(ko,ki);
            else
                yl1.Value = NaN;
                yl2.Value = NaN;
            end
        end

        function updateDataByLimits(this,ko,ki,ka)
            responseObjects = getResponseObjects(this.ResponseView,ko,ki,ka);
            responseLine = responseObjects{1}(this.ResponseLineIdx);
            ax = responseLine.Parent;
            
            if ~isempty(ax)
                m = this.SettlingTimeMarkers(ko,ki,ka);
                xl = this.SettlingTimeXLines(ko,ki,ka);

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
            end
        end

        function updateDataTips_(this,ko,ki,ka,nameDataTipRow,ioDataTipRow,customDataTipRows)
            data = this.Response.ResponseData.SettlingTime;
            conversionFcn = getTimeUnitConversionFcn(this,this.Response.ResponseData.TimeUnit,this.TimeUnit);
            valueRow = dataTipTextRow(getString(message('Controllib:plots:strSettlingTime')) + " (" + ...
                this.TimeUnitLabel + ")",conversionFcn(data.Time{ka}(ko,ki)),'%0.3g');
            this.SettlingTimeMarkers(ko,ki,ka).DataTipTemplate.DataTipRows = ...
                [nameDataTipRow; ioDataTipRow; valueRow; customDataTipRows(:)];
        end

        function cbTimeUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        for ka = 1:this.Response.NResponses
                            this.SettlingTimeMarkers(ko,ki,ka).XData = conversionFcn(this.SettlingTimeMarkers(ko,ki,ka).XData);
                            this.SettlingTimeXLines(ko,ki,ka).XData = conversionFcn(this.SettlingTimeXLines(ko,ki,ka).XData);

                            rowNum = this.replaceDataTipRowLabel(this.SettlingTimeMarkers(ko,ki,ka),getString(message('Controllib:plots:strSettlingTime')),...
                                getString(message('Controllib:plots:strSettlingTime')) + " (" + this.TimeUnitLabel + ")");
                            this.SettlingTimeMarkers(ko,ki,ka).DataTipTemplate.DataTipRows(rowNum).Value = ...
                                conversionFcn(this.SettlingTimeMarkers(ko,ki,ka).DataTipTemplate.DataTipRows(rowNum).Value);
                        end
                    end
                end
            end
        end

        function c = getMarkerObjects_(this,ko,ki,ka)
            c = this.SettlingTimeMarkers(ko,ki,ka);
        end

        function l = getSupportingObjects_(this,ko,ki,ka)
            l = cat(3,this.SettlingTimeUpperYLines(ko,ki,ka),...
                this.SettlingTimeLowerYLines(ko,ki,ka),...
                this.SettlingTimeXLines(ko,ki,ka));
        end
    end
end