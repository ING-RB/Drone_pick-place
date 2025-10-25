classdef TimeOutputResponseView < controllib.chart.internal.view.wave.OutputResponseView & ...
        controllib.chart.internal.foundation.MixInTimeUnit
    % Class for managing lines and markers for a time based plot

    % Copyright 2023 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        ResponseLines
        ImaginaryResponseLines
        MagnitudeResponseLines
        ImaginaryMarkerPatch
        SteadyStateYLines
        ImaginarySteadyStateYLines
        ShowSteadyStateLine
    end

    properties (Dependent)
        ShowMagnitudeResponse
        ShowReal
        ShowImaginary
    end

    properties (Access = private)
        ShowMagnitudeResponse_I
        ShowReal_I
        ShowImaginary_I
    end

    properties (SetAccess=immutable)
        IsDiscrete
        IsReal
    end

    %% Constructor
    methods
        function this = TimeOutputResponseView(response,timeOptionalInputs,optionalInputs)
            arguments
                response (1,1) controllib.chart.internal.foundation.BaseResponse ...
                    {mustBeA(response,'controllib.chart.internal.foundation.MixInRowResponse')}
                timeOptionalInputs.ShowSteadyStateLine (1,1) logical = true
                timeOptionalInputs.ShowMagnitude (1,1) logical = false
                timeOptionalInputs.ShowReal (1,1) logical = true
                timeOptionalInputs.ShowImaginary (1,1) logical = true
                optionalInputs.OutputVisible (:,1) logical = true(response.NOutputs,1);
                optionalInputs.ArrayVisible logical = response.ArrayVisible
            end
            this@controllib.chart.internal.foundation.MixInTimeUnit(response.ResponseData.TimeUnit);
            optionalInputs = namedargs2cell(optionalInputs);
            this@controllib.chart.internal.view.wave.OutputResponseView(response,optionalInputs{:});
            this.ShowSteadyStateLine = timeOptionalInputs.ShowSteadyStateLine;
            this.ShowMagnitudeResponse_I = timeOptionalInputs.ShowMagnitude;
            this.ShowReal_I = timeOptionalInputs.ShowReal;
            this.ShowImaginary_I = timeOptionalInputs.ShowImaginary;
            this.IsDiscrete = response.IsDiscrete;
            this.IsReal = response.IsReal;
        end
    end

    %% set/get for dependent
    methods
        function ShowMagnitude = get.ShowMagnitudeResponse(this)
            ShowMagnitude = this.ShowMagnitudeResponse_I;
        end

        function set.ShowMagnitudeResponse(this,ShowMagnitudeResponseLine)
            this.ShowMagnitudeResponse_I = ShowMagnitudeResponseLine;
            updateVisibility(this);
        end

        function ShowReal = get.ShowReal(this)
            ShowReal = this.ShowReal_I;
        end

        function set.ShowReal(this,ShowReal)
            this.ShowReal_I = ShowReal;
            updateVisibility(this);
        end

        function ShowImaginary = get.ShowImaginary(this)
            ShowImaginary = this.ShowImaginary_I;
        end

        function set.ShowImaginary(this,ShowImaginary)
            this.ShowImaginary_I = ShowImaginary;
            updateVisibility(this);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function createResponseObjects(this)
            if this.Response.IsDiscrete
                lineType = "stair";
            else
                lineType = "line";
            end

            this.ResponseLines = createGraphicsObjects(this,lineType,this.Response.NOutputs,...
                1,this.Response.NResponses,Tag='TimeResponseLine');
            if any(~this.Response.IsReal)
                % Create lines for imaginary and magnitude, and patch/text
                % for markers
                this.ImaginaryResponseLines = createGraphicsObjects(this,lineType,this.Response.NOutputs,...
                    1,this.Response.NResponses,Tag='TimeImaginaryResponseLine');
                this.ImaginaryMarkerPatch = createGraphicsObjects(this,"patch",this.Response.NOutputs,...
                    1,this.Response.NResponses,Tag='TimeImaginaryMarkerPatch');
                this.MagnitudeResponseLines = createGraphicsObjects(this,lineType,this.Response.NOutputs,...
                    1,this.Response.NResponses,Tag='TimeMagnitudeResponseLine');
            end
        end

        function createSupportingObjects(this)
            % Steady state lines
            this.SteadyStateYLines = createSteadyStateLines(this,'TimeSteadyStateLine');
            this.ImaginarySteadyStateYLines = createSteadyStateLines(this,'TimeImaginarySteadyStateLine');
        end

        function legendLines = createLegendObjects(this)
            legendLines = createGraphicsObjects(this,"line",1,...
                1,1,DisplayName=strrep(this.Response.Name,'_','\_'));
        end

        function responseObjects = getResponseObjects_(this,ko,~,ka)
            responseObjects = this.ResponseLines(ko,1,ka);
            if ~this.Response.IsReal(ka)
                responseObjects(:,:,2) = this.ImaginaryResponseLines(ko,1,ka);
                responseObjects(:,:,3) = this.ImaginaryMarkerPatch(ko,1,ka);
                responseObjects(:,:,4) = this.MagnitudeResponseLines(ko,1,ka);
            end
        end

        function supportingLines = getSupportingObjects_(this,ko,~,ka)
            supportingLines = cat(3,this.SteadyStateYLines(ko,1,ka),...
                this.ImaginarySteadyStateYLines(ko,1,ka));
        end

        function updateResponseData(this)
            conversionFcn = getTimeUnitConversionFcn(this,this.Response.ResponseData.TimeUnit,this.TimeUnit);
            for ko = 1:this.Response.NOutputs
                for ka = 1:this.Response.NResponses
                    % Time data
                    time = getTime(this.Response.ResponseData,{ko,1},ka);
                    time = conversionFcn(time);
                    % Amplitude data
                    [realAmplitude,imaginaryAmplitude] = getAmplitude(this.Response.ResponseData,{ko,1},ka);
                    % Steady state data
                    [realSteadyStateValue,imaginarySteadyStateValue] = getFinalValue(this.Response.ResponseData,{ko},ka);

                    % Set on real response lines
                    this.ResponseLines(ko,1,ka).XData = time;
                    this.ResponseLines(ko,1,ka).YData = realAmplitude;
                    if ~this.Response.IsReal(ka)
                        % Set data on imaginary amplitude lines
                        this.ImaginaryResponseLines(ko,1,ka).XData = time;
                        this.ImaginaryResponseLines(ko,1,ka).YData = imaginaryAmplitude;
                        % Set data on magnitude response lines
                        this.MagnitudeResponseLines(ko,1,ka).XData = time;
                        this.MagnitudeResponseLines(ko,1,ka).YData = sqrt(realAmplitude.^2 + imaginaryAmplitude.^2);
                    elseif any(this.Response.IsReal)
                        % At least one response, but not ka-th, is
                        % complex. Set the corresponding graphics
                        % object data to NaN to make sure they don't
                        % show in plot.
                        this.ImaginaryResponseLines(ko,1,ka).XData = NaN;
                        this.ImaginaryResponseLines(ko,1,ka).YData = NaN;
                        this.ImaginaryMarkerPatch(ko,1,ka).XData = NaN;
                        this.ImaginaryMarkerPatch(ko,1,ka).YData = NaN;
                        this.ImaginaryMarkerPatch(ko,1,ka).YData = NaN;
                        this.MagnitudeResponseLines(ko,1,ka).XData = NaN;
                        this.MagnitudeResponseLines(ko,1,ka).YData = NaN;
                    end

                    % Set on real steady state lines
                    if ~isinf(realSteadyStateValue)
                        this.SteadyStateYLines(ko,1,ka).Value = realSteadyStateValue;
                    else
                        this.SteadyStateYLines(ko,1,ka).Value = NaN;
                    end

                    % Set on imaginary steady state lines
                    if ~isinf(imaginarySteadyStateValue)
                        this.ImaginarySteadyStateYLines(ko,1,ka).Value = imaginarySteadyStateValue;
                    else
                        this.ImaginarySteadyStateYLines(ko,1,ka).Value = NaN;
                    end

                    % Update arrows if an existing response is updated, and not if
                    % this response is being created for the first time (axes
                    % information not available)
                    if this.IsResponseViewValid
                        updateMarkers(this);
                    end
                end
            end
        end

        function createResponseDataTips_(this,ko,ka,nameDataTipRow,outputDataTipRow,customDataTipRows)
            % Time row
            timeDataTipRow = dataTipTextRow(...
                [getString(message('Controllib:plots:strTime')),' (',char(this.TimeUnitLabel),')'],...
                'XData','%0.3g');

            % Amplitude row
            if this.Response.IsReal(ka)
                amplitudeString = getString(message('Controllib:plots:strAmplitude'));
            else
                amplitudeString = [getString(message('Controllib:plots:strAmplitude')),...
                    ' (', getString(message('Controllib:plots:strReal')),')'];
            end
            amplitudeDataTipRow = dataTipTextRow(amplitudeString,'YData','%0.3g');

            % Add to DataTipTemplate
            this.ResponseLines(ko,1,ka).DataTipTemplate.DataTipRows = ...
                [nameDataTipRow; outputDataTipRow; ...
                timeDataTipRow; amplitudeDataTipRow; customDataTipRows(:)];

            if ~this.Response.IsReal(ka)
                amplitudeString = [getString(message('Controllib:plots:strAmplitude')),...
                    ' (', getString(message('Controllib:plots:strImaginary')),')'];
                amplitudeDataTipRow = dataTipTextRow(amplitudeString,'YData','%0.3g');
                this.ImaginaryResponseLines(ko,1,ka).DataTipTemplate.DataTipRows = ...
                    [nameDataTipRow; outputDataTipRow; ...
                    timeDataTipRow; amplitudeDataTipRow; customDataTipRows(:)];
            end
        end

        function updateResponseVisibility(this,outputVisible,~,arrayVisible)
            for ko = 1:this.Response.NOutputs
                for ka = 1:this.Response.NResponses
                    visibilityFlag = arrayVisible(ka) & outputVisible(ko);
                    
                    if this.Response.IsReal(ka)
                        this.ResponseLines(ko,1,ka).Visible = visibilityFlag;
                    elseif this.ShowReal
                        this.ResponseLines(ko,1,ka).Visible = visibilityFlag;
                    else
                        this.ResponseLines(ko,1,ka).Visible = 'off';
                    end
                    
                    % Set visibility of imaginary response line
                    if ~this.Response.IsReal(ka) && this.ShowImaginary
                        this.ImaginaryResponseLines(ko,1,ka).Visible = visibilityFlag;
                        this.ImaginaryMarkerPatch(ko,1,ka).Visible = visibilityFlag;
                    else
                        this.ImaginaryResponseLines(ko,1,ka).Visible = 'off';
                        this.ImaginaryMarkerPatch(ko,1,ka).Visible = 'off';
                    end

                    % Set visibility of magnitude response line
                    if ~this.Response.IsReal(ka) && this.ShowMagnitudeResponse
                        this.MagnitudeResponseLines(ko,1,ka).Visible = visibilityFlag;
                    else
                        this.MagnitudeResponseLines(ko,1,ka).Visible = 'off';
                    end

                    if isempty(this.Response.NominalIndex) || this.Response.NominalIndex == ka
                        this.SteadyStateYLines(ko,1,ka).Visible = visibilityFlag & this.ShowSteadyStateLine;
                        if ~this.Response.IsReal(ka)
                            this.ImaginarySteadyStateYLines(ko,1,ka).Visible = visibilityFlag & this.ShowSteadyStateLine;
                        end
                    else
                        this.SteadyStateYLines(ko,1,ka).Visible = false;
                        this.ImaginarySteadyStateYLines(ko,1,ka).Visible = false;
                    end
                end
            end
            set(getLegendObjects(this),Visible = any(outputVisible) && any(arrayVisible,'all'));
        end

        function cbTimeUnitChanged(this,conversionFcn)
            for ko = 1:this.Response.NOutputs
                for ka = 1:this.Response.NResponses
                    this.ResponseLines(ko,1,ka).XData = ...
                        conversionFcn(this.ResponseLines(ko,1,ka).XData);
                    if ~this.Response.IsReal(ka)
                        this.ImaginaryResponseLines(ko,1,ka).XData = ...
                            conversionFcn(this.ImaginaryResponseLines(ko,1,ka).XData);
                    end
                end
            end

            if this.IsResponseDataTipsCreated
                for ko = 1:this.Response.NOutputs
                    for ka = 1:this.Response.NResponses
                        this.replaceDataTipRowLabel(this.ResponseLines(ko,1,ka),...
                            getString(message('Controllib:plots:strTime')),...
                            getString(message('Controllib:plots:strTime')) + ...
                            " (" + this.TimeUnitLabel + ")");
                    end
                end
            end
        end

        function updateResponseStyle(this,style)
            updateResponseStyle@controllib.chart.internal.view.wave.BaseResponseView(this,style);
            if any(~this.Response.IsReal)
                controllib.plot.internal.utils.setColorProperty([this.ImaginaryMarkerPatch(:),...
                    this.ImaginaryMarkerPatch(:)],"FaceColor",style.Color);
            end
        end
    end

    methods (Access = private)
        function steadyStateLines = createSteadyStateLines(this,tag)
            arguments
                this
                tag
            end
            steadyStateLines = createGraphicsObjects(this,"constantLine",this.Response.NOutputs,...
                1,this.Response.NResponses,Tag=tag);
            set(steadyStateLines,'InterceptAxis','y');
            set(steadyStateLines,'LineStyle',':');
            controllib.plot.internal.utils.setColorProperty(steadyStateLines,...
                "Color","--mw-graphics-colorNeutral-line-primary");
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
                        % Do not draw markers if lines are not valid
                        if ~isvalid(this.ResponseLines(ko,1,ka)) || ~isvalid(this.ImaginaryResponseLines(ko,1,ka))
                            continue;
                        end

                        % Get real line data
                        realResponseLine = this.ResponseLines(ko,1,ka);
                        xDataReal = realResponseLine.XData;
                        yDataReal = realResponseLine.YData;
                        ax = realResponseLine.Parent;
                        if ~isempty(ax)
                            xRangeReal = ax.XLim;
                            yRangeReal = ax.YLim;
                        else
                            xRangeReal = [min(xDataReal) max(xDataReal)];
                            yRangeReal = [min(yDataReal) max(yDataReal)];
                        end

                        % Get imaginary line data
                        imaginaryResponseLine = this.ImaginaryResponseLines(ko,1,ka);
                        xDataImaginary = imaginaryResponseLine.XData;
                        yDataImaginary = imaginaryResponseLine.YData;
                        ax = imaginaryResponseLine.Parent;
                        if ~isempty(ax)
                            xRangeImaginary = ax.XLim;
                            yRangeIMaginary = ax.YLim;
                        else
                            xRangeImaginary = [min(xDataImaginary) max(xDataImaginary)];
                            yRangeIMaginary = [min(yDataImaginary) max(yDataImaginary)];
                        end

                        % Get time index for markers
                        idx = getIdxForLabel(xDataReal,xRangeReal,yDataReal,yDataImaginary);
                        if ~isempty(optionalArguments.AspectRatio)
                            aspectRatio = optionalArguments.AspectRatio;
                        elseif isempty(ax)
                            aspectRatio = [1 0.8];
                        else
                            aspectRatio = ax.PlotBoxAspectRatio;
                        end

                        % Update marker on imaginary line
                        x = xDataImaginary(idx:idx+1);
                        y = yDataImaginary(idx:idx+1);
                        controllib.chart.internal.utils.drawArrow(this.ImaginaryMarkerPatch(ko,1,ka),...
                            x,y,1/150,XRange=xRangeImaginary,YRange=yRangeIMaginary,AspectRatio=aspectRatio,...
                            Style="diamond");
                        this.ImaginaryMarkerPatch(ko,1,ka).ZData = ones(size(this.ImaginaryMarkerPatch(ko,1,ka).XData));
                        this.ImaginaryMarkerPatch(ko,1,ka).LineWidth = 1;
                    end
                end
            end
        end
    end
end

function idx = getIdxForLabel(t,tRange,y,y2)

idx0 = find(t>tRange(1),1,'first');
idx1 = find(t<tRange(2),1,'last');
n = idx1 - idx0 + 1;
nLower = floor(n/5) + idx0 - 1;
nUpper = floor(4*n/5) + idx0 - 1;

% val = arrayfun(@(k) min(abs((yForLabel(k)-yOther).^2 + (t(k)-t).^2)),...
%     nLower+1:nUpper);
val = y(nLower+1:nUpper);
val2 = y2(nLower+1:nUpper);

tDiff = diff(t(nLower+1:nUpper));
yDiffDiff = diff(diff(val))./(tDiff(2:end).^2);
yDiffDiff2 = diff(diff(val2))./(tDiff(2:end).^2);

val = val(3:end);
val2 = val2(3:end);
val(abs(yDiffDiff)>20 | abs(yDiffDiff2)>20) = NaN;
val2(abs(yDiffDiff)>20 | abs(yDiffDiff2)>20) = NaN;

[~,idx] = max(abs(val-val2));
idx = idx + nLower + 2;
end