classdef TimePhasorInputOutputResponseView < controllib.chart.internal.view.wave.BaseResponseView & ...
        controllib.chart.internal.foundation.MixInTimeUnit
    % Class for managing lines and markers for a time based plot
    
    % Copyright 2021-2023 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        % Graphics objects
        ResponseLines
        ResponseLineArrows
        InitialValueMarker
        LegendLines
    end

    properties (SetAccess=immutable)
        IsDiscrete
        IsReal
        NArrows = 18
    end
    
    %% Constructor
    methods
        function this = TimePhasorInputOutputResponseView(response,optionalInputs)
            arguments
                response (1,1) controllib.chart.internal.foundation.BaseResponse ...
                    {mustBeA(response,'controllib.chart.internal.foundation.MixInInputOutputResponse')}
                optionalInputs.ColumnVisible (1,:) logical = true(1,response.NColumns);
                optionalInputs.RowVisible (:,1) logical = true(response.NRows,1);
                optionalInputs.ArrayVisible logical = response.ArrayVisible
            end
            this@controllib.chart.internal.foundation.MixInTimeUnit(response.ResponseData.TimeUnit);
            optionalInputs.NRows = response.NRows;
            optionalInputs.NColumns = response.NColumns;
            optionalInputs = namedargs2cell(optionalInputs);
            this@controllib.chart.internal.view.wave.BaseResponseView(response,optionalInputs{:});
            this.IsDiscrete = response.IsDiscrete;
            this.IsReal = response.IsReal;
            build(this);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function createResponseObjects(this)
            this.ResponseLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='TimeResponseLine');
            this.InitialValueMarker = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag="InitialValueMarker");
            set(this.InitialValueMarker,Marker='s');

            % Arrows
            for k = 1:this.NArrows
                arrows = createGraphicsObjects(this,"patch",this.Response.NRows,...
                    this.Response.NColumns,this.Response.NResponses,HitTest='off',...
                    Tag='TimeResponseArrows');
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

        function responseObjects = getResponseObjects_(this,ko,ki,ka)
            responseObjects = cat(3,this.ResponseLines(ko,ki,ka),...
                this.InitialValueMarker(ko,ki,ka));
            for k = 1:this.NArrows
                responseObjects(:,:,k+2) = this.ResponseLineArrows(ko,ki,ka,k);
            end
        end

        % function supportingObjects = getSupportingObjects_(this,ko,ki,ka)
        %     supportingObjects = this.SteadyStateYLines(ko,ki,ka);
        %     if ~this.Response.IsReal(ka)
        %         supportingObjects = [supportingObjects; this.ImaginarySteadyStateYLines(ko,ki,ka)];
        %     end
        % end

        function updateResponseData(this)
            conversionFcn = getTimeUnitConversionFcn(this,this.Response.ResponseData.TimeUnit,this.TimeUnit);
            for ko = 1:this.Response.NRows
                for ki = 1:this.Response.NColumns
                    for ka = 1:this.Response.NResponses
                        time = getTime(this.Response.ResponseData,{ko,ki},ka);
                        time = conversionFcn(time);
                        % Get amplitude
                        [realAmplitude, imaginaryAmplitude] = getAmplitude(this.Response.ResponseData,{ko,ki},ka);
                        % Set data on real amplitude lines
                        this.ResponseLines(ko,ki,ka).XData = realAmplitude;
                        this.ResponseLines(ko,ki,ka).YData = imaginaryAmplitude;
                        this.ResponseLines(ko,ki,ka).UserData.Time = time;
                        % Update Initial value marker
                        realInitialValue = realAmplitude(1);
                        imaginaryInitialValue = imaginaryAmplitude(1);
                        this.InitialValueMarker(ko,ki,ka).XData = realInitialValue;
                        this.InitialValueMarker(ko,ki,ka).YData = imaginaryInitialValue;
                    end
                end
            end

            % Update arrows if an existing response is updated, and not if
            % this response is being created for the first time (axes
            % information not available)
            if this.IsResponseViewValid
                updateMarkers(this);
            end
        end

        function createResponseDataTips_(this,ko,ki,ka,nameDataTipRow,ioDataTipRow,customDataTipRows)
            % Time row
            realAmplitudeDataTipRow = dataTipTextRow(...
                getString(message('Controllib:plots:strReal')),'XData','%0.3g');

            % Amplitude row
            imaginaryAmplitudeDataTipRow = dataTipTextRow(...
                getString(message('Controllib:plots:strImaginary')),'YData','%0.3g');

            % Time row
            timeRow = dataTipTextRow(getString(message('Controllib:plots:strTime')) + ...
                " (" + this.TimeUnitLabel + ")",...
                @(x,y) this.getTimeValue(this.ResponseLines(ko,ki,ka),x,y),'%0.3g');

            % Add to DataTipTemplate
            this.ResponseLines(ko,ki,ka).DataTipTemplate.DataTipRows = ...
                [nameDataTipRow; ioDataTipRow; ...
                realAmplitudeDataTipRow; imaginaryAmplitudeDataTipRow; timeRow; customDataTipRows(:)];
        end

        function updateResponseVisibility(this,rowVisible,columnVisible,arrayVisible)
            for ko = 1:this.Response.NRows
                for ki = 1:this.Response.NColumns
                    for ka = 1:this.Response.NResponses
                        visibilityFlag = arrayVisible(ka) & rowVisible(ko) & columnVisible(ki);
                        this.ResponseLines(ko,ki,ka).Visible = visibilityFlag;
                        this.InitialValueMarker(ko,ki,ka).Visible = visibilityFlag;
                        set(this.ResponseLineArrows(ko,ki,ka,:),Visible=visibilityFlag);
                    end
                end
            end
            set(getLegendObjects(this),Visible = any(rowVisible) && any(columnVisible) && any(arrayVisible,'all'));
        end

        function createCharacteristics(this,data)
            c = controllib.chart.internal.view.characteristic.BaseCharacteristicView.empty;
            % PeakResponse
            if isprop(data,"PeakResponse") && ~isempty(data.PeakResponse)
                c = controllib.chart.internal.view.characteristic.TimePhasorInputOutputPeakResponseView(this,data.PeakResponse);
            end
            % RiseTime
            if isprop(data,"RiseTime") && ~isempty(data.RiseTime)
                c = [c; controllib.chart.internal.view.characteristic.TimePhasorInputOutputRiseTimeView(this,data.RiseTime)];
            end
            % SettlingTime
            if isprop(data,"SettlingTime") && ~isempty(data.SettlingTime)
                c = [c; controllib.chart.internal.view.characteristic.TimePhasorInputOutputSettlingTimeView(this,data.SettlingTime)];
            end
            % TransientTime
            if isprop(data,"TransientTime") && ~isempty(data.TransientTime)
                c = [c; controllib.chart.internal.view.characteristic.TimePhasorInputOutputTransientTimeView(this,data.TransientTime)];
            end
            % SteadyState
            if isprop(data,"SteadyState") && ~isempty(data.SteadyState)
                c = [c; controllib.chart.internal.view.characteristic.TimePhasorInputOutputSteadyStateView(this,data.SteadyState)];
            end
            % % ConfidenceRegion
            % if isprop(data,"ConfidenceRegion") && ~isempty(data.ConfidenceRegion)
            %     c = [c; controllib.chart.internal.view.characteristic.StepConfidenceRegionView(this,...
            %             data.ConfidenceRegion)];
            % end
            this.Characteristics = c;
        end

        function cbTimeUnitChanged(this,conversionFcn)
            % Update data tip
            if this.IsResponseDataTipsCreated
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        for ka = 1:this.Response.NResponses
                            this.replaceDataTipRowLabel(this.ResponseLines(ko,ki,ka),...
                                getString(message('Controllib:plots:strTime')),...
                                getString(message('Controllib:plots:strTime')) + ...
                                " (" + this.TimeUnitLabel + ")");
                        end
                    end
                end
            end
        end

        function updateResponseStyle_(this,styleValue,ko,ki,ka)
            this.InitialValueMarker(ko,ki,ka).Marker = 's';
            controllib.plot.internal.utils.setColorProperty(this.InitialValueMarker(ko,ki,ka),...
                "MarkerFaceColor",styleValue.Color);
        end
    end

    methods
        function updateMarkers(this,optionalArguments)
            arguments
                this
                optionalArguments.AspectRatio = []
            end

            for ko = 1:this.Response.NRows
                for ki = 1:this.Response.NColumns
                    for ka = 1:this.Response.NResponses
                        if ~this.Response.IsReal(ka)
                            % Get x/y data
                            responseLine = this.ResponseLines(ko,ki,ka);
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
                            idx = floor(n/20:n/20:9*n/10);
                            for k = 1:length(idx)
                                hMarker = this.ResponseLineArrows(ko,ki,ka,k);
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
            interpValue = controllib.chart.internal.view.wave.TimePhasorInputOutputResponseView.scaledProject2(...
                xData,yData,gains,point,xlim,ylim,xScale,yScale);
        end
    end
	
    %% Hidden methods
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