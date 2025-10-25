classdef PassiveResponseView < controllib.chart.internal.view.wave.BaseResponseView & ...
        controllib.chart.internal.foundation.MixInFrequencyUnit & ...
        controllib.chart.internal.foundation.MixInMagnitudeUnit
    % SigmaResponseView     Manage response lines and characteristics of a singular value plot
    
    % Copyright 2023 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        ResponseLines
        PositiveArrows
        NegativeArrows
        NyquistLines
    end

    properties (SetAccess = {?controllib.chart.internal.view.wave.BaseResponseView,...
            ?controllib.chart.internal.view.axes.BaseAxesView})
        FrequencyScale = "log"
    end

    properties (SetAccess=immutable)
        NLines
    end

    %% Public methods
    methods
        function this = PassiveResponseView(response,optionalInputs)            
            arguments
                response (1,1) controllib.chart.response.PassiveResponse
                optionalInputs.ArrayVisible logical = response.ArrayVisible
            end
            this@controllib.chart.internal.foundation.MixInFrequencyUnit(response.FrequencyUnit);
            this@controllib.chart.internal.foundation.MixInMagnitudeUnit(response.IndexUnit);
            optionalInputs = namedargs2cell(optionalInputs);
            this@controllib.chart.internal.view.wave.BaseResponseView(response,optionalInputs{:});
            this.NLines = size(response.ResponseData.RelativeIndex{1},1);
            build(this);
        end
    end

    %% Public methods
    methods
        function updateArrows(this,optionalArguments)
            arguments
                this
                optionalArguments.AspectRatio = []
            end
            if ~this.Response.IsResponseValid
                return;
            end
            if this.FrequencyScale=="log"
                for k = 1:this.NLines
                    for ka = 1:this.Response.NResponses
                        if ~this.Response.ResponseData.IsReal(ka)
                            if ~isvalid(this.ResponseLines(k,1,ka))
                                continue;
                            end
                            xData = this.ResponseLines(k,1,ka).XData;
                            yData = this.ResponseLines(k,1,ka).YData;
                            ax = this.ResponseLines(k,1,ka).Parent;
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
                                xRange,yRange,(0.5+this.ResponseLines(k,1,ka).LineWidth)/150,...
                                optionalArguments.AspectRatio);
                            % Positive Arrow
                            this.localDrawArrow(this.PositiveArrows(k,1,ka),xData(ia2),yData(ia2),...
                                xRange,yRange,(0.5+this.ResponseLines(k,1,ka).LineWidth)/150,...
                                optionalArguments.AspectRatio);
                        end
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
                this (1,1) controllib.chart.internal.view.wave.PassiveResponseView
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
            % PeakResponse
            if isprop(data,"PassiveWorstIndexResponse") && ~isempty(data.PassiveWorstIndexResponse)
                c = controllib.chart.internal.view.characteristic.PassiveWorstIndexResponseView(this,data.PassiveWorstIndexResponse);
            end 
            this.Characteristics = c;                                  
        end

        function createResponseObjects(this)
            nLines = max(this.NLines,1);
            this.ResponseLines = createGraphicsObjects(this,"line",nLines,1,this.Response.NResponses,...
                Tag='PassiveResponseLine',DisplayName=strrep(this.Response.Name,'_','\_'));
            this.ResponseLines(1,1,1).LegendDisplay = 'on';
            this.PositiveArrows = createGraphicsObjects(this,"patch",nLines,1,this.Response.NResponses,...
                Tag='PassivePositiveArrow',HitTest='off',PickableParts='none');
            this.NegativeArrows = createGraphicsObjects(this,"patch",nLines,1,this.Response.NResponses,...
                Tag='PassiveNegativeArrow',HitTest='off',PickableParts='none');
        end

        function createSupportingObjects(this)
            this.NyquistLines = createGraphicsObjects(this,"constantLine",1,1,2,...
                Tag='PassiveNyquistLine',HitTest='off',PickableParts='none');
            set(this.NyquistLines,InterceptAxis='x',LineWidth=1.5);
            controllib.plot.internal.utils.setColorProperty(this.NyquistLines,...
                "Color","--mw-graphics-colorNeutral-line-primary");
        end

        function legendLines = createLegendObjects(this)
            nLines = max(this.NLines,1);
            legendLines = createGraphicsObjects(this,"line",nLines,1,this.Response.NResponses,...
                DisplayName=strrep(this.Response.Name,'_','\_'));
        end

        function responseObjects = getResponseObjects_(this,~,~,ka)
            lines = reshape(this.ResponseLines(:,1,ka),1,1,this.NLines);
            posArrows = reshape(this.PositiveArrows(:,1,ka),1,1,this.NLines);
            negArrows = reshape(this.NegativeArrows(:,1,ka),1,1,this.NLines);
            responseObjects = cat(3,lines,posArrows,negArrows);
        end

        function supportingObjects = getSupportingObjects_(this,~,~,~)
            supportingObjects = this.NyquistLines;
        end
        
        function updateResponseData(this,optionalInputs)
            arguments
                this (1,1) controllib.chart.internal.view.wave.PassiveResponseView
                optionalInputs.UpdateArrows (1,1) logical = true
            end
            frequencyConversionFcn = getFrequencyUnitConversionFcn(this,this.Response.FrequencyUnit,this.FrequencyUnit);
            magnitudeConversionFcn = getMagnitudeUnitConversionFcn(this,this.Response.IndexUnit,this.MagnitudeUnit);
            for k = 1:this.NLines
                for ka = 1:this.Response.NResponses
                    w = frequencyConversionFcn(this.Response.ResponseData.Frequency{ka});
                    ind = magnitudeConversionFcn(this.Response.ResponseData.RelativeIndex{ka}(k,:));
                    ixp = find(w>0);
                    ixn = find(w<0);
                    if this.Response.ResponseData.IsReal(ka)
                        w = [-flipud(w(ixp,:));w(ixp,:)];
                        ind = [fliplr(ind(:,ixp)) ind(:,ixp)];
                    else
                        w = [w(ixn,:);w(ixp,:)];
                        ind = [ind(:,ixn) ind(:,ixp)];
                    end
                    switch this.FrequencyScale
                        case "log"
                            if ~this.Response.ResponseData.IsReal(ka)
                                w = abs(w);
                                this.PositiveArrows(k,1,ka).Visible = this.ResponseLines(k,1,ka).Visible;
                                this.NegativeArrows(k,1,ka).Visible = this.ResponseLines(k,1,ka).Visible;
                            else
                                this.PositiveArrows(k,1,ka).Visible = false;
                                this.NegativeArrows(k,1,ka).Visible = false;
                            end
                        case "linear"
                            this.PositiveArrows(k,1,ka).Visible = false;
                            this.NegativeArrows(k,1,ka).Visible = false;
                    end
                    this.ResponseLines(k,1,ka).XData = w;
                    this.ResponseLines(k,1,ka).YData = ind;
                end
            end
            if this.Response.IsDiscrete
                nyFreq = frequencyConversionFcn(pi/abs(this.Response.Model.Ts));
                set(this.NyquistLines(1),Value=nyFreq);
                set(this.NyquistLines(2),Value=-nyFreq);
                visibilityFlag = any(arrayfun(@(x) x.Visible,this.ResponseLines),'all');
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
                this (1,1) controllib.chart.internal.view.wave.PassiveResponseView
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
            visibilityFlag = any(arrayfun(@(x) x.Visible,this.ResponseLines),'all');
            set(this.NyquistLines,Visible = visibilityFlag & this.Response.IsDiscrete);
        end

        function createResponseDataTips_(this,~,~,ka,nameDataTipRow,~,customDataTipRows)
            % Create data tip for all lines
            % Name row (pole markers)
            for k = 1:this.NLines
                frequencyRow = dataTipTextRow(...
                    getString(message('Controllib:plots:strFrequency')) + " (" + this.FrequencyUnitLabel + ")",...
                    'XData','%0.3g');
                magnitudeRow = dataTipTextRow(...
                    getString(message('Controllib:plots:strRelativeIndex')) + " (" + this.MagnitudeUnitLabel + ")",...
                    'YData','%0.3g');
                % Add to DataTipTemplate
                this.ResponseLines(k,1,ka).DataTipTemplate.DataTipRows = ...
                    [nameDataTipRow; frequencyRow; magnitudeRow; customDataTipRows(:)];
            end
        end

        function cbMagnitudeUnitChanged(this,conversionFcn)
            % Update response lines
            for k = 1:this.NLines
                for ka = 1:this.Response.NResponses
                    this.ResponseLines(k,1,ka).YData = conversionFcn(this.ResponseLines(k,1,ka).YData);
                end
            end
            % Update characteristic
            if ~isempty(this.Characteristics)
                this.Characteristics.MagnitudeUnit = this.MagnitudeUnit;
            end
            % Update datatip
            for k = 1:this.NLines
                for ka = 1:this.Response.NResponses
                    this.ResponseLines(k,1,ka).DataTipTemplate.DataTipRows(3).Label = ...
                        getString(message('Controllib:plots:strRelativeIndex')) + " (" + this.MagnitudeUnitLabel + ")";
                end
            end
        end

        function cbFrequencyUnitChanged(this,conversionFcn)
            % Update response
            for k = 1:this.NLines
                for ka = 1:this.Response.NResponses
                    this.ResponseLines(k,1,ka).XData = conversionFcn(this.ResponseLines(k,1,ka).XData);
                end
            end

            arrayfun(@(x) set(x,'Value',conversionFcn(x.Value)),this.NyquistLines);

            % Update characteristic
            if ~isempty(this.Characteristics)
                this.Characteristics.FrequencyUnit = this.FrequencyUnit;
            end
            % Update datatip
            for k = 1:this.NLines
                for ka = 1:this.Response.NResponses
                    this.ResponseLines(k,1,ka).DataTipTemplate.DataTipRows(2).Label = ...
                        getString(message('Controllib:plots:strFrequency')) + " (" + this.FrequencyUnitLabel + ")";
                end
            end
        end
    end

    %% Static sealed protected methods
    methods (Static, Sealed, Access=protected)
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