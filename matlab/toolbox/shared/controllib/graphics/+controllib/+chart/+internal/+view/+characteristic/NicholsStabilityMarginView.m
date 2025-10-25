classdef NicholsStabilityMarginView < controllib.chart.internal.view.characteristic.FrequencyCharacteristicView & ...
                                               controllib.chart.internal.foundation.MixInMagnitudeUnit & ...
                                               controllib.chart.internal.foundation.MixInPhaseUnit
    % this = controllib.chart.internal.view.characteristic.TimePeakResponseView(data)
    %
    % Copyright 2021-2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent,AbortSet,SetObservable)
        InteractionMode
    end

    properties (SetAccess = protected)
        GainMarginMarkers
        GainMarginLines
        GainMarginFullLines
        PhaseMarginMarkers
        PhaseMarginLines
    end

    properties (Dependent,SetAccess=private)
        ShowAllMargins
    end

    properties (Access=private)
        InteractionMode_I = "default"
    end

    %% Constructor
    methods
        function this = NicholsStabilityMarginView(response,data)
            this@controllib.chart.internal.view.characteristic.FrequencyCharacteristicView(response,data);
            this@controllib.chart.internal.foundation.MixInMagnitudeUnit(response.MagnitudeUnit);
            this@controllib.chart.internal.foundation.MixInPhaseUnit(response.PhaseUnit);
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
                    set(this.PhaseMarginMarkers,HitTest='on');
                otherwise
                    set(this.GainMarginMarkers,HitTest='off');
                    set(this.PhaseMarginMarkers,HitTest='off');
            end
            this.InteractionMode_I = InteractionMode;
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)
            this.GainMarginMarkers = createGraphicsObjects(this,"scatter",1,1,this.Response.NResponses,Tag='NicholsGainMarginScatter');
            this.GainMarginLines = createGraphicsObjects(this,"line",1,1,this.Response.NResponses,...
                HitTest='off',PickableParts='none',Tag='NicholsGainMarginLine');
            controllib.plot.internal.utils.setColorProperty(...
                this.GainMarginLines,"Color","--mw-graphics-colorNeutral-line-primary");
            set(this.GainMarginLines,LineStyle='-.')
            this.GainMarginFullLines = createGraphicsObjects(this,"line",1,1,this.Response.NResponses,...
                HitTest='off',PickableParts='none',Tag='NicholsGainMarginXLine');
            set(this.GainMarginFullLines,LineStyle=':')
            controllib.plot.internal.utils.setColorProperty(...
                this.GainMarginFullLines,"Color","--mw-graphics-colorNeutral-line-primary");
            this.PhaseMarginMarkers = createGraphicsObjects(this,"scatter",1,1,this.Response.NResponses,Tag='NicholsPhaseMarginScatter');
            this.PhaseMarginLines = createGraphicsObjects(this,"line",1,1,this.Response.NResponses,...
                HitTest='off',PickableParts='none',Tag='NicholsPhaseMarginLine');
            set(this.PhaseMarginLines,LineStyle='-.')
            controllib.plot.internal.utils.setColorProperty(...
                this.PhaseMarginLines,"Color","--mw-graphics-colorNeutral-line-primary");
        end

        function updateData(this,~,~,ka)
            % Use AllStabilityMargins if specified
            if this.ShowAllMargins
                data = this.Response.ResponseData.AllStabilityMargin;
            else
                data = this.Response.ResponseData.MinimumStabilityMargin;
            end
            responseObjects = getResponseObjects(this.ResponseView,1,1,ka);
            responseLine = responseObjects{1}(this.ResponseLineIdx);

            frequencyConversionFcn = getFrequencyUnitConversionFcn(this,this.Response.FrequencyUnit,this.FrequencyUnit);
            magnitudeConversionFcn = getMagnitudeUnitConversionFcn(this,'abs',this.MagnitudeUnit);
            phaseConversionFcnDeg = getPhaseUnitConversionFcn(this,'deg',this.PhaseUnit);
            phaseConversionFcnDegInv = getPhaseUnitConversionFcn(this,this.PhaseUnit,'deg');

            % Update Gain Margin
            gmFrequency = data.GMFrequency{ka};

            % Set NaNs
            this.GainMarginMarkers(ka).XData = NaN;
            this.GainMarginMarkers(ka).YData = NaN;
            this.GainMarginLines(ka).XData = [NaN NaN];
            this.GainMarginLines(ka).YData = [NaN NaN];
            this.GainMarginFullLines(ka).XData = [NaN NaN];
            this.GainMarginFullLines(ka).YData = [NaN NaN];
            if ~isempty(gmFrequency) && any(~isnan(gmFrequency))
                % Get number of gain margins and initialize variables
                % Set xdata and ydata
                for k = 1:length(gmFrequency)
                    f = frequencyConversionFcn(gmFrequency(k));
                    if ~isinf(f)
                        % Get Y Value
                        fDiff = abs(frequencyConversionFcn(data.ResponseData.Frequency{ka}) - f);
                        [~,idx] = min(fDiff);
                        x = phaseConversionFcnDegInv(responseLine.XData(idx));
                        xRound = phaseConversionFcnDeg(round((x+180)/360)*360-180);
                        samples = idx;
                        if idx > 1
                            samples = [idx-1 samples]; %#ok<AGROW>
                        end
                        if idx < length(responseLine.XData)
                            samples = [samples idx+1]; %#ok<AGROW>
                        end
                        xData = responseLine.XData(samples);
                        yData = responseLine.YData(samples);
                        [xData,ia] = unique(xData,'stable');
                        yData = yData(ia);
                        if all(isnan(xData))
                            y = NaN;
                        elseif isscalar(xData)
                            y = yData(ia);
                        else
                            y = interp1(xData,yData(ia),xRound);
                        end
                        % Set marker data for gain margins within focus
                        this.GainMarginMarkers(ka).XData(k) = xRound;
                        this.GainMarginMarkers(ka).YData(k) = y;

                        % Set line data
                        this.GainMarginLines(ka).XData((3*(k-1)+1):3*k) = [xRound xRound NaN];
                        this.GainMarginLines(ka).YData((3*(k-1)+1):3*k) = [magnitudeConversionFcn(1) y NaN];

                        % Set line data for full line
                        this.GainMarginFullLines(ka).XData((3*(k-1)+1):3*k) = [xRound xRound NaN];
                        this.GainMarginFullLines(ka).YData((3*(k-1)+1):3*k) = [-1e20 1e20 NaN];
                    else
                        % Leave xdata/ydata as NaNs
                        this.GainMarginMarkers(ka).XData(k) = NaN;
                        this.GainMarginMarkers(ka).YData(k) = NaN;
                        this.GainMarginLines(ka).XData((3*(k-1)+1):3*k) = [NaN NaN NaN];
                        this.GainMarginLines(ka).YData((3*(k-1)+1):3*k) = [NaN NaN NaN];
                        this.GainMarginFullLines(ka).XData((3*(k-1)+1):3*k) = [NaN NaN NaN];
                        this.GainMarginFullLines(ka).YData((3*(k-1)+1):3*k) = [NaN NaN NaN];
                    end
                end
            end

            % Update Phase Margin
            pmFrequency = data.PMFrequency{ka};

            % Set NaNs
            this.PhaseMarginMarkers(ka).XData = NaN;
            this.PhaseMarginMarkers(ka).YData = NaN;
            this.PhaseMarginLines(ka).XData = [NaN NaN];
            this.PhaseMarginLines(ka).YData = [NaN NaN];
            if ~isempty(pmFrequency) && any(~isnan(pmFrequency))
                % Get number of gain margins and initialize variables
                % Set xdata and ydata
                for k = 1:length(pmFrequency)
                    f = frequencyConversionFcn(pmFrequency(k));
                    if ~isinf(f)
                        % Get Y Value
                        fDiff = abs(frequencyConversionFcn(data.ResponseData.Frequency{ka}) - f);
                        [~,idx] = min(fDiff);

                        samples = idx;
                        if idx > 1
                            samples = [idx-1 samples]; %#ok<AGROW>
                        end
                        if idx < length(responseLine.XData)
                            samples = [samples idx+1]; %#ok<AGROW>
                        end
                        xData = responseLine.XData(samples);
                        yData = responseLine.YData(samples);
                        [yData,ia] = unique(yData,'stable');
                        if all(isnan(yData))
                            x = NaN;
                        elseif isscalar(yData)
                            x = xData(ia);
                        else
                            x = interp1(yData,xData(ia),magnitudeConversionFcn(1));
                        end

                        % Set marker data for gain margins within focus
                        this.PhaseMarginMarkers(ka).XData(k) = x;
                        this.PhaseMarginMarkers(ka).YData(k) = magnitudeConversionFcn(1);

                        xMarker = phaseConversionFcnDegInv(x);
                        xMarker = phaseConversionFcnDeg(round((xMarker+180)/360)*360-180);

                        % Set line data
                        this.PhaseMarginLines(ka).XData((3*(k-1)+1):3*k) = [xMarker x NaN];
                        this.PhaseMarginLines(ka).YData((3*(k-1)+1):3*k) = [magnitudeConversionFcn(1)*ones(1,2) NaN];
                    else
                        % Leave xdata/ydata as NaNs
                        this.PhaseMarginMarkers(ka).XData(k) = NaN;
                        this.PhaseMarginMarkers(ka).YData(k) = NaN;
                        this.PhaseMarginLines(ka).XData((3*(k-1)+1):3*k) = [NaN NaN NaN];
                        this.PhaseMarginLines(ka).YData((3*(k-1)+1):3*k) = [NaN NaN NaN];
                    end
                end
            end
        end

        function updateDataByLimits(this,~,~,ka)
            responseObjects = getResponseObjects(this.ResponseView,1,1,ka);
            responseLine = responseObjects{1}(this.ResponseLineIdx);
            ax = responseLine.Parent;
            for ii = 1:length(this.GainMarginMarkers(ka).XData)
                if ~isnan(this.GainMarginFullLines(ka).YData(3*(ii-1)+1))
                    this.GainMarginFullLines(ka).YData((3*(ii-1)+1):3*ii-1) = ax.YLim;
                end
            end
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

            phaseConversionFcn = getPhaseUnitConversionFcn(this,'deg',this.PhaseUnit);
            if isempty(data.PhaseMargin{ka}) || all(isnan(data.PhaseMargin{ka}))
                pm = NaN;
            else
                pm = phaseConversionFcn(data.PhaseMargin{ka});
            end

            % Phase Margin
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
        end

        function cbFrequencyUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ka = 1:this.Response.NResponses
                    % Update data tip
                    this.GainMarginMarkers(ka).DataTipTemplate.DataTipRows(3).Label = ...
                        getString(message('Controllib:plots:strFrequency')) + ...
                        " (" + this.FrequencyUnitLabel + ")";
                    this.GainMarginMarkers(ka).DataTipTemplate.DataTipRows(3).Value = ...
                        conversionFcn(this.GainMarginMarkers(ka).DataTipTemplate.DataTipRows(3).Value);

                    % Update data tip
                    this.PhaseMarginMarkers(ka).DataTipTemplate.DataTipRows(4).Label = ...
                        getString(message('Controllib:plots:strFrequency')) + ...
                        " (" + this.FrequencyUnitLabel + ")";
                    this.PhaseMarginMarkers(ka).DataTipTemplate.DataTipRows(4).Value = ...
                        conversionFcn(this.PhaseMarginMarkers(ka).DataTipTemplate.DataTipRows(4).Value);
                end
            end
        end

        function cbPhaseUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ka = 1:this.Response.NResponses
                    % Update marker and lines xdata
                    this.GainMarginMarkers(ka).XData = conversionFcn(this.GainMarginMarkers(ka).XData);
                    this.GainMarginLines(ka).XData = conversionFcn(this.GainMarginLines(ka).XData);
                    this.GainMarginFullLines(ka).XData = conversionFcn(this.GainMarginFullLines(ka).XData);

                    this.PhaseMarginMarkers(ka).XData = conversionFcn(this.PhaseMarginMarkers(ka).XData);
                    this.PhaseMarginLines(ka).XData = conversionFcn(this.PhaseMarginLines(ka).XData);

                    % Update data tip
                    this.PhaseMarginMarkers(ka).DataTipTemplate.DataTipRows(2).Label = ...
                        getString(message('Controllib:plots:strPhaseMargin')) + ...
                        " (" + this.PhaseUnitLabel + ")";
                    this.PhaseMarginMarkers(ka).DataTipTemplate.DataTipRows(2).Value = ...
                        conversionFcn(this.PhaseMarginMarkers(ka).DataTipTemplate.DataTipRows(2).Value);
                end
            end
        end

        function cbMagnitudeUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ka = 1:this.Response.NResponses
                    % Update marker and lines xdata
                    this.GainMarginMarkers(ka).YData = conversionFcn(this.GainMarginMarkers(ka).YData);
                    this.GainMarginLines(ka).YData = conversionFcn(this.GainMarginLines(ka).YData);
                    this.GainMarginFullLines(ka).YData = conversionFcn(this.GainMarginFullLines(ka).YData);

                    % Update data tip
                    this.GainMarginMarkers(ka).DataTipTemplate.DataTipRows(2).Label = ...
                        getString(message('Controllib:plots:strGainMargin')) + ...
                        " (" + this.MagnitudeUnitLabel + ")";
                    this.GainMarginMarkers(ka).DataTipTemplate.DataTipRows(2).Value = ...
                        conversionFcn(this.GainMarginMarkers(ka).DataTipTemplate.DataTipRows(2).Value);

                    this.PhaseMarginMarkers(ka).YData = conversionFcn(this.PhaseMarginMarkers(ka).YData);
                    this.PhaseMarginLines(ka).YData = conversionFcn(this.PhaseMarginLines(ka).YData);
                end
            end
        end

        function c = getMarkerObjects_(this,~,~,ka)
            c = cat(3,this.GainMarginMarkers(ka),this.PhaseMarginMarkers(ka));
        end

        function l = getSupportingObjects_(this,~,~,ka)
            l = cat(3,this.GainMarginLines(ka),this.GainMarginFullLines(ka),this.PhaseMarginLines(ka));
        end
    end
end
