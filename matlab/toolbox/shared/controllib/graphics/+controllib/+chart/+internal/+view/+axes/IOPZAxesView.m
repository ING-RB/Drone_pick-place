classdef IOPZAxesView < controllib.chart.internal.view.axes.RowColumnAxesView & ...
        controllib.chart.internal.view.axes.MixInInputOutputAxesViewLabels & ...
        controllib.chart.internal.foundation.MixInTimeUnit & ...
        controllib.chart.internal.foundation.MixInFrequencyUnit
    % IOPZView

    % Copyright 2021-2022 The MathWorks, Inc.

    %% Properties
    properties (AbortSet, SetObservable)
        GridType (1,1) string = "default"
        GridOptions (1,1) struct = gridopts('pzmap')
    end

    properties (Access = protected)
        XLabelWithoutUnits = ""
        YLabelWithoutUnits = ""
        GridLines
        GridLineLabels
    end

    %% Constructor
    methods
        function this = IOPZAxesView(chart)
            arguments
                chart (1,1) controllib.chart.IOPZPlot
            end
            this@controllib.chart.internal.foundation.MixInTimeUnit(chart.TimeUnit);
            this@controllib.chart.internal.foundation.MixInFrequencyUnit(chart.FrequencyUnit);
            this@controllib.chart.internal.view.axes.RowColumnAxesView(chart);
            this.GridType = this.Chart.AxesStyle.GridType;
            this.GridOptions.TimeUnits = char(this.TimeUnit);
            this.GridOptions.FrequencyUnits = char(this.FrequencyUnit);

            build(this);
        end
    end

    %% Public methods
    methods
        function responseViews = addResponseView(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.IOPZAxesView
                responses (:,1) controllib.chart.response.IOPZResponse
            end
            responseViews = addResponseView@controllib.chart.internal.view.axes.RowColumnAxesView(this,responses);
            updateGrid(this);
        end

        function updateResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.IOPZAxesView
                response (1,1) controllib.chart.response.IOPZResponse
            end
            updateResponseView@controllib.chart.internal.view.axes.RowColumnAxesView(this,response)
            updateGrid(this);
        end

        function deleteResponseView(this,responseView)
            arguments
                this (1,1) controllib.chart.internal.view.axes.RowColumnAxesView
                responseView (1,1) controllib.chart.internal.view.wave.IOPZResponseView
            end
            deleteResponseView@controllib.chart.internal.view.axes.RowColumnAxesView(this,responseView);
            updateGrid(this);
        end
    end

    %% Get/Set
    methods
        function set.GridType(this,GridType)
            arguments
                this (1,1) controllib.chart.internal.view.axes.IOPZAxesView
                GridType (1,1) string {mustBeMember(GridType,["default","s-plane","z-plane"])}
            end
            this.GridType = GridType;
            if ~isempty(this.AxesGrid) && isvalid(this.AxesGrid)
                updateGrid(this);
            end
        end
    end

    %% Protected methods
    methods (Access = protected)
        function responseView = createResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.IOPZAxesView
                response (1,1) controllib.chart.response.IOPZResponse
            end
            % Create IOPZResponse based on system and InputVisible, OutputVisible
            responseView = controllib.chart.internal.view.wave.IOPZResponseView(response,...
                ColumnVisible=this.ColumnVisible(1:response.NColumns),...
                RowVisible=this.RowVisible(1:response.NRows));
            % Set TimeUnit of response based on View
            responseView.TimeUnit = this.TimeUnit;
        end

        function [realAxisFocus, imaginaryAxisFocus] = updateFocus_(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.IOPZAxesView
                responses (:,1) controllib.chart.response.IOPZResponse
            end
            % Compute focus
            [realAxisFocus, imaginaryAxisFocus] = computeFocus(this,responses);
        end

        function cbTimeUnitChanged(this,conversionFcn)
            arguments
                this (1,1) controllib.chart.internal.view.axes.IOPZAxesView
                conversionFcn (1,1) function_handle
            end
            % Change TimeUnit on each response
            for n = 1:length(this.ResponseViews)
                this.ResponseViews(n).TimeUnit = this.TimeUnit;
            end

            % Convert Focus
            for ii = 1:numel(this.AxesGrid.XLimitsFocus)
                this.AxesGrid.XLimitsFocus{ii} = 1./conversionFcn(1./this.AxesGrid.XLimitsFocus{ii});
                this.AxesGrid.YLimitsFocus{ii} = 1./conversionFcn(1./this.AxesGrid.YLimitsFocus{ii});
            end

            for ii = 1:numel(this.AxesGrid.XLimits)
                if strcmp(this.AxesGrid.XLimitsMode{ii},'manual')
                    this.AxesGrid.XLimits{ii} = 1./conversionFcn(1./this.AxesGrid.XLimits{ii});
                end
            end

            for ii = 1:numel(this.AxesGrid.YLimits)
                if strcmp(this.AxesGrid.YLimitsMode{ii},'manual')
                    this.AxesGrid.YLimits{ii} = 1./conversionFcn(1./this.AxesGrid.YLimits{ii});
                end
            end

            update(this.AxesGrid);

            % Modify Label
            setXLabelString(this,this.XLabelWithoutUnits);
            setYLabelString(this,this.YLabelWithoutUnits);

            this.GridOptions.TimeUnits = char(this.TimeUnit);
            updateGrid(this);
        end

        function cbFrequencyUnitChanged(this,~)
            arguments
                this (1,1) controllib.chart.internal.view.axes.IOPZAxesView
                ~
            end
            % Change FrequencyUnit on each response
            for k = 1:length(this.ResponseViews)
                this.ResponseViews(k).FrequencyUnit = this.FrequencyUnit;
            end

            this.GridOptions.FrequencyUnits = char(this.FrequencyUnit);
            updateGrid(this);
        end

        function XLabel = getXLabelString(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.IOPZAxesView
            end
            XLabel = this.XLabelWithoutUnits;
        end

        function setXLabelString(this,XLabel)
            arguments
                this (1,1) controllib.chart.internal.view.axes.IOPZAxesView
                XLabel (1,1) string
            end
            this.XLabelWithoutUnits = XLabel;
            % Add units to xlabel
            this.AxesGrid.XLabel = this.XLabelWithoutUnits + " (" + this.TimeUnitLabel + "^{-1}" + ")";
        end

        function YLabel = getYLabelString(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.IOPZAxesView
            end
            YLabel = this.YLabelWithoutUnits;
        end

        function setYLabelString(this,YLabel)
            arguments
                this (1,1) controllib.chart.internal.view.axes.IOPZAxesView
                YLabel (1,1) string
            end
            this.YLabelWithoutUnits = YLabel;
            % Add units to ylabel
            this.AxesGrid.YLabel = this.YLabelWithoutUnits + " (" + this.TimeUnitLabel + "^{-1}" + ")";
        end

        function cbChartAxesStyleChanged(this,ed)
            switch ed.PropertyChanged
                case "GridType"
                    this.GridType = this.Chart.AxesStyle.GridType;
                    refreshGrid(this);
                case "GridFrequencySpec"
                    this.GridOptions.Frequency = this.Chart.AxesStyle.GridFrequencySpec;
                    refreshGrid(this);
                case "GridDampingSpec"
                    this.GridOptions.Damping = this.Chart.AxesStyle.GridDampingSpec;
                    refreshGrid(this);
                case "GridSampleTime"
                    this.GridOptions.SampleTime = this.Chart.AxesStyle.GridSampleTime;
                    refreshGrid(this);
                case "GridLabelType"
                    this.GridOptions.GridLabelType = this.Chart.AxesStyle.GridLabelType;
                    refreshGrid(this);
                otherwise
                    cbChartAxesStyleChanged@controllib.chart.internal.view.axes.BaseAxesView(this,ed);
            end
        end

        function updateGrid_(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.IOPZAxesView
            end
            delete(this.GridLines);
            delete(this.GridLineLabels);
            if this.Chart.AxesStyle.GridVisible
                isDiscreteResponse = arrayfun(@(x) x.Response.IsDiscrete,this.ResponseViews);
                opts = this.GridOptions;
                if isempty(opts.Damping)
                    opts.Damping = NaN;
                end
                if isempty(opts.Frequency)
                    opts.Frequency = NaN;
                end
                if strcmp(this.GridType,"z-plane") || ...
                        (strcmp(this.GridType,"default") && ~isempty(this.ResponseViews) && all(isDiscreteResponse))
                    if opts.SampleTime == -1
                        Ts = zeros(size(this.ResponseViews));
                        for ii = 1:length(this.ResponseViews)
                            if isa(this.ResponseViews(ii),'controllib.chart.internal.view.wave.PZBoundResponseView')
                                Ts(ii) = this.ResponseViews(ii).Response.Ts;
                            else
                                Ts(ii) = this.ResponseViews(ii).Response.SourceData.Model.Ts;
                            end
                        end
                        if all(Ts==Ts(1)) && Ts(1) ~= 0
                            opts.SampleTime = Ts(1);
                        end
                    end
                    ax = getAxes(this);
                    GL = cell(size(ax));
                    GLL = cell(size(ax));
                    for ii = 1:numel(ax)
                        [GL{ii},GLL{ii}] = zpchart(ax(ii),opts);
                    end
                    this.GridLines = vertcat(GL{:});
                    this.GridLineLabels = vertcat(GLL{:});
                    isCustomGridUsed = true;
                elseif strcmp(this.GridType,"s-plane") || ...
                        (strcmp(this.GridType,"default") && ~isempty(this.ResponseViews) && ~any(isDiscreteResponse))
                    ax = getAxes(this);
                    GL = cell(size(ax));
                    GLL = cell(size(ax));
                    for ii = 1:numel(ax)
                        [GL{ii},GLL{ii}] = spchart(ax(ii),opts);
                    end
                    this.GridLines = vertcat(GL{:});
                    this.GridLineLabels = vertcat(GLL{:});
                    isCustomGridUsed = true;
                else
                    isCustomGridUsed = false;
                end

                if isCustomGridUsed
                    this.GridLines = handle(this.GridLines);
                    this.GridLineLabels = handle(this.GridLineLabels);

                    % Set Color
                    updateCustomGridColor(this);

                    % Set PickableParts to 'none' to avoid datatips
                    set(this.GridLines,Serializable='off',LineWidth=this.Style.Axes.GridLineWidth,...
                        LineStyle=this.Style.Axes.GridLineStyle);
                    set(this.GridLineLabels,Serializable='off',...
                        Visible=this.Chart.AxesStyle.GridLabelsVisible);

                    this.Style.Axes.HasCustomGrid = true;
                else
                    this.Style.Axes.HasCustomGrid = false;
                end
            else
                this.Style.Axes.HasCustomGrid = false;
            end
        end

        function updateCustomGridColor(this)
            if ~isempty(this.GridLines) && all(isvalid(this.GridLines))
                rects = false(size(this.GridLines));
                for ii = 1:numel(this.GridLines)
                    rects(ii) = isa(this.GridLines(ii),'matlab.graphics.primitive.Rectangle');
                end
                lines = this.GridLines(~rects);
                rects = this.GridLines(rects);
                if strcmp(this.Style.Axes.GridColorMode,"auto")
                    controllib.plot.internal.utils.setColorProperty(lines,...
                        "Color","--mw-graphics-borderColor-axes-tertiary");
                    controllib.plot.internal.utils.setColorProperty(rects,...
                        "EdgeColor","--mw-graphics-borderColor-axes-tertiary");
                    controllib.plot.internal.utils.setColorProperty(this.GridLineLabels,...
                        "Color","--mw-graphics-borderColor-axes-tertiary");
                else
                    controllib.plot.internal.utils.setColorProperty(lines,...
                        "Color","--mw-graphics-borderColor-axes-tertiary");
                    controllib.plot.internal.utils.setColorProperty(rects,...
                        "EdgeColor","--mw-graphics-borderColor-axes-tertiary");
                    controllib.plot.internal.utils.setColorProperty(this.GridLineLabels,...
                        "Color",this.Style.Axes.GridColor);
                end
            end
        end

        function [realAxisFocus, imaginaryAxisFocus] = computeFocus(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.IOPZAxesView
                responses (:,1) controllib.chart.response.IOPZResponse
            end
            realAxisFocus = repmat({[NaN NaN]},this.NRows,this.NColumns);
            imaginaryAxisFocus = repmat({[NaN NaN]},this.NRows,this.NColumns);
            if ~isempty(responses)
                data = [responses.ResponseData];
                crVisible =  isfield(this.CharacteristicsVisibility,'ConfidenceRegion') && this.CharacteristicsVisibility.ConfidenceRegion;
                [realAxisFocus_, imaginaryAxisFocus_, timeUnit] = getCommonFocusForMultipleData(data,crVisible,{responses.ArrayVisible});
                timeConversionFcn = getTimeUnitConversionFcn(this,timeUnit,this.TimeUnit);
                for ko = 1:size(realAxisFocus_,1)
                    for ki = 1:size(realAxisFocus_,2)
                        realAxisFocus_{ko,ki} = timeConversionFcn(realAxisFocus_{ko,ki});
                        imaginaryAxisFocus_{ko,ki} = timeConversionFcn(imaginaryAxisFocus_{ko,ki});
                    end
                end
                realAxisFocus(1:size(realAxisFocus_,1),1:size(realAxisFocus_,2)) = realAxisFocus_;
                imaginaryAxisFocus(1:size(imaginaryAxisFocus_,1),1:size(imaginaryAxisFocus_,2)) = imaginaryAxisFocus_;
            end
        end

        function cbAxesGridXLimitsChanged(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.IOPZAxesView
            end
            cbAxesGridXLimitsChanged@controllib.chart.internal.view.axes.RowColumnAxesView(this);
            updateGrid(this);
        end

        function cbAxesGridYLimitsChanged(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.IOPZAxesView
            end
            cbAxesGridYLimitsChanged@controllib.chart.internal.view.axes.RowColumnAxesView(this);
            updateGrid(this);
        end
    end

    methods (Hidden)
        function [gridLines,gridLineLabels] = qeGetGridLines(this)
            gridLines = this.GridLines;
            gridLineLabels = this.GridLineLabels;
        end
    end
end

