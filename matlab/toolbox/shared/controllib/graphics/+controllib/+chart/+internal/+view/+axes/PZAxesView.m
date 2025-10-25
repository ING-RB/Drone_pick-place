classdef PZAxesView < controllib.chart.internal.view.axes.BaseAxesView & ...
        controllib.chart.internal.foundation.MixInTimeUnit & ...
        controllib.chart.internal.foundation.MixInFrequencyUnit
        
    % TimeView

    % Copyright 2021-2022 The MathWorks, Inc.
    properties (AbortSet, SetObservable)
        GridType (1,1) string
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
        function this = PZAxesView(chart)
            arguments
                chart (1,1) controllib.chart.PZPlot
            end
            this@controllib.chart.internal.foundation.MixInTimeUnit(chart.TimeUnit);
            this@controllib.chart.internal.foundation.MixInFrequencyUnit(chart.FrequencyUnit);
            this@controllib.chart.internal.view.axes.BaseAxesView(chart);
            this.GridType = this.Chart.AxesStyle.GridType;
            this.GridOptions.TimeUnits = char(this.TimeUnit);
            this.GridOptions.FrequencyUnits = char(this.FrequencyUnit);

            build(this);
        end
    end

    %% Public methods
    methods
        function updateResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.PZAxesView
                response (1,1) controllib.chart.internal.foundation.BaseResponse
            end
            updateResponseView@controllib.chart.internal.view.axes.BaseAxesView(this,response);
            responseView = getResponseView(this,response);
            if isa(responseView,'controllib.chart.internal.view.wave.PZBoundResponseView')
                updateSpectralLimits(responseView,this.XLimits,this.YLimits);
            end
        end
    end

    %% Get/Set
    methods
        function set.GridType(this,GridType)
            arguments
                this (1,1) controllib.chart.internal.view.axes.PZAxesView
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
                this (1,1) controllib.chart.internal.view.axes.PZAxesView
                response (1,1) controllib.chart.internal.foundation.BaseResponse
            end
            switch class(response)
                case "controllib.chart.response.PZResponse"
                    responseView = controllib.chart.internal.view.wave.PZResponseView(response);
                case "controllib.chart.response.internal.PZBoundResponse"
                    responseView = controllib.chart.internal.view.wave.PZBoundResponseView(response);
            end
            responseView.TimeUnit = this.TimeUnit;
        end

        function postParentResponseView(this,responseView)
            arguments
                this (1,1) controllib.chart.internal.view.axes.PZAxesView
                responseView (1,1) controllib.chart.internal.view.wave.BaseResponseView
            end

            if isa(responseView,"controllib.chart.internal.view.wave.PZBoundResponseView")
                updateSpectralLimits(responseView,this.XLimits,this.YLimits);
            end
        end

        function cbAxesGridXLimitsChanged(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.PZAxesView
            end
            cbAxesGridXLimitsChanged@controllib.chart.internal.view.axes.BaseAxesView(this);
            for k = 1:length(this.ResponseViews)
                if isa(this.ResponseViews(k),'controllib.chart.internal.view.wave.PZBoundResponseView')
                    updateSpectralLimits(this.ResponseViews(k),this.AxesGrid.XLimits{1},this.AxesGrid.YLimits{1});
                end
            end
            updateGrid(this);
        end

        function cbAxesGridYLimitsChanged(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.PZAxesView
            end
            cbAxesGridYLimitsChanged@controllib.chart.internal.view.axes.BaseAxesView(this);
            for k = 1:length(this.ResponseViews)
                if isa(this.ResponseViews(k),'controllib.chart.internal.view.wave.PZBoundResponseView')
                    updateSpectralLimits(this.ResponseViews(k),this.AxesGrid.XLimits{1},this.AxesGrid.YLimits{1});
                end
            end
            updateGrid(this);
        end

        function [realAxisFocus,imaginaryAxisFocus] = updateFocus_(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.PZAxesView
                responses (:,1) controllib.chart.internal.foundation.BaseResponse
            end
            % Compute focus
            [realAxisFocus, imaginaryAxisFocus] = computeFocus(this,responses);
        end

        function cbTimeUnitChanged(this,conversionFcn)
            arguments
                this (1,1) controllib.chart.internal.view.axes.PZAxesView
                conversionFcn (1,1) function_handle
            end
            % Change TimeUnit on each response
            for n = 1:length(this.ResponseViews)
                this.ResponseViews(n).TimeUnit = this.TimeUnit;
            end

            % Convert Focus
            this.AxesGrid.XLimitsFocus{1} = 1./conversionFcn(1./this.AxesGrid.XLimitsFocus{1});
            this.AxesGrid.YLimitsFocus{1} = 1./conversionFcn(1./this.AxesGrid.YLimitsFocus{1});
            
            % Convert Limits that are set manually
            if strcmp(this.AxesGrid.XLimitsMode{1},'manual')
                this.AxesGrid.XLimits{1} = 1./conversionFcn(1./this.AxesGrid.XLimits{1});
            end

            if strcmp(this.AxesGrid.YLimitsMode{1},'manual')
                this.AxesGrid.YLimits{1} = 1./conversionFcn(1./this.AxesGrid.YLimits{1});
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
                this (1,1) controllib.chart.internal.view.axes.PZAxesView
                ~
            end
            % Change FrequencyUnit on each response
            for n = 1:length(this.ResponseViews)
                this.ResponseViews(n).FrequencyUnit = this.FrequencyUnit;
            end

            this.GridOptions.FrequencyUnits = char(this.FrequencyUnit);
            updateGrid(this);
        end

        function XLabel = getXLabelString(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.PZAxesView
            end
            XLabel = this.XLabelWithoutUnits;
        end

        function setXLabelString(this,XLabel)
            arguments
                this (1,1) controllib.chart.internal.view.axes.PZAxesView
                XLabel (1,1) string
            end
            this.XLabelWithoutUnits = XLabel;
            this.AxesGrid.XLabel = this.XLabelWithoutUnits + " (" + this.TimeUnitLabel + "^{-1}" + ")";
        end

        function YLabel = getYLabelString(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.PZAxesView
            end
            YLabel = this.YLabelWithoutUnits;
        end

        function setYLabelString(this,YLabel)
            arguments
                this (1,1) controllib.chart.internal.view.axes.PZAxesView
                YLabel (1,1) string
            end
            this.YLabelWithoutUnits = YLabel;
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
                this (1,1) controllib.chart.internal.view.axes.PZAxesView
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
                    [this.GridLines, this.GridLineLabels] = zpchart(getAxes(this),opts);
                    isCustomGridUsed = true;
                elseif strcmp(this.GridType,"s-plane") || ...
                        (strcmp(this.GridType,"default") && ~isempty(this.ResponseViews) && ~any(isDiscreteResponse))
                    [this.GridLines, this.GridLineLabels] = spchart(getAxes(this),opts);
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
                this (1,1) controllib.chart.internal.view.axes.PZAxesView
                responses (:,1) controllib.chart.internal.foundation.BaseResponse
            end
            realAxisFocus = {[NaN NaN]};
            imaginaryAxisFocus = {[NaN NaN]};
            if ~isempty(responses)
                data = [responses.ResponseData];
                isPZResponse = arrayfun(@(x) isa(x,"controllib.chart.response.PZResponse"),responses);
                pzData = data(isPZResponse);
                pzBoundData = data(~isPZResponse);
                dataVisible = {responses.ArrayVisible};
                pzVisible = dataVisible(isPZResponse);
                pzBoundVisible = dataVisible(~isPZResponse);
                if ~isempty(pzData)
                    [realAxisFocus, imaginaryAxisFocus, timeUnit] = getCommonFocusForMultipleData(pzData,pzVisible);
                end
                if ~isempty(pzBoundData)
                    [realAxisFocusBounds, imaginaryAxisFocusBounds, timeUnitBounds] = getCommonFocusForMultipleData(pzBoundData,pzBoundVisible);
                    if isempty(pzData)
                        timeUnit = timeUnitBounds;
                        realAxisFocus = realAxisFocusBounds;
                        imaginaryAxisFocus = imaginaryAxisFocusBounds;
                    else
                        cf = tunitconv(timeUnitBounds,timeUnit);
                        realAxisFocusBounds{1} = (1/cf)*realAxisFocusBounds{1};
                        imaginaryAxisFocusBounds{1} = (1/cf)*imaginaryAxisFocusBounds{1};
                        realAxisFocus{1} = [min(realAxisFocus{1}(1),realAxisFocusBounds{1}(1)),...
                            max(realAxisFocus{1}(2),realAxisFocusBounds{1}(2))];
                        imaginaryAxisFocus{1} = [min(imaginaryAxisFocus{1}(1),imaginaryAxisFocusBounds{1}(1)),...
                            max(imaginaryAxisFocus{1}(2),imaginaryAxisFocusBounds{1}(2))];
                    end
                end
                timeConversionFcn = getTimeUnitConversionFcn(this,timeUnit,this.TimeUnit);
                realAxisFocus{1} = timeConversionFcn(realAxisFocus{1});
                imaginaryAxisFocus{1} = timeConversionFcn(imaginaryAxisFocus{1});
            end
        end
    end

    methods (Hidden)
        function [gridLines,gridLineLabels] = qeGetGridLines(this)
            gridLines = this.GridLines;
            gridLineLabels = this.GridLineLabels;
        end
    end
end