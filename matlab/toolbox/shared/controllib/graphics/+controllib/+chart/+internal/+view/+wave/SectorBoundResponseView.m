classdef SectorBoundResponseView < controllib.chart.internal.view.wave.BaseResponseView & ...
        controllib.chart.internal.foundation.MixInFrequencyUnit & ...
        controllib.chart.internal.foundation.MixInMagnitudeUnit
    % SigmaResponseView     Manage response lines and characteristics of a singular value plot
    
    % Copyright 2023 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        ResponsePatches
        PositiveArrows
        NegativeArrows
        NyquistLines
    end

    properties (SetAccess = {?controllib.chart.internal.view.wave.BaseResponseView,...
            ?controllib.chart.internal.view.axes.BaseAxesView})
        FrequencyScale = "log"
    end

    properties (SetAccess=immutable)
        NPatches
    end

    %% Constructor
    methods
        function this = SectorBoundResponseView(response,optionalInputs)            
            arguments
                response (1,1) controllib.chart.response.internal.SectorBoundResponse
                optionalInputs.ArrayVisible logical = response.ArrayVisible
            end
            this@controllib.chart.internal.foundation.MixInFrequencyUnit(response.FrequencyUnit);
            this@controllib.chart.internal.foundation.MixInMagnitudeUnit(response.IndexUnit);
            optionalInputs = namedargs2cell(optionalInputs);
            this@controllib.chart.internal.view.wave.BaseResponseView(response,optionalInputs{:});
            this.NPatches = size(response.ResponseData.RelativeIndex{1},1);
            build(this);
        end
    end

    %% Public methods
    methods
        function updateArrows(this,optionalInputs)
            arguments
                this
                optionalInputs.AspectRatio = []
            end
            if ~this.Response.IsResponseValid
                return;
            end
            if this.FrequencyScale=="log"
                for k = 1:this.NPatches
                    for ka = 1:this.Response.NResponses
                        if ~this.Response.ResponseData.IsReal(ka)
                            if ~isvalid(this.ResponsePatches(k,1,ka))
                                continue;
                            end
                            switch this.Response.BoundType
                                case {"upper","lower"}
                                    numData = length(this.ResponsePatches(k,1,ka).XData);
                                    xData = this.ResponsePatches(k,1,ka).XData(1:numData/2);
                                    yData = this.ResponsePatches(k,1,ka).YData(1:numData/2);
                                otherwise
                                    xData = this.ResponsePatches(k,1,ka).XData;
                                    yData = this.ResponsePatches(k,1,ka).YData;
                            end
                            ax = this.ResponsePatches(k,1,ka).Parent;
                            if ~isempty(ax)
                                xRange = ax.XLim;
                                yRange = ax.YLim;
                            else
                                xRange = [min(xData) max(xData)];
                                yRange = [min(yData) max(yData)];
                            end
                            [ia1,ia2] = this.localPositionArrow(xData,yData,xRange,yRange);
                            % Negative Arrow
                            this.localDrawArrow(this.NegativeArrows(k,1,ka),xData(ia1),yData(ia1),...
                                xRange,yRange,(0.5+this.ResponsePatches(k,1,ka).LineWidth)/150,...
                                optionalInputs.AspectRatio);
                            % Positive Arrow
                            this.localDrawArrow(this.PositiveArrows(k,1,ka),xData(ia2),yData(ia2),...
                                xRange,yRange,(0.5+this.ResponsePatches(k,1,ka).LineWidth)/150,...
                                optionalInputs.AspectRatio);
                        end
                    end
                end
            end
        end
        
        function updatePatchHeight(this,YLimits)
            for k = 1:this.NPatches
                for ka = 1:this.Response.NResponses
                    numData = length(this.ResponsePatches(k,1,ka).XData);
                    switch this.Response.BoundType
                        case "upper"
                            yMin = min(this.ResponsePatches(k,1,ka).YData(1:numData/2));
                            this.ResponsePatches(k,1,ka).YData(numData/2+1:numData) = max(yMin,YLimits(2));
                        case "lower"
                            yMax = max(this.ResponsePatches(k,1,ka).YData(1:numData/2));
                            this.ResponsePatches(k,1,ka).YData(numData/2+1:numData) = min(yMax,YLimits(1));
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
                this (1,1) controllib.chart.internal.view.wave.SectorBoundResponseView
                FrequencyScale (1,1) string {mustBeMember(FrequencyScale,["log","linear"])}
            end
            this.FrequencyScale = FrequencyScale;
            updateResponseData(this,UpdateArrows=false);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function createResponseObjects(this)
            this.ResponsePatches = createGraphicsObjects(this,"patch",this.NPatches,1,this.Response.NResponses,...
                Tag='SectorBoundResponsePatch');
            this.disableDataTipInteraction(this.ResponsePatches);
            this.PositiveArrows = createGraphicsObjects(this,"patch",this.NPatches,1,this.Response.NResponses,...
                Tag='SectorBoundPositiveArrow',HitTest='off',PickableParts='none');
            this.NegativeArrows = createGraphicsObjects(this,"patch",this.NPatches,1,this.Response.NResponses,...
                Tag='SectorBoundNegativeArrow',HitTest='off',PickableParts='none');
        end

        function createSupportingObjects(this)
            this.NyquistLines = createGraphicsObjects(this,"constantLine",1,1,2,...
                Tag='SectorBoundNyquistLine',HitTest='off',PickableParts='none');
            set(this.NyquistLines,InterceptAxis='x',LineWidth=1.5);
            controllib.plot.internal.utils.setColorProperty(this.NyquistLines,...
                "Color","--mw-graphics-colorNeutral-line-primary");
        end

        function responseObjects = getResponseObjects_(this,~,~,ka)
            patches = reshape(this.ResponsePatches(:,1,ka),1,1,this.NPatches);
            posArrows = reshape(this.PositiveArrows(:,1,ka),1,1,this.NPatches);
            negArrows = reshape(this.NegativeArrows(:,1,ka),1,1,this.NPatches);
            responseObjects = cat(3,patches,posArrows,negArrows);
        end

        function supportingObjects = getSupportingObjects_(this,~,~,~)
            supportingObjects = this.NyquistLines;
        end

        function updateResponseData(this,optionalInputs)
            arguments
                this (1,1) controllib.chart.internal.view.wave.SectorBoundResponseView
                optionalInputs.UpdateArrows (1,1) logical = true
            end
            frequencyConversionFcn = getFrequencyUnitConversionFcn(this,this.Response.FrequencyUnit,this.FrequencyUnit);
            magnitudeConversionFcn = getMagnitudeUnitConversionFcn(this,this.Response.IndexUnit,this.MagnitudeUnit);
            for k = 1:this.NPatches
                for ka = 1:this.Response.NResponses
                    w = frequencyConversionFcn(this.Response.ResponseData.Frequency{ka});
                    sv = magnitudeConversionFcn(this.Response.ResponseData.RelativeIndex{ka}(k,:));
                    ixp = find(w>0);
                    ixn = find(w<0);
                    if this.Response.ResponseData.IsReal(ka)
                        w = [-flipud(w(ixp,:));w(ixp,:)];
                        sv = [fliplr(sv(:,ixp)) sv(:,ixp)];
                    else
                        w = [w(ixn,:);w(ixp,:)];
                        sv = [sv(:,ixn) sv(:,ixp)];
                    end
                    switch this.FrequencyScale
                        case "log"
                            if ~this.Response.ResponseData.IsReal(ka)
                                w = abs(w);
                                this.PositiveArrows(k,1,ka).Visible = this.ResponsePatches(k,1,ka).Visible;
                                this.NegativeArrows(k,1,ka).Visible = this.ResponsePatches(k,1,ka).Visible;
                            else
                                sv = sv(w>0);
                                w = w(w>0);
                                this.PositiveArrows(k,1,ka).Visible = false;
                                this.NegativeArrows(k,1,ka).Visible = false;
                            end
                        case "linear"
                            this.PositiveArrows(k,1,ka).Visible = false;
                            this.NegativeArrows(k,1,ka).Visible = false;
                    end
                    switch this.Response.BoundType
                        case "upper"
                            w = [w;flipud(w)]; %#ok<AGROW>
                            sv = [sv 1e20*ones(size(sv))]; %#ok<AGROW>
                        case "lower"
                            w = [w;flipud(w)]; %#ok<AGROW>
                            sv = [sv 1e-20*ones(size(sv))]; %#ok<AGROW>
                    end
                    this.ResponsePatches(k,1,ka).XData = w;
                    this.ResponsePatches(k,1,ka).YData = sv;
                end
            end
            if this.Response.IsDiscrete
                nyFreq = frequencyConversionFcn(pi/abs(this.Response.Model.Ts));
                set(this.NyquistLines(1),Value=nyFreq);
                set(this.NyquistLines(2),Value=-nyFreq);
                visibilityFlag = any(arrayfun(@(x) x.Visible,this.ResponsePatches),'all');
                set(this.NyquistLines,Visible=visibilityFlag);
            else
                set(this.NyquistLines,Visible=false);
            end
            if optionalInputs.UpdateArrows
                updateArrows(this);
            end
        end

        function updateResponseVisibility(this,rowVisible,columnVisible,arrayVisible)
            arguments
                this (1,1) controllib.chart.internal.view.wave.SectorBoundResponseView
                rowVisible (:,1) logical
                columnVisible (1,:) logical
                arrayVisible logical
            end
            updateResponseVisibility@controllib.chart.internal.view.wave.BaseResponseView(this,rowVisible,columnVisible,arrayVisible);
            for ka = 1:this.Response.NResponses
                isReal = this.Response.ResponseData.IsReal(ka);
                this.NegativeArrows(ka).Visible = arrayVisible(ka) & ~isReal;
                this.PositiveArrows(ka).Visible = arrayVisible(ka) & ~isReal;
            end
            visibilityFlag = any(arrayfun(@(x) x.Visible,this.ResponsePatches),'all');
            set(this.NyquistLines,Visible=visibilityFlag & this.Response.IsDiscrete);
        end
        
        function cbMagnitudeUnitChanged(this,conversionFcn)
            % Update response patches
            for k = 1:this.NPatches
                for ka = 1:this.Response.NResponses
                    this.ResponsePatches(k,1,ka).YData = conversionFcn(this.ResponsePatches(k,1,ka).YData);
                end
            end
        end

        function cbFrequencyUnitChanged(this,conversionFcn)
            % Update response patches
            for k = 1:this.NPatches
                for ka = 1:this.Response.NResponses
                    this.ResponsePatches(k,1,ka).XData = conversionFcn(this.ResponsePatches(k,1,ka).XData);
                end
            end
            for ii = 1:2
                this.NyquistLines(ii).Value = conversionFcn(this.NyquistLines(ii).Value);
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