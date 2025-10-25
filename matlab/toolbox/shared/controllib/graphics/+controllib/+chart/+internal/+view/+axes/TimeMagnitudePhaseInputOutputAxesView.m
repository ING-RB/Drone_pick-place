classdef TimeMagnitudePhaseInputOutputAxesView < controllib.chart.internal.view.axes.RowColumnAxesView & ...
        controllib.chart.internal.foundation.MixInTimeUnit & ...
        controllib.chart.internal.view.axes.MixInInputOutputAxesViewLabels
    % TimeView

    % Copyright 2021-2022 The MathWorks, Inc.

    properties (Access = private)
        XLabelWithoutUnits = ""
    end

    %% Constructor
    methods
        function this = TimeMagnitudePhaseInputOutputAxesView(chart,varargin)
            arguments
                chart (1,1) controllib.chart.internal.foundation.AbstractPlot
            end

            arguments (Repeating)
                varargin
            end
            this@controllib.chart.internal.foundation.MixInTimeUnit(chart.TimeUnit);
            this@controllib.chart.internal.view.axes.RowColumnAxesView(chart,varargin{:});
            build(this);
        end
    end

    %% Public methods
    methods
        function updateResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.RowColumnAxesView
                response (1,1)  controllib.chart.internal.foundation.BaseResponse ...
                    {controllib.chart.internal.view.axes.TimeRowColumnAxesView.mustBeRowColumnResponse(response)}
            end
            idx = find(arrayfun(@(x) x.Response.Tag == response.Tag,this.ResponseViews),1);
            responseView = this.ResponseViews(idx);
            hasDifferentCharacteristics = ~isempty(setdiff(...
                union(responseView.CharacteristicTypes,response.CharacteristicTypes),...
                intersect(responseView.CharacteristicTypes,response.CharacteristicTypes)));
            isOldResponseReal = all(responseView.IsReal);
            isNewResponseReal = all(response.IsReal);
            if responseView.Response.NResponses ~= response.NResponses ||...
                    responseView.Response.NRows ~= response.NRows ||...
                    responseView.Response.NColumns ~= response.NColumns ||...
                    ~isequal(responseView.PlotColumnIdx,response.ResponseData.PlotInputIdx) || ...
                    ~isequal(responseView.PlotRowIdx,response.ResponseData.PlotOutputIdx) || ...
                    responseView.IsDiscrete ~= response.IsDiscrete ||...
                    hasDifferentCharacteristics || ...
                    isOldResponseReal ~= isNewResponseReal
                delete(responseView);
                this.ResponseViews = this.ResponseViews(isvalid(this.ResponseViews));
                responseView = createResponseView(this,response);
                responseView.ColumnNames = this.ColumnNames;
                responseView.RowNames = this.RowNames;
                createResponseDataTips(responseView);
                this.ResponseViews = [this.ResponseViews(1:idx-1); responseView; this.ResponseViews(idx:end)];
                parentResponseViews(this);
                for ii = 1:length(responseView.CharacteristicTypes)
                    charType = responseView.CharacteristicTypes(ii);
                    updateCharacteristic(responseView,charType);
                    if isfield(this.CharacteristicsVisibility,charType)
                        setCharacteristicVisible(responseView,charType,this.CharacteristicsVisibility.(charType));
                    end
                end
                postParentResponseView(this,responseView);
            else
                update(responseView);
            end
        end

        function unparentResponseViews(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
            end

            unparentResponseViews@controllib.chart.internal.view.axes.BaseAxesView(this);
            % This unparents all the graphic objects that the ResponseView
            % manages
            for k = 1:length(this.ResponseViews)
                set(this.ResponseViews(k).PhaseResponseLines,Parent=[]);
                set(this.ResponseViews(k).PhaseMarkerPatch,Parent=[]);
            end
        end
    end

    %% Protected methods
    methods (Access = protected)
        function responseView = createResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.RowColumnAxesView
                response (1,1) controllib.chart.internal.foundation.ModelResponse
            end
            responseView = controllib.chart.internal.view.wave.TimeMagnitudePhaseInputOutputResponseView(response,...
                ColumnVisible=this.ColumnVisible(1:response.NColumns),...
                RowVisible=this.RowVisible(1:response.NRows));
            responseView.TimeUnit = this.TimeUnit;
        end

        function [timeFocus,magnitudeFocus] = updateFocus_(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.RowColumnAxesView
                responses (:,1) controllib.chart.internal.foundation.BaseResponse ...
                    {controllib.chart.internal.view.axes.TimeRowColumnAxesView.mustBeRowColumnResponse(responses)}
            end
            % Compute focus
            [timeFocus,magnitudeFocus] = computeFocus(this,responses);
        end

        function cbTimeUnitChanged(this,conversionFcn)
            arguments
                this (1,1) controllib.chart.internal.view.axes.RowColumnAxesView
                conversionFcn (1,1) function_handle
            end
            % Change TimeUnit on each response
            for n = 1:length(this.ResponseViews)
                this.ResponseViews(n).TimeUnit = this.TimeUnit;
            end

            % Convert Limits
            for ii = 1:numel(this.AxesGrid.XLimitsFocus)
                this.AxesGrid.XLimitsFocus{ii} = conversionFcn(this.AxesGrid.XLimitsFocus{ii});
            end

            for ii = 1:numel(this.AxesGrid.XLimits)
                if strcmp(this.AxesGrid.XLimitsMode{ii},'manual')
                    this.AxesGrid.XLimits{ii} = conversionFcn(this.AxesGrid.XLimits{ii});
                end
            end

            % Modify Label
            setXLabelString(this,this.XLabelWithoutUnits);

            update(this.AxesGrid);
        end

        function postParentResponseView(this,responseView)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeMagnitudePhaseInputOutputAxesView
                responseView (1,1) controllib.chart.internal.view.wave.TimeMagnitudePhaseInputOutputResponseView
            end
            updateFocus(this);

            % Right YRuler should align with PhaseResponseLines
            ax = getAxes(this);
            for k = 1:numel(ax)
                yyaxis(ax(k),'right');
            end

            % Unparent and parent all phase response lines
            % Also store ylim to set on the axes later on
            % yLimForPhaseLines = cell();
            for k = 1:length(this.ResponseViews)
                rv = this.ResponseViews(k);
                for ko = 1:rv.Response.NRows
                    for ki = 1:rv.Response.NColumns
                        for ka = 1:rv.Response.NResponses
                            phaseResponseLine = rv.PhaseResponseLines(ko,ki,ka);
                            magnitudeResponseLine = getResponseObjects(rv,ko,ki,ka);
                            parentAxes = magnitudeResponseLine{1}.Parent;
                            phaseResponseLine.Parent = parentAxes;
                            rv.PhaseMarkerPatch(ko,ki,ka).Parent = parentAxes;
                        end
                    end
                end
            end

            disableListeners(this.AxesGrid);
            for kr = 1:size(ax,1)
                yLimits = localGetSharedYLimitsOfLinesInAxes(ax(kr,:));
                set(ax(kr,:),YLim=yLimits);
            end
            enableListeners(this.AxesGrid);

            if ~responseView.Response.IsReal
                ax = getAxes(this);
                aspectRatio = ax(1).PlotBoxAspectRatio_I(1:2);
                updateMarkers(responseView,AspectRatio=aspectRatio);
            end

            % Set active ruler to left
            for k = 1:numel(ax)
                yyaxis(ax(k),'left');
            end

            set(ax,ColorOrder=cell2mat(this.Chart.StyleManager.ColorOrder));
        end

        function postBuild(this)
            ax = getAxes(this);
            for kr = 1:size(ax,1)
                for kc = 1:size(ax,2)
                    % Create and additional y ruler on the right with same
                    % color as left ruler
                    yyaxis(ax(kr,kc),'right');
                    ax(kr,kc).YAxis(1).Color = this.Style.Axes.RulerColor;
                    ax(kr,kc).YAxis(2).Color = this.Style.Axes.RulerColor;
                    if kc ~= size(ax,2)
                        ax(kr,kc).YAxis(2).TickLabels = {};
                    end
                    % Let active ruler be the one on right
                    yyaxis(ax(kr,kc),'left');

                    if kc == size(ax,2)
                        ax(kr,kc).YAxis(2).Label.String = ...
                            [char(9670),'  ',getString(message('Controllib:plots:strPhase')),...
                            ' (',getString(message('Controllib:gui:strDeg')),') '];
                    end
                end
            end
        end

        function XLabel = getXLabelString(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeMagnitudePhaseInputOutputAxesView
            end
            XLabel = this.XLabelWithoutUnits;
        end

        function setXLabelString(this,XLabel)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeMagnitudePhaseInputOutputAxesView
                XLabel (1,1) string
            end
            this.XLabelWithoutUnits = XLabel;
            this.AxesGrid.XLabel = this.XLabelWithoutUnits + " (" + this.TimeUnitLabel + ")";
        end

        function [timeFocus, amplitudeFocus] = computeFocus(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeMagnitudePhaseInputOutputAxesView
                responses (:,1) controllib.chart.internal.foundation.BaseResponse
            end
            timeFocus = repmat({[NaN NaN]},this.NRows,this.NColumns);
            amplitudeFocus = repmat({[NaN NaN]},this.NRows,this.NColumns);
            if ~isempty(responses)
                data = [responses.ResponseData];
                [timeFocus_, amplitudeFocus_, timeUnit] = getCommonFocusForMultipleData(data,...
                    false,false,{responses.ArrayVisible},ShowMagnitude=true,ShowReal=false,...
                    ShowImaginary=false);
                timeFocus(1:size(timeFocus_,1),1:size(timeFocus_,2)) = timeFocus_;
                amplitudeFocus(1:size(amplitudeFocus_,1),1:size(amplitudeFocus_,2)) = amplitudeFocus_;
                timeConversionFcn = getTimeUnitConversionFcn(this,timeUnit,this.TimeUnit);
                for ko = 1:this.NRows
                    for ki = 1:this.NColumns
                        timeFocus{ko,ki} = timeConversionFcn(timeFocus{ko,ki});
                    end
                end
            end
        end
    end
end

function yLimits = localGetSharedYLimitsOfLinesInAxes(ax)
arguments
    ax (1,:)
end

yRange = [Inf, -Inf];

for kax = 1:size(ax,2)
    hChildren = ax(kax).Children;
    for kChild = 1:length(hChildren)
        child = hChildren(kChild);
        if strcmp(child.Type,'line')
            yRange(1) = min(yRange(1),min(child.YData));
            yRange(2) = max(yRange(2),max(child.YData));
        end
    end
end

yLimits = controllib.chart.internal.layout.LimitManager.getAutoAdjustedLimits(yRange);
end

