classdef MagnitudePhaseFrequencyResponseView < controllib.chart.internal.view.wave.BaseResponseView & ...
        controllib.chart.internal.foundation.MixInFrequencyUnit & ...
        controllib.chart.internal.foundation.MixInMagnitudeUnit & ...
        controllib.chart.internal.foundation.MixInPhaseUnit
    % Bode Response

    % Copyright 2022-2024 The MathWorks, Inc.

    properties (SetAccess = protected)
        MagnitudeResponseLines
        PhaseResponseLines
        MagnitudePositiveArrows
        MagnitudeNegativeArrows
        PhasePositiveArrows
        PhaseNegativeArrows
        MagnitudeNyquistLines
        PhaseNyquistLines
    end

    properties (SetAccess = {?controllib.chart.internal.view.axes.BaseAxesView,...
            ?controllib.chart.internal.view.wave.BaseResponseView},AbortSet)
        FrequencyScale = "log"
        PhaseWrappingEnabled = false
        PhaseMatchingEnabled = false
    end

    %% Constructor
    methods
        function this = MagnitudePhaseFrequencyResponseView(response,magphaseOptionalInputs,...
                                                                optionalInputs)
            arguments
                response (1,1) controllib.chart.response.BodeResponse
                magphaseOptionalInputs.MinimumGainEnabled (1,1) logical = false
                magphaseOptionalInputs.PhaseWrappingEnabled (1,1) logical = false
                magphaseOptionalInputs.PhaseMatchingEnabled (1,1) logical = false
                magphaseOptionalInputs.FrequencyScale (1,1) string = "log"
                optionalInputs.ColumnVisible (1,:) logical = true(1,response.NColumns);
                optionalInputs.RowVisible (:,1) logical = true(response.NRows,1);
                optionalInputs.ArrayVisible logical = response.ArrayVisible
            end
            this@controllib.chart.internal.foundation.MixInFrequencyUnit(response.FrequencyUnit);
            this@controllib.chart.internal.foundation.MixInMagnitudeUnit(response.MagnitudeUnit);
            this@controllib.chart.internal.foundation.MixInPhaseUnit(response.PhaseUnit);
            
            optionalInputs.NRows = response.NRows;
            optionalInputs.NColumns = response.NColumns;
            optionalInputs = namedargs2cell(optionalInputs);
            this@controllib.chart.internal.view.wave.BaseResponseView(response,optionalInputs{:});

            % Set BodeResponse properties
            this.PhaseWrappingEnabled = magphaseOptionalInputs.PhaseWrappingEnabled;
            this.PhaseMatchingEnabled = magphaseOptionalInputs.PhaseMatchingEnabled;
            this.FrequencyScale = magphaseOptionalInputs.FrequencyScale;

            build(this);
        end
    end

    %% Public methods
    methods
        function deleteAllDataTips(this,rowIdx,columnIdx,axesType)
            arguments
                this (1,1) controllib.chart.internal.view.wave.MagnitudePhaseFrequencyResponseView
                rowIdx (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NRows
                columnIdx (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NColumns
                axesType (1,1) string {mustBeMember(axesType,["all","magnitude","phase"])} = "all"
            end
            for ko = rowIdx
                if ~isempty(this.PlotRowIdx)
                    ko_idx = find(this.PlotRowIdx==ko,1);
                else
                    ko_idx = ko;
                end
                for ki = columnIdx
                    if ~isempty(this.PlotColumnIdx)
                        ki_idx = find(this.PlotColumnIdx==ki,1);
                    else
                        ki_idx = ki;
                    end
                    for ka = 1:this.Response.NResponses
                        if ~isempty(ko_idx) && ko_idx <= this.Response.NRows && ...
                                ~isempty(ki_idx) && ki_idx <= this.Response.NColumns
                            % Delete for response lines
                            responseObjects = getResponseObjects(this,ko_idx,ki_idx,ka);
                            if ~isempty(responseObjects{1})
                                switch axesType
                                    case "magnitude"
                                        responseObjects = {responseObjects{1}(1,1,:)};
                                    case "phase"
                                        responseObjects = {responseObjects{1}(2,1,:)};
                                end
                            end
                            dataTipObjects = findobj(responseObjects{1},'Type','datatip');
                            delete(dataTipObjects);
                            % Delete for characteristic markers
                            charMarkers = getCharacteristicMarkers(this,ko_idx,ki_idx,ka);
                            if ~isempty(charMarkers{1})
                                switch axesType
                                    case "magnitude"
                                        charMarkers = {charMarkers{1}(1,1,:)};
                                    case "phase"
                                        charMarkers = {charMarkers{1}(2,1,:)};
                                end
                            end
                            dataTipObjects = findobj(charMarkers{1},'Type','datatip');
                            delete(dataTipObjects);
                        end
                    end
                end
            end
        end

        function updateArrows(this,optionalArguments)
            arguments
                this
                optionalArguments.AspectRatio = []
            end
            if ~this.Response.IsResponseValid
                return;
            end
            if this.FrequencyScale=="log"
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        for ka = 1:this.Response.NResponses
                            w = this.Response.ResponseData.Frequency{ka};
                            if iscell(w)
                                w = w{ko,ki};
                            end
                            if ~this.Response.ResponseData.IsReal(ka) || any(w < 0)
                                if ~isvalid(this.MagnitudeResponseLines(ko,ki,ka)) || ~isvalid(this.PhaseResponseLines(ko,ki,ka))
                                    continue;
                                end
                                % Magnitude
                                xData = this.MagnitudeResponseLines(ko,ki,ka).XData;
                                yData = this.MagnitudeResponseLines(ko,ki,ka).YData;
                                ax = this.MagnitudeResponseLines(ko,ki,ka).Parent;
                                if ~isempty(ax)
                                    xRange = ax.XLim;
                                    yRange = ax.YLim;
                                else
                                    xRange = [min(abs(xData)) max(abs(xData))];
                                    yRange = [min(yData) max(yData)];
                                end
                                % Positive Arrow
                                [ia1,ia2] = this.localPositionArrow(xData,yData,xRange,yRange);
                                % Negative Arrow
                                this.localDrawArrow(this.MagnitudeNegativeArrows(ko,ki,ka),xData(ia1),yData(ia1),...
                                    xRange,yRange,(0.5+this.MagnitudeResponseLines(ko,ki,ka).LineWidth)/150,...
                                    optionalArguments.AspectRatio);
                                this.localDrawArrow(this.MagnitudePositiveArrows(ko,ki,ka),xData(ia2),yData(ia2),...
                                    xRange,yRange,(0.5+this.MagnitudeResponseLines(ko,ki,ka).LineWidth)/150,...
                                    optionalArguments.AspectRatio);
                                % Phase
                                xData = this.PhaseResponseLines(ko,ki,ka).XData;
                                yData = this.PhaseResponseLines(ko,ki,ka).YData;
                                ax = this.PhaseResponseLines(ko,ki,ka).Parent;
                                if ~isempty(ax)
                                    xRange = ax.XLim;
                                    yRange = ax.YLim;
                                else
                                    xRange = [min(abs(xData)) max(abs(xData))];
                                    yRange = [min(yData) max(yData)];
                                end
                                % Positive Arrow
                                [ia1,ia2] = this.localPositionArrow(xData,yData,xRange,yRange);
                                % Negative Arrow
                                this.localDrawArrow(this.PhaseNegativeArrows(ko,ki,ka),xData(ia1),yData(ia1),...
                                    xRange,yRange,(0.5+this.PhaseResponseLines(ko,ki,ka).LineWidth)/150,...
                                    optionalArguments.AspectRatio);
                                this.localDrawArrow(this.PhasePositiveArrows(ko,ki,ka),xData(ia2),yData(ia2),...
                                    xRange,yRange,(0.5+this.PhaseResponseLines(ko,ki,ka).LineWidth)/150,...
                                    optionalArguments.AspectRatio);
                            end
                        end
                    end
                end
            end
        end

        function hideArrows(this)
            set(this.MagnitudePositiveArrows,Visible='off');
            set(this.MagnitudeNegativeArrows,Visible='off');
            set(this.PhasePositiveArrows,Visible='off');
            set(this.PhaseNegativeArrows,Visible='off');
        end
    end

    %% Get/Set
    methods
        % FrequencyScale
        function set.FrequencyScale(this,FrequencyScale)
            arguments
                this (1,1) controllib.chart.internal.view.wave.MagnitudePhaseFrequencyResponseView
                FrequencyScale (1,1) string {mustBeMember(FrequencyScale,["log","linear"])}
            end
            this.FrequencyScale = FrequencyScale;
            if strcmp(FrequencyScale,"linear")
                hideArrows(this);
            end
            if this.IsResponseViewValid
                updateResponseData(this,UpdateArrows=false);
            end
        end

        % PhaseWrappingEnabled
        function set.PhaseWrappingEnabled(this,PhaseWrappingEnabled)
            arguments
                this (1,1) controllib.chart.internal.view.wave.MagnitudePhaseFrequencyResponseView
                PhaseWrappingEnabled (1,1) logical
            end
            this.PhaseWrappingEnabled = PhaseWrappingEnabled;
            if this.IsResponseViewValid
                updateResponseData(this);
                for ii = 1:length(this.Characteristics)
                    if this.Characteristics(ii).IsInitialized
                        update(this.Characteristics(ii));
                    end
                end
            end
        end

        % PhaseMatchingEnabled
        function set.PhaseMatchingEnabled(this,PhaseMatchingEnabled)
            arguments
                this (1,1) controllib.chart.internal.view.wave.MagnitudePhaseFrequencyResponseView
                PhaseMatchingEnabled (1,1) logical
            end
            this.PhaseMatchingEnabled = PhaseMatchingEnabled;
            if this.IsResponseViewValid
                updateResponseData(this);
                for ii = 1:length(this.Characteristics)
                    if this.Characteristics(ii).IsInitialized
                        update(this.Characteristics(ii));
                    end
                end
            end
        end
    end

    %% Protected methods
    methods (Access = protected)
        function createResponseDataTips_(this,ko,ki,ka,nameDataTipRow,ioDataTipRow,customDataTipRows)
            % % Create data tip row for frequency and magnitude
            % frequencyRow = dataTipTextRow(...
            %     getString(message('Controllib:plots:strFrequency')) + " (" + this.FrequencyUnitLabel + ")",...
            %     'XData','%0.3g');
            % magnitudeRow = dataTipTextRow(...
            %     getString(message('Controllib:plots:strMagnitude')) + " (" + this.MagnitudeUnitLabel + ")",...
            %     'YData','%0.3g');
            % 
            % % Add to DataTipTemplate
            % this.MagnitudeResponseLines(ko,ki,ka).DataTipTemplate.DataTipRows = ...
            %     [nameDataTipRow; ioDataTipRow; frequencyRow; magnitudeRow; customDataTipRows(:)];
            % 
            % % Create data tip row for phase
            % phaseRow = dataTipTextRow(...
            %     getString(message('Controllib:plots:strPhase')) + " (" + this.PhaseUnitLabel + ")",...
            %     'YData','%0.3g');
            % 
            % % Add to DataTipTemplate
            % this.PhaseResponseLines(ko,ki,ka).DataTipTemplate.DataTipRows = ...
            %     [nameDataTipRow; ioDataTipRow; frequencyRow; phaseRow; customDataTipRows(:)];
        end

        function createResponseObjects(this)
            this.MagnitudeResponseLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='BodeMagnitudeLine');
            this.MagnitudePositiveArrows = createGraphicsObjects(this,"patch",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='BodeMagnitudePositiveArrow',HitTest='off',PickableParts='none');
            this.MagnitudeNegativeArrows = createGraphicsObjects(this,"patch",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='BodeMagnitudeNegativeArrow',HitTest='off',PickableParts='none');
            this.PhaseResponseLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='BodePhaseLine');
            this.PhasePositiveArrows = createGraphicsObjects(this,"patch",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='BodePhasePositiveArrow',HitTest='off',PickableParts='none');
            this.PhaseNegativeArrows = createGraphicsObjects(this,"patch",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='BodePhaseNegativeArrow',HitTest='off',PickableParts='none');
        end

        function createSupportingObjects(this)
            this.MagnitudeNyquistLines = createGraphicsObjects(this,"constantLine",this.Response.NRows,...
                this.Response.NColumns,2,Tag='BodeMagnitudeNyquistLine',HitTest='off',PickableParts='none');
            set(this.MagnitudeNyquistLines,InterceptAxis='x',LineWidth=1.5);
            controllib.plot.internal.utils.setColorProperty(this.MagnitudeNyquistLines,...
                "Color","--mw-graphics-colorNeutral-line-primary");
            this.PhaseNyquistLines = createGraphicsObjects(this,"constantLine",this.Response.NRows,...
                this.Response.NColumns,2,Tag='BodePhaseNyquistLine',HitTest='off',PickableParts='none');
            set(this.PhaseNyquistLines,InterceptAxis='x',LineWidth=1.5);
            controllib.plot.internal.utils.setColorProperty(this.PhaseNyquistLines,...
                "Color","--mw-graphics-colorNeutral-line-primary");
        end

        function legendObjects = createLegendObjects(this)
            legendObjects = createGraphicsObjects(this,"line",1,1,1,...
                DisplayName=strrep(this.Response.Name,'_','\_'));
        end

        function responseObjects = getResponseObjects_(this,ko,ki,ka)
            responseObjects = [cat(3,this.MagnitudeResponseLines(ko,ki,ka),this.MagnitudePositiveArrows(ko,ki,ka),this.MagnitudeNegativeArrows(ko,ki,ka));
                cat(3,this.PhaseResponseLines(ko,ki,ka),this.PhasePositiveArrows(ko,ki,ka),this.PhaseNegativeArrows(ko,ki,ka))];
        end

        function supportingObjects = getSupportingObjects_(this,ko,ki,~)
            supportingObjects = [this.MagnitudeNyquistLines(ko,ki,:);this.PhaseNyquistLines(ko,ki,:)];
        end

        function updateResponseData(this,optionalInputs)
            arguments
                this (1,1) controllib.chart.internal.view.wave.MagnitudePhaseFrequencyResponseView
                optionalInputs.UpdateArrows (1,1) logical = true
            end
            % Get unit conversion functions (system units are rad/model
            % TimeUnit, abs and rad)
            freqConversionFcn = getFrequencyUnitConversionFcn(this,this.Response.FrequencyUnit,this.FrequencyUnit);
            magConversionFcn = getMagnitudeUnitConversionFcn(this,this.Response.MagnitudeUnit,this.MagnitudeUnit);
            phaseConversionFcn = getPhaseUnitConversionFcn(this,this.Response.PhaseUnit,this.PhaseUnit);
            for ko = 1:this.Response.NRows
                for ki = 1:this.Response.NColumns
                    for ka = 1:this.Response.NResponses
                        % Convert frequency, magnitude and phase
                        w = this.Response.ResponseData.Frequency{ka};
                        mag = this.Response.ResponseData.Magnitude{ka};
                        if iscell(w)
                           w = w{ko,ki}; 
                           mag = mag{ko,ki};
                        else
                           mag = mag(:,ko,ki);
                        end
                        w = freqConversionFcn(w);
                        mag = magConversionFcn(mag);
                        if this.PhaseWrappingEnabled && this.PhaseMatchingEnabled
                            ph = this.Response.ResponseData.WrappedAndMatchedPhase{ka};
                        elseif this.PhaseWrappingEnabled
                            ph = this.Response.ResponseData.WrappedPhase{ka};
                        elseif this.PhaseMatchingEnabled
                            ph = this.Response.ResponseData.MatchedPhase{ka};
                        else
                            ph = this.Response.ResponseData.Phase{ka};
                        end
                           
                        if iscell(ph)
                           ph = ph{ko,ki};
                        else
                           ph = ph(:,ko,ki);
                        end
                        ph = phaseConversionFcn(ph);
                        
                        if this.Response.ResponseData.IsReal(ka) && (~this.Response.ResponseData.IsFRD && ~any(w < 0))
                            w = [-flipud(w);w]; %#ok<AGROW>
                            mag = [flipud(mag);mag]; %#ok<AGROW>
                            ph = [-flipud(ph);ph]; %#ok<AGROW>
                        end
                        
                        NumChannels = size(mag,2);
                        if NumChannels>1
                            mag = [mag; NaN(1,NumChannels)];
                            mag = mag(1:end-1)';
                            ph = [ph; NaN(1,NumChannels)];
                            ph = ph(1:end-1)';
                            w = repmat([w; NaN],[1 NumChannels]);
                            w = w(1:end-1)';
                        end

                        switch this.FrequencyScale
                            case "log"
                                if ~this.Response.ResponseData.IsReal(ka) || (this.Response.ResponseData.IsFRD && any(w < 0))
                                    w = abs(w);
                                    this.MagnitudePositiveArrows(ko,ki,ka).Visible = this.MagnitudeResponseLines(ko,ki,ka).Visible;
                                    this.MagnitudeNegativeArrows(ko,ki,ka).Visible = this.MagnitudeResponseLines(ko,ki,ka).Visible;
                                    this.PhasePositiveArrows(ko,ki,ka).Visible = this.PhaseResponseLines(ko,ki,ka).Visible;
                                    this.PhaseNegativeArrows(ko,ki,ka).Visible = this.PhaseResponseLines(ko,ki,ka).Visible;
                                else
                                    this.MagnitudePositiveArrows(ko,ki,ka).Visible = false;
                                    this.MagnitudePositiveArrows(ko,ki,ka).Visible = false;
                                    this.PhaseNegativeArrows(ko,ki,ka).Visible = false;
                                    this.PhaseNegativeArrows(ko,ki,ka).Visible = false;
                                end
                            case "linear"
                                this.MagnitudePositiveArrows(ko,ki,ka).Visible = false;
                                this.MagnitudePositiveArrows(ko,ki,ka).Visible = false;
                                this.PhaseNegativeArrows(ko,ki,ka).Visible = false;
                                this.PhaseNegativeArrows(ko,ki,ka).Visible = false;
                        end
                        magL = this.MagnitudeResponseLines(ko,ki,ka);
                        set(magL,XData=w,YData=mag);
                        phaseL = this.PhaseResponseLines(ko,ki,ka);
                        set(phaseL,XData=w,YData=ph);
                    end

                    if this.Response.IsDiscrete
                        Ts = getTs(this.Response.ResponseData,ko,ki,ka);
                        nyFreq = freqConversionFcn(pi/abs(Ts));
                        set(this.MagnitudeNyquistLines(ko,ki,1),Value=nyFreq);
                        set(this.PhaseNyquistLines(ko,ki,1),Value=nyFreq);
                        set(this.MagnitudeNyquistLines(ko,ki,2),Value=-nyFreq);
                        set(this.PhaseNyquistLines(ko,ki,2),Value=-nyFreq);
                        visibilityFlag = any(arrayfun(@(x) x.Visible,this.MagnitudeResponseLines(ko,ki,:)),'all');
                        set(this.MagnitudeNyquistLines,Visible=visibilityFlag);
                        visibilityFlag = any(arrayfun(@(x) x.Visible,this.PhaseResponseLines(ko,ki,:)),'all');
                        set(this.PhaseNyquistLines,Visible=visibilityFlag);
                    else
                        set(this.MagnitudeNyquistLines,Visible=false);
                        set(this.PhaseNyquistLines,Visible=false);
                    end
                end
            end
            if optionalInputs.UpdateArrows
                updateArrows(this);
            end
        end

        function updateResponseVisibility(this,rowVisible,columnVisible,arrayVisible)
            arguments
                this (1,1) controllib.chart.internal.view.wave.MagnitudePhaseFrequencyResponseView
                rowVisible (:,1) logical
                columnVisible (1,:) logical
                arrayVisible logical
            end
            updateResponseVisibility@controllib.chart.internal.view.wave.BaseResponseView(this,rowVisible,columnVisible,arrayVisible);
            isFrequencyScaleLog = strcmp(this.FrequencyScale,"log");
            for ko = 1:this.Response.NRows
                for ki = 1:this.Response.NColumns
                    for ka = 1:this.Response.NResponses
                        visibilityFlag = arrayVisible(ka) & rowVisible(ko) & columnVisible(ki);
                        showArrows = ~this.Response.ResponseData.IsReal(ka) || (this.Response.ResponseData.IsFRD && any(this.Response.ResponseData.Frequency{ka}(:) < 0));
                        this.MagnitudeNegativeArrows(ko,ki,ka).Visible = ...
                            visibilityFlag & showArrows & isFrequencyScaleLog;
                        this.MagnitudePositiveArrows(ko,ki,ka).Visible = ...
                            visibilityFlag & showArrows & isFrequencyScaleLog;
                        this.PhaseNegativeArrows(ko,ki,ka).Visible = ...
                            visibilityFlag & showArrows & isFrequencyScaleLog;
                        this.PhasePositiveArrows(ko,ki,ka).Visible = ...
                            visibilityFlag & showArrows & isFrequencyScaleLog;
                    end
                    visibilityFlag = any(arrayfun(@(x) x.Visible,this.MagnitudeResponseLines(ko,ki,:)),'all');
                    set(this.MagnitudeNyquistLines(ko,ki,:),Visible = visibilityFlag & this.Response.IsDiscrete);
                    visibilityFlag = any(arrayfun(@(x) x.Visible,this.PhaseResponseLines(ko,ki,:)),'all');
                    set(this.PhaseNyquistLines(ko,ki,:),Visible = visibilityFlag & this.Response.IsDiscrete);
                end
            end
        end

        function cbFrequencyUnitChanged(this,conversionFcn)
            for ko = 1:this.Response.NRows
                for ki = 1:this.Response.NColumns
                    for ka = 1:this.Response.NResponses
                        this.MagnitudeResponseLines(ko,ki,ka).XData = ...
                            conversionFcn(this.MagnitudeResponseLines(ko,ki,ka).XData);
                        this.PhaseResponseLines(ko,ki,ka).XData = ...
                            conversionFcn(this.PhaseResponseLines(ko,ki,ka).XData);
                    end
                    for ii = 1:2
                        this.MagnitudeNyquistLines(ko,ki,ii).Value = conversionFcn(this.MagnitudeNyquistLines(ko,ki,ii).Value);
                        this.PhaseNyquistLines(ko,ki,ii).Value = conversionFcn(this.PhaseNyquistLines(ko,ki,ii).Value);
                    end
                end
            end

            % Update response line data tip
            updateFrequencyLabelDataTip(this);
            updateFrequencyValueDataTip(this,conversionFcn);

            for k = 1:length(this.Characteristics)
                if isa(this.Characteristics(k),'controllib.chart.internal.foundation.MixInFrequencyUnit')
                    this.Characteristics(k).FrequencyUnit = this.FrequencyUnit;
                end 
            end

            updateArrows(this);
        end

        function cbMagnitudeUnitChanged(this,conversionFcn)
            for ko = 1:this.Response.NRows
                for ki = 1:this.Response.NColumns
                    for ka = 1:this.Response.NResponses
                        this.MagnitudeResponseLines(ko,ki,ka).YData = ...
                            conversionFcn(this.MagnitudeResponseLines(ko,ki,ka).YData);
                    end
                end
            end

            % Update response line data tip
            updateMagnitudeLabelDataTip(this);
            
            for k = 1:length(this.Characteristics)
                if isa(this.Characteristics(k),'controllib.chart.internal.foundation.MixInMagnitudeUnit')
                    this.Characteristics(k).MagnitudeUnit = this.MagnitudeUnit;
                end 
            end
        end

        function cbPhaseUnitChanged(this,conversionFcn)
            for ko = 1:this.Response.NRows
                for ki = 1:this.Response.NColumns
                    for ka = 1:this.Response.NResponses
                        this.PhaseResponseLines(ko,ki,ka).YData = ...
                            conversionFcn(this.PhaseResponseLines(ko,ki,ka).YData);
                    end
                end
            end

            % Update response line data tip
            updatePhaseLabelDataTip(this);

            % Convert units on phase margin characteristic
            for k = 1:length(this.Characteristics)
                if isa(this.Characteristics(k),'controllib.chart.internal.foundation.MixInPhaseUnit')
                    this.Characteristics(k).PhaseUnit = this.PhaseUnit;
                end 
            end
        end

        function updateFrequencyLabelDataTip(this)
            if this.IsResponseDataTipsCreated
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        for ka = 1:this.Response.NResponses
                            this.replaceDataTipRowLabel(this.MagnitudeResponseLines(ko,ki,ka),...
                                getString(message('Controllib:plots:strFrequency')),...
                                getString(message('Controllib:plots:strFrequency')) + ...
                                " (" + this.FrequencyUnitLabel + ")");
                            this.replaceDataTipRowLabel(this.PhaseResponseLines(ko,ki,ka),...
                                getString(message('Controllib:plots:strFrequency')),...
                                getString(message('Controllib:plots:strFrequency')) + ...
                                " (" + this.FrequencyUnitLabel + ")");
                        end
                    end
                end
            end
        end

        function updateFrequencyValueDataTip(this,conversionFcn)

        end

        function updateMagnitudeLabelDataTip(this)
            if this.IsResponseDataTipsCreated
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        for ka = 1:this.Response.NResponses
                            this.replaceDataTipRowLabel(this.MagnitudeResponseLines(ko,ki,ka),...
                                getString(message('Controllib:plots:strMagnitude')),...
                                getString(message('Controllib:plots:strMagnitude')) + ...
                                " (" + this.MagnitudeUnitLabel + ")");
                        end
                    end
                end
            end
        end

        function updatePhaseLabelDataTip(this)
            if this.IsResponseDataTipsCreated
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        for ka = 1:this.Response.NResponses
                            this.replaceDataTipRowLabel(this.PhaseResponseLines(ko,ki,ka),...
                                getString(message('Controllib:plots:strPhase')),...
                                getString(message('Controllib:plots:strPhase')) + ...
                                " (" + this.PhaseUnitLabel + ")");
                        end
                    end
                end
            end
        end
    end

    %% Static sealed protected methods
    methods (Static, Sealed, Access = protected)
        function [ia1,ia2] = localPositionArrow(X,Y,XLim,YLim)
            % Find best location to place the arrows in BODE/SIGMA plots.
            % IA1 is for the negative arrow and IA2 for the positive arrow.
            iz = find(X >= 0 & [false,diff(X)>0],1);
            ix = 1:numel(X);
            % Note: X=|w| with NaN to separate w<0 and w>0
            InScope = (X>XLim(1) & X<XLim(2) & Y>YLim(1) & Y<YLim(2));
            if isempty(iz) % this is when only negative frequencies are available
                ix1 = ix; w1 = ix/10;
                ix2 = []; w2 = [];
            else
                ix1 = find(ix<iz-1 & InScope);  w1 = X(:,ix1);  % w<0 in scope, decreasing
                ix2 = find(ix>iz & InScope);    w2 = X(:,ix2);  % w>0 in scope, increasing
            end
            if isempty(ix1) || isempty(ix2)
                % One or both of the branches is not visible. Put arrow near center of range
                wc = sqrt(XLim(1)*XLim(2));
                [~,ia1] = min(abs(w1-wc));  ia1 = ix1(ia1);
                [~,ia2] = min(abs(w2-wc));  ia2 = ix2(ia2);
            else
                % Put arrows near frequency of maximum separation between the two curves
                w = logspace(log10(XLim(1)),log10(XLim(2)),10);
                Y1 = utInterp1(w1,Y(:,ix1),w);
                Y2 = utInterp1(w2,Y(:,ix2),w);
                [~,imax] = max(abs(Y1-Y2));
                [~,ia1] = min(abs(w1-w(imax)));  ia1 = ix1(ia1);
                [~,ia2] = min(abs(w2-w(imax)));  ia2 = ix2(ia2); 
                if ia2 >= length(X)
                    ia2 = length(X)-1; 
                end
            end
            ia1 = [ia1 ia1+1];  % < iz
            ia2 = [ia2 ia2+1];  % > iz
        end
        function localDrawArrow(harrow,X,Y,Xlim,Ylim,RAS,aspectRatio)
            if ~isempty(harrow.Parent)
                controllib.chart.internal.utils.drawArrow(harrow,X,Y,RAS,Axes=harrow.Parent,AspectRatio=aspectRatio);
            else
                controllib.chart.internal.utils.drawArrow(harrow,X,Y,RAS,XRange=Xlim,YRange=Ylim,AspectRatio=[1 0.8]);
            end
        end
    end
end



