classdef TimePhasorInputOutputTransientTimeView < controllib.chart.internal.view.characteristic.TimeInputOutputCharacteristicView
    % this = controllib.chart.internal.view.characteristic.TimePeakResponseView(data)
    %
    % Copyright 2021 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        TransientTimeMarkers
        TransientTimeThresholdLine
    end

    %% Constructor
    methods
        function this = TimePhasorInputOutputTransientTimeView(response,data)
            this@controllib.chart.internal.view.characteristic.TimeInputOutputCharacteristicView(response,data);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)
            this.TransientTimeMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='TimeTransientTimeScatter');
            this.TransientTimeThresholdLine = createGraphicsObjects(this,"line",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='TimeRiseTimeXLineHigh');
            set(this.TransientTimeThresholdLine,LineStyle='-.',XData=[NaN NaN],YData=[NaN NaN])
            controllib.plot.internal.utils.setColorProperty(...
                this.TransientTimeThresholdLine,"Color","--mw-graphics-colorNeutral-line-primary");
        end

        function updateData(this,ko,ki,ka)
            data = this.Response.ResponseData.TransientTime;
            responseData = this.Response.ResponseData;

            m = this.TransientTimeMarkers(ko,ki,ka);
            realValue = real(data.Value{ka}(ko,ki));
            imaginaryValue = imag(data.Value{ka}(ko,ki));

            % Marker
            m.XData(end) = realValue;
            m.YData(end) = imaginaryValue;

            % Threshold
            [realFinalValue,imaginaryFinalValue] = getFinalValue(responseData,[ko,ki],ka);

            radius = sqrt( (realValue-realFinalValue)^2 + (imaginaryValue-imaginaryFinalValue)^2);
            theta = linspace(0,2*pi*100);
            circleValues = radius*exp(1i*theta);
            this.TransientTimeThresholdLine(ko,ki,ka).XData = realFinalValue + real(circleValues);
            this.TransientTimeThresholdLine(ko,ki,ka).YData = imaginaryFinalValue + imag(circleValues);
        end

        % function updateDataByLimits(this,ko,ki,ka)
        %     responseObjects = getResponseObjects(this.ResponseView,ko,ki,ka);
        %     responseLine = responseObjects{1}(this.ResponseLineIdx);
        %     ax = responseLine.Parent;
        % 
        %     m = this.TransientTimeMarkers(ko,ki,ka);
        %     xl = this.TransientTimeXLines(ko,ki,ka);
        % 
        %     peakTime = xl.XData(1);
        %     xLim = ax.XLim;
        %     yLim = ax.YLim;
        %     m.UserData.ValueLessThanLimits = peakTime < xLim(1);
        %     m.UserData.ValueGreaterThanLimits = peakTime > xLim(2);
        %     if m.UserData.ValueLessThanLimits
        %         % Value is less than lower x-limit of axes
        %         x = xLim(1);
        %         xData = responseLine.XData;
        %         yData = responseLine.YData;
        %         idx = find(xData >= xLim(1),1,'first');
        %         if idx > 1
        %             y = interp1(xData(idx-1:idx),yData(idx-1:idx),x);
        %         else
        %             y = yData(1);
        %         end
        %     elseif m.UserData.ValueGreaterThanLimits
        %         % Value is greater than higher x-limit of axes
        %         x = xLim(2);
        %         xData = responseLine.XData;
        %         yData = responseLine.YData;
        %         idx = find(xData <= xLim(2),1,'last');
        %         if idx < length(yData)
        %             y = interp1(xData(idx:idx+1),yData(idx:idx+1),x);
        %         else
        %             y = yData(end);
        %         end
        %     else
        %         % Value is within x-limits
        %         x = peakTime;
        %         xData = responseLine.XData;
        %         yData = responseLine.YData;
        %         [~,idx] = min(abs(xData - x));
        %         y = yData(idx);
        %     end
        %     m.XData = x;
        %     m.YData = y;
        %     xl.YData(1) = yLim(1);
        % end

        function updateDataTips_(this,ko,ki,ka,nameDataTipRow,ioDataTipRow,customDataTipRows)
            data = this.Response.ResponseData.TransientTime;
            conversionFcn = getTimeUnitConversionFcn(this,this.Response.ResponseData.TimeUnit,this.TimeUnit);
            valueRow = dataTipTextRow(getString(message('Controllib:plots:strTransientTime')) + " (" + ...
                this.TimeUnitLabel + ")",conversionFcn(data.Time{ka}(ko,ki)),'%0.3g');
            this.TransientTimeMarkers(ko,ki,ka).DataTipTemplate.DataTipRows = ...
                [nameDataTipRow; ioDataTipRow; valueRow; customDataTipRows(:)];
        end

        function cbTimeUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        for ka = 1:this.Response.NResponses
                            this.TransientTimeMarkers(ko,ki,ka).XData = conversionFcn(this.TransientTimeMarkers(ko,ki,ka).XData);
                            this.TransientTimeXLines(ko,ki,ka).XData = conversionFcn(this.TransientTimeXLines(ko,ki,ka).XData);

                            rowNum = this.replaceDataTipRowLabel(this.TransientTimeMarkers(ko,ki,ka),getString(message('Controllib:plots:strTransientTime')),...
                                getString(message('Controllib:plots:strTransientTime')) + " (" + this.TimeUnitLabel + ")");
                            this.TransientTimeMarkers(ko,ki,ka).DataTipTemplate.DataTipRows(rowNum).Value = ...
                                conversionFcn(this.TransientTimeMarkers(ko,ki,ka).DataTipTemplate.DataTipRows(rowNum).Value);
                        end
                    end
                end
            end
        end

        function c = getMarkerObjects_(this,ko,ki,ka)
            c = this.TransientTimeMarkers(ko,ki,ka);
        end

        function l = getSupportingObjects_(this,ko,ki,ka)
            l = this.TransientTimeThresholdLine(ko,ki,ka); 
        end
    end
end