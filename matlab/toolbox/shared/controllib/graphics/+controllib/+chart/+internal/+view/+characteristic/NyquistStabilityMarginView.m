classdef NyquistStabilityMarginView < controllib.chart.internal.view.characteristic.FrequencyCharacteristicView
    % this = controllib.chart.internal.view.characteristic.TimePeakResponseView(data)
    %
    % Copyright 2021-2022 The MathWorks, Inc.

    properties (SetAccess = protected)
        GainMarginMarkers
        GainMarginLines
        PhaseMarginMarkers
        PhaseMarginLines
        UnitCircle
    end

    properties (Dependent,SetAccess=private)
        ShowAllMargins
    end

    %% Public methods
    methods
        function this = NyquistStabilityMarginView(responseView,data)
            this@controllib.chart.internal.view.characteristic.FrequencyCharacteristicView(responseView,data);
        end
    end

    %% Get/Set
    methods
        function ShowAllMargins = get.ShowAllMargins(this)
            ShowAllMargins = this.Type == "AllStabilityMargins";
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)
            this.GainMarginMarkers = createGraphicsObjects(this,"scatter",1,1,this.Response.NResponses,Tag='NyquistGainMarginScatter');
            this.GainMarginLines = createGraphicsObjects(this,"line",1,1,this.Response.NResponses,...
                HitTest='off',PickableParts='none',Tag='NyquistGainMarginLine');
            set(this.GainMarginLines,LineStyle='-.')
            controllib.plot.internal.utils.setColorProperty(...
                this.GainMarginLines,"Color","--mw-graphics-colorNeutral-line-primary");
            this.PhaseMarginMarkers = createGraphicsObjects(this,"scatter",1,1,this.Response.NResponses,Tag='NyquistPhaseMarginScatter');
            this.PhaseMarginLines = createGraphicsObjects(this,"line",1,1,this.Response.NResponses,...
                HitTest='off',PickableParts='none',Tag='NyquistPhaseMarginLiner');
            set(this.PhaseMarginLines,LineStyle='-.')
            controllib.plot.internal.utils.setColorProperty(...
                this.PhaseMarginLines,"Color","--mw-graphics-colorNeutral-line-primary");

            % Unit Circle
            this.UnitCircle = createGraphicsObjects(this,"rectangle",1,1,1,...
                HitTest="off",PickableParts="none",Tag='NyquistUnitCircle');
            set(this.UnitCircle,Position=[-1 -1 2 2],Curvature=[1 1],LineStyle='-.');
            controllib.plot.internal.utils.setColorProperty(this.UnitCircle,...
                "EdgeColor","--mw-graphics-colorNeutral-line-primary");
        end

        function updateData(this,~,~,ka)
            % Use AllStabilityMargins if specified
            if this.ShowAllMargins
                data = this.Response.ResponseData.AllStabilityMargin;
            else
                data = this.Response.ResponseData.MinimumStabilityMargin;
            end

            % Update Gain Margin markers
            gmFrequency = data.GMFrequency{ka};
            gmMagnitude = data.GainMargin{ka};
            gmPhase = data.GMPhase{ka};

            % Set NaNs
            this.GainMarginMarkers(ka).XData = NaN;
            this.GainMarginMarkers(ka).YData = NaN;
            this.GainMarginLines(ka).XData = [NaN NaN];
            this.GainMarginLines(ka).YData = [NaN NaN];
            if ~isempty(gmFrequency) && any(~isnan(gmFrequency))
                % Get number of gain margins and initialize variables
                % Set xdata and ydata
                for k = 1:length(gmFrequency)
                    f = gmFrequency(k);
                    if ~isinf(f)
                        responseValue = (1/gmMagnitude(k))*exp(1j*deg2rad(gmPhase(k)));
                        realValue = real(responseValue);
                        imaginaryValue = imag(responseValue);
                        % Set marker data for gain margins within focus
                        this.GainMarginMarkers(ka).XData(k) = realValue;
                        this.GainMarginMarkers(ka).YData(k) = imaginaryValue;

                        % Set line data
                        this.GainMarginLines(ka).XData((3*(k-1)+1):3*k) = [0 realValue NaN];
                        this.GainMarginLines(ka).YData((3*(k-1)+1):3*k) = [0 imaginaryValue NaN];
                    else
                        % Leave xdata/ydata as NaNs
                        this.GainMarginMarkers(ka).XData(k) = NaN;
                        this.GainMarginMarkers(ka).YData(k) = NaN;
                        this.GainMarginLines(ka).XData((3*(k-1)+1):3*k) = [NaN NaN NaN];
                        this.GainMarginLines(ka).YData((3*(k-1)+1):3*k) = [NaN NaN NaN];
                    end
                end
            end

            % Update Phase Margin
            % Update Gain Margin markers
            pmFrequency = data.PMFrequency{ka};
            pmPhase = data.PMPhase{ka};

            % Set NaNs
            this.PhaseMarginMarkers(ka).XData = NaN;
            this.PhaseMarginMarkers(ka).YData = NaN;
            this.PhaseMarginLines(ka).XData=[NaN NaN];
            this.PhaseMarginLines(ka).YData=[NaN NaN];
            if ~isempty(pmFrequency) && any(~isnan(pmFrequency))
                % Get number of gain margins and initialize variables
                % Set xdata and ydata
                for k = 1:length(pmFrequency)
                    f = pmFrequency(k);
                    responseValue = 1*exp(1j*deg2rad(pmPhase(k)));
                    realValue = real(responseValue);
                    imaginaryValue = imag(responseValue);

                    if ~isinf(f)
                        % Set marker data for gain margins within focus
                        this.PhaseMarginMarkers(ka).XData(k) = realValue;
                        this.PhaseMarginMarkers(ka).YData(k) = imaginaryValue;

                        % Set line data
                        this.PhaseMarginLines(ka).XData((3*(k-1)+1):3*k) = [0 realValue NaN];
                        this.PhaseMarginLines(ka).YData((3*(k-1)+1):3*k) = [0 imaginaryValue NaN];
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

        function updateDataTips_(this,~,~,ka,nameDataTipRow,~,customDataTipRows)
            % Use AllStabilityMargins if specified
            if this.ShowAllMargins
                data = this.Response.ResponseData.AllStabilityMargin;
            else
                data = this.Response.ResponseData.MinimumStabilityMargin;
            end

            % Gain Margin
            if isempty(data.GainMargin{ka}) || all(isnan(data.GainMargin{ka}))
                gm = NaN;
            else
                gm = mag2db(data.GainMargin{ka});
            end
            gainMarginRow = dataTipTextRow(getString(message('Controllib:plots:strGainMargin')) +...
                " (" + getString(message('Controllib:gui:strDB')) + ")",gm,'%0.3g');
            
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

            % Phase Margin
            if isempty(data.PhaseMargin{ka}) || all(isnan(data.PhaseMargin{ka}))
                pm = NaN;
            else
                pm = data.PhaseMargin{ka};
            end
            phaseMarginRow = dataTipTextRow(getString(message('Controllib:plots:strPhaseMargin')) +...
                " (" + getString(message('Controllib:gui:strDeg')) + ")",pm,'%0.3g');

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
                    % Update gain data tip
                    dataTipValue = conversionFcn(this.GainMarginMarkers(ka).DataTipTemplate.DataTipRows(3).Value);
                    this.GainMarginMarkers(ka).DataTipTemplate.DataTipRows(3).Value = dataTipValue;
                    this.GainMarginMarkers(ka).DataTipTemplate.DataTipRows(3).Label = ...
                        getString(message('Controllib:plots:strFrequency')) + ...
                        " (" + this.FrequencyUnitLabel + ")";

                    % Update phase data tip
                    dataTipValue = conversionFcn(this.PhaseMarginMarkers(ka).DataTipTemplate.DataTipRows(4).Value);
                    this.PhaseMarginMarkers(ka).DataTipTemplate.DataTipRows(4).Value = dataTipValue;
                    this.PhaseMarginMarkers(ka).DataTipTemplate.DataTipRows(4).Label = ...
                        getString(message('Controllib:plots:strFrequency')) + ...
                        " (" + this.FrequencyUnitLabel + ")";
                end
            end
        end

        function c = getMarkerObjects_(this,~,~,ka)
            c = cat(3,this.GainMarginMarkers(ka),this.PhaseMarginMarkers(ka));
        end

        function l = getSupportingObjects_(this,~,~,ka)
            l = cat(3,this.GainMarginLines(ka),this.PhaseMarginLines(ka),this.UnitCircle);
        end
    end
end