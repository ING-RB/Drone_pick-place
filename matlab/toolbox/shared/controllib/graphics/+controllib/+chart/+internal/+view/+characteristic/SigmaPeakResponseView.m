classdef SigmaPeakResponseView < controllib.chart.internal.view.characteristic.BaseCharacteristicView & ...
        controllib.chart.internal.foundation.MixInFrequencyUnit & ...
        controllib.chart.internal.foundation.MixInMagnitudeUnit
    % SIGMAPEAKRESPONSECHARACTERISTIC   Manage marker and lines for peak response of a singular value plot.
    
    % Copyright 2022 The MathWorks, Inc.
    
    %% Private properties
    properties (SetAccess = protected)
        PeakResponseMarkers
        PeakResponseXLines
        PeakResponseYLines
    end
    
    %% Constructor
    methods
        function this = SigmaPeakResponseView(responseView,data)
            this@controllib.chart.internal.view.characteristic.BaseCharacteristicView(responseView,data);
            this@controllib.chart.internal.foundation.MixInFrequencyUnit(responseView.FrequencyUnit);
            this@controllib.chart.internal.foundation.MixInMagnitudeUnit(responseView.MagnitudeUnit);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)
            this.PeakResponseMarkers = createGraphicsObjects(this,"scatter",1,1,this.Response.NResponses,Tag='SigmaPeakResponseScatter');
            this.PeakResponseXLines = createGraphicsObjects(this,"line",1,1,this.Response.NResponses,...
                HitTest='off',PickableParts='none',Tag='SigmaPeakResponseXLine');
            set(this.PeakResponseXLines,LineStyle='-.',XData=[NaN NaN],YData=[NaN NaN])
            controllib.plot.internal.utils.setColorProperty(...
                this.PeakResponseXLines,"Color","--mw-graphics-colorNeutral-line-primary");
            this.PeakResponseYLines = createGraphicsObjects(this,"line",1,1,this.Response.NResponses,...
                HitTest='off',PickableParts='none',Tag='SigmaPeakResponseYLine');
            set(this.PeakResponseYLines,LineStyle='-.',XData=[NaN NaN],YData=[NaN NaN])
            controllib.plot.internal.utils.setColorProperty(...
                this.PeakResponseYLines,"Color","--mw-graphics-colorNeutral-line-primary");
        end

        function updateData(this,~,~,ka)
            data = this.Response.ResponseData;
            peakResponseData = data.SigmaPeakResponse;
            responseObjects = getResponseObjects(this.ResponseView,1,1,ka);
            responseLine = responseObjects{1}(peakResponseData.IdxForPeakValue);
            ax = responseLine.Parent;

            m = this.PeakResponseMarkers(ka);
            xl = this.PeakResponseXLines(ka);
            yl = this.PeakResponseYLines(ka);

            frequencyConversionFcn = getFrequencyUnitConversionFcn(this,this.Response.FrequencyUnit,this.FrequencyUnit);
            magnitudeConversionFcn = getMagnitudeUnitConversionFcn(this,this.Response.MagnitudeUnit,this.MagnitudeUnit);

            peakFrequency = frequencyConversionFcn(peakResponseData.Frequency{ka});

            responseFrequency = frequencyConversionFcn(data.Frequency{ka});
            responseMagnitude = magnitudeConversionFcn(data.SingularValue{ka}(peakResponseData.IdxForPeakValue,:));
            peakSingularValue = this.scaledInterp1(responseFrequency,responseMagnitude,peakFrequency,...
                ax.XScale,ax.YScale);

            % Update markers
            m.XData = peakFrequency;
            m.YData = peakSingularValue;
                
            % Update X line
            xl.XData = [peakFrequency peakFrequency];
            xl.YData = [-1e20 peakSingularValue];
            % Update Y line
            yl.XData = [-1e20 peakFrequency];
            yl.YData = [peakSingularValue peakSingularValue];
        end

        function updateDataByLimits(this,~,~,ka)
            % Update characteristic data based on responseHandle and parent axes]
            data = this.Response.ResponseData;
            peakResponseData = data.SigmaPeakResponse;
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
            data = this.Response.ResponseData.SigmaPeakResponse;

            % Peak Gain Row
            magnitudeConversionFcn = getMagnitudeUnitConversionFcn(this,this.Response.MagnitudeUnit,this.MagnitudeUnit);
            peakGainRow = dataTipTextRow(getString(message('Controllib:plots:strPeakGain')) + ...
                " (" + this.MagnitudeUnitLabel + ")",magnitudeConversionFcn(data.Value{ka}),'%0.3g');

            % Frequency Row
            frequencyConversionFcn = getFrequencyUnitConversionFcn(this,this.Response.FrequencyUnit,this.FrequencyUnit);
            frequencyRow = dataTipTextRow(...
                getString(message('Controllib:plots:strFrequency')) + " (" + this.FrequencyUnitLabel + ")",...
                frequencyConversionFcn(data.Frequency{ka}),'%0.3g');
            
            this.PeakResponseMarkers(ka).DataTipTemplate.DataTipRows = [...
                nameDataTipRow; peakGainRow; frequencyRow; customDataTipRows(:)];
        end

        function cbFrequencyUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ka = 1:this.Response.NResponses
                    this.PeakResponseMarkers(ka).XData = conversionFcn(this.PeakResponseMarkers(ka).XData);
                    this.PeakResponseXLines(ka).XData = conversionFcn(this.PeakResponseXLines(ka).XData);
                    this.PeakResponseYLines(ka).XData(2) = conversionFcn(this.PeakResponseYLines(ka).XData(2));

                    % Update data tip
                    this.PeakResponseMarkers(ka).DataTipTemplate.DataTipRows(3).Label = ...
                        getString(message('Controllib:plots:strFrequency')) + ...
                        " (" + this.FrequencyUnitLabel + ")";
                    this.PeakResponseMarkers(ka).DataTipTemplate.DataTipRows(3).Value = this.PeakResponseXLines(ka).XData(1);
                end
            end
        end

        function cbMagnitudeUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ka = 1:this.Response.NResponses
                    this.PeakResponseMarkers(ka).YData = conversionFcn(this.PeakResponseMarkers(ka).YData);
                    this.PeakResponseXLines(ka).YData(2) = conversionFcn(this.PeakResponseXLines(ka).YData(2));
                    this.PeakResponseYLines(ka).YData = conversionFcn(this.PeakResponseYLines(ka).YData);

                    % Update data tip
                    this.PeakResponseMarkers(ka).DataTipTemplate.DataTipRows(2).Label = ...
                        getString(message('Controllib:plots:strPeakGain')) + ...
                        " (" + this.MagnitudeUnitLabel + ")";
                    this.PeakResponseMarkers(ka).DataTipTemplate.DataTipRows(2).Value = this.PeakResponseYLines(ka).YData(1);
                end
            end
        end

        function c = getMarkerObjects_(this,~,~,ka)
            c = this.PeakResponseMarkers(ka);
        end

        function l = getSupportingObjects_(this,~,~,ka)
            l = cat(3,this.PeakResponseXLines(ka),this.PeakResponseYLines(ka));
        end
    end
end
