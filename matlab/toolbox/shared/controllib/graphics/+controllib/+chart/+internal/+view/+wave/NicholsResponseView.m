classdef NicholsResponseView < controllib.chart.internal.view.wave.BaseResponseView & ...
                        controllib.chart.internal.foundation.MixInFrequencyUnit & ...
                        controllib.chart.internal.foundation.MixInMagnitudeUnit & ...
                        controllib.chart.internal.foundation.MixInPhaseUnit
    % NicholsResponseView

    % Copyright 2022-2024 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        ResponseLines
        ZeroMagnitudeLines
        CriticalPointMarkers
    end

    properties (SetAccess = {?controllib.chart.internal.view.axes.BaseAxesView,...
            ?controllib.chart.internal.view.wave.BaseResponseView})
        PhaseWrappingEnabled = false
        PhaseMatchingEnabled = false
        ShowMagnitudeLines = true
    end

    %% Constructor
    methods
        function this = NicholsResponseView(response,nicholsOptionalInputs,optionalInputs)
            arguments
                response (1,1) controllib.chart.response.NicholsResponse
                nicholsOptionalInputs.PhaseWrappingEnabled (1,1) logical = false
                nicholsOptionalInputs.PhaseMatchingEnabled (1,1) logical = false
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

            % Set NicholsResponse properties
            this.PhaseWrappingEnabled = nicholsOptionalInputs.PhaseWrappingEnabled;
            this.PhaseMatchingEnabled = nicholsOptionalInputs.PhaseMatchingEnabled;

            % Build response
            build(this);
        end
    end
    
    %% Get/Set
    methods
        function set.ShowMagnitudeLines(this,ShowMagnitudeLines)
            arguments
                this (1,1) controllib.chart.internal.view.wave.NicholsResponseView
                ShowMagnitudeLines (1,1) logical
            end
            this.ShowMagnitudeLines = ShowMagnitudeLines;
            set(this.ZeroMagnitudeLines(isvalid(this.ZeroMagnitudeLines)),Visible=ShowMagnitudeLines); %#ok<MCSUP>
        end

        % PhaseWrappingEnabled
        function set.PhaseWrappingEnabled(this,PhaseWrappingEnabled)
            arguments
                this (1,1) controllib.chart.internal.view.wave.NicholsResponseView
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
                this (1,1) controllib.chart.internal.view.wave.NicholsResponseView
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

    %% Public methods
    methods
        function updateCriticalMarkers(this,xLimits)
            if ~iscell(xLimits)
                xLimits = {xLimits};
            end
            magConversionFcn = getMagnitudeUnitConversionFcn(this,'dB',this.MagnitudeUnit);
            phaseConversionFcn = getPhaseUnitConversionFcn(this,'deg',this.PhaseUnit);
            phaseConversionFcnInv = getPhaseUnitConversionFcn(this,this.PhaseUnit,'deg');
            if size(xLimits,1) == 1 && this.Response.NRows > 1
                xLimits = repmat(xLimits,this.Response.NRows,1);
            end
            if size(xLimits,2) == 1 && this.Response.NColumns > 1
                xLimits = repmat(xLimits,1,this.Response.NColumns);
            end
            for ko = 1:min(this.Response.NRows,size(xLimits,1))
                for ki = 1:min(this.Response.NColumns,size(xLimits,2))
                    if ~isvalid(this.CriticalPointMarkers(ko,ki))
                        continue;
                    end
                    xlim = phaseConversionFcnInv(xLimits{ko,ki});
                    xlim(1) = floor(xlim(1)/360)*360-180;
                    xlim(2) = ceil(xlim(2)/360)*360+180;
                    xDataForMarkers = phaseConversionFcn(xlim(1):360:xlim(2));
                    yDataForMarkers = magConversionFcn(zeros(size(xDataForMarkers)));
                    this.CriticalPointMarkers(ko,ki).XData = xDataForMarkers;
                    this.CriticalPointMarkers(ko,ki).YData = yDataForMarkers;
                end
            end
        end
    end
    
    %% Protected methods
    methods (Access = protected)
        function createCharacteristics(this,data)
            c = controllib.chart.internal.view.characteristic.BaseCharacteristicView.empty;
            % Peak Response
            if isprop(data,"NicholsPeakResponse") && ~isempty(data.NicholsPeakResponse)
                c = controllib.chart.internal.view.characteristic.NicholsPeakResponseView(this,data.NicholsPeakResponse);
            end
            % AllStabilityMargin
            if isprop(data,"AllStabilityMargin") && ~isempty(data.AllStabilityMargin)
                c = [c; controllib.chart.internal.view.characteristic.NicholsStabilityMarginView(this,...
                            data.AllStabilityMargin)];
            end
            % MinimumStabilityMargin
            if isprop(data,"MinimumStabilityMargin") && ~isempty(data.MinimumStabilityMargin)
                c = [c; controllib.chart.internal.view.characteristic.NicholsStabilityMarginView(this,...
                            data.MinimumStabilityMargin)];
            end
            this.Characteristics = c;
        end

        function createResponseDataTips_(this,ko,ki,ka,nameDataTipRow,ioDataTipRow,customDataTipRows)
            % Create data tip row for frequency and magnitude
            phaseRow = dataTipTextRow(...
                getString(message('Controllib:plots:strPhase')) + " (" + this.PhaseUnitLabel + ")",...
                'XData','%0.3g');
            magnitudeRow = dataTipTextRow(...
                getString(message('Controllib:plots:strMagnitude')) + " (" + this.MagnitudeUnitLabel + ")",...
                'YData','%0.3g');
            frequencyRow = dataTipTextRow(getString(message('Controllib:plots:strFrequency')) + ...
                " (" + this.FrequencyUnitLabel + ")",...
                @(x,y) this.getFrequencyValue(this.ResponseLines(ko,ki,ka),x,y),'%0.3g');
            
            % Add to DataTipTemplate
            this.ResponseLines(ko,ki,ka).DataTipTemplate.DataTipRows = ...
                [nameDataTipRow; ioDataTipRow; phaseRow; magnitudeRow; frequencyRow; customDataTipRows(:)];
        end

        function createResponseObjects(this)
            this.ResponseLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='NicholsResponseLine');
        end

        function createSupportingObjects(this)
            magConversionFcn = getMagnitudeUnitConversionFcn(this,'dB',this.MagnitudeUnit);
            phaseConversionFcn = getPhaseUnitConversionFcn(this,'deg',this.PhaseUnit);
            this.ZeroMagnitudeLines = createGraphicsObjects(this,"constantLine",this.Response.NRows,...
                this.Response.NColumns,1,Tag='NicholsZeroMagnitudeLine',...
                HitTest="off",PickableParts="none");
            set(this.ZeroMagnitudeLines,InterceptAxis='y',LineStyle=':',Visible=this.ShowMagnitudeLines,Value=magConversionFcn(0));
            controllib.plot.internal.utils.setColorProperty(this.ZeroMagnitudeLines,...
                "Color","--mw-graphics-colorNeutral-line-primary");
            this.CriticalPointMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,1,Tag='NicholsCriticalPointScatter',...
                HitTest="off",PickableParts="none");
            xDataForMarkers = phaseConversionFcn((-49:2:49)*180);
            yDataForMarkers = magConversionFcn(zeros(size(xDataForMarkers)));
            set(this.CriticalPointMarkers,LineWidth=1.5,Marker='+',SizeData=100,...
                XData=xDataForMarkers,YData=yDataForMarkers);
            controllib.plot.internal.utils.setColorProperty(this.CriticalPointMarkers,...
                "MarkerEdgeColor","--mw-graphics-colorOrder-10-primary");
        end

        function legendLines = createLegendObjects(this)
            legendLines = createGraphicsObjects(this,"line",1,1,1,...
                DisplayName=strrep(this.Response.Name,'_','\_'));
        end

        function responseObjects = getResponseObjects_(this,ko,ki,ka)
            responseObjects = this.ResponseLines(ko,ki,ka);
        end

        function supportingObjects = getSupportingObjects_(this,ko,ki,~)
            supportingObjects = cat(3,this.ZeroMagnitudeLines(ko,ki),this.CriticalPointMarkers(ko,ki));
        end

        function updateResponseData(this)
            % Get unit conversion functions (system units are rad/model
            % TimeUnit, abs and rad)
            freqConversionFcn = getFrequencyUnitConversionFcn(this,this.Response.FrequencyUnit,this.FrequencyUnit);
            magConversionFcn = getMagnitudeUnitConversionFcn(this,this.Response.MagnitudeUnit,this.MagnitudeUnit);
            phaseConversionFcn = getPhaseUnitConversionFcn(this,this.Response.PhaseUnit,this.PhaseUnit);
            for ko = 1:this.Response.NRows
                for ki = 1:this.Response.NColumns
                    for ka = 1:this.Response.NResponses
                        % Convert frequency, magnitude and phase
                        w = freqConversionFcn(this.Response.ResponseData.Frequency{ka});
                        mag = magConversionFcn(this.Response.ResponseData.Magnitude{ka}(:,ko,ki));
                        if this.PhaseWrappingEnabled && this.PhaseMatchingEnabled
                            ph = phaseConversionFcn(this.Response.ResponseData.WrappedAndMatchedPhase{ka}(:,ko,ki));
                        elseif this.PhaseWrappingEnabled
                            ph = phaseConversionFcn(this.Response.ResponseData.WrappedPhase{ka}(:,ko,ki));
                        elseif this.PhaseMatchingEnabled
                            ph = phaseConversionFcn(this.Response.ResponseData.MatchedPhase{ka}(:,ko,ki));
                        else
                            ph = phaseConversionFcn(this.Response.ResponseData.Phase{ka}(:,ko,ki));
                        end
                        this.ResponseLines(ko,ki,ka).XData = ph;
                        this.ResponseLines(ko,ki,ka).YData = mag;
                        this.ResponseLines(ko,ki,ka).UserData.Frequency = w;
                        if this.IsResponseDataTipsCreated
                            this.replaceDataTipRowValue(this.ResponseLines(ko,ki,ka),...
                                getString(message('Controllib:plots:strFrequency')),w);
                        end
                    end
                end
            end
        end

        function cbFrequencyUnitChanged(this,conversionFcn)
           
            for ko = 1:this.Response.NRows
                for ki = 1:this.Response.NColumns
                    for ka = 1:this.Response.NResponses
                        this.ResponseLines(ko,ki,ka).UserData.Frequency =...
                            conversionFcn(this.ResponseLines(ko,ki,ka).UserData.Frequency);
                    end
                end
            end
            % Update response line data tip. This also triggers the data
            % update function on the dataTipTextRow updating the frequency
            % value.
            updateFrequencyLabelDataTip(this);

            for k = 1:length(this.Characteristics)
                if isa(this.Characteristics(k),'controllib.chart.internal.foundation.MixInFrequencyUnit')
                    this.Characteristics(k).FrequencyUnit = this.FrequencyUnit;
                end 
            end
        end
        
        function cbMagnitudeUnitChanged(this,conversionFcn)
            for ko = 1:this.Response.NRows
                for ki = 1:this.Response.NColumns
                    for ka = 1:this.Response.NResponses
                        this.ResponseLines(ko,ki,ka).YData = ...
                            conversionFcn(this.ResponseLines(ko,ki,ka).YData);
                    end
                    this.ZeroMagnitudeLines(ko,ki).Value = ...
                            conversionFcn(this.ZeroMagnitudeLines(ko,ki).Value);
                    this.CriticalPointMarkers(ko,ki).YData = ...
                            conversionFcn(this.CriticalPointMarkers(ko,ki).YData);
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
                        this.ResponseLines(ko,ki,ka).XData = ...
                            conversionFcn(this.ResponseLines(ko,ki,ka).XData);
                    end
                    this.CriticalPointMarkers(ko,ki).XData = ...
                            conversionFcn(this.CriticalPointMarkers(ko,ki).XData);
                end
            end

            % Update response line data tip
            updatePhaseLabelDataTip(this);

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
                            this.replaceDataTipRowLabel(this.ResponseLines(ko,ki,ka),getString(message('Controllib:plots:strFrequency')),...
                                getString(message('Controllib:plots:strFrequency')) + " (" + this.FrequencyUnitLabel + ")");
                        end
                    end
                end
            end
        end

        function updateMagnitudeLabelDataTip(this)
            if this.IsResponseDataTipsCreated
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        for ka = 1:this.Response.NResponses
                            this.replaceDataTipRowLabel(this.ResponseLines(ko,ki,ka),getString(message('Controllib:plots:strMagnitude')),...
                                getString(message('Controllib:plots:strMagnitude')) + " (" + this.MagnitudeUnitLabel + ")");
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
                            this.replaceDataTipRowLabel(this.ResponseLines(ko,ki,ka),getString(message('Controllib:plots:strPhase')),...
                                getString(message('Controllib:plots:strPhase')) + " (" + this.PhaseUnitLabel + ")");
                        end
                    end
                end
            end
        end
    end

    %% Static sealed protected methods
    methods (Static,Sealed,Access=protected)
        function interpValue = getFrequencyValue(hLine,x,y)
            xData = hLine.XData;
            yData = hLine.YData;
            gains = hLine.UserData.Frequency;
            point = [x;y];
            ax = hLine.Parent;
            xlim = ax.XLim;
            ylim = ax.YLim;
            xScale = ax.XScale;
            yScale = ax.YScale;
            interpValue = controllib.chart.internal.view.wave.NicholsResponseView.scaledProject2(...
                xData,yData,gains,point,xlim,ylim,xScale,yScale);
        end
    end
end

