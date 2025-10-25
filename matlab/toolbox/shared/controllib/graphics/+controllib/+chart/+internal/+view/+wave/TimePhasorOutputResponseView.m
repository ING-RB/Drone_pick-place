classdef TimePhasorOutputResponseView < controllib.chart.internal.view.wave.OutputResponseView & ...
        controllib.chart.internal.foundation.MixInTimeUnit
    % Class for managing lines and markers for a time based plot
    
    % Copyright 2021-2023 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        % Graphics objects
        ResponseLines
        ResponseLineArrows
        InitialValueMarker
        FinalValueMarker
        LegendLines
    end

    properties (SetAccess=immutable)
        IsDiscrete
        IsReal
        NArrows = 18
    end
    
    %% Constructor
    methods
        function this = TimePhasorOutputResponseView(response,optionalInputs)
            arguments
                response (1,1) controllib.chart.internal.foundation.BaseResponse ...
                    {mustBeA(response,'controllib.chart.internal.foundation.MixInInputOutputResponse')}
                optionalInputs.OutputVisible (:,1) logical = true(response.NOutputs,1);
                optionalInputs.ArrayVisible logical = response.ArrayVisible
            end
            this@controllib.chart.internal.foundation.MixInTimeUnit(response.ResponseData.TimeUnit);
            optionalInputs = namedargs2cell(optionalInputs);
            this@controllib.chart.internal.view.wave.OutputResponseView(response,optionalInputs{:});
            this.IsDiscrete = response.IsDiscrete;
            this.IsReal = response.IsReal;
            build(this);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function createResponseObjects(this)
            this.ResponseLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                1,this.Response.NResponses,Tag='TimeResponseLine');
            this.InitialValueMarker = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                1,this.Response.NResponses,Tag="InitialValueMarker");
            set(this.InitialValueMarker,Marker='none');
            this.FinalValueMarker = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                1,this.Response.NResponses,Tag="FinalValueMarker");
            set(this.FinalValueMarker,Marker='o')

            % Arrows
            for k = 1:this.NArrows
                arrows = createGraphicsObjects(this,"patch",this.Response.NRows,...
                    1,this.Response.NResponses,Tag='TimeResponseArrows');
                if k == 1
                    this.ResponseLineArrows = arrows;
                else
                    this.ResponseLineArrows = cat(4,this.ResponseLineArrows,arrows);
                end
            end
        end

        function createSupportingObjects(this)
            
        end

        function legendLines = createLegendObjects(this)
            legendLines = createGraphicsObjects(this,"line",1,...
                1,1,DisplayName=strrep(this.Response.Name,'_','\_'));
        end

        function responseObjects = getResponseObjects_(this,ko,~,ka)
            responseObjects = cat(3,this.ResponseLines(ko,1,ka),...
                this.InitialValueMarker(ko,1,ka),this.FinalValueMarker(ko,1,ka));
            for k = 1:this.NArrows
                responseObjects(:,:,k+2) = this.ResponseLineArrows(ko,1,ka,k);
            end
        end

        % function supportingObjects = getSupportingObjects_(this,ko,ki,ka)
        %     supportingObjects = this.SteadyStateYLines(ko,ki,ka);
        %     if ~this.Response.IsReal(ka)
        %         supportingObjects = [supportingObjects; this.ImaginarySteadyStateYLines(ko,ki,ka)];
        %     end
        % end

        function updateResponseData(this)
            for ko = 1:this.Response.NRows
                for ka = 1:this.Response.NResponses
                    % Get amplitude
                    [realAmplitude, imaginaryAmplitude] = getAmplitude(this.Response.ResponseData,{ko,1},ka);
                    time = getTime(this.Response.ResponseData,{ko,1},ka);
                    % Set data on real amplitude lines
                    this.ResponseLines(ko,1,ka).XData = realAmplitude;
                    this.ResponseLines(ko,1,ka).YData = imaginaryAmplitude;
                    this.ResponseLines(ko,1,ka).UserData.Time = time;
                    % Update Initial value marker
                    realInitialValue = realAmplitude(1);
                    imaginaryInitialValue = imaginaryAmplitude(1);
                    this.InitialValueMarker(ko,1,ka).XData = realInitialValue;
                    this.InitialValueMarker(ko,1,ka).YData = imaginaryInitialValue;
                    % Update final value marker
                    [realFinalValue,imaginaryFinalValue] = getFinalValue(this.Response.ResponseData,{ko,1},ka);
                    this.FinalValueMarker(ko,1,ka).XData = realFinalValue;
                    this.FinalValueMarker(ko,1,ka).YData = imaginaryFinalValue;
                end
            end

            % Update arrows if an existing response is updated, and not if
            % this response is being created for the first time (axes
            % information not available)
            if this.IsResponseViewValid
                updateMarkers(this);
            end
        end

        function createResponseDataTips_(this,ko,ka,nameDataTipRow,ioDataTipRow,customDataTipRows)
            % Time row
            realAmplitudeDataTipRow = dataTipTextRow(...
                getString(message('Controllib:plots:strReal')),'XData','%0.3g');

            % Amplitude row
            imaginaryAmplitudeDataTipRow = dataTipTextRow(...
                getString(message('Controllib:plots:strImaginary')),'YData','%0.3g');

            % Time row
            timeRow = dataTipTextRow(getString(message('Controllib:plots:strTime')) + ...
                " (" + this.TimeUnitLabel + ")",...
                @(x,y) this.getTimeValue(this.ResponseLines(ko,ki,ka),x,y),'%0.3g')

            % Add to DataTipTemplate
            this.ResponseLines(ko,1,ka).DataTipTemplate.DataTipRows = ...
                [nameDataTipRow; ioDataTipRow; ...
                realAmplitudeDataTipRow; imaginaryAmplitudeDataTipRow; timeRow; customDataTipRows(:)];
        end

        function updateResponseVisibility(this,rowVisible,~,arrayVisible)
            for ko = 1:this.Response.NRows
                for ka = 1:this.Response.NResponses
                    visibilityFlag = arrayVisible(ka) & rowVisible(ko);
                    this.ResponseLines(ko,1,ka).Visible = visibilityFlag;
                    this.InitialValueMarker(ko,1,ka).Visible = visibilityFlag;
                    this.FinalValueMarker(ko,1,ka).Visible = visibilityFlag;
                    set(this.ResponseLineArrows(ko,1,ka,:),Visible=visibilityFlag);
                end
            end
            set(getLegendObjects(this),Visible = any(rowVisible) && any(arrayVisible,'all'));
        end

        function createCharacteristics(this,data)
            c = controllib.chart.internal.view.characteristic.BaseCharacteristicView.empty;
            % PeakResponse
            if isprop(data,"PeakResponse") && ~isempty(data.PeakResponse)
                c = controllib.chart.internal.view.characteristic.TimePhasorOutputPeakResponseView(this,data.PeakResponse);
            end
            % TransientTime
            % if isprop(data,"TransientTime") && ~isempty(data.TransientTime)
            %     c = [c; controllib.chart.internal.view.characteristic.TimePhasorInputOutputTransientTimeView(this,data.TransientTime)];
            % end
            this.Characteristics = c;
        end

        function cbTimeUnitChanged(this,conversionFcn)
            % Update data tip
            if this.IsResponseDataTipsCreated
                for ko = 1:this.Response.NRows
                    for ka = 1:this.Response.NResponses
                        this.replaceDataTipRowLabel(this.ResponseLines(ko,1,ka),...
                            getString(message('Controllib:plots:strTime')),...
                            getString(message('Controllib:plots:strTime')) + ...
                            " (" + this.TimeUnitLabel + ")");
                    end
                end
            end
        end

        function updateResponseStyle_(this,styleValue,ko,~,ka)
            this.InitialValueMarker(ko,1,ka).Marker = 's';
            this.FinalValueMarker(ko,1,ka).Marker = 'o';
            controllib.plot.internal.utils.setColorProperty([this.InitialValueMarker(ko,1,ka),...
                this.FinalValueMarker(ko,1,ka)],"MarkerFaceColor",styleValue.Color);
        end
    end

    methods
        function updateMarkers(this,optionalArguments)
            arguments
                this
                optionalArguments.AspectRatio = []
            end

            for ko = 1:this.Response.NRows
                for ka = 1:this.Response.NResponses
                    if ~this.Response.IsReal(ka)
                        % Get x/y data
                        responseLine = this.ResponseLines(ko,1,ka);
                        xData = responseLine.XData;
                        yData = responseLine.YData;
                        ax = responseLine.Parent;
                        % Get x/y range
                        if ~isempty(ax)
                            xRange = ax.XLim;
                            yRange = ax.YLim;
                        else
                            xRange = [min(xData), max(xData)];
                            yRange = [min(yData), max(yData)];
                        end
                        % Aspect ratio
                        if ~isempty(optionalArguments.AspectRatio)
                            aspectRatio = optionalArguments.AspectRatio;
                        elseif isempty(ax)
                            aspectRatio = [1 0.8];
                        else
                            aspectRatio = ax.PlotBoxAspectRatio;
                        end
                        % Get idx
                        n = length(xData);
                        idx = floor(linspace(n/20,9*n/10,this.NArrows-1));
                        idx(idx < 1 | idx==n) = [];
                        idx = [1 idx]; %#ok<AGROW>
                        idx = unique(idx);
                        for k = 1:length(idx)
                            hMarker = this.ResponseLineArrows(ko,1,ka,k);
                            x = xData(idx(k):idx(k)+1);
                            y = yData(idx(k):idx(k)+1);
                            if abs(xData(idx(k))-xData(end))>0.02 || abs(yData(idx(k))-yData(end))>0.02
                                controllib.chart.internal.utils.drawArrow(hMarker,x,y,0.5/150,...
                                    XRange=xRange,YRange=yRange,AspectRatio=aspectRatio);
                            else
                                hMarker.XData = NaN;
                                hMarker.YData = NaN;
                                hMarker.ZData = 1;
                            end
                        end
                    end
                end
            end
        end
    end

    %% Static sealed protected methods
    methods (Static,Sealed,Access=protected)
        function interpValue = getTimeValue(hLine,x,y)
            xData = hLine.XData;
            yData = hLine.YData;
            gains = hLine.UserData.Time;
            point = [x;y];
            ax = hLine.Parent;
            xlim = ax.XLim;
            ylim = ax.YLim;
            xScale = ax.XScale;
            yScale = ax.YScale;
            interpValue = controllib.chart.internal.view.wave.TimePhasorOutputResponseView.scaledProject2(...
                xData,yData,gains,point,xlim,ylim,xScale,yScale);
        end
    end

    methods (Hidden)
        function responseLines = qeGetResponseLines(this)
            responseLines = this.ResponseLines;
        end

        function responseLineArrows = qeGetResponseLineArrows(this)
            responseLineArrows = this.ResponseLineArrows;
        end

        function initialMarker = qeGetInitialValueMarker(this)
            initialMarker = this.InitialValueMarker;
        end
    end
end