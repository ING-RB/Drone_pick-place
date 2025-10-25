classdef NyquistResponseView < controllib.chart.internal.view.wave.BaseResponseView & ...
        controllib.chart.internal.foundation.MixInFrequencyUnit
    % NyquistResponseView
    
    % Copyright 2022-2023 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        ResponseLines
        PositiveArrows
        NegativeArrows     

        ImaginaryAxes
        RealAxes
        CriticalPointMarkers
    end

    properties (SetAccess = {?controllib.chart.internal.view.axes.BaseAxesView,...
            ?controllib.chart.internal.view.wave.BaseResponseView})
        ShowFullContour
    end

    %% Constructor
    methods
        function this = NyquistResponseView(response,nyquistResponseOptions,optionalInputs)
            arguments
                response (1,1) controllib.chart.response.NyquistResponse
                nyquistResponseOptions.ShowFullContour (1,1) logical = true
                optionalInputs.ColumnVisible (1,:) logical = true(1,response.NColumns);
                optionalInputs.RowVisible (:,1) logical = true(response.NRows,1);
                optionalInputs.ArrayVisible logical = response.ArrayVisible
            end
            this@controllib.chart.internal.foundation.MixInFrequencyUnit(response.FrequencyUnit);
            optionalInputs.NRows = response.NRows;
            optionalInputs.NColumns = response.NColumns;
            optionalInputsCell = namedargs2cell(optionalInputs);
            this@controllib.chart.internal.view.wave.BaseResponseView(response,optionalInputsCell{:});

            this.ShowFullContour = nyquistResponseOptions.ShowFullContour;

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
            % Draw/update arrow
            for ka = 1:this.Response.NResponses
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        if ~isvalid(this.ResponseLines(ko,ki,ka))
                            continue;
                        end
                        xData = this.ResponseLines(ko,ki,ka).XData;
                        yData = this.ResponseLines(ko,ki,ka).YData;
                        ax = this.ResponseLines(ko,ki,ka).Parent;
                        if isempty(ax)
                            xRange = [min(xData) max(xData)];
                            yRange = [min(yData) max(yData)];
                        else
                            xRange = ax.XLim;
                            yRange = ax.YLim;
                        end
                        if this.ShowFullContour
                            idx = find(isnan(xData),1);
                            ip = 1:idx-1;
                            in = idx+1:length(xData);
                            % Positive Arrow
                            this.localPositionArrow(this.PositiveArrows(ko,ki,ka),xData(ip),yData(ip),...
                                xRange,yRange,(0.5+this.ResponseLines(ko,ki,ka).LineWidth)/150,...
                                optionalArguments.AspectRatio);
                            % Negative Arrow
                            this.localPositionArrow(this.NegativeArrows(ko,ki,ka),xData(in),yData(in),...
                                xRange,yRange,(0.5+this.ResponseLines(ko,ki,ka).LineWidth)/150,...
                                optionalArguments.AspectRatio);
                        else
                            this.localPositionArrow(this.PositiveArrows(ko,ki,ka),xData,yData,...
                                xRange,yRange,(0.5+this.ResponseLines(ko,ki,ka).LineWidth)/150,...
                                optionalArguments.AspectRatio);
                            set(this.NegativeArrows(ko,ki,ka),XData=NaN,YData=NaN);
                        end
                    end
                end
            end
        end
    end

    %% Get/Set
    methods
        % ShowFullContour
        function set.ShowFullContour(this,ShowFullContour)
            this.ShowFullContour = ShowFullContour;
            if ~isempty(this.ResponseLines) %#ok<MCSUP>
                updateResponseData(this);
            end
            if any(contains(this.CharacteristicTypes,"ConfidenceRegion"))
                updateCharacteristic(this,"ConfidenceRegion");
            end
        end
    end

    %% Protected methods
    methods (Access = protected)
        function createCharacteristics(this,data)
            c = controllib.chart.internal.view.characteristic.BaseCharacteristicView.empty;
            % Peak Response
            if isprop(data,"NyquistPeakResponse") && ~isempty(data.NyquistPeakResponse)
                c = controllib.chart.internal.view.characteristic.NyquistPeakResponseView(this,data.NyquistPeakResponse);
            end            
            % AllStabilityMargin
            if isprop(data,"AllStabilityMargin") && ~isempty(data.AllStabilityMargin)
                c = [c; controllib.chart.internal.view.characteristic.NyquistStabilityMarginView(this,...
                            data.AllStabilityMargin)];
            end
            % MinimumStabilityMargin
            if isprop(data,"MinimumStabilityMargin") && ~isempty(data.MinimumStabilityMargin)
                c = [c; controllib.chart.internal.view.characteristic.NyquistStabilityMarginView(this,...
                            data.MinimumStabilityMargin)];
            end
            % ConfidenceRegion
            if isprop(data,"ConfidenceRegion") && ~isempty(data.ConfidenceRegion)
                c = [c; controllib.chart.internal.view.characteristic.NyquistConfidenceRegionView(this,...
                        data.ConfidenceRegion)];
            end
            this.Characteristics = c;
        end

        function createResponseObjects(this)
            this.ResponseLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='NyquistResponseLine');
            this.PositiveArrows = createGraphicsObjects(this,"patch",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,...
                Tag='NyquistPositiveArrow',HitTest='off',PickableParts='none');
            this.NegativeArrows = createGraphicsObjects(this,"patch",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,...
                Tag='NyquistNegativeArrow',HitTest='off',PickableParts='none');
        end

        function createSupportingObjects(this)
            % Imaginary Axis
            this.ImaginaryAxes = createGraphicsObjects(this,"constantLine",this.Response.NRows,...
                this.Response.NColumns,1,HitTest="off",PickableParts="none",Tag='NyquistImaginaryAxisLine');
            set(this.ImaginaryAxes,'InterceptAxis','x');
            set(this.ImaginaryAxes,'Value',0);
            set(this.ImaginaryAxes,'LineStyle',':');
            controllib.plot.internal.utils.setColorProperty(this.ImaginaryAxes,...
                "Color","--mw-graphics-colorNeutral-line-primary");
            % Real Axis
            this.RealAxes = createGraphicsObjects(this,"constantLine",this.Response.NRows,...
                this.Response.NColumns,1,HitTest="off",PickableParts="none",Tag='NyquistRealAxisLine');
            set(this.RealAxes,'InterceptAxis','y');
            set(this.RealAxes,'Value',0);
            set(this.RealAxes,'LineStyle',':');
            controllib.plot.internal.utils.setColorProperty(this.RealAxes,...
                "Color","--mw-graphics-colorNeutral-line-primary");
            % Critical Points
            this.CriticalPointMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,1,HitTest="off",PickableParts="none",Tag='NyquistCriticalPointScatter');
            set(this.CriticalPointMarkers,LineWidth=1.5,Marker='+',SizeData=100,XData=-1,YData=0);
            controllib.plot.internal.utils.setColorProperty(this.CriticalPointMarkers,...
                "MarkerEdgeColor","--mw-graphics-colorOrder-10-primary");
        end

        function legendLines = createLegendObjects(this)
            legendLines = createGraphicsObjects(this,"line",1,...
                1,1,Tag='NyquistLegendLines',DisplayName=strrep(this.Response.Name,'_','\_'));
        end

        function responseObjects = getResponseObjects_(this,ko,ki,ka)
            responseObjects = cat(3,this.ResponseLines(ko,ki,ka),this.PositiveArrows(ko,ki,ka),this.NegativeArrows(ko,ki,ka));
        end

        function supportingObjects = getSupportingObjects_(this,ko,ki,~)
            supportingObjects = cat(3,this.ImaginaryAxes(ko,ki),this.RealAxes(ko,ki),this.CriticalPointMarkers(ko,ki));
        end

        function updateResponseData(this)
            frequencyConversionFcn = getFrequencyUnitConversionFcn(this,this.Response.FrequencyUnit,this.FrequencyUnit);
            for ka = 1:this.Response.NResponses
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        f = this.Response.ResponseData.PositiveFrequency{ka}(:);
                        h = this.Response.ResponseData.PositiveFrequencyResponse{ka}(:,ko,ki);
                        h = h(:);
                        if this.Response.ResponseData.IsReal(ka)
                            if this.ShowFullContour
                                f = [this.Response.ResponseData.NegativeFrequency{ka}(:); NaN; this.Response.ResponseData.PositiveFrequency{ka}(:)];                                
                                cNaN = complex(NaN,NaN);
                                h = cat(1,this.Response.ResponseData.NegativeFrequencyResponse{ka}(:,ko,ki),cNaN,...
                                            this.Response.ResponseData.PositiveFrequencyResponse{ka}(:,ko,ki));
                            end
                        else
                            in = find(f<=0);
                            ip = find(f>=0);
                            if this.ShowFullContour
                                % Insert NaN separator to handle possible singularity at w=0
                                f = [f(in,:) ; NaN ; f(ip,:)];
                                cNaN = complex(NaN,NaN);
                                h = cat(1,h(in),cNaN,h(ip));
                            else
                                % Show only w>=0
                                f = f(ip,:);
                                h = h(ip);
                            end
                        end
                        f = frequencyConversionFcn(f);
                        
                        % Update response line
                        this.ResponseLines(ko,ki,ka).XData = real(h);
                        this.ResponseLines(ko,ki,ka).YData = imag(h);
                        this.ResponseLines(ko,ki,ka).UserData.Frequency = f;
                    end
                end
            end
            updateArrows(this);
        end

        function createResponseDataTips_(this,ko,ki,ka,nameDataTipRow,ioDataTipRow,customDataTipRows)
            % Real row
            realDataTipRow = dataTipTextRow(getString(message('Controllib:plots:strReal')),'XData','%0.3g');
            % Imaginary row
            imaginaryDataTipRow = dataTipTextRow(getString(message('Controllib:plots:strImaginary')),'YData','%0.3g');
            % Frequency row
            frequencyRow = dataTipTextRow(getString(message('Controllib:plots:strFrequency')) + ...
                " (" + this.FrequencyUnitLabel + ")",...
                @(x,y) this.getFrequencyValue(this.ResponseLines(ko,ki,ka),x,y),'%0.3g');
            
            % Add to DataTipTemplate
            this.ResponseLines(ko,ki,ka).DataTipTemplate.DataTipRows = ...
                [nameDataTipRow; ioDataTipRow; realDataTipRow; imaginaryDataTipRow; ...
                frequencyRow; customDataTipRows(:)];
        end

        function cbFrequencyUnitChanged(this,conversionFcn)
            for ka = 1:this.Response.NResponses
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        this.ResponseLines(ko,ki,ka).UserData.Frequency = ...
                            conversionFcn(this.ResponseLines(ko,ki,ka).UserData.Frequency);
                        if this.IsResponseDataTipsCreated
                            this.replaceDataTipRowLabel(this.ResponseLines(ko,ki,ka),getString(message('Controllib:plots:strFrequency')),...
                                getString(message('Controllib:plots:strFrequency')) + " (" + this.FrequencyUnitLabel + ")");
                        end
                    end
                end                
            end            
            % Set FrequencyUnit on relevant characteristics
            for k = 1:length(this.Characteristics)
                if isa(this.Characteristics(k),'controllib.chart.internal.foundation.MixInFrequencyUnit')
                    this.Characteristics(k).FrequencyUnit = this.FrequencyUnit;
                end
            end
        end
    end

    %% Static sealed protected methods
    methods (Sealed, Static, Access=protected)
        function localPositionArrow(harrow,X,Y,Xlim,Ylim,RAS,aspectRatio)
            % Find longest visible portion of curve, put arrow halfway along arc
            inScope = find(X>=Xlim(1) & X<=Xlim(2) & Y>=Ylim(1) & Y<=Ylim(2));
            delta = diff(inScope,[],2);
            if any(delta==1)
                is = [0 find(delta>1) numel(inScope)];
                narc = numel(is)-1;
                L = zeros(narc,1);
                im = zeros(narc,1);
                for ct=1:narc
                    iarc = inScope(is(ct)+1:is(ct+1));
                    % Compute arc length and index of midpoint
                    n = numel(X(iarc));
                    if n<2
                        L(ct) = 0;  rim = 1;
                    else
                        cL = [0 cumsum(sqrt(diff(X(iarc)).^2+diff(Y(iarc)).^2))];
                        L(ct) = cL(n);
                        rim = min(find(cL<=L/2,1,'last'),n-1);
                    end
                    im(ct) = iarc(rim);
                end
                [Lmax,imax] = max(L);
                if Lmax>0
                    % Found suitable arc
                    ix = im(imax);  ix = [ix ix+1];
                    % Take into account how big the Nyquist plot is relative to axis frame
                    Xvis = X(inScope);
                    Yvis = Y(inScope);
                    RPS = max((max(Xvis)-min(Xvis))/(Xlim(2)-Xlim(1)),...
                        (max(Yvis)-min(Yvis))/(Ylim(2)-Ylim(1)));
                    if ~isempty(harrow.Parent)
                        controllib.chart.internal.utils.drawArrow(harrow,X(ix),Y(ix),sqrt(RPS)*RAS,...
                            Axes=harrow.Parent,AspectRatio=aspectRatio);
                    else
                        controllib.chart.internal.utils.drawArrow(harrow,X(ix),Y(ix),sqrt(RPS)*RAS,...
                            XRange=Xlim,YRange=Ylim,AspectRatio=[1 0.8]);
                    end

                end
            end
        end

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
            interpValue = controllib.chart.internal.view.wave.NyquistResponseView.scaledProject2(...
                xData,yData,gains,point,xlim,ylim,xScale,yScale);
        end
    end
end
