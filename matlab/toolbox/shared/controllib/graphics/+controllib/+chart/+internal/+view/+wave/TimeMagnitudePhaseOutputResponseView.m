classdef TimeMagnitudePhaseOutputResponseView < controllib.chart.internal.view.wave.OutputResponseView & ...
        controllib.chart.internal.foundation.MixInTimeUnit
    % Class for managing lines and markers for a time based plot

    % Copyright 2021-2023 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        % Graphics objects
        MagnitudeResponseLines
        PhaseResponseLines
        ResponseLineArrows
        LegendLines

        PhaseMarkerPatch
    end

    properties (SetAccess=immutable)
        IsDiscrete
        IsReal
        NArrows = 18
    end

    %% Constructor
    methods
        function this = TimeMagnitudePhaseOutputResponseView(response,optionalInputs)
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
            this.MagnitudeResponseLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                1,this.Response.NResponses,Tag='TimeResponseLine');
            this.PhaseResponseLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                1,this.Response.NResponses,Tag='TimeResponseLine');
            this.PhaseMarkerPatch = createGraphicsObjects(this,"patch",this.Response.NRows,...
                1,this.Response.NResponses,Tag='TimeImaginaryMarkerPatch',...
                HitTest='off');
        end

        function createSupportingObjects(this)

        end

        function legendLines = createLegendObjects(this)
            legendLines = createGraphicsObjects(this,"line",1,...
                1,1,DisplayName=strrep(this.Response.Name,'_','\_'));
        end

        function responseObjects = getResponseObjects_(this,ko,~,ka)
            responseObjects = this.MagnitudeResponseLines(ko,1,ka);
            % responseObjects = cat(3,this.MagnitudeResponseLines(ko,ki,ka),...
            %     this.PhaseResponseLines(ko,ki,ka));
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
                for ka = 1:this.Response.NResponses
                    time = getTime(this.Response.ResponseData,{ko,1},ka);
                    time = conversionFcn(time);
                    % Get amplitude
                    [realAmplitude, imaginaryAmplitude] = getAmplitude(this.Response.ResponseData,{ko,1},ka);
                    z = complex(realAmplitude,imaginaryAmplitude);
                    % Set data on magnitude lines
                    this.MagnitudeResponseLines(ko,1,ka).XData = time;
                    this.MagnitudeResponseLines(ko,1,ka).YData = abs(z);
                    % Set data on phase lines
                    this.PhaseResponseLines(ko,1,ka).XData = time;
                    this.PhaseResponseLines(ko,1,ka).YData = rad2deg(phase(z));
                    this.PhaseResponseLines(ko,1,ka).YData(1) = NaN;
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
            timeDataTipRow = dataTipTextRow(...
                [getString(message('Controllib:plots:strTime')),' (',char(this.TimeUnitLabel),')'],...
                'XData','%0.3g');

            % Amplitude row
            amplitudeDataTipRow = dataTipTextRow(...
                getString(message('Controllib:plots:strAmplitude')),'YData','%0.3g');

            % Add to DataTipTemplate
            this.MagnitudeResponseLines(ko,1,ka).DataTipTemplate.DataTipRows = ...
                [nameDataTipRow; ioDataTipRow; ...
                timeDataTipRow; amplitudeDataTipRow; customDataTipRows(:)];
        end

        function updateResponseVisibility(this,rowVisible,~,arrayVisible)
            for ko = 1:this.Response.NRows
                for ka = 1:this.Response.NResponses
                    visibilityFlag = arrayVisible(ka) & rowVisible(ko);
                    this.MagnitudeResponseLines(ko,1,ka).Visible = visibilityFlag;
                    this.PhaseResponseLines(ko,1,ka).Visible = visibilityFlag;
                    this.PhaseMarkerPatch(ko,1,ka).Visible = visibilityFlag;
                end
            end
            set(getLegendObjects(this),Visible = any(rowVisible) && any(arrayVisible,'all'));
        end

        function createCharacteristics(this,data)
            c = controllib.chart.internal.view.characteristic.BaseCharacteristicView.empty;
            % PeakResponse
            if isprop(data,"PeakResponse") && ~isempty(data.PeakResponse)
                c = controllib.chart.internal.view.characteristic.TimeMagnitudeOutputPeakResponseView(this,data.PeakResponse);
            end
            this.Characteristics = c;
        end

        function cbTimeUnitChanged(this,conversionFcn)
            for ko = 1:this.Response.NRows
                for ka = 1:this.Response.NResponses
                    this.MagnitudeResponseLines(ko,1,ka).XData = ...
                        conversionFcn(this.MagnitudeResponseLines(ko,1,ka).XData);
                    this.PhaseResponseLines(ko,1,ka).XData = ...
                        conversionFcn(this.PhaseResponseLines(ko,1,ka).XData);
                end
            end

            % Update data tip
            if this.IsResponseDataTipsCreated
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        for ka = 1:this.Response.NResponses
                            this.replaceDataTipRowLabel(this.MagnitudeResponseLines(ko,ki,ka),...
                                getString(message('Controllib:plots:strTime')),...
                                getString(message('Controllib:plots:strTime')) + ...
                                " (" + this.TimeUnitLabel + ")");
                        end
                    end
                end
            end

            for k = 1:length(this.Characteristics)
                if isa(this.Characteristics(k),'controllib.chart.internal.foundation.MixInTimeUnit')
                    this.Characteristics(k).TimeUnit = this.TimeUnit;
                end
            end
        end

        function updateResponseStyle_(this,styleValue,ko,~,ka)
            controllib.plot.internal.utils.setColorProperty(...
                this.PhaseResponseLines(ko,1,ka),"Color",styleValue.Color);
            set(this.PhaseResponseLines(ko,1,ka),LineStyle=styleValue.LineStyle);
            set(this.PhaseResponseLines(ko,1,ka),Marker=styleValue.MarkerStyle);
            set(this.PhaseResponseLines(ko,1,ka),LineWidth=styleValue.LineWidth);
            set(this.PhaseResponseLines(ko,1,ka),MarkerSize=styleValue.MarkerSize);
            controllib.plot.internal.utils.setColorProperty(this.PhaseMarkerPatch(:),...
                ["FaceColor","EdgeColor"],styleValue.Color);
        end
    end

    methods
        function updateMarkers(this,optionalArguments)
            arguments
                this
                optionalArguments.AspectRatio = []
            end

            if isvalid(this.Response.ResponseData)
                for ko = 1:this.Response.NRows
                    for ka = 1:this.Response.NResponses
                        if ~this.Response.IsReal(ka)
                            % Do not draw markers if lines are not valid
                            if ~isvalid(this.MagnitudeResponseLines(ko,1,ka)) || ~isvalid(this.PhaseResponseLines(ko,1,ka))
                                continue;
                            end

                            % Get imaginary line data
                            phaseResponseLine = this.PhaseResponseLines(ko,1,ka);
                            timePhase = phaseResponseLine.XData;
                            phase = phaseResponseLine.YData;
                            ax = phaseResponseLine.Parent;
                            if ~isempty(ax)
                                tPhaseRange = ax.XLim;
                                phaseRange = ax.YLim;
                            else
                                tPhaseRange = [min(timePhase) max(timePhase)];
                                phaseRange = [min(phase) max(phase)];
                            end

                            % Get time index for markers
                            n = length(timePhase);
                            idx = floor(n/2);
                            if ~isempty(optionalArguments.AspectRatio)
                                aspectRatio = optionalArguments.AspectRatio;
                            elseif isempty(ax)
                                aspectRatio = [1 0.8];
                            else
                                aspectRatio = ax.PlotBoxAspectRatio;
                            end

                            % Update marker on imaginary line
                            x = timePhase(idx:idx+1);
                            y = phase(idx:idx+1);
                            controllib.chart.internal.utils.drawArrow(this.PhaseMarkerPatch(ko,1,ka),...
                                x,y,1/150,XRange=tPhaseRange,YRange=phaseRange,AspectRatio=aspectRatio,...
                                Style="diamond");
                            this.PhaseMarkerPatch(ko,1,ka).ZData = ones(size(this.PhaseMarkerPatch(ko,1,ka).XData));
                            this.PhaseMarkerPatch(ko,1,ka).LineWidth = 1;
                        end
                    end
                end
            end
        end
    end

    %% Hidden methods
    methods (Hidden)
        function magnitudeResponseLines = qeGetMagnitudeResponseLines(this)
            magnitudeResponseLines = this.MagnitudeResponseLines;
        end

        function phaseResponseLines = qeGetPhaseResponseLines(this)
            phaseResponseLines = this.PhaseResponseLines;
        end

        function phaseMarkerPatch = qeGetPhaseMarkerPatch(this)
            phaseMarkerPatch = this.PhaseMarkerPatch;
        end
    end
end