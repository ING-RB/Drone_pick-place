classdef NyquistAxesView < controllib.chart.internal.view.axes.RowColumnAxesView & ...
        controllib.chart.internal.view.axes.MixInInputOutputAxesViewLabels & ...
        controllib.chart.internal.foundation.MixInFrequencyUnit & ...
        controllib.chart.internal.foundation.MixInMagnitudeUnit & ...
        controllib.chart.internal.foundation.MixInPhaseUnit
    % Nyquist

    % Copyright 2022-23 The MathWorks, Inc.
    properties (Dependent,AbortSet,SetObservable)
        ShowFullContour (1,1) matlab.lang.OnOffSwitchState
    end

    properties (AbortSet,SetObservable)
        GridOptions (1,1) struct = gridopts('nyquist')
    end
    
    properties (Access = protected)
        XLabelWithoutUnits = ""
        YLabelWithoutUnits = ""
        GridLines
        GridLineLabels

        ShowFullContour_I
    end

    %% Constructor
    methods
        function this = NyquistAxesView(chart)
            arguments
                chart (1,1) controllib.chart.NyquistPlot
            end
            this@controllib.chart.internal.foundation.MixInFrequencyUnit(chart.FrequencyUnit);
            this@controllib.chart.internal.foundation.MixInMagnitudeUnit(chart.MagnitudeUnit);
            this@controllib.chart.internal.foundation.MixInPhaseUnit(chart.PhaseUnit);
            this@controllib.chart.internal.view.axes.RowColumnAxesView(chart);
            this.ShowFullContour = chart.ShowNegativeFrequencies;
            this.GridOptions.FrequencyUnits = char(chart.FrequencyUnit);
            this.GridOptions.MagnitudeUnits = char(chart.MagnitudeUnit);

            build(this);
        end
    end

    %% Public methods
    methods
        function updateResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NyquistAxesView
                response (1,1) controllib.chart.internal.foundation.BaseResponse
            end
            idx = find(arrayfun(@(x) x.Response.Tag == response.Tag,this.ResponseViews),1);
            responseView = this.ResponseViews(idx);
            hasDifferentCharacteristics = ~isempty(setdiff(...
                union(responseView.CharacteristicTypes,response.CharacteristicTypes),...
                intersect(responseView.CharacteristicTypes,response.CharacteristicTypes)));
            if isa(responseView,'controllib.chart.internal.view.wave.NyquistResponseView') &&...
                    (responseView.Response.NResponses ~= response.NResponses ||...
                    responseView.Response.NRows ~= response.NOutputs ||...
                    responseView.Response.NColumns ~= response.NInputs ||...
                    ~isequal(responseView.PlotColumnIdx,response.ResponseData.PlotInputIdx) || ...
                    ~isequal(responseView.PlotRowIdx,response.ResponseData.PlotOutputIdx) || ...
                    hasDifferentCharacteristics)
                delete(responseView);
                this.ResponseViews = this.ResponseViews(isvalid(this.ResponseViews));
                responseView = createResponseView(this,response);
                responseView.ColumnNames = this.ColumnNames;
                responseView.RowNames = this.RowNames;
                createResponseDataTips(responseView);
                this.ResponseViews = [this.ResponseViews(1:idx-1); responseView; this.ResponseViews(idx:end)];
                parentResponseViews(this);
            else
                update(responseView);
                if isa(responseView,"robustplot.internal.diskmargin.DiskMarginNyquistDiskResponseView")
                    updatePatchExtent(responseView,this.AxesGrid.XLimits{1},this.AxesGrid.YLimits{1});
                end
            end
        end

        function updateResponseVisibility(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NyquistAxesView
                response (1,1) controllib.chart.internal.foundation.BaseResponse
            end
            responseView = getResponseView(this,response);
            if isa(responseView,'controllib.chart.internal.view.wave.NyquistResponseView')
                updateVisibility(responseView,response.Visible & response.ShowInView,ColumnVisible=this.ColumnVisible(responseView.PlotColumnIdx),...
                    RowVisible=this.RowVisible(responseView.PlotRowIdx),ArrayVisible=response.ArrayVisible);
            else
                updateVisibility(responseView,response.Visible & response.ShowInView,ColumnVisible=this.ColumnVisible,...
                    RowVisible=this.RowVisible,ArrayVisible=response.ArrayVisible);
            end
        end

        function showDGMDataTips(this)
            for ii = 1:length(this.ResponseViews)
                responseView = this.ResponseViews(ii);
                if ~isa(responseView,'controllib.chart.internal.view.wave.NyquistResponseView')
                    showDGMDataTips(responseView);
                end
            end
        end

        function showFullContour = get.ShowFullContour(this)
            showFullContour = this.ShowFullContour_I;
        end

        function set.ShowFullContour(this,ShowFullContour)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NyquistAxesView
                ShowFullContour (1,1) matlab.lang.OnOffSwitchState
            end
            this.ShowFullContour_I = ShowFullContour;
            for k = 1:length(this.ResponseViews)
                if isa(this.ResponseViews(k),'controllib.chart.internal.view.wave.NyquistResponseView')
                    this.ResponseViews(k).ShowFullContour = ShowFullContour;
                end
                update(this.ResponseViews(k));
            end
        end
        
        function updateAxesGridSize(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NyquistAxesView
            end
            updateAxesGridSize@controllib.chart.internal.view.axes.RowColumnAxesView(this);
            updateGrid(this);
        end

        function zoomcp(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NyquistAxesView
                responses (:,1) controllib.chart.internal.foundation.BaseResponse
            end
            % Zoom in region around critical point
            % Hide data outside ball of rho max(4,1.5 x min. distance to (-1,0))
            if ~any(this.RowVisible) || ~any(this.ColumnVisible)
                return;
            end
            [realAxisFocus, imaginaryAxisFocus] = computeFocus(this,responses,true);
            switch this.RowColumnGrouping
                case "all"
                    allXLimitsFocus = cell2mat(realAxisFocus);
                    realAxisFocus = {[min(allXLimitsFocus(:,1)), max(allXLimitsFocus(:,2))]};
                    allYLimitsFocus = cell2mat(imaginaryAxisFocus(:));
                    imaginaryAxisFocus = {[min(allYLimitsFocus(:,1)), max(allYLimitsFocus(:,2))]};
                case "columns"
                    xLimitsFocus = cell(this.NRows,1);
                    yLimitsFocus = cell(this.NRows,1);
                    for ko = 1:this.NRows
                        allXLimitsFocus = cell2mat(realAxisFocus(ko,:)');
                        xLimitsFocus{ko} = [min(allXLimitsFocus(:,1)), max(allXLimitsFocus(:,2))];

                        allYLimitsFocus = cell2mat(imaginaryAxisFocus(ko,:)');
                        yLimitsFocus{ko} = [min(allYLimitsFocus(:,1)), max(allYLimitsFocus(:,2))];
                    end
                    realAxisFocus = xLimitsFocus;
                    imaginaryAxisFocus = yLimitsFocus;
                case "rows"
                    xLimitsFocus = cell(1,this.NColumns);
                    yLimitsFocus = cell(1,this.NColumns);
                    for ki = 1:this.NColumns
                        allXLimitsFocus = cell2mat(realAxisFocus(:,ki));
                        xLimitsFocus{ki} = [min(allXLimitsFocus(:,1)), max(allXLimitsFocus(:,2))];

                        allYLimitsFocus = cell2mat(imaginaryAxisFocus(:,ki));
                        yLimitsFocus{ki} = [min(allYLimitsFocus(:,1)), max(allYLimitsFocus(:,2))];
                    end
                    realAxisFocus = xLimitsFocus;
                    imaginaryAxisFocus = yLimitsFocus;
            end
            switch this.AxesGrid.XLimitsSharing
                case "all"
                    yLimits = [NaN NaN];
                    for ii = 1:size(realAxisFocus,1)
                        for jj = 1:size(realAxisFocus,2)
                            yLimits(1) = min(yLimits(1),realAxisFocus{ii,jj}(1));
                            yLimits(2) = max(yLimits(2),realAxisFocus{ii,jj}(2));
                        end
                    end
                case "column"
                    yLimits = repmat({[NaN NaN]},1,this.NColumns);
                    for ii = 1:size(realAxisFocus,1)
                        for jj = 1:size(realAxisFocus,2)
                            yLimits{1,jj}(1) = min(yLimits{1,jj}(1),realAxisFocus{ii,jj}(1));
                            yLimits{1,jj}(2) = max(yLimits{1,jj}(2),realAxisFocus{ii,jj}(2));
                        end
                    end
                    switch this.RowColumnGrouping
                        case {"all","columns"}
                            yLimits = yLimits(1);
                        otherwise
                            yLimits = yLimits(this.ColumnVisible);
                    end
                case "none"
                    switch this.RowColumnGrouping
                        case "all"
                            yLimits = realAxisFocus(1);
                        case "columns"
                            yLimits = realAxisFocus(this.RowVisible,1);
                        case "rows"
                            yLimits = realAxisFocus(1,this.ColumnVisible);
                        case "none"
                            yLimits = realAxisFocus(this.RowVisible,this.ColumnVisible);
                    end
            end
            this.AxesGrid.XLimits = yLimits;
            switch this.AxesGrid.YLimitsSharing
                case "all"
                    yLimits = [NaN NaN];
                    for ii = 1:size(imaginaryAxisFocus,1)
                        for jj = 1:size(imaginaryAxisFocus,2)
                            yLimits(1) = min(yLimits(1),imaginaryAxisFocus{ii,jj}(1));
                            yLimits(2) = max(yLimits(2),imaginaryAxisFocus{ii,jj}(2));
                        end
                    end
                case "row"
                    yLimits = repmat({[NaN NaN]},this.NRows,1);
                    for ii = 1:size(imaginaryAxisFocus,1)
                        for jj = 1:size(imaginaryAxisFocus,2)
                            yLimits{ii,1}(1) = min(yLimits{ii,1}(1),imaginaryAxisFocus{ii,jj}(1));
                            yLimits{ii,1}(2) = max(yLimits{ii,1}(2),imaginaryAxisFocus{ii,jj}(2));
                        end
                    end
                    switch this.RowColumnGrouping
                        case {"all","rows"}
                            yLimits = yLimits(1);
                        otherwise
                            yLimits = yLimits(this.RowVisible);
                    end
                case "none"
                    switch this.RowColumnGrouping
                        case "all"
                            yLimits = imaginaryAxisFocus(1);
                        case "columns"
                            yLimits = imaginaryAxisFocus(this.RowVisible,1);
                        case "rows"
                            yLimits = imaginaryAxisFocus(1,this.ColumnVisible);
                        case "none"
                            yLimits = imaginaryAxisFocus(this.RowVisible,this.ColumnVisible);
                    end
            end
            this.AxesGrid.YLimits = yLimits;
            update(this.AxesGrid);
        end
    end

    methods (Access = protected)
        function responseView = createResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NyquistAxesView
                response (1,1) controllib.chart.internal.foundation.BaseResponse
            end
            switch class(response)
                case "controllib.chart.response.NyquistResponse"
                    responseView = controllib.chart.internal.view.wave.NyquistResponseView(response,...
                        ColumnVisible=this.ColumnVisible(1:response.NColumns),...
                        RowVisible=this.RowVisible(1:response.NRows),...
                        ShowFullContour=this.ShowFullContour);
                    responseView.FrequencyUnit = this.FrequencyUnit;
                case "robustplot.response.DiskMarginResponse"
                    if response.DGMType == "disk"
                        responseView = robustplot.internal.diskmargin.DiskMarginDiskResponseView(response);
                    else
                        responseView = robustplot.internal.diskmargin.DiskMarginNyquistDiskResponseView(response);
                    end
                    responseView.MagnitudeUnit = this.MagnitudeUnit;
                    responseView.PhaseUnit = this.PhaseUnit;
            end
        end

        function postParentResponseView(this,responseView)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NyquistAxesView
                responseView (1,1) controllib.chart.internal.view.wave.BaseResponseView
            end
            switch class(responseView)
                case "controllib.chart.internal.view.wave.NyquistResponseView"
                    ax = getAxes(this);
                    aspectRatio = ax(1).PlotBoxAspectRatio;
                    updateArrows(responseView,AspectRatio=aspectRatio);
                case "robustplot.internal.diskmargin.DiskMarginNyquistDiskResponseView"
                    updatePatchExtent(responseView,this.AxesGrid.XLimits{1},this.AxesGrid.YLimits{1});
            end
        end

        function cbAxesGridXLimitsChanged(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NyquistAxesView
            end
            cbAxesGridXLimitsChanged@controllib.chart.internal.view.axes.RowColumnAxesView(this);
            updateGrid(this);
            for k = 1:length(this.ResponseViews)
                switch class(this.ResponseViews(k))
                    case "controllib.chart.internal.view.wave.NyquistResponseView"
                        ax = getAxes(this);
                        aspectRatio = ax(1).PlotBoxAspectRatio;
                        updateArrows(this.ResponseViews(k),AspectRatio=aspectRatio);
                    case "robustplot.internal.diskmargin.DiskMarginNyquistDiskResponseView"
                        updatePatchExtent(this.ResponseViews(k),this.AxesGrid.XLimits{1},this.AxesGrid.YLimits{1});
                end
            end
        end

        function cbAxesGridYLimitsChanged(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NyquistAxesView
            end
            cbAxesGridYLimitsChanged@controllib.chart.internal.view.axes.RowColumnAxesView(this);
            updateGrid(this);
            for k = 1:length(this.ResponseViews)
                switch class(this.ResponseViews(k))
                    case "controllib.chart.internal.view.wave.NyquistResponseView"
                        ax = getAxes(this);
                        aspectRatio = ax(1).PlotBoxAspectRatio;
                        updateArrows(this.ResponseViews(k),AspectRatio=aspectRatio);
                    case "robustplot.internal.diskmargin.DiskMarginNyquistDiskResponseView"
                        updatePatchExtent(this.ResponseViews(k),this.AxesGrid.XLimits{1},this.AxesGrid.YLimits{1});
                end
            end
        end

        function [realAxisFocus, imaginaryAxisFocus] = updateFocus_(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NyquistAxesView
                responses (:,1) controllib.chart.internal.foundation.BaseResponse
            end
            % Compute focus
            [realAxisFocus, imaginaryAxisFocus] = computeFocus(this,responses);
        end

        function cbFrequencyUnitChanged(this,~)
            % Change FrequencyUnit on each response
            for k = 1:length(this.ResponseViews)
                if isa(this.ResponseViews(k),'controllib.chart.internal.view.wave.NyquistResponseView')
                    this.ResponseViews(k).FrequencyUnit = this.FrequencyUnit;
                end
            end
            this.GridOptions.FrequencyUnits = char(this.FrequencyUnit);
            updateGrid(this);
        end

        function cbMagnitudeUnitChanged(this,~)
            % Change TimeUnit on each response
            for n = 1:length(this.ResponseViews)
                if ~isa(this.ResponseViews(n),'controllib.chart.internal.view.wave.NyquistResponseView')
                    this.ResponseViews(n).MagnitudeUnit = this.MagnitudeUnit;
                end
            end
            this.GridOptions.MagnitudeUnits = char(this.MagnitudeUnit);
            updateGrid(this);
        end

        function cbPhaseUnitChanged(this,~)
            % Change TimeUnit on each response
            for n = 1:length(this.ResponseViews)
                if ~isa(this.ResponseViews(n),'controllib.chart.internal.view.wave.NyquistResponseView')
                    this.ResponseViews(n).PhaseUnit = this.PhaseUnit;
                end
            end
        end

        function XLabel = getXLabelString(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NyquistAxesView
            end
            XLabel = this.XLabelWithoutUnits;
        end

        function setXLabelString(this,XLabel)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NyquistAxesView
                XLabel (1,1) string
            end
            this.XLabelWithoutUnits = XLabel;
            % Add units to xlabel
            this.AxesGrid.XLabel = this.XLabelWithoutUnits;
        end

        function YLabel = getYLabelString(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NyquistAxesView
            end
            YLabel = this.YLabelWithoutUnits;
        end

        function setYLabelString(this,YLabel)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NyquistAxesView
                YLabel (1,1) string
            end
            this.YLabelWithoutUnits = YLabel;
            % Add units to ylabel
            this.AxesGrid.YLabel = this.YLabelWithoutUnits;
        end

        function updateGrid_(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NyquistAxesView
            end
            delete(this.GridLines);
            delete(this.GridLineLabels);
            if this.Chart.AxesStyle.GridVisible && this.NColumns == 1 && this.NRows == 1
                [this.GridLines, this.GridLineLabels] = nyqchart(getAxes(this),this.GridOptions);

                this.GridLines = handle(this.GridLines);
                this.GridLineLabels = handle(this.GridLineLabels);

                % Set Color
                updateCustomGridColor(this);

                % Set PickableParts to 'none' to avoid datatips
                set(this.GridLines',Serializable='off',LineWidth=this.Style.Axes.GridLineWidth,...
                    LineStyle=this.Style.Axes.GridLineStyle);
                set(this.GridLineLabels,Serializable='off',Visible=this.Chart.AxesStyle.GridLabelsVisible);

                this.Style.Axes.HasCustomGrid = true;
            else
                this.Style.Axes.HasCustomGrid = false;
            end
        end

        function updateCustomGridColor(this)
            if ~isempty(this.GridLines) && all(isvalid(this.GridLines))
                if strcmp(this.Style.Axes.GridColorMode,"auto")
                    controllib.plot.internal.utils.setColorProperty(this.GridLines,...
                        "Color","--mw-graphics-borderColor-axes-tertiary");
                    controllib.plot.internal.utils.setColorProperty(this.GridLineLabels,...
                        "Color","--mw-graphics-borderColor-axes-tertiary");
                else
                    controllib.plot.internal.utils.setColorProperty(this.GridLines,...
                        "Color",this.Style.Axes.GridColor);
                    controllib.plot.internal.utils.setColorProperty(this.GridLineLabels,...
                        "Color",this.Style.Axes.GridColor);
                end
            end
        end

        function [realAxisFocus, imaginaryAxisFocus] = computeFocus(this,responses,zoomcp)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NyquistAxesView
                responses (:,1) controllib.chart.internal.foundation.BaseResponse
                zoomcp (1,1) logical = false
            end
            realAxisFocus = repmat({[NaN NaN]},this.NRows,this.NColumns);
            imaginaryAxisFocus = repmat({[NaN NaN]},this.NRows,this.NColumns);
            if ~isempty(responses)
                data = [responses.ResponseData];
                isNyquistResponse = arrayfun(@(x) isa(x,"controllib.chart.response.NyquistResponse"),responses);
                nyquistData = data(isNyquistResponse);
                diskMarginData = data(~isNyquistResponse);
                dataVisible = {responses.ArrayVisible};
                nyquistVisible = dataVisible(isNyquistResponse);
                diskMarginVisible = dataVisible(~isNyquistResponse);
                if ~isempty(nyquistData)
                    [realAxisFocus_, imaginaryAxisFocus_] = getCommonFocusForMultipleData(nyquistData,this.ShowFullContour,zoomcp,nyquistVisible);
                    realAxisFocus(1:size(realAxisFocus_,1),1:size(realAxisFocus_,2)) = realAxisFocus_;
                    imaginaryAxisFocus(1:size(imaginaryAxisFocus_,1),1:size(imaginaryAxisFocus_,2)) = imaginaryAxisFocus_;
                end
                if ~isempty(diskMarginData)
                    [realAxisFocusDiskMargin, imaginaryAxisFocusDiskMargin] = getCommonFocusForMultipleData(diskMarginData,diskMarginVisible);
                    realAxisFocus{1} = [min(realAxisFocus{1}(1),realAxisFocusDiskMargin{1}(1)),...
                        max(realAxisFocus{1}(2),realAxisFocusDiskMargin{1}(2))];
                    imaginaryAxisFocus{1} = [min(imaginaryAxisFocus{1}(1),imaginaryAxisFocusDiskMargin{1}(1)),...
                        max(imaginaryAxisFocus{1}(2),imaginaryAxisFocusDiskMargin{1}(2))];
                end
            end
        end
    end

    %% Hidden methods
    methods (Hidden)
        function [gridLines,gridLineLabels] = qeGetGridLines(this)
            gridLines = this.GridLines;
            gridLineLabels = this.GridLineLabels;
        end
    end
end

