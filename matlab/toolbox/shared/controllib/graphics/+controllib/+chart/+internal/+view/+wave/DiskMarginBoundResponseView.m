classdef DiskMarginBoundResponseView < controllib.chart.internal.view.wave.BaseResponseView & ...
        controllib.chart.internal.foundation.MixInFrequencyUnit & ...
        controllib.chart.internal.foundation.MixInMagnitudeUnit & ...
        controllib.chart.internal.foundation.MixInPhaseUnit
    % Bode Response

    % Copyright 2023 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        GainResponsePatch
        PhaseResponsePatch
        GainNyquistLines
        PhaseNyquistLines
    end

    properties (SetAccess={?controllib.chart.internal.view.axes.BaseAxesView,...
            ?controllib.chart.internal.view.wave.BaseResponseView})
        FrequencyScale = "log"
    end

    %% Constructor
    methods
        function this = DiskMarginBoundResponseView(response,optionalInputs)
            arguments
                response (1,1) controllib.chart.response.internal.DiskMarginBoundResponse
                optionalInputs.ArrayVisible logical = response.ArrayVisible
            end
            this@controllib.chart.internal.foundation.MixInFrequencyUnit(response.FrequencyUnit);
            this@controllib.chart.internal.foundation.MixInMagnitudeUnit(response.MagnitudeUnit);
            this@controllib.chart.internal.foundation.MixInPhaseUnit(response.PhaseUnit);
            optionalInputs = namedargs2cell(optionalInputs);
            this@controllib.chart.internal.view.wave.BaseResponseView(response,optionalInputs{:});
            build(this);
        end
    end

    %% Public methods
    methods
        function deleteAllDataTips(this,rowIdx,columnIdx,axesType)
            arguments
                this (1,1) controllib.chart.internal.view.wave.DiskMarginBoundResponseView
                rowIdx (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NRows
                columnIdx (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NColumns
                axesType (1,1) string {mustBeMember(axesType,["all","gain","phase"])} = "all"
            end
            for ko = rowIdx
                for ki = columnIdx
                    for ka = 1:this.Response.NResponses
                        % Delete for response lines
                        responseObjects = getResponseObjects(this,ko,ki,ka);
                        if ~isempty(responseObjects{1})
                            switch axesType
                                case "gain"
                                    responseObjects = {responseObjects{1}(1,1,:)};
                                case "phase"
                                    responseObjects = {responseObjects{1}(2,1,:)};
                            end
                        end
                        dataTipObjects = findobj(responseObjects{1},'Type','datatip');
                        delete(dataTipObjects);
                        % Delete for characteristic markers
                        charMarkers = getCharacteristicMarkers(this,ko,ki,ka);
                        if ~isempty(charMarkers{1})
                            switch axesType
                                case "gain"
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

        function updatePatchLimits(this,XLimits,MagLimits,PhaseLimits)
            arguments
                this (1,1) controllib.chart.internal.view.wave.DiskMarginBoundResponseView
                XLimits (1,2) double
                MagLimits (1,2) double
                PhaseLimits (1,2) double
            end
            FreqLimits = XLimits;
            switch this.FrequencyScale
                case "log"
                    leftEdge = [1 4];
                    rightEdge = [2 3];
                case "linear"
                    leftEdge = [1 2 3 6 7 8];
                    rightEdge = [4 5];
            end
            if this.Response.Focus(1) == 0
                this.GainResponsePatch.XData(leftEdge) = max(FreqLimits(1),0);
                this.PhaseResponsePatch.XData(leftEdge) = max(FreqLimits(1),0);
            end
            if isinf(this.Response.Focus(2))
                this.GainResponsePatch.XData(rightEdge) = FreqLimits(2);
                this.PhaseResponsePatch.XData(rightEdge) = FreqLimits(2);
            end
            numData = length(this.GainResponsePatch.XData);
            switch this.Response.BoundType
                case "upper"
                    yMin = min(this.GainResponsePatch.YData(1:numData/2));
                    this.GainResponsePatch.YData(numData/2+1:numData) = max(yMin,MagLimits(2));
                    yMin = min(this.PhaseResponsePatch.YData(1:numData/2));
                    this.PhaseResponsePatch.YData(numData/2+1:numData) = max(yMin,PhaseLimits(2));
                case "lower"
                    yMax = max(this.GainResponsePatch.YData(1:numData/2));
                    this.GainResponsePatch.YData(numData/2+1:numData) = min(yMax,MagLimits(1));
                    yMax = max(this.PhaseResponsePatch.YData(1:numData/2));
                    this.PhaseResponsePatch.YData(numData/2+1:numData) = min(yMax,PhaseLimits(1));
            end
        end
    end

    %% Protected methods
    methods (Access = protected)
        function createResponseObjects(this)
            this.GainResponsePatch = createGraphicsObjects(this,"patch",1,1,1,...
                Tag='DiskMarginBoundGainResponse');
            this.disableDataTipInteraction(this.GainResponsePatch);
            this.PhaseResponsePatch = createGraphicsObjects(this,"patch",1,1,1,...
                Tag='DiskMarginBoundPhaseResponse');
            this.disableDataTipInteraction(this.PhaseResponsePatch);
        end

        function createSupportingObjects(this)
            this.GainNyquistLines = createGraphicsObjects(this,"constantLine",1,1,2,...
                Tag='DiskMarginBoundGainNyquistLine',HitTest='off',PickableParts='none');
            set(this.GainNyquistLines,InterceptAxis='x',LineWidth=1.5);
            controllib.plot.internal.utils.setColorProperty(this.GainNyquistLines,...
                "Color","--mw-graphics-colorNeutral-line-primary");
            this.PhaseNyquistLines = createGraphicsObjects(this,"constantLine",1,1,2,...
                Tag='DiskMarginBoundPhaseNyquistLine',HitTest='off',PickableParts='none');
            set(this.PhaseNyquistLines,InterceptAxis='x',LineWidth=1.5);
            controllib.plot.internal.utils.setColorProperty(this.PhaseNyquistLines,...
                "Color","--mw-graphics-colorNeutral-line-primary");
        end

        function responseLines = getResponseObjects_(this,~,~,~)
            responseLines = [this.GainResponsePatch;this.PhaseResponsePatch];
        end

        function supportingObjects = getSupportingObjects_(this,~,~,~)
            supportingObjects = [this.GainNyquistLines;this.PhaseNyquistLines];
        end
        
        function updateResponseData(this)
            % Get unit conversion functions (system units are rad/model
            % TimeUnit, abs and rad)
            freqConversionFcn = getFrequencyUnitConversionFcn(this,this.Response.FrequencyUnit,this.FrequencyUnit);
            magConversionFcn = getMagnitudeUnitConversionFcn(this,this.Response.MagnitudeUnit,this.MagnitudeUnit);
            phaseConversionFcn = getPhaseUnitConversionFcn(this,this.Response.PhaseUnit,this.PhaseUnit);

            % Convert frequency, magnitude and phase
            w = freqConversionFcn(this.Response.ResponseData.Frequency);
            mag = magConversionFcn(this.Response.ResponseData.GainMargin);
            ph = phaseConversionFcn(this.Response.ResponseData.PhaseMargin);

            if this.FrequencyScale=="linear"
                w = [-flipud(w);w];
                mag = [flipud(mag);mag];
                ph = [flipud(ph);ph];
            end

            w = [w;flipud(w)];

            switch this.Response.BoundType
                case "upper"
                    mag = [mag;1e20*ones(size(mag))];
                    ph = [ph;1e20*ones(size(ph))];
                case "lower"
                    mag = [mag;1e-20*ones(size(mag))];
                    ph = [ph;-1e20*ones(size(ph))];
            end
            this.GainResponsePatch.XData = w;
            this.GainResponsePatch.YData = mag;
            this.PhaseResponsePatch.XData = w;
            this.PhaseResponsePatch.YData = ph;

            if this.Response.Ts ~= 0
                nyFreq = freqConversionFcn(pi/abs(this.Response.Ts));
                set(this.GainNyquistLines(1),Value=nyFreq);
                set(this.PhaseNyquistLines(1),Value=nyFreq);
                set(this.GainNyquistLines(2),Value=-nyFreq);
                set(this.PhaseNyquistLines(2),Value=-nyFreq);
                set(this.GainNyquistLines,Visible=this.GainResponsePatch.Visible);
                set(this.PhaseNyquistLines,Visible=this.PhaseResponsePatch.Visible);
            else
                set(this.GainNyquistLines,Visible=false);
                set(this.PhaseNyquistLines,Visible=false);
            end
        end

        function updateResponseVisibility(this,rowVisible,columnVisible,arrayVisible)
            arguments
                this (1,1) controllib.chart.internal.view.wave.DiskMarginBoundResponseView
                rowVisible (:,1) logical
                columnVisible (1,:) logical
                arrayVisible logical
            end
            updateResponseVisibility@controllib.chart.internal.view.wave.BaseResponseView(this,rowVisible,columnVisible,arrayVisible);
            set(this.GainNyquistLines,Visible = this.GainResponsePatch.Visible & this.Response.Ts ~= 0);
            set(this.PhaseNyquistLines,Visible = this.PhaseResponsePatch.Visible & this.Response.Ts ~= 0);
        end

        function cbFrequencyUnitChanged(this,conversionFcn)
            this.GainResponsePatch.XData = conversionFcn(this.GainResponsePatch.XData);
            this.PhaseResponsePatch.XData = conversionFcn(this.PhaseResponsePatch.XData);
            for ii = 1:2
                this.GainNyquistLines(ii).Value = conversionFcn(this.GainNyquistLines(ii).Value);
                this.PhaseNyquistLines(ii).Value = conversionFcn(this.PhaseNyquistLines(ii).Value);
            end
        end

        function cbMagnitudeUnitChanged(this,conversionFcn)
            this.GainResponsePatch.YData = conversionFcn(this.GainResponsePatch.YData);
        end

        function cbPhaseUnitChanged(this,conversionFcn)
            this.PhaseResponsePatch.YData = conversionFcn(this.PhaseResponsePatch.YData);
        end
    end
end



