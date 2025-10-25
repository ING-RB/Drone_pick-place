classdef DiskMarginMinimumResponseView < controllib.chart.internal.view.characteristic.BaseCharacteristicView & ...
        controllib.chart.internal.foundation.MixInFrequencyUnit & ...
        controllib.chart.internal.foundation.MixInMagnitudeUnit & ...
        controllib.chart.internal.foundation.MixInPhaseUnit
    % this = controllib.chart.internal.view.characteristic.TimePeakResponseView(data)
    %
    % Copyright 2021 The MathWorks, Inc.
    
    %% Properties
    properties (SetAccess = protected)
        MinGainMarginResponseMarkers
        MinPhaseMarginResponseMarkers
    end
    
    %% Constructor
    methods
        function this = DiskMarginMinimumResponseView(response,data)
            this@controllib.chart.internal.view.characteristic.BaseCharacteristicView(response,data);
            this@controllib.chart.internal.foundation.MixInFrequencyUnit(response.FrequencyUnit);
            this@controllib.chart.internal.foundation.MixInMagnitudeUnit(response.MagnitudeUnit);
            this@controllib.chart.internal.foundation.MixInPhaseUnit(response.PhaseUnit);
            this.ResponseLineIdx = [1 2];
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)
            this.MinGainMarginResponseMarkers = createGraphicsObjects(this,"scatter",1,1,this.Response.NResponses,Tag='DiskMarginMinimumGainMarginScatter');
            this.MinPhaseMarginResponseMarkers = createGraphicsObjects(this,"scatter",1,1,this.Response.NResponses,Tag='DiskMarginMinimumPhaseMarginScatter');
        end
        
        function updateData(this,~,~,ka)
            data = this.Response.ResponseData;
            minResponseData = data.DiskMarginMinimumResponse;
            responseObjects = getResponseObjects(this.ResponseView,1,1,ka);
            gainResponseLine = responseObjects{1}(this.ResponseLineIdx(1));
            phaseResponseLine = responseObjects{1}(this.ResponseLineIdx(2));
            gainAx = gainResponseLine.Parent;
            phaseAx = phaseResponseLine.Parent;

            frequencyConversionFcn = getFrequencyUnitConversionFcn(this,this.Response.FrequencyUnit,this.FrequencyUnit);
            magnitudeConversionFcn = getMagnitudeUnitConversionFcn(this,this.Response.MagnitudeUnit,this.MagnitudeUnit);
            phaseConversionFcn = getPhaseUnitConversionFcn(this,this.Response.PhaseUnit,this.PhaseUnit);

            minFrequency = frequencyConversionFcn(minResponseData.Frequency{ka});

            responseFrequency = frequencyConversionFcn(data.Frequency{ka});
            responseGainMargin = magnitudeConversionFcn(data.GainMargin{ka});
            minGainMargin = this.scaledInterp1(responseFrequency,responseGainMargin,minFrequency,...
                gainAx.XScale,gainAx.YScale);
            responsePhaseMargin = phaseConversionFcn(data.PhaseMargin{ka});
            minPhaseMargin = this.scaledInterp1(responseFrequency,responsePhaseMargin,minFrequency,...
                phaseAx.XScale,phaseAx.YScale);

            mg = this.MinGainMarginResponseMarkers(ka);
            mp = this.MinPhaseMarginResponseMarkers(ka);

            % Update markers
            mg.XData = minFrequency;
            mg.YData = minGainMargin;
            
            mp.XData = minFrequency;
            mp.YData = minPhaseMargin;
        end

        function updateDataByLimits(this,~,~,ka)
            data = this.Response.ResponseData;
            minResponseData = data.DiskMarginMinimumResponse; 
            frequencyConversionFcn = getFrequencyUnitConversionFcn(this,this.Response.FrequencyUnit,this.FrequencyUnit);           
            minFrequency = frequencyConversionFcn(minResponseData.Frequency{ka});

            responseObjects = getResponseObjects(this.ResponseView,1,1,ka);
            gainResponseLine = responseObjects{1}(this.ResponseLineIdx(1));
            phaseResponseLine = responseObjects{1}(this.ResponseLineIdx(2));
            gainAx = gainResponseLine.Parent;
            phaseAx = phaseResponseLine.Parent;

            mg = this.MinGainMarginResponseMarkers(ka);
            mp = this.MinPhaseMarginResponseMarkers(ka);

            for ii = this.ResponseLineIdx
                switch ii
                    case 1 %gain
                        m = mg;
                        ax = gainAx;
                        responseLine = gainResponseLine;
                    case 4 %phase
                        m = mp;
                        ax = phaseAx;
                        responseLine = phaseResponseLine;
                end
                % Update characteristic data based on responseHandle and parent axes
                xLim = ax.XLim;
                XScale = ax.XScale;
                YScale = ax.YScale;
                if strcmp(ax.XScale,'log') && minFrequency < 0
                    valueLessThanLimits = abs(minFrequency) < xLim(1);
                    valueGreaterThanLimits = abs(minFrequency) > xLim(2);
                else
                    valueLessThanLimits = minFrequency < xLim(1);
                    valueGreaterThanLimits = minFrequency > xLim(2);
                end
                m.UserData.ValueOutsideLimits = valueLessThanLimits || valueGreaterThanLimits;
                if valueLessThanLimits
                    % Value is less than lower x-limit of axes
                    x = xLim(1);
                    xData = responseLine.XData;
                    yData = responseLine.YData;
                    n = ceil(length(xData)/2);
                    if strcmp(ax.XScale,'log') && minFrequency < 0
                        xData = xData(1:n);
                        yData = yData(1:n);
                        idx = find(xData <= xLim(1),1,'first');
                    elseif strcmp(ax.XScale,'log') && minFrequency >= 0
                        xData = xData(n+1:end);
                        yData = yData(n+1:end);
                        idx = find(xData >= xLim(1),1,'first');
                    else
                        idx = find(xData >= xLim(1),1,'first');
                    end
                    if idx > 1
                        try
                            y = this.scaledInterp1(xData(idx-1:idx),yData(idx-1:idx),x,XScale,YScale);
                        catch %infinite margin
                            y = yData(idx);
                        end
                    else
                        y = yData(1);
                    end
                elseif valueGreaterThanLimits
                    % Value is greater than higher x-limit of axes
                    x = xLim(2);
                    xData = responseLine.XData;
                    yData = responseLine.YData;
                    n = ceil(length(xData)/2);
                    if strcmp(ax.XScale,'log') && minFrequency < 0
                        xData = xData(1:n);
                        yData = yData(1:n);
                        idx = find(xData >= xLim(2),1,'last');
                    elseif strcmp(ax.XScale,'log') && minFrequency >= 0
                        xData = xData(n+1:end);
                        yData = yData(n+1:end);
                        idx = find(xData <= xLim(2),1,'last');
                    else
                        idx = find(xData <= xLim(2),1,'last');
                    end
                    if idx < length(yData)
                        try
                            y = this.scaledInterp1(xData(idx:idx+1),yData(idx:idx+1),x,XScale,YScale);
                        catch %infinite margin
                            y = yData(idx);
                        end
                    else
                        y = yData(end);
                    end
                else
                    % Value is within x-limits
                    xData = responseLine.XData;
                    yData = responseLine.YData;
                    n = ceil(length(xData)/2);
                    if strcmp(ax.XScale,'log') && minFrequency < 0
                        x = -minFrequency;
                        xData = xData(1:n);
                        yData = yData(1:n);
                        [~,idx] = min(abs(xData - x));
                        y = yData(idx);
                    elseif strcmp(ax.XScale,'log') && minFrequency >= 0
                        x = minFrequency;
                        xData = xData(n+1:end);
                        yData = yData(n+1:end);
                        [~,idx] = min(abs(xData - x));
                        y = yData(idx);
                    else
                        x = minFrequency;
                        [~,idx] = min(abs(xData - x));
                        y = yData(idx);
                    end
                end
                m.XData = x;
                m.YData = y;
            end
        end

        function updateDataTips_(this,~,~,ka,nameDataTipRow,customDataTipRows)
            data = this.Response.ResponseData.DiskMarginMinimumResponse;

            % Disk Margin Row
            diskMarginRow = dataTipTextRow(getString(message('Controllib:plots:strDiskMargin')),...
                data.DiskMargin{ka},'%0.3g');

            % Gain Margin Row
            magnitudeConversionFcn = getMagnitudeUnitConversionFcn(this,this.Response.MagnitudeUnit,this.MagnitudeUnit);
            gainMarginRow = dataTipTextRow(getString(message('Controllib:plots:strGainMargin')) + ...
                " (" + this.MagnitudeUnitLabel + ")",magnitudeConversionFcn(data.GainMargin{ka}),'%0.3g');

            % Phase Margin Row
            phaseConversionFcn = getPhaseUnitConversionFcn(this,this.Response.PhaseUnit,this.PhaseUnit);
            phaseMarginRow = dataTipTextRow(getString(message('Controllib:plots:strPhaseMargin')) + ...
                " (" + this.PhaseUnitLabel + ")",phaseConversionFcn(data.PhaseMargin{ka}),'%0.3g');

            % Frequency Row
            frequencyConversionFcn = getFrequencyUnitConversionFcn(this,...
                        this.Response.FrequencyUnit,this.FrequencyUnit);
            frequencyRow = dataTipTextRow(...
                getString(message('Controllib:plots:strFrequency')) + " (" + this.FrequencyUnitLabel + ")",...
                frequencyConversionFcn(data.Frequency{ka}),'%0.3g');

            % Stable Row
            if isnan(data.DiskMargin{ka})
                strStable = string(getString(message('Controllib:plots:strNotKnown')));
            elseif data.DiskMargin{ka} > 0
                strStable = string(getString(message('Controllib:plots:strYes')));
            else
                strStable = string(getString(message('Controllib:plots:strNo')));
            end
            stableRow = dataTipTextRow(getString(message(...
                'Controllib:plots:strClosedLoopStableQuestion')),@(x) strStable);
            
            this.MinGainMarginResponseMarkers(ka).DataTipTemplate.DataTipRows = [...
                nameDataTipRow; diskMarginRow; gainMarginRow; frequencyRow; stableRow; customDataTipRows(:)];
            this.MinPhaseMarginResponseMarkers(ka).DataTipTemplate.DataTipRows = [...
                nameDataTipRow; diskMarginRow; phaseMarginRow; frequencyRow; stableRow; customDataTipRows(:)];
        end

        function cbFrequencyUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ka = 1:this.Response.NResponses
                    minGainMarker = this.MinGainMarginResponseMarkers(ka);
                    minGainMarker.XData = conversionFcn(minGainMarker.XData);

                    minGainMarker.DataTipTemplate.DataTipRows(4).Label = ...
                        getString(message('Controllib:plots:strFrequency')) + ...
                        " (" + this.FrequencyUnitLabel + ")";
                    minGainMarker.DataTipTemplate.DataTipRows(4).Value = ...
                        conversionFcn(minGainMarker.DataTipTemplate.DataTipRows(4).Value);

                    minPhaseMarker = this.MinPhaseMarginResponseMarkers(ka);
                    minPhaseMarker.XData = conversionFcn(minPhaseMarker.XData);

                    minPhaseMarker.DataTipTemplate.DataTipRows(4).Label = ...
                        getString(message('Controllib:plots:strFrequency')) + ...
                        " (" + this.FrequencyUnitLabel + ")";
                    minPhaseMarker.DataTipTemplate.DataTipRows(4).Value = ...
                        conversionFcn(minPhaseMarker.DataTipTemplate.DataTipRows(4).Value);
                end
            end
        end

        function cbMagnitudeUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ka = 1:this.Response.NResponses
                    minGainMarker = this.MinGainMarginResponseMarkers(ka);
                    minGainMarker.YData = conversionFcn(minGainMarker.YData);

                    minGainMarker.DataTipTemplate.DataTipRows(3).Label = ...
                            getString(message('Controllib:plots:strGainMargin')) + ...
                            " (" + this.MagnitudeUnitLabel + ")";
                    minGainMarker.DataTipTemplate.DataTipRows(3).Value = ...
                        conversionFcn(minGainMarker.DataTipTemplate.DataTipRows(3).Value);
                end
            end
        end

        function cbPhaseUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ka = 1:this.Response.NResponses
                    minPhaseMarker = this.MinPhaseMarginResponseMarkers(ka);
                    minPhaseMarker.YData = conversionFcn(minPhaseMarker.YData);

                    minPhaseMarker.DataTipTemplate.DataTipRows(3).Label = ...
                            getString(message('Controllib:plots:strPhaseMargin')) + ...
                            " (" + this.PhaseUnitLabel + ")";
                    minPhaseMarker.DataTipTemplate.DataTipRows(3).Value = ...
                        conversionFcn(minPhaseMarker.DataTipTemplate.DataTipRows(3).Value);
                end
            end
        end

        function c = getMarkerObjects_(this,~,~,ka)
            c = [this.MinGainMarginResponseMarkers(ka);this.MinPhaseMarginResponseMarkers(ka)];
        end
    end
end