classdef TimeMagnitudeOutputPeakResponseView < controllib.chart.internal.view.characteristic.TimeOutputCharacteristicView
    % this = controllib.chart.internal.response.PeakResponseCharacteristic(data)
    %
    % Copyright 2021 The MathWorks, Inc.
    
    %% Properties
    properties (SetAccess = protected)
        PeakResponseMarkers
        PeakResponseXLines
        PeakResponseYLines
    end
    
    %% Constructor
    methods
        function this = TimeMagnitudeOutputPeakResponseView(responseView,data)
            this@controllib.chart.internal.view.characteristic.TimeOutputCharacteristicView(responseView,data);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)
            this.PeakResponseMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                1,this.Response.NResponses,Tag='TimePeakResponseScatter');
            this.PeakResponseXLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                1,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='TimePeakResponseXLine');
            set(this.PeakResponseXLines,LineStyle='-.',XData=[NaN NaN],YData=[NaN NaN])
            controllib.plot.internal.utils.setColorProperty(...
                this.PeakResponseXLines,"Color","--mw-graphics-colorNeutral-line-primary");
            this.PeakResponseYLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                1,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='TimePeakResponseYLine');
            set(this.PeakResponseYLines,LineStyle='-.',XData=[NaN NaN],YData=[NaN NaN])
            controllib.plot.internal.utils.setColorProperty(...
                this.PeakResponseYLines,"Color","--mw-graphics-colorNeutral-line-primary");
        end

        function updateData(this,ko,~,ka)
            data = this.Response.ResponseData;
            peakResponseData = data.PeakResponse;

            m = this.PeakResponseMarkers(ko,1,ka);
            xl = this.PeakResponseXLines(ko,1,ka);
            yl = this.PeakResponseYLines(ko,1,ka);

            conversionFcn = getTimeUnitConversionFcn(this,this.Response.ResponseData.TimeUnit,this.TimeUnit);
            peakTime = conversionFcn(peakResponseData.Time{ka}(ko,1));
            peakMagnitude = abs(peakResponseData.Value{ka}(ko,1));
            % Update markers
            m.XData = peakTime;
            m.YData = peakMagnitude;
            % Update X line
            xl.XData = [peakTime peakTime];
            xl.YData = [-1e20 peakMagnitude];
            % Update Y line
            yl.XData = [-1e20 peakTime];
            yl.YData = [peakMagnitude peakMagnitude];
        end

        % function updateDataByLimits(this,ko,~,ka)
        %     responseObjects = getResponseObjects(this.ResponseView,ko,1,ka);
        %     responseLine = responseObjects{1}(this.ResponseLineIdx);
        %     ax = responseLine.Parent;
        % 
        %     if ~isempty(ax)
        %         m = this.PeakResponseMarkers(ko,1,ka);
        %         xl = this.PeakResponseXLines(ko,1,ka);
        %         yl = this.PeakResponseYLines(ko,1,ka);
        % 
        %         peakTime = xl.XData(1);
        %         xLim = ax.XLim;
        %         yLim = ax.YLim;
        %         valueLessThanLimits = peakTime < xLim(1);
        %         valueGreaterThanLimits = peakTime > xLim(2);
        %         m.UserData.ValueOutsideLimits = valueLessThanLimits || valueGreaterThanLimits;
        %         if valueLessThanLimits
        %             % Value is less than lower x-limit of axes
        %             x = xLim(1);
        %             xData = responseLine.XData;
        %             yData = responseLine.YData;
        %             idx = find(xData >= xLim(1),1,'first');
        %             if idx > 1
        %                 y = interp1(xData(idx-1:idx),yData(idx-1:idx),x);
        %             else
        %                 y = yData(1);
        %             end
        %         elseif valueGreaterThanLimits
        %             % Value is greater than higher x-limit of axes
        %             x = xLim(2);
        %             xData = responseLine.XData;
        %             yData = responseLine.YData;
        %             idx = find(xData <= xLim(2),1,'last');
        %             if idx < length(yData)
        %                 y = interp1(xData(idx:idx+1),yData(idx:idx+1),x);
        %             else
        %                 y = yData(end);
        %             end
        %         else
        %             % Value is within x-limits
        %             x = peakTime;
        %             xData = responseLine.XData;
        %             yData = responseLine.YData;
        %             [~,idx] = min(abs(xData - x));
        %             y = yData(idx);
        %         end
        %         m.XData = x;
        %         m.YData = y;
        %         xl.YData(1) = yLim(1);
        %         yl.XData(1) = xLim(1);
        %     end
        % end

        function updateDataTips_(this,ko,ka,nameDataTipRow,outputDataTipRow,customDataTipRows)
            data = this.Response.ResponseData.PeakResponse;
            
            % Time
            timeConversionFcn = getTimeUnitConversionFcn(this,this.Response.TimeUnit,this.TimeUnit);
            timeRow = dataTipTextRow(getString(message('Controllib:plots:strAtTime')) + " (" + ...
                this.TimeUnitLabel + ")",timeConversionFcn(data.Time{ka}(ko,1)),'%0.3g');
            
            % Amplitude
            peakAmplitudeRow = dataTipTextRow(getString(message('Controllib:plots:strPeakAmplitude')),...
                data.Value{ka}(ko,1),'%0.3g');
            
            % Overshoot
            overshootRow = dataTipTextRow(getString(message('Controllib:plots:strOvershoot')) + " (%)", ...
                data.Overshoot{ka}(ko,1),'%0.3g');
            
            % Set DataTipRows
            this.PeakResponseMarkers(ko,1,ka).DataTipTemplate.DataTipRows = ...
                [nameDataTipRow; outputDataTipRow; peakAmplitudeRow; overshootRow; timeRow; customDataTipRows(:)];
        end

        function cbTimeUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ko = 1:this.Response.NRows
                    for ka = 1:this.Response.NResponses
                        this.PeakResponseMarkers(ko,1,ka).XData = conversionFcn(this.PeakResponseMarkers(ko,1,ka).XData);
                        this.PeakResponseXLines(ko,1,ka).XData = conversionFcn(this.PeakResponseXLines(ko,1,ka).XData);
                        this.PeakResponseYLines(ko,1,ka).XData(2) = conversionFcn(this.PeakResponseYLines(ko,1,ka).XData(2));

                        row = this.replaceDataTipRowLabel(this.PeakResponseMarkers(ko,1,ka),getString(message('Controllib:plots:strAtTime')),...
                            getString(message('Controllib:plots:strAtTime')) + " (" + this.TimeUnitLabel + ")");
                        this.PeakResponseMarkers(ko,1,ka).DataTipTemplate.DataTipRows(row).Value = this.PeakResponseXLines(ko,1,ka).XData(1);
                    end
                end
            end
        end

        function c = getMarkerObjects_(this,ko,~,ka)
            c = this.PeakResponseMarkers(ko,1,ka);
        end

        function l = getSupportingObjects_(this,ko,~,ka)
            l = cat(3,this.PeakResponseXLines(ko,1,ka),this.PeakResponseYLines(ko,1,ka));
        end
    end
end