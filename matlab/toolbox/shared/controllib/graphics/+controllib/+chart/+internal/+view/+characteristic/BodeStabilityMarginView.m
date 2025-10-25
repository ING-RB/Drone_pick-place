classdef BodeStabilityMarginView < controllib.chart.internal.view.characteristic.FrequencyCharacteristicView & ...
        controllib.chart.internal.foundation.MixInMagnitudeUnit & ...
        controllib.chart.internal.foundation.MixInPhaseUnit
    % this = controllib.chart.internal.view.characteristic.TimePeakResponseView(data)
    %
    % Copyright 2021-2022 The MathWorks, Inc.

    %% Properties
    properties (Dependent,AbortSet,SetObservable)
        InteractionMode
    end

    properties (SetAccess = protected)
        GainMarginMarkers
        GainMarginOpenMarkers
        GainMarginXLines
        GainMarginYLines
        PhaseMarginMarkers
        PhaseMarginOpenMarkers
        PhaseMarginXLines
        PhaseMarginYLines
    end

    properties (Dependent,SetAccess=private)
        ShowAllMargins
    end

    properties (Access=private)
        InteractionMode_I = "default"
    end

    %% Constructor
    methods
        function this = BodeStabilityMarginView(responseView,data)
            this@controllib.chart.internal.view.characteristic.FrequencyCharacteristicView(responseView,data);
            this@controllib.chart.internal.foundation.MixInMagnitudeUnit(responseView.MagnitudeUnit);
            this@controllib.chart.internal.foundation.MixInPhaseUnit(responseView.PhaseUnit);
            this.ResponseLineIdx = [1 2];
        end
    end

    %% Get/Set
    methods
        % ShowAllMargins
        function ShowAllMargins = get.ShowAllMargins(this)
            ShowAllMargins = this.Type == "AllStabilityMargins";
        end

        % InteractionMode
        function InteractionMode = get.InteractionMode(this)
            InteractionMode = this.InteractionMode_I;
        end

        function set.InteractionMode(this,InteractionMode)
            switch InteractionMode
                case "default"
                    set(this.GainMarginMarkers,HitTest='on');
                    set(this.GainMarginOpenMarkers,HitTest='on');
                    set(this.PhaseMarginMarkers,HitTest='on');
                    set(this.PhaseMarginOpenMarkers,HitTest='on');
                otherwise
                    set(this.GainMarginMarkers,HitTest='off');
                    set(this.GainMarginOpenMarkers,HitTest='off');
                    set(this.PhaseMarginMarkers,HitTest='off');
                    set(this.PhaseMarginOpenMarkers,HitTest='off');
            end
            this.InteractionMode_I = InteractionMode;
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)
            this.GainMarginMarkers = createGraphicsObjects(this,"scatter",1,1,this.Response.NResponses,Tag='BodeGainMarginScatter');
            this.GainMarginOpenMarkers = createGraphicsObjects(this,"scatter",1,1,this.Response.NResponses,Tag='BodeGainMarginScatter');
            set(this.GainMarginOpenMarkers,UserData=struct('ValueOutsideLimits',true));
            this.GainMarginXLines = createGraphicsObjects(this,"line",1,1,this.Response.NResponses,...
                HitTest='off',PickableParts='none',Tag='BodeGainMarginXLine');
            set(this.GainMarginXLines,LineStyle='-.',XData=[NaN NaN],YData=[NaN NaN])
            controllib.plot.internal.utils.setColorProperty(...
                this.GainMarginXLines,"Color","--mw-graphics-colorNeutral-line-primary");
            this.GainMarginYLines = createGraphicsObjects(this,"constantLine",1,1,...
                this.Response.NResponses,HitTest='off',PickableParts='none',Tag='BodeGainMarginYLine');
            set(this.GainMarginYLines,LineStyle='-.',InterceptAxis='y')
            controllib.plot.internal.utils.setColorProperty(...
                this.GainMarginYLines,"Color","--mw-graphics-colorNeutral-line-primary");
            this.PhaseMarginMarkers = createGraphicsObjects(this,"scatter",1,1,this.Response.NResponses,Tag='BodePhaseMarginMarker');
            this.PhaseMarginOpenMarkers = createGraphicsObjects(this,"scatter",1,1,this.Response.NResponses,Tag='BodePhaseMarginMarker');
            set(this.PhaseMarginOpenMarkers,UserData=struct('ValueOutsideLimits',true));
            this.PhaseMarginXLines = createGraphicsObjects(this,"line",1,1,this.Response.NResponses,...
                HitTest='off',PickableParts='none',Tag='BodePhaseMarginXLine');
            set(this.PhaseMarginXLines,LineStyle='-.',XData=[NaN NaN],YData=[NaN NaN])
            controllib.plot.internal.utils.setColorProperty(...
                this.PhaseMarginXLines,"Color","--mw-graphics-colorNeutral-line-primary");
            this.PhaseMarginYLines = createGraphicsObjects(this,"line",1,1,this.Response.NResponses,...
                HitTest='off',PickableParts='none',Tag='BodePhaseMarginYLine');
            set(this.PhaseMarginYLines,LineStyle='-.',XData=[NaN NaN],YData=[NaN NaN])
            controllib.plot.internal.utils.setColorProperty(...
                this.PhaseMarginYLines,"Color","--mw-graphics-colorNeutral-line-primary");
        end

        function updateData(this,~,~,ka)
            % Use AllStabilityMargins if specified
            if this.ShowAllMargins
                data = this.Response.ResponseData.AllStabilityMargin;
            else
                data = this.Response.ResponseData.MinimumStabilityMargin;
            end
            responseObjects = getResponseObjects(this.ResponseView,1,1,ka);
            phaseResponseLine = responseObjects{1}(this.ResponseLineIdx(2));

            % Get conversion functions
            frequencyConversionFcn = getFrequencyUnitConversionFcn(this,this.Response.FrequencyUnit,this.FrequencyUnit);
            magnitudeConversionFcn = getMagnitudeUnitConversionFcn(this,'abs',this.MagnitudeUnit);
            phaseConversionFcn = getPhaseUnitConversionFcn(this,'deg',this.PhaseUnit);

            % Get data
            gmFrequency = data.GMFrequency{ka};
            gmValue = data.GainMargin{ka};

            % Set NaNs
            this.GainMarginMarkers(ka).XData = NaN;
            this.GainMarginMarkers(ka).YData = NaN;
            this.GainMarginOpenMarkers(ka).XData = NaN;
            this.GainMarginOpenMarkers(ka).YData = NaN;
            this.GainMarginXLines(ka).XData = [NaN NaN];
            this.GainMarginXLines(ka).YData = [NaN NaN];
            this.GainMarginYLines(ka).Value = NaN;
            if ~isempty(gmFrequency) && any(~isnan(gmFrequency))
                % Get number of gain margins and initialize variables
                % Set xdata and ydata
                for k = 1:length(gmFrequency)
                    f = frequencyConversionFcn(gmFrequency(k));
                    y = -magnitudeConversionFcn(gmValue(k));
                    % Set marker data for gain margins within focus
                    this.GainMarginMarkers(ka).XData(k) = f;
                    this.GainMarginMarkers(ka).YData(k) = y;
                    % Set xline data
                    this.GainMarginXLines(ka).XData((3*(k-1)+1):3*k) = [f f NaN];
                    this.GainMarginXLines(ka).YData((3*(k-1)+1):3*k) = [magnitudeConversionFcn(1), y NaN];
                end
                % YLines
                this.GainMarginYLines(ka).Value = magnitudeConversionFcn(1);
            end

            % Get data
            pmFrequency = data.PMFrequency{ka};
            pmValue = data.PhaseMargin{ka};

            this.PhaseMarginMarkers(ka).XData = NaN;
            this.PhaseMarginMarkers(ka).YData = NaN;
            this.PhaseMarginOpenMarkers(ka).XData = NaN;
            this.PhaseMarginOpenMarkers(ka).YData = NaN;
            this.PhaseMarginXLines(ka).XData = [NaN NaN];
            this.PhaseMarginXLines(ka).YData = [NaN NaN];
            this.PhaseMarginYLines(ka).XData = [NaN NaN];
            this.PhaseMarginYLines(ka).YData = [NaN NaN];
            if ~isempty(pmFrequency) && any(~isnan(pmFrequency))
                % Get number of gain margins and initialize variables
                for k = 1:length(pmFrequency)
                    f = frequencyConversionFcn(pmFrequency(k));
                    % Check phase at Phase Margin frequency to compute
                    % YData for marker (the marker should be close to the
                    % phase response)
                    [~,idx] = min(abs(phaseResponseLine.XData - f));
                    pmResponseValue = phaseResponseLine.YData(idx);
                    pmData = phaseConversionFcn(pmValue(k));
                    % Add (-180 - 360*m) to the Phase Margin value (in degrees)
                    if strcmp(this.PhaseUnit,'deg')
                        m = round((-180 - (pmResponseValue - pmData))/360);
                        y = -180 - 360*m + pmData;
                    else
                        m = round((-pi - (pmResponseValue - pmData))/(2*pi));
                        y = -pi - 2*pi*m + pmData;
                    end
                    % Set marker data for phase margins within focus
                    this.PhaseMarginMarkers(ka).XData(k) = f;
                    this.PhaseMarginMarkers(ka).YData(k) = y;
                    % Set xline data
                    this.PhaseMarginXLines(ka).XData((3*(k-1)+1):3*k) = [f f NaN];
                    this.PhaseMarginXLines(ka).YData((3*(k-1)+1):3*k) = [phaseConversionFcn(-180 - 360*m) y NaN];

                    % Set yline data (horiztonal lines) if m computed above
                    % is different than before
                    this.PhaseMarginYLines(ka).XData((3*(k-1)+1):3*k) = [-1e20 1e20 NaN];
                    this.PhaseMarginYLines(ka).YData((3*(k-1)+1):3*k) = [phaseConversionFcn(-180 - 360*m)*ones(1,2) NaN];
                end
            end
        end

        function updateDataByLimits(this,~,~,ka)
            % Use AllStabilityMargins if specified
            responseObjects = getResponseObjects(this.ResponseView,1,1,ka);
            magnitudeResponseLine = responseObjects{1}(this.ResponseLineIdx(1));
            magAx = magnitudeResponseLine.Parent;
            phaseResponseLine = responseObjects{1}(this.ResponseLineIdx(2));
            phaseAx = phaseResponseLine.Parent;

            if this.ShowAllMargins
                data = this.Response.ResponseData.AllStabilityMargin;
            else
                data = this.Response.ResponseData.MinimumStabilityMargin;
            end

            m = this.GainMarginMarkers(ka);
            mo = this.GainMarginOpenMarkers(ka);
            % Update characteristic data based on responseHandle and parent axes
            for k = 1:length(m.XData)
                if ~isnan(m.XData(k))
                    f = data.GMFrequency{ka}(k);
                    isNegativeFrequencyInLogScale = f < 0 & strcmp(magAx.XScale,'log');
                    if isNegativeFrequencyInLogScale
                        f = -f;
                    end
                    m.XData(k) = f;
                    this.GainMarginXLines(ka).XData((3*(k-1)+1:3*(k-1)+2)) = [f,f];

                    if m.XData(k) < magAx.XLim(1)
                        % Value is less than lower x-limit of axes
                        mo.XData(k) = magAx.XLim(1);
                        idx = find(magnitudeResponseLine.XData >= magAx.XLim(1),1,'first');
                        f = magAx.XLim(1);
                        if idx > 1
                            y = this.scaledInterp1(magnitudeResponseLine.XData(idx-1:idx),magnitudeResponseLine.YData(idx-1:idx),f,...
                                magAx.XScale,magAx.YScale);
                        else
                            y = magnitudeResponseLine.YData(1);
                        end
                        mo.YData(k) = y;
                    elseif m.XData(k) > magAx.XLim(2)
                        % Value is greater than higher x-limit of axes
                        mo.XData(k) = magAx.XLim(2);
                        idx = find(magnitudeResponseLine.XData <= magAx.XLim(2),1,'last');
                        f = magAx.XLim(2);
                        if idx < length(magnitudeResponseLine.XData)
                            y = this.scaledInterp1(magnitudeResponseLine.XData(idx:idx+1),magnitudeResponseLine.YData(idx:idx+1),f,...
                                magAx.XScale,magAx.YScale);
                        else
                            y = magnitudeResponseLine.YData(end);
                        end
                        mo.YData(k) = y;
                    else
                        mo.XData(k) = NaN;
                        mo.YData(k) = NaN;

                        if isNegativeFrequencyInLogScale
                            idx = find(magnitudeResponseLine.XData <= f,1,'first');
                            if ~isempty(idx)
                                % Match the ydata to the response line ydata. This
                                % ensures that marker is on the line.
                                if idx < length(magnitudeResponseLine.XData)
                                    xIdx = idx-1:idx;
                                    y = this.scaledInterp1(magnitudeResponseLine.XData(xIdx),...
                                        magnitudeResponseLine.YData(xIdx),f,magAx.XScale,magAx.YScale);
                                else
                                    y = magnitudeResponseLine.YData(end);
                                end
                                m.YData(k) = y;
                                this.GainMarginXLines.YData(3*(k-1)+2) = y;
                            end
                        end
                    end
                end
            end

            m = this.PhaseMarginMarkers(ka);
            mo = this.PhaseMarginOpenMarkers(ka);
            % Update characteristic data based on responseHandle and parent axes
            for k = 1:length(m.XData)
                if ~isnan(m.XData(k))
                    f = data.PMFrequency{ka}(k);
                    isNegativeFrequencyInLogScale = f < 0 & strcmp(phaseAx.XScale,'log');
                    if isNegativeFrequencyInLogScale
                        f = -f;
                    end

                    m.XData(k) = f;
                    this.PhaseMarginXLines(ka).XData((3*(k-1)+1):3*(k-1)+2) = [f,f];

                    if m.XData(k) < phaseAx.XLim(1)
                        % Value is less than lower x-limit of axes
                        mo.XData(k) = phaseAx.XLim(1);
                        idx = find(phaseResponseLine.XData >= phaseAx.XLim(1),1,'first');
                        f = phaseAx.XLim(1);
                        if idx > 1
                            y = this.scaledInterp1(phaseResponseLine.XData(idx-1:idx),phaseResponseLine.YData(idx-1:idx),f,...
                                phaseAx.XScale,phaseAx.YScale);
                        else
                            y = phaseResponseLine.YData(1);
                        end
                        mo.YData(k) = y;
                    elseif m.XData(k) > phaseAx.XLim(2)
                        % Value is greater than higher x-limit of axes
                        mo.XData(k) = phaseAx.XLim(2);
                        idx = find(phaseResponseLine.XData <= phaseAx.XLim(2),1,'last');
                        f = phaseAx.XLim(2);
                        if idx < length(phaseResponseLine.XData)
                            y = this.scaledInterp1(phaseResponseLine.XData(idx:idx+1),phaseResponseLine.YData(idx:idx+1),f,...
                                phaseAx.XScale,phaseAx.YScale);
                        else
                            y = phaseResponseLine.YData(end);
                        end
                        mo.YData(k) = y;
                    else
                        mo.XData(k) = NaN;
                        mo.YData(k) = NaN;
                        f = m.XData(k);
                        y = m.YData(k);
                        if isNegativeFrequencyInLogScale
                            idx = find(phaseResponseLine.XData <= f,1,'first');
                        else
                            idx = find(phaseResponseLine.XData <= f,1,'last');
                        end
                        if ~isempty(idx)
                            % Match the ydata to the response line ydata. This
                            % ensures that marker is on the line.
                            if idx < length(phaseResponseLine.XData)
                                if isNegativeFrequencyInLogScale
                                    xIdx = idx-1:idx;
                                else
                                    xIdx = idx:idx+1;
                                end
                                y = this.scaledInterp1(phaseResponseLine.XData(xIdx),...
                                    phaseResponseLine.YData(xIdx),f,phaseAx.XScale,phaseAx.YScale);
                            else
                                y = phaseResponseLine.YData(end);
                            end
                            m.YData(k) = y;
                        end
                    end

                    if strcmp(this.PhaseUnit,'rad')
                        xLineData2 = rad2deg(y);
                    else
                        xLineData2 = y;
                    end
                    xLineData = round((xLineData2+180)/360)*360 - 180;
                    if strcmp(this.PhaseUnit,'rad')
                        xLineData = deg2rad(xLineData);
                    end

                    this.PhaseMarginXLines(ka).YData((3*(k-1)+1:3*(k-1)+2)) = [xLineData,xLineData2];
                    this.PhaseMarginXLines(ka).XData((3*(k-1)+1:3*(k-1)+2)) = [m.XData(k),m.XData(k)];
                    this.PhaseMarginYLines(ka).YData((3*(k-1)+1:3*(k-1)+2)) = [xLineData,xLineData];
                end
            end
            this.PhaseMarginYLines(ka).XData(1:3:end) = phaseAx.XLim(1);
            this.PhaseMarginYLines(ka).XData(2:3:end) = phaseAx.XLim(2);
        end

        function updateDataTips_(this,~,~,ka,nameDataTipRow,~,customDataTipRows)
            % Use AllStabilityMargins if specified
            if this.ShowAllMargins
                data = this.Response.ResponseData.AllStabilityMargin;
            else
                data = this.Response.ResponseData.MinimumStabilityMargin;
            end

            % Gain Margin
            magnitudeConversionFcn = getMagnitudeUnitConversionFcn(this,'abs',this.MagnitudeUnit);
            if isempty(data.GainMargin{ka}) || all(isnan(data.GainMargin{ka}))
                gm = NaN;
            else
                gm = magnitudeConversionFcn(data.GainMargin{ka});
            end
            gainMarginRow = dataTipTextRow(getString(message('Controllib:plots:strGainMargin')) +...
                " (" + this.MagnitudeUnitLabel + ")",gm,'%0.3g');

            % Frequency
            frequencyConversionFcn = getFrequencyUnitConversionFcn(this,...
                this.Response.FrequencyUnit,this.FrequencyUnit);
            if isempty(data.GMFrequency{ka}) || all(isnan(data.GMFrequency{ka}))
                f = NaN;
            else
                f = frequencyConversionFcn(data.GMFrequency{ka});
            end
            frequencyRow = dataTipTextRow(getString(message('Controllib:plots:strFrequency')) + ...
                " (" + this.FrequencyUnitLabel + ")",f,'%0.3g');

            % Stability
            if isnan(data.Stable{ka})
                strStable = string(getString(message('Controllib:plots:strNotKnown')));
            elseif data.Stable{ka}
                strStable = string(getString(message('Controllib:plots:strYes')));
            else
                strStable = string(getString(message('Controllib:plots:strNo')));
            end
            stableRow = dataTipTextRow(getString(message(...
                'Controllib:plots:strClosedLoopStableQuestion')),@(x) strStable);

            % Set data tip template
            this.GainMarginMarkers(ka).DataTipTemplate.DataTipRows = ...
                [nameDataTipRow; gainMarginRow; frequencyRow; stableRow; customDataTipRows(:)];
            this.GainMarginOpenMarkers(ka).DataTipTemplate.DataTipRows = ...
                [nameDataTipRow; gainMarginRow; frequencyRow; stableRow; customDataTipRows(:)];

            % Phase Margin
            phaseConversionFcn = getPhaseUnitConversionFcn(this,'deg',this.PhaseUnit);
            if isempty(data.PhaseMargin{ka}) || all(isnan(data.PhaseMargin{ka}))
                pm = NaN;
            else
                pm = phaseConversionFcn(data.PhaseMargin{ka});
            end
            phaseMarginRow = dataTipTextRow(getString(message('Controllib:plots:strPhaseMargin')) +...
                " (" + this.PhaseUnitLabel + ")",pm,'%0.3g');

            % Delay Margin
            if isempty(data.DelayMargin{ka}) || all(isnan(data.DelayMargin{ka}))
                dm = NaN;
            else
                dm = data.DelayMargin{ka};
            end
            delayMarginRow = dataTipTextRow(getString(message('Controllib:plots:strDelayMargin')) +...
                " (" + getString(message('Controllib:gui:strSeconds')) + ")",dm,'%0.3g');

            % Frequency
            frequencyConversionFcn = getFrequencyUnitConversionFcn(this,...
                this.Response.FrequencyUnit,this.FrequencyUnit);
            if isempty(data.PMFrequency{ka}) || all(isnan(data.PMFrequency{ka}))
                f = NaN;
            else
                f = frequencyConversionFcn(data.PMFrequency{ka});
            end
            frequencyRow = dataTipTextRow(getString(message('Controllib:plots:strFrequency')) + ...
                " (" + this.FrequencyUnitLabel + ")",f,'%0.3g');

            % Stability
            if isnan(data.Stable{ka})
                strStable = string(getString(message('Controllib:plots:strNotKnown')));
            elseif data.Stable{ka}
                strStable = string(getString(message('Controllib:plots:strYes')));
            else
                strStable = string(getString(message('Controllib:plots:strNo')));
            end
            stableRow = dataTipTextRow(getString(message(...
                'Controllib:plots:strClosedLoopStableQuestion')),@(x) strStable);

            % Set data tip template
            this.PhaseMarginMarkers(ka).DataTipTemplate.DataTipRows = ...
                [nameDataTipRow; phaseMarginRow; delayMarginRow; frequencyRow; stableRow; customDataTipRows(:)];
            this.PhaseMarginOpenMarkers(ka).DataTipTemplate.DataTipRows = ...
                [nameDataTipRow; phaseMarginRow; delayMarginRow; frequencyRow; stableRow; customDataTipRows(:)];
        end

        function cbFrequencyUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ka = 1:this.Response.NResponses
                    % Update marker and lines xdata
                    this.GainMarginMarkers(ka).XData = conversionFcn(this.GainMarginMarkers(ka).XData);
                    this.GainMarginXLines(ka).XData = conversionFcn(this.GainMarginXLines(ka).XData);

                    % Update data tip
                    this.GainMarginMarkers(ka).DataTipTemplate.DataTipRows(3).Label = ...
                        getString(message('Controllib:plots:strFrequency')) + ...
                        " (" + this.FrequencyUnitLabel + ")";
                    this.GainMarginMarkers(ka).DataTipTemplate.DataTipRows(3).Value = ...
                        conversionFcn(this.GainMarginMarkers(ka).DataTipTemplate.DataTipRows(3).Value);

                    this.GainMarginOpenMarkers(ka).DataTipTemplate.DataTipRows(3).Label = ...
                        getString(message('Controllib:plots:strFrequency')) + ...
                        " (" + this.FrequencyUnitLabel + ")";
                    this.GainMarginOpenMarkers(ka).DataTipTemplate.DataTipRows(3).Value = ...
                        conversionFcn(this.GainMarginOpenMarkers(ka).DataTipTemplate.DataTipRows(3).Value);

                    % Update marker and lines xdata
                    this.PhaseMarginMarkers(ka).XData = conversionFcn(this.PhaseMarginMarkers(ka).XData);
                    this.PhaseMarginXLines(ka).XData = conversionFcn(this.PhaseMarginXLines(ka).XData);

                    % Update data tip
                    this.PhaseMarginMarkers(ka).DataTipTemplate.DataTipRows(4).Label = ...
                        getString(message('Controllib:plots:strFrequency')) + ...
                        " (" + this.FrequencyUnitLabel + ")";
                    this.PhaseMarginMarkers(ka).DataTipTemplate.DataTipRows(4).Value = ...
                        conversionFcn(this.PhaseMarginMarkers(ka).DataTipTemplate.DataTipRows(4).Value);
                    this.PhaseMarginOpenMarkers(ka).DataTipTemplate.DataTipRows(4).Label = ...
                        getString(message('Controllib:plots:strFrequency')) + ...
                        " (" + this.FrequencyUnitLabel + ")";
                    this.PhaseMarginOpenMarkers(ka).DataTipTemplate.DataTipRows(4).Value = ...
                        conversionFcn(this.PhaseMarginOpenMarkers(ka).DataTipTemplate.DataTipRows(4).Value);
                end
            end
        end

        function cbMagnitudeUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ka = 1:this.Response.NResponses
                    % Update marker
                    this.GainMarginMarkers(ka).YData = conversionFcn(this.GainMarginMarkers(ka).YData);

                    % Update xlines
                    this.GainMarginXLines(ka).YData = conversionFcn(this.GainMarginXLines(ka).YData);

                    % Update data tip
                    this.GainMarginMarkers(ka).DataTipTemplate.DataTipRows(2).Label = ...
                        getString(message('Controllib:plots:strGainMargin')) + ...
                        " (" + this.MagnitudeUnitLabel + ")";
                    this.GainMarginMarkers(ka).DataTipTemplate.DataTipRows(2).Value = ...
                        conversionFcn(this.GainMarginMarkers(ka).DataTipTemplate.DataTipRows(2).Value);

                    this.GainMarginOpenMarkers(ka).DataTipTemplate.DataTipRows(2).Label = ...
                        getString(message('Controllib:plots:strGainMargin')) + ...
                        " (" + this.MagnitudeUnitLabel + ")";
                    this.GainMarginOpenMarkers(ka).DataTipTemplate.DataTipRows(2).Value = ...
                        conversionFcn(this.GainMarginOpenMarkers(ka).DataTipTemplate.DataTipRows(2).Value);

                    % Update ylines
                    this.GainMarginYLines(ka).Value = conversionFcn(this.GainMarginYLines(ka).Value);
                end
            end
        end

        function cbPhaseUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ka = 1:this.Response.NResponses
                    % Update marker
                    this.PhaseMarginMarkers(ka).YData = conversionFcn(this.PhaseMarginMarkers(ka).YData);

                    % Update xlines
                    this.PhaseMarginXLines(ka).YData = conversionFcn(this.PhaseMarginXLines(ka).YData);

                    % Update data tip
                    this.PhaseMarginMarkers(ka).DataTipTemplate.DataTipRows(2).Label = ...
                        getString(message('Controllib:plots:strPhaseMargin')) +...
                        " (" + this.PhaseUnitLabel + ")";
                    this.PhaseMarginMarkers(ka).DataTipTemplate.DataTipRows(2).Value = ...
                        conversionFcn(this.PhaseMarginMarkers(ka).DataTipTemplate.DataTipRows(2).Value);

                    this.PhaseMarginOpenMarkers(ka).DataTipTemplate.DataTipRows(2).Label = ...
                        getString(message('Controllib:plots:strPhaseMargin')) +...
                        " (" + this.PhaseUnitLabel + ")";
                    this.PhaseMarginOpenMarkers(ka).DataTipTemplate.DataTipRows(2).Value = ...
                        conversionFcn(this.PhaseMarginOpenMarkers(ka).DataTipTemplate.DataTipRows(2).Value);

                    % Update ylines
                    this.PhaseMarginYLines(ka).YData = conversionFcn(this.PhaseMarginYLines(ka).YData);
                end
            end
        end

        function c = getMarkerObjects_(this,~,~,ka)
            c = [cat(3,this.GainMarginMarkers(ka),this.GainMarginOpenMarkers(ka));...
                cat(3,this.PhaseMarginMarkers(ka),this.PhaseMarginOpenMarkers(ka))];
        end

        function l = getSupportingObjects_(this,~,~,ka)
            l = [cat(3,this.GainMarginXLines(ka),this.GainMarginYLines(ka));...
                cat(3,this.PhaseMarginXLines(ka),this.PhaseMarginYLines(ka))];
        end
    end
end
