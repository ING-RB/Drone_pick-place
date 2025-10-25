classdef RootLocusResponseView < controllib.chart.internal.view.wave.BaseResponseView & ...
        controllib.chart.internal.foundation.MixInTimeUnit & ...
        controllib.chart.internal.foundation.MixInFrequencyUnit
    % Class for managing lines and markers for a time based plot

    % Copyright 2021-2023 The MathWorks, Inc.

    %% Protected properties
    properties (SetAccess = protected)
        PoleMarkers
        ZeroMarkers
        LocusLines

        RealAxis
        ImaginaryAxis
        UnitCircle
    end

    properties (Access = private)
        BranchSemanticColorList = ["--mw-graphics-colorOrder-1-primary",...
            "--mw-graphics-colorOrder-5-primary",...
            "--mw-graphics-colorOrder-10-primary",...
            "--mw-graphics-colorOrder-6-primary",...
            "--mw-graphics-colorOrder-7-primary",...
            "--mw-graphics-colorOrder-3-primary",...
            "--mw-graphics-colorNeutral-line-primary"];
    end

    properties (SetAccess=immutable)
        NLines
    end

    %% Public methods
    methods
        function this = RootLocusResponseView(response,optionalInputs)
            arguments
                response (1,1) controllib.chart.response.RootLocusResponse
                optionalInputs.ArrayVisible logical = response.ArrayVisible
            end
            this@controllib.chart.internal.foundation.MixInTimeUnit(response.TimeUnit);
            this@controllib.chart.internal.foundation.MixInFrequencyUnit(response.FrequencyUnit);
            optionalInputs = namedargs2cell(optionalInputs);
            this@controllib.chart.internal.view.wave.BaseResponseView(response,optionalInputs{:});
            this.NLines = size(this.Response.ResponseData.Roots{1},2);
            build(this);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function createResponseObjects(this)
            this.PoleMarkers = createGraphicsObjects(this,"scatter",1,1,this.Response.NResponses,...
                Tag='RootLocusPoleScatter');
            this.disableDataTipInteraction(this.PoleMarkers);
            set(this.PoleMarkers,'Marker','x');

            this.ZeroMarkers = createGraphicsObjects(this,"scatter",1,1,this.Response.NResponses,...
                Tag='RootLocusZeroScatter');
            this.disableDataTipInteraction(this.ZeroMarkers);
            set(this.ZeroMarkers,'Marker','o');

            this.LocusLines = createGraphicsObjects(this,"line",this.NLines,1,this.Response.NResponses,...
                Tag='RootLocusLocusLines');
        end

        function createSupportingObjects(this)
            % Imaginary Axis
            this.ImaginaryAxis = createGraphicsObjects(this,"constantLine",1,1,1,...
                HitTest="off",PickableParts="none",Tag='RootLocusImaginaryAxisLine');
            this.ImaginaryAxis.InterceptAxis = 'x';
            this.ImaginaryAxis.Value = 0;
            this.ImaginaryAxis.LineStyle = ':';
            controllib.plot.internal.utils.setColorProperty(this.ImaginaryAxis,...
                "Color","--mw-graphics-colorNeutral-line-primary");
            % Real Axis
            this.RealAxis = createGraphicsObjects(this,"constantLine",1,1,1,...
                HitTest="off",PickableParts="none",Tag='RootLocusRealAxisLine');
            this.RealAxis.InterceptAxis = 'y';
            this.RealAxis.Value = 0;
            this.RealAxis.LineStyle = ':';
            controllib.plot.internal.utils.setColorProperty(this.RealAxis,...
                "Color","--mw-graphics-colorNeutral-line-primary");
            % Unit Circle
            this.UnitCircle = createGraphicsObjects(this,"rectangle",1,1,1,...
                HitTest="off",PickableParts="none",Tag='RootLocusUnitCircle');
            this.UnitCircle.Position = [-1 -1 2 2];
            this.UnitCircle.Curvature = [1 1];
            this.UnitCircle.LineStyle = ':';
            controllib.plot.internal.utils.setColorProperty(this.UnitCircle,...
                "EdgeColor","--mw-graphics-colorNeutral-line-primary");
        end

        function legendLine = createLegendObjects(this)
            legendLine = createGraphicsObjects(this,"line",1,1,1,...
                DisplayName=strrep(this.Response.Name,'_','\_'));
        end

        function responseObjects = getResponseObjects_(this,~,~,ka)
            lines = reshape(this.LocusLines(:,1,ka),1,1,this.NLines);
            responseObjects = cat(3,this.PoleMarkers(ka),this.ZeroMarkers(ka),lines);
        end

        function supportingObjects = getSupportingObjects_(this,~,~,~)
            supportingObjects = cat(3,this.ImaginaryAxis,this.RealAxis,this.UnitCircle);
        end

        function updateResponseData(this)
            conversionFcn = getTimeUnitConversionFcn(this,this.TimeUnit,this.Response.TimeUnit);
            for ka = 1:this.Response.NResponses
                this.PoleMarkers(ka).XData = 1./conversionFcn(1./real(this.Response.ResponseData.SystemPoles{ka}));
                this.PoleMarkers(ka).YData = 1./conversionFcn(1./imag(this.Response.ResponseData.SystemPoles{ka}));

                this.ZeroMarkers(ka).XData = 1./conversionFcn(1./real(this.Response.ResponseData.SystemZeros{ka}));
                this.ZeroMarkers(ka).YData = 1./conversionFcn(1./imag(this.Response.ResponseData.SystemZeros{ka}));

                for k = 1:this.NLines
                    this.LocusLines(k,1,ka).XData = 1./conversionFcn(1./real(this.Response.ResponseData.Roots{ka}(:,k)));
                    this.LocusLines(k,1,ka).YData = 1./conversionFcn(1./imag(this.Response.ResponseData.Roots{ka}(:,k)));
                    this.LocusLines(k,1,ka).UserData.SystemGains = this.Response.ResponseData.SystemGains{ka}(:,k)';
                end
            end
            % Show/hide unit circle
            this.UnitCircle.Visible = this.Response.IsDiscrete;
        end

        function createResponseDataTips_(this,~,~,ka,nameDataTipRow,~,customDataTipRows)
            % Create data tip for all lines
            for k = 1:this.NLines
                locusLines = this.LocusLines(k,1,ka);

                % Gain Row
                gainRow = dataTipTextRow(getString(message('Controllib:plots:strGain')),...
                    @(x,y) this.getGainValue(locusLines,x,y),'%0.3g');               
                % Pole Row
                poleRow = dataTipTextRow(getString(message('Controllib:plots:strPole')),...
                    @(x,y) this.getPZString(x,y));
                % Damping row
                dampingRow = dataTipTextRow(getString(message('Controllib:plots:strDamping')),...
                    @(x,y) this.getDampingValue(x,y,this.Response.ResponseData.Ts),'%0.3g');
                % Frequency row
                frequencyRow = dataTipTextRow(getString(message('Controllib:plots:strFrequency')) + ...
                    " (" + this.FrequencyUnit + ")",...
                    @(x,y) this.getFrequencyValue(x,y,this.Response.ResponseData.Ts,...
                    this.TimeUnit,this.FrequencyUnit),'%0.3g');
                % Overshoot row
                overshootRow = dataTipTextRow(getString(message('Controllib:plots:strOvershoot')) + " (%)",...
                    @(x,y) this.getOvershootValue(x,y,this.Response.ResponseData.Ts),'%0.3g');

                this.LocusLines(k,1,ka).DataTipTemplate.DataTipRows = ...
                    [nameDataTipRow;gainRow;poleRow;dampingRow;overshootRow;frequencyRow;customDataTipRows(:)];
            end
        end

        function updateResponseStyle_(this,~,~,~,ka)
            this.PoleMarkers(ka).Marker = 'x';
            this.ZeroMarkers(ka).Marker = 'o';
            if this.Response.NResponses==1 && this.Response.Style.ColorMode == "auto"
                nBranchColors = length(this.BranchSemanticColorList);
                for k = 1:this.NLines
                    controllib.plot.internal.utils.setColorProperty(...
                        this.LocusLines(k,1,ka),"Color",this.BranchSemanticColorList{mod(k-1,nBranchColors)+1});
                end
            end
        end

        function cbTimeUnitChanged(this,conversionFcn)
            for ka = 1:this.Response.NResponses
                % Pole markers
                this.PoleMarkers(ka).XData = 1./(conversionFcn(1./this.PoleMarkers(ka).XData));
                this.PoleMarkers(ka).YData = 1./(conversionFcn(1./this.PoleMarkers(ka).YData));

                % Zero markers
                this.ZeroMarkers(ka).XData = 1./(conversionFcn(1./this.ZeroMarkers(ka).XData));
                this.ZeroMarkers(ka).YData = 1./(conversionFcn(1./this.ZeroMarkers(ka).YData));

                for k = 1:this.NLines
                    this.LocusLines(k,1,ka).XData = 1./(conversionFcn(1./this.LocusLines(k,1,ka).XData));
                    this.LocusLines(k,1,ka).YData = 1./(conversionFcn(1./this.LocusLines(k,1,ka).YData));
                end
            end        
            % Set TimeUnit on relevant characteristics
            for k = 1:length(this.Characteristics)
                if isa(this.Characteristics(k),'controllib.chart.internal.foundation.MixInTimeUnit')
                    this.Characteristics(k).TimeUnit = this.TimeUnit;
                end
            end
        end

        function cbFrequencyUnitChanged(this,~)
            for k = 1:this.NLines
                for ka = 1:this.Response.NResponses
                    this.LocusLines(k,1,ka).DataTipTemplate.DataTipRows(6).Label = getString(message('Controllib:plots:strFrequency')) + ...
                        " (" + this.FrequencyUnit + ")";
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
    methods (Static,Sealed,Access=protected)
        function interpValue = getGainValue(hLine,x,y)
            xData = hLine.XData;
            yData = hLine.YData;
            gains = hLine.UserData.SystemGains;
            point = [x;y];
            ax = hLine.Parent;
            xlim = ax.XLim;
            ylim = ax.YLim;
            xScale = ax.XScale;
            yScale = ax.YScale;
            interpValue = controllib.chart.internal.view.wave.RootLocusResponseView.scaledProject2(...
                xData,yData,gains,point,xlim,ylim,xScale,yScale);
        end

        function zeta = getDampingValue(x,y,Ts)
            if isempty(Ts)
                Ts = 1;
            end
            [~,zeta] = damp(x + 1i*y,abs(Ts));
        end

        function wn = getFrequencyValue(x,y,Ts,timeUnit,freqUnit)
            if isempty(Ts)
                Ts = 1;
            end
            timeConversionFcn = controllib.chart.internal.utils.getTimeUnitConversionFcn(timeUnit,"seconds");
            x = 1/timeConversionFcn(1/x);
            y = 1/timeConversionFcn(1/y);
            [wn,~] = damp(x + 1i*y,abs(Ts));

            frequencyConversionFcn = controllib.chart.internal.utils.getFrequencyUnitConversionFcn("rad/s",freqUnit);
            wn = frequencyConversionFcn(wn);
        end

        function ppo = getOvershootValue(x,y,Ts)
            if isempty(Ts)
                Ts = 1;
            end
            [~,zeta] = damp(x + 1i*y,abs(Ts));
            ppo = exp(-pi*zeta./sqrt((1-zeta).*(1+zeta))); % equiv to exp(-z*pi/sqrt(1-z^2))
            ppo = round(1e6*ppo)/1e4; % round off small values
            ppo(abs(zeta)==1) = 0;
        end
		
        function poleLabel = getPZString(realPart,imagPart)
            if realPart == 0 && imagPart == 0
                poleLabel = '0';
            elseif imagPart == 0
                poleLabel = sprintf('%0.3g',realPart);
            else
                if imagPart > 0
                    poleLabel = [sprintf('%0.3g',realPart) ' + ' sprintf('%0.3g',imagPart) 'i'];
                else
                    poleLabel = [sprintf('%0.3g',realPart) ' - ' sprintf('%0.3g',abs(imagPart)) 'i'];
                end
            end
        end
    end
end