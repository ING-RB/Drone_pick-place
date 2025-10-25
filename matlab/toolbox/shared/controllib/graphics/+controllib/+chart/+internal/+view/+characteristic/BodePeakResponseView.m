classdef BodePeakResponseView < controllib.chart.internal.view.characteristic.FrequencyCharacteristicView & ...
                                               controllib.chart.internal.foundation.MixInMagnitudeUnit
    % this = controllib.chart.internal.view.characteristic.TimePeakResponseView(data)
    %
    % Copyright 2021 The MathWorks, Inc.
    
    %% Properties
    properties (Dependent,AbortSet,SetObservable)
        InteractionMode
    end

    properties (SetAccess = protected)
        PeakResponseMarkers
        PeakResponseXLines
        PeakResponseYLines
    end

    properties (Access=private)
        % Dummy objects for phase parenting
        DummyMarkers
        DummyXLines
        DummyYLines
        InteractionMode_I = "default"
    end
    
    %% Constructor
    methods
        function this = BodePeakResponseView(responseView,data)
            this@controllib.chart.internal.view.characteristic.FrequencyCharacteristicView(responseView,data);
            this@controllib.chart.internal.foundation.MixInMagnitudeUnit(responseView.MagnitudeUnit);
            this.ResponseLineIdx = 1;
        end
    end

    %% Get/Set
    methods
        % InteractionMode        
        function InteractionMode = get.InteractionMode(this)
            InteractionMode = this.InteractionMode_I;
        end

        function set.InteractionMode(this,InteractionMode)
            switch InteractionMode
                case "default"          
                    set(this.PeakResponseMarkers,HitTest='on');
                otherwise
                    set(this.PeakResponseMarkers,HitTest='off');
            end
            this.InteractionMode_I = InteractionMode;
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)
            this.PeakResponseMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='BodePeakResponseScatter');
            this.PeakResponseXLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='BodePeakResponseXLine');
            set(this.PeakResponseXLines,LineStyle='-.',XData=[NaN NaN],YData=[NaN NaN])
            controllib.plot.internal.utils.setColorProperty(...
                this.PeakResponseXLines,"Color","--mw-graphics-colorNeutral-line-primary");
            this.PeakResponseYLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='BodePeakResponseYLine');
            set(this.PeakResponseYLines,LineStyle='-.',XData=[NaN NaN],YData=[NaN NaN])
            controllib.plot.internal.utils.setColorProperty(...
                this.PeakResponseYLines,"Color","--mw-graphics-colorNeutral-line-primary");
            this.DummyMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses);
            this.DummyXLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses);
            this.DummyYLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses);
        end

        function updateData(this,ko,ki,ka)
            data = this.Response.ResponseData;
            peakResponseData = this.Response.ResponseData.BodePeakResponse;
            responseObjects = getResponseObjects(this.ResponseView,ko,ki,ka);
            responseLine = responseObjects{1}(this.ResponseLineIdx);
            ax = responseLine.Parent;
            
            if ~isempty(ax)
                frequencyConversionFcn = getFrequencyUnitConversionFcn(this,this.Response.FrequencyUnit,this.FrequencyUnit);
                magnitudeConversionFcn = getMagnitudeUnitConversionFcn(this,this.Response.MagnitudeUnit,this.MagnitudeUnit);

                peakFrequency = frequencyConversionFcn(peakResponseData.Frequency{ka}(ko,ki));

                responseFrequency = frequencyConversionFcn(data.Frequency{ka});
                responseMagnitude = magnitudeConversionFcn(data.Magnitude{ka}(:,ko,ki));
                peakMagnitude = this.scaledInterp1(responseFrequency,responseMagnitude,peakFrequency,...
                    ax.XScale,ax.YScale);

                m = this.PeakResponseMarkers(ko,ki,ka);
                xl = this.PeakResponseXLines(ko,ki,ka);
                yl = this.PeakResponseYLines(ko,ki,ka);

                % Update markers
                m.XData = peakFrequency;
                m.YData = peakMagnitude;

                % Update X line
                xl.XData = [peakFrequency peakFrequency];
                xl.YData = [-1e20 peakMagnitude];
                % Update Y line
                yl.XData = [-1e20 peakFrequency];
                yl.YData = [peakMagnitude peakMagnitude];
            end
        end

        function updateDataByLimits(this,ko,ki,ka)
            responseObjects = getResponseObjects(this.ResponseView,ko,ki,ka);
            responseLine = responseObjects{1}(this.ResponseLineIdx);
            ax = responseLine.Parent;

            m = this.PeakResponseMarkers(ko,ki,ka);
            xl = this.PeakResponseXLines(ko,ki,ka);
            yl = this.PeakResponseYLines(ko,ki,ka);

            % Update characteristic data based on responseHandle and parent axes
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
                    xData = xData(floor(length(xData)/2)+1:end);
                    yData = yData(floor(length(yData)/2)+1:end);
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
                    xData = xData(1:floor(length(xData)/2));
                    yData = yData(1:floor(length(yData)/2));
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

        function updateDataTips_(this,ko,ki,ka,nameDataTipRow,ioDataTipRow,customDataTipRows)
            data = this.Response.ResponseData.BodePeakResponse;

            % Peak Gain Row
            magnitudeConversionFcn = getMagnitudeUnitConversionFcn(this,this.Response.MagnitudeUnit,this.MagnitudeUnit);
            peakGainRow = dataTipTextRow(getString(message('Controllib:plots:strPeakGain')) + ...
                " (" + this.MagnitudeUnitLabel + ")",magnitudeConversionFcn(data.Magnitude{ka}(ko,ki)),'%0.3g');

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
                            this.PeakResponseMarkers(ko,ki,ka).XData = conversionFcn(this.PeakResponseMarkers(ko,ki,ka).XData);
                            this.PeakResponseXLines(ko,ki,ka).XData = conversionFcn(this.PeakResponseXLines(ko,ki,ka).XData);
                            this.PeakResponseYLines(ko,ki,ka).XData(2) = conversionFcn(this.PeakResponseYLines(ko,ki,ka).XData(2));

                            % Update data tip
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

        function cbMagnitudeUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        for ka = 1:this.Response.NResponses
                            this.PeakResponseMarkers(ko,ki,ka).YData = conversionFcn(this.PeakResponseMarkers(ko,ki,ka).YData);
                            this.PeakResponseXLines(ko,ki,ka).YData(2) = conversionFcn(this.PeakResponseXLines(ko,ki,ka).YData(2));
                            this.PeakResponseYLines(ko,ki,ka).YData = conversionFcn(this.PeakResponseYLines(ko,ki,ka).YData);

                            % Update data tip
                            rowNum = this.replaceDataTipRowLabel(this.PeakResponseMarkers(ko,ki,ka),...
                                getString(message('Controllib:plots:strPeakGain')),...
                                getString(message('Controllib:plots:strPeakGain')) + ...
                                " (" + this.MagnitudeUnitLabel + ")");
                            this.PeakResponseMarkers(ko,ki,ka).DataTipTemplate.DataTipRows(rowNum).Value = ...
                                conversionFcn(this.PeakResponseMarkers(ko,ki,ka).DataTipTemplate.DataTipRows(rowNum).Value);
                        end
                    end
                end
            end
        end

        function c = getMarkerObjects_(this,ko,ki,ka)
            c = [this.PeakResponseMarkers(ko,ki,ka);this.DummyMarkers(ko,ki,ka)];
        end

        function l = getSupportingObjects_(this,ko,ki,ka)
               l = [cat(3,this.PeakResponseXLines(ko,ki,ka), this.PeakResponseYLines(ko,ki,ka));...
                   cat(3,this.DummyXLines(ko,ki,ka),this.DummyYLines(ko,ki,ka))];
        end
    end
end