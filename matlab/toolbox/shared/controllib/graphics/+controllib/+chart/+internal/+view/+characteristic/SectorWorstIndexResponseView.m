classdef SectorWorstIndexResponseView < controllib.chart.internal.view.characteristic.SigmaPeakResponseView
    % SIGMAPEAKRESPONSECHARACTERISTIC   Manage marker and lines for peak response of a singular value plot.
    
    % Copyright 2023 The MathWorks, Inc.
    
    %% Constructor
    methods
        function this = SectorWorstIndexResponseView(responseView,data)
            this@controllib.chart.internal.view.characteristic.SigmaPeakResponseView(responseView,data);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)
            build_@controllib.chart.internal.view.characteristic.SigmaPeakResponseView(this);
            set(this.PeakResponseMarkers,Tag='SectorWorstIndexResponseScatter')
            set(this.PeakResponseXLines,Tag='SectorWorstIndexResponseXLine')
            set(this.PeakResponseYLines,Tag='SectorWorstIndexResponseYLine')
        end

        function updateData(this,~,~,ka)
            data = this.Response.ResponseData;
            peakResponseData = data.SectorWorstIndexResponse;
            responseObjects = getResponseObjects(this.ResponseView,1,1,ka);
            responseLine = responseObjects{1}(peakResponseData.IdxForPeakValue);
            ax = responseLine.Parent;

            m = this.PeakResponseMarkers(ka);
            xl = this.PeakResponseXLines(ka);
            yl = this.PeakResponseYLines(ka);

            frequencyConversionFcn = getFrequencyUnitConversionFcn(this,this.Response.FrequencyUnit,this.FrequencyUnit);
            magnitudeConversionFcn = getMagnitudeUnitConversionFcn(this,this.Response.IndexUnit,this.MagnitudeUnit);

            peakFrequency = frequencyConversionFcn(peakResponseData.Frequency{ka});

            responseFrequency = frequencyConversionFcn(data.Frequency{ka});
            responseMagnitude = magnitudeConversionFcn(data.RelativeIndex{ka}(peakResponseData.IdxForPeakValue,:));
            peakRelativeIndex = this.scaledInterp1(responseFrequency,responseMagnitude,peakFrequency,...
                ax.XScale,ax.YScale);

            % Update markers
            m.XData = peakFrequency;
            m.YData = peakRelativeIndex;
                
            % Update X line
            xl.XData = [peakFrequency peakFrequency];
            xl.YData = [-1e20 peakRelativeIndex];
            % Update Y line
            yl.XData = [-1e20 peakFrequency];
            yl.YData = [peakRelativeIndex peakRelativeIndex];
        end

        function updateDataByLimits(this,~,~,ka)
            % Update characteristic data based on responseHandle and parent axes]
            data = this.Response.ResponseData;
            peakResponseData = data.SectorWorstIndexResponse;
            responseObjects = getResponseObjects(this.ResponseView,1,1,ka);
            responseLine = responseObjects{1}(peakResponseData.IdxForPeakValue);
            ax = responseLine.Parent;

            m = this.PeakResponseMarkers(ka);
            xl = this.PeakResponseXLines(ka);
            yl = this.PeakResponseYLines(ka);

            peakFrequency = xl.XData(1);
            xLim = ax.XLim;
            yLim = ax.YLim;
            if strcmp(ax.XScale,'log') && peakFrequency < 0
                valueLessThanLimits = abs(peakFrequency) < xLim(1);
                valueGreaterThanLimits = abs(peakFrequency) > xLim(2);
            else
                valueLessThanLimits = peakFrequency < xLim(1);
                valueGreaterThanLimits = peakFrequency > xLim(2);
            end
            m.UserData.ValueOutsideLimits = valueLessThanLimits || valueGreaterThanLimits;
            XScale = ax.XScale;
            YScale = ax.YScale;
            if valueLessThanLimits
                % Value is less than lower x-limit of axes
                x = xLim(1);
                xData = responseLine.XData;
                yData = responseLine.YData;
                if strcmp(ax.XScale,'log') && peakFrequency < 0
                    xData = xData(1:length(xData)/2);
                    yData = yData(1:length(yData)/2);
                    idx = find(xData <= xLim(1),1,'first');
                elseif strcmp(ax.XScale,'log') && peakFrequency >= 0
                    xData = xData(length(xData)/2+1:end);
                    yData = yData(length(yData)/2+1:end);
                    idx = find(xData >= xLim(1),1,'first');
                else
                    idx = find(xData >= xLim(1),1,'first');
                end
                if idx > 1
                    y = this.scaledInterp1(xData(idx-1:idx),yData(idx-1:idx),x,XScale,YScale);
                else
                    y = yData(1);
                end
            elseif valueGreaterThanLimits
                % Value is greater than higher x-limit of axes
                x = xLim(2);
                xData = responseLine.XData;
                yData = responseLine.YData;
                if strcmp(ax.XScale,'log') && peakFrequency < 0
                    xData = xData(1:length(xData)/2);
                    yData = yData(1:length(yData)/2);
                    idx = find(xData >= xLim(2),1,'last');
                elseif strcmp(ax.XScale,'log') && peakFrequency >= 0
                    xData = xData(length(xData)/2+1:end);
                    yData = yData(length(yData)/2+1:end);
                    idx = find(xData <= xLim(2),1,'last');
                else
                    idx = find(xData <= xLim(2),1,'last');
                end
                if idx < length(yData)
                    y = this.scaledInterp1(xData(idx:idx+1),yData(idx:idx+1),x,XScale,YScale);
                else
                    y = yData(end);
                end
            else
                % Value is within x-limits
                xData = responseLine.XData;
                yData = responseLine.YData;
                if strcmp(ax.XScale,'log') && peakFrequency < 0
                    x = -peakFrequency;
                    xData = xData(1:length(xData)/2);
                    yData = yData(1:length(yData)/2);
                    [~,idx] = min(abs(xData - x));
                    y = yData(idx);
                elseif strcmp(ax.XScale,'log') && peakFrequency >= 0
                    x = peakFrequency;
                    xData = xData(length(xData)/2+1:end);
                    yData = yData(length(yData)/2+1:end);
                    [~,idx] = min(abs(xData - x));
                    y = yData(idx);
                else
                    x = peakFrequency;
                    [~,idx] = min(abs(xData - x));
                    y = yData(idx);
                end
            end
            m.XData = x;
            m.YData = y;
            xl.YData(1) = yLim(1);
            yl.XData(1) = xLim(1);
        end

        function updateDataTips_(this,~,~,ka,nameDataTipRow,customDataTipRows)
            data = this.Response.ResponseData.SectorWorstIndexResponse;

            % Peak Gain Row
            magnitudeConversionFcn = getMagnitudeUnitConversionFcn(this,this.Response.IndexUnit,this.MagnitudeUnit);
            peakGainRow = dataTipTextRow(getString(message('Controllib:plots:strMaxIndex')) + ...
                " (" + this.MagnitudeUnitLabel + ")",magnitudeConversionFcn(data.Value{ka}),'%0.3g');

            % Frequency Row
            frequencyConversionFcn = getFrequencyUnitConversionFcn(this,...
                        this.Response.FrequencyUnit,this.FrequencyUnit);
            frequencyRow = dataTipTextRow(...
                getString(message('Controllib:plots:strFrequency')) + " (" + this.FrequencyUnitLabel + ")",...
                frequencyConversionFcn(data.Frequency{ka}),'%0.3g');
            
            this.PeakResponseMarkers(ka).DataTipTemplate.DataTipRows = [...
                nameDataTipRow; peakGainRow; frequencyRow; customDataTipRows(:)];
        end

        function cbMagnitudeUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ka = 1:this.Response.NResponses
                    this.PeakResponseMarkers(ka).YData = conversionFcn(this.PeakResponseMarkers(ka).YData);
                    this.PeakResponseXLines(ka).YData(2) = conversionFcn(this.PeakResponseXLines(ka).YData(2));
                    this.PeakResponseYLines(ka).YData = conversionFcn(this.PeakResponseYLines(ka).YData);

                    % Update data tip
                    this.PeakResponseMarkers(ka).DataTipTemplate.DataTipRows(2).Label = ...
                        getString(message('Controllib:plots:strWorstIndex')) + ...
                        " (" + this.MagnitudeUnitLabel + ")";
                    this.PeakResponseMarkers(ka).DataTipTemplate.DataTipRows(2).Value = this.PeakResponseXLines(ka).YData(2);
                end
            end
        end
    end
end