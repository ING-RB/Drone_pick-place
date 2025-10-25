classdef DiskMarginResponseView < controllib.chart.internal.view.wave.BaseResponseView & ...
        controllib.chart.internal.foundation.MixInFrequencyUnit & ...
        controllib.chart.internal.foundation.MixInMagnitudeUnit & ...
        controllib.chart.internal.foundation.MixInPhaseUnit
    % Bode Response

    % Copyright 2023 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        GainResponseLines
        PhaseResponseLines
        GainPositiveArrows
        GainNegativeArrows
        PhasePositiveArrows
        PhaseNegativeArrows
        GainNyquistLines
        PhaseNyquistLines
    end

    properties (SetAccess={?controllib.chart.internal.view.axes.BaseAxesView,...
            ?controllib.chart.internal.view.wave.BaseResponseView})
        FrequencyScale = "log"
    end

    %% Constructor
    methods
        function this = DiskMarginResponseView(response,optionalInputs)            
            arguments
                response (1,1) controllib.chart.response.DiskMarginResponse
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
                this (1,1) controllib.chart.internal.view.wave.DiskMarginResponseView
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

        function updateArrows(this,optionalArguments)
            arguments
                this
                optionalArguments.AspectRatio = []
            end
            if ~this.Response.IsResponseValid
                return;
            end
            if this.FrequencyScale=="log"
                for ka = 1:this.Response.NResponses
                    if ~this.Response.ResponseData.IsReal(ka)
                        if ~isvalid(this.GainResponseLines(1,1,ka)) || ~isvalid(this.PhaseResponseLines(1,1,ka))
                            continue;
                        end
                        % Magnitude
                        xData = this.GainResponseLines(1,1,ka).XData;
                        yData = this.GainResponseLines(1,1,ka).YData;
                        ax = this.GainResponseLines(1,1,ka).Parent;
                        if ~isempty(ax)
                            xRange = ax.XLim;
                            yRange = ax.YLim;
                        else
                            xRange = [min(xData) max(xData)];
                            yRange = [min(yData) max(yData)];
                        end
                        [ia1,ia2] = this.localPositionArrow(xData,yData,xRange,yRange);
                        % Negative Arrow
                        this.localDrawArrow(this.GainNegativeArrows(1,1,ka),xData(ia1),yData(ia1),...
                            xRange,yRange,(0.5+this.GainResponseLines(1,1,ka).LineWidth)/150,...
                            optionalArguments.AspectRatio);
                        % Positive Arrow
                        this.localDrawArrow(this.GainPositiveArrows(1,1,ka),xData(ia2),yData(ia2),...
                            xRange,yRange,(0.5+this.GainResponseLines(1,1,ka).LineWidth)/150,...
                            optionalArguments.AspectRatio);
                        % Phase
                        xData = this.PhaseResponseLines(1,1,ka).XData;
                        yData = this.PhaseResponseLines(1,1,ka).YData;
                        ax = this.PhaseResponseLines(1,1,ka).Parent;
                        if ~isempty(ax)
                            xRange = ax.XLim;
                            yRange = ax.YLim;
                        else
                            xRange = [min(xData) max(xData)];
                            yRange = [min(yData) max(yData)];
                        end
                        [ia1,ia2] = this.localPositionArrow(xData,yData,xRange,yRange);
                        % Negative Arrow
                        this.localDrawArrow(this.PhaseNegativeArrows(1,1,ka),xData(ia1),yData(ia1),...
                            xRange,yRange,(0.5+this.PhaseResponseLines(1,1,ka).LineWidth)/150,...
                            optionalArguments.AspectRatio);
                        % Positive Arrow
                        this.localDrawArrow(this.PhasePositiveArrows(1,1,ka),xData(ia2),yData(ia2),...
                            xRange,yRange,(0.5+this.PhaseResponseLines(1,1,ka).LineWidth)/150,...
                            optionalArguments.AspectRatio);
                    end
                end
            end
        end
    end

    %% Get/Set
    methods
        % FrequencyScale
        function set.FrequencyScale(this,FrequencyScale)
            arguments
                this (1,1) controllib.chart.internal.view.wave.DiskMarginResponseView
                FrequencyScale (1,1) string {mustBeMember(FrequencyScale,["log","linear"])}
            end
            this.FrequencyScale = FrequencyScale;
            updateResponseData(this,UpdateArrows=false);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function createCharacteristics(this,data)
            c = controllib.chart.internal.view.characteristic.BaseCharacteristicView.empty;
            % MinimumResponse
            if isprop(data,"DiskMarginMinimumResponse") && ~isempty(data.DiskMarginMinimumResponse)
                c = controllib.chart.internal.view.characteristic.DiskMarginMinimumResponseView(this,data.DiskMarginMinimumResponse);
            end
            this.Characteristics = c;
        end

        function createResponseObjects(this)
            this.GainResponseLines = createGraphicsObjects(this,"line",1,1,this.Response.NResponses,...
                Tag='DiskMarginGainLine');
            this.GainPositiveArrows = createGraphicsObjects(this,"patch",1,1,this.Response.NResponses,...
                Tag='DiskMarginGainPositiveArrow',HitTest='off',PickableParts='none');
            this.GainNegativeArrows = createGraphicsObjects(this,"patch",1,1,this.Response.NResponses,...
                Tag='DiskMarginGainNegativeArrow',HitTest='off',PickableParts='none');
            this.PhaseResponseLines = createGraphicsObjects(this,"line",1,1,this.Response.NResponses,...
                Tag='DiskMarginPhaseLine');
            this.PhasePositiveArrows = createGraphicsObjects(this,"patch",1,1,this.Response.NResponses,...
                Tag='DiskMarginPhasePositiveArrow',HitTest='off',PickableParts='none');
            this.PhaseNegativeArrows = createGraphicsObjects(this,"patch",1,1,this.Response.NResponses,...
                Tag='DiskMarginPhaseNegativeArrow',HitTest='off',PickableParts='none');
        end

        function createSupportingObjects(this)
            this.GainNyquistLines = createGraphicsObjects(this,"constantLine",1,1,2,...
                Tag='DiskMarginGainNyquistLine',HitTest='off',PickableParts='none');
            set(this.GainNyquistLines,InterceptAxis='x',LineWidth=1.5);
            controllib.plot.internal.utils.setColorProperty(this.GainNyquistLines,...
                "Color","--mw-graphics-colorNeutral-line-primary");
            this.PhaseNyquistLines = createGraphicsObjects(this,"constantLine",1,1,2,...
                Tag='DiskMarginPhaseNyquistLine',HitTest='off',PickableParts='none');
            set(this.PhaseNyquistLines,InterceptAxis='x',LineWidth=1.5);
            controllib.plot.internal.utils.setColorProperty(this.PhaseNyquistLines,...
                "Color","--mw-graphics-colorNeutral-line-primary");
        end

        function legendLine = createLegendObjects(this)
            legendLine = createGraphicsObjects(this,"line",1,1,1,...
                DisplayName=strrep(this.Response.Name,'_','\_'));
        end

        function responseObjects = getResponseObjects_(this,~,~,ka)
            responseObjects = [cat(3,this.GainResponseLines(ka),this.GainPositiveArrows(ka),this.GainNegativeArrows(ka));
                cat(3,this.PhaseResponseLines(ka),this.PhasePositiveArrows(ka),this.PhaseNegativeArrows(ka))];
        end

        function supportingObjects = getSupportingObjects_(this,~,~,~)
            supportingObjects = [this.GainNyquistLines;this.PhaseNyquistLines];
        end

        function updateResponseData(this,optionalInputs)
            arguments
                this (1,1) controllib.chart.internal.view.wave.DiskMarginResponseView
                optionalInputs.UpdateArrows (1,1) logical = true
            end
            % Get unit conversion functions (system units are rad/model
            % TimeUnit, abs and rad)
            freqConversionFcn = getFrequencyUnitConversionFcn(this,this.Response.FrequencyUnit,this.FrequencyUnit);
            magConversionFcn = getMagnitudeUnitConversionFcn(this,this.Response.MagnitudeUnit,this.MagnitudeUnit);
            phaseConversionFcn = getPhaseUnitConversionFcn(this,this.Response.PhaseUnit,this.PhaseUnit);
            for ka = 1:this.Response.NResponses
                % Convert frequency, magnitude and phase
                w = freqConversionFcn(this.Response.ResponseData.Frequency{ka});
                mag = magConversionFcn(this.Response.ResponseData.GainMargin{ka});
                ph = phaseConversionFcn(this.Response.ResponseData.PhaseMargin{ka});
                if this.Response.ResponseData.IsReal(ka)
                    w = [-flipud(w);w]; %#ok<AGROW>
                    mag = [flipud(mag);mag]; %#ok<AGROW>
                    ph = [flipud(ph);ph]; %#ok<AGROW>
                end
                switch this.FrequencyScale
                    case "log"
                        if ~this.Response.ResponseData.IsReal(ka)
                            w = abs(w);
                            this.GainPositiveArrows(ka).Visible = this.GainResponseLines(ka).Visible;
                            this.GainNegativeArrows(ka).Visible = this.GainResponseLines(ka).Visible;
                            this.PhasePositiveArrows(ka).Visible = this.PhaseResponseLines(ka).Visible;
                            this.PhaseNegativeArrows(ka).Visible = this.PhaseResponseLines(ka).Visible;
                        else
                            this.GainPositiveArrows(ka).Visible = false;
                            this.GainNegativeArrows(ka).Visible = false;
                            this.PhasePositiveArrows(ka).Visible = false;
                            this.PhaseNegativeArrows(ka).Visible = false;
                        end
                    case "linear"
                        this.GainPositiveArrows(ka).Visible = false;
                        this.GainNegativeArrows(ka).Visible = false;
                        this.PhasePositiveArrows(ka).Visible = false;
                        this.PhaseNegativeArrows(ka).Visible = false;
                end
                this.GainResponseLines(ka).XData = w;
                this.GainResponseLines(ka).YData = mag;
                this.PhaseResponseLines(ka).XData = w;
                this.PhaseResponseLines(ka).YData = ph;
            end
            if this.Response.IsDiscrete
                nyFreq = freqConversionFcn(pi/abs(this.Response.Model.Ts));
                set(this.GainNyquistLines(1),Value=nyFreq);
                set(this.PhaseNyquistLines(1),Value=nyFreq);
                set(this.GainNyquistLines(2),Value=-nyFreq);
                set(this.PhaseNyquistLines(2),Value=-nyFreq);
                visibilityFlag = any(arrayfun(@(x) x.Visible,this.GainResponseLines),'all');
                set(this.GainNyquistLines,Visible=visibilityFlag);
                visibilityFlag = any(arrayfun(@(x) x.Visible,this.PhaseResponseLines),'all');
                set(this.PhaseNyquistLines,Visible=visibilityFlag);
            else
                set(this.GainNyquistLines,Visible=false);
                set(this.PhaseNyquistLines,Visible=false);
            end
            if optionalInputs.UpdateArrows
                updateArrows(this);
            end
        end

        function updateResponseVisibility(this,rowVisible,columnVisible,arrayVisible)
            arguments
                this (1,1) controllib.chart.internal.view.wave.DiskMarginResponseView
                rowVisible (:,1) logical
                columnVisible (1,:) logical
                arrayVisible logical
            end
            updateResponseVisibility@controllib.chart.internal.view.wave.BaseResponseView(this,rowVisible,columnVisible,arrayVisible);
            for ka = 1:this.Response.NResponses
                isReal = this.Response.ResponseData.IsReal(ka);
                this.GainNegativeArrows(ka).Visible = arrayVisible(ka) & ~isReal;
                this.GainPositiveArrows(ka).Visible = arrayVisible(ka) & ~isReal;
                this.PhaseNegativeArrows(ka).Visible = arrayVisible(ka) & ~isReal;
                this.PhasePositiveArrows(ka).Visible = arrayVisible(ka) & ~isReal;
            end
            visibilityFlag = any(arrayfun(@(x) x.Visible,this.GainResponseLines),'all');
            set(this.GainNyquistLines,Visible=visibilityFlag & this.Response.IsDiscrete);
            visibilityFlag = any(arrayfun(@(x) x.Visible,this.PhaseResponseLines),'all');
            set(this.PhaseNyquistLines,Visible=visibilityFlag & this.Response.IsDiscrete);
        end

        function createResponseDataTips_(this,~,~,ka,nameDataTipRow,~,customDataTipRows)
            % Create data tip row for frequency and magnitude
            frequencyRow = dataTipTextRow(...
                getString(message('Controllib:plots:strFrequency')) + " (" + this.FrequencyUnitLabel + ")",...
                'XData','%0.3g');
            magnitudeRow = dataTipTextRow(...
                getString(message('Controllib:plots:strGainMargin')) + " (" + this.MagnitudeUnitLabel + ")",...
                'YData','%0.3g');

            % Add to DataTipTemplate
            this.GainResponseLines(ka).DataTipTemplate.DataTipRows = ...
                [nameDataTipRow; frequencyRow; magnitudeRow; customDataTipRows(:)];

            % Create data tip row for phase
            phaseRow = dataTipTextRow(...
                getString(message('Controllib:plots:strPhaseMargin')) + " (" + this.PhaseUnitLabel + ")",...
                'YData','%0.3g');

            % Add to DataTipTemplate
            this.PhaseResponseLines(ka).DataTipTemplate.DataTipRows = ...
                [nameDataTipRow; frequencyRow; phaseRow; customDataTipRows(:)];
        end

        function cbFrequencyUnitChanged(this,conversionFcn)
            % Update response
            for ka = 1:this.Response.NResponses
                this.GainResponseLines(ka).XData = ...
                    conversionFcn(this.GainResponseLines(ka).XData);
                this.PhaseResponseLines(ka).XData = ...
                    conversionFcn(this.PhaseResponseLines(ka).XData);
            end
            for ii = 1:2
                this.GainNyquistLines(ii).Value = conversionFcn(this.GainNyquistLines(ii).Value);
                this.PhaseNyquistLines(ii).Value = conversionFcn(this.PhaseNyquistLines(ii).Value);
            end
            
            % Update response line data tip
            updateFrequencyLabelDataTip(this);

            % Convert units on characteristics
            for k = 1:length(this.Characteristics)
                if isa(this.Characteristics(k),'controllib.chart.internal.foundation.MixInFrequencyUnit')
                    this.Characteristics(k).FrequencyUnit = this.FrequencyUnit;
                end
            end
        end

        function cbMagnitudeUnitChanged(this,conversionFcn)
            for ka = 1:this.Response.NResponses
                this.GainResponseLines(ka).YData = ...
                    conversionFcn(this.GainResponseLines(ka).YData);
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
            for ka = 1:this.Response.NResponses
                this.PhaseResponseLines(ka).YData = ...
                    conversionFcn(this.PhaseResponseLines(ka).YData);
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
            for ka = 1:this.Response.NResponses
                this.GainResponseLines(ka).DataTipTemplate.DataTipRows(2).Label = ...
                    getString(message('Controllib:plots:strFrequency')) + " (" + this.FrequencyUnitLabel + ")";
                this.PhaseResponseLines(ka).DataTipTemplate.DataTipRows(2).Label = ...
                    getString(message('Controllib:plots:strFrequency')) + " (" + this.FrequencyUnitLabel + ")";
            end
        end

        function updateMagnitudeLabelDataTip(this)
            for ka = 1:this.Response.NResponses
                this.GainResponseLines(ka).DataTipTemplate.DataTipRows(3).Label = ...
                    getString(message('Controllib:plots:strGainMargin')) + " (" + this.MagnitudeUnitLabel + ")";
            end
        end

        function updatePhaseLabelDataTip(this)
            for ka = 1:this.Response.NResponses
                this.PhaseResponseLines(ka).DataTipTemplate.DataTipRows(3).Label = ...
                    getString(message('Controllib:plots:strPhaseMargin')) + " (" + this.PhaseUnitLabel + ")";
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
            ix1 = find(ix<iz-1 & InScope);  w1 = X(:,ix1);  % w<0 in scope, decreasing
            ix2 = find(ix>iz & InScope);    w2 = X(:,ix2);  % w>0 in scope, increasing
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



