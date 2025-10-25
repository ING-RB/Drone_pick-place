classdef LimitManager < matlab.mixin.SetGet
    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (Access=?controllib.chart.internal.layout.AxesGrid)
        Enabled (1,1) matlab.lang.OnOffSwitchState = true
    end

    % Read & Write
    properties (Dependent,Access=private)
        AllXLimits
        AllYLimits
    end

    % Read-only
    properties (Dependent,Access=private)
        TiledLayout
        Axes
        VisibleAxes

        GridSize
        SubGridSize

        XRulerType
        XLimitsSharing
        AllXLimitsMode
        XLimitsFocus
        XScale
        XLimitPickerBase
        AutoAdjustXLimits
        ShowXTickLabels
        XTickLabelFormat

        YRulerType
        YLimitsSharing
        AllYLimitsMode
        YLimitsFocus
        YScale
        YLimitPickerBase
        AutoAdjustYLimits
        ShowYTickLabels
        YTickLabelFormat

        AllRowVisible
        AllColumnVisible
        SubGridRowVisible
        SubGridColumnVisible
        NVisibleSubGridRows
        NVisibleSubGridColumns
    end

    properties (Access=private,WeakHandle)
        AxesGrid controllib.chart.internal.layout.AxesGrid {mustBeScalarOrEmpty}
    end

    %% Constructor
    methods
        function this = LimitManager(axesGrid)
            arguments
                axesGrid (1,1) controllib.chart.internal.layout.AxesGrid
            end
            this.AxesGrid = axesGrid;
        end
    end

    %% Get/Set
    methods
        % TiledLayout
        function TiledLayout = get.TiledLayout(this)
            TiledLayout = this.AxesGrid.TiledLayout;
        end

        % Axes
        function Axes = get.Axes(this)
            Axes = this.AxesGrid.Axes;
        end

        % VisibleAxes
        function VisibleAxes = get.VisibleAxes(this)
            VisibleAxes = this.AxesGrid.VisibleAxes;
        end

        % GridSize
        function GridSize = get.GridSize(this)
            GridSize = this.AxesGrid.GridSize;
        end

        % SubGridSize
        function SubGridSize = get.SubGridSize(this)
            SubGridSize = this.AxesGrid.SubGridSize;
        end

        % XRulerType
        function XRulerType = get.XRulerType(this)
            XRulerType = this.AxesGrid.XRulerType;
        end

        % YRulerType
        function YRulerType = get.YRulerType(this)
            YRulerType = this.AxesGrid.YRulerType;
        end

        % XLimitsSharing
        function XLimitsSharing = get.XLimitsSharing(this)
            XLimitsSharing = this.AxesGrid.XLimitsSharing;
        end

        % YLimitsSharing
        function YLimitsSharing = get.YLimitsSharing(this)
            YLimitsSharing = this.AxesGrid.YLimitsSharing;
        end

        % XLimitsFocus
        function XLimitsFocus = get.XLimitsFocus(this)
            XLimitsFocus = this.AxesGrid.XLimitsFocus;
        end

        % YLimitsFocus
        function YLimitsFocus = get.YLimitsFocus(this)
            YLimitsFocus = this.AxesGrid.YLimitsFocus;
        end

        % AutoAdjustXLimits
        function AutoAdjustXLimits = get.AutoAdjustXLimits(this)
            AutoAdjustXLimits = this.AxesGrid.AutoAdjustXLimits;
        end

        % AutoAdjustYLimits
        function AutoAdjustYLimits = get.AutoAdjustYLimits(this)
            AutoAdjustYLimits = this.AxesGrid.AutoAdjustYLimits;
        end

        % XScale
        function XScale = get.XScale(this)
            XScale = this.AxesGrid.XScale;
        end

        % YScale
        function YScale = get.YScale(this)
            YScale = this.AxesGrid.YScale;
        end

        % AllXLimits
        function AllXLimits = get.AllXLimits(this)
            AllXLimits = this.AxesGrid.AllXLimits;
        end

        function set.AllXLimits(this,AllXLimits)
            this.AxesGrid.AllXLimits = AllXLimits;
        end

        % AllXLimitsMode
        function AllXLimitsMode = get.AllXLimitsMode(this)
            AllXLimitsMode = this.AxesGrid.AllXLimitsMode;
        end

        % AllYLimits
        function AllYLimits = get.AllYLimits(this)
            AllYLimits = this.AxesGrid.AllYLimits;
        end

        function set.AllYLimits(this,AllYLimits)
            this.AxesGrid.AllYLimits = AllYLimits;
        end

        % AllYLimitsMode
        function AllYLimitsMode = get.AllYLimitsMode(this)
            AllYLimitsMode = this.AxesGrid.AllYLimitsMode;
        end

        % AllRowVisible
        function AllRowVisible = get.AllRowVisible(this)
            AllRowVisible = this.AxesGrid.AllRowVisible;
        end

        % AllColumnVisible
        function AllColumnVisible = get.AllColumnVisible(this)
            AllColumnVisible = this.AxesGrid.AllColumnVisible;
        end

        % ShowXTickLabels
        function ShowXTickLabels = get.ShowXTickLabels(this)
            ShowXTickLabels = this.AxesGrid.ShowXTickLabels;
        end

        % ShowYTickLabels
        function ShowYTickLabels = get.ShowYTickLabels(this)
            ShowYTickLabels = this.AxesGrid.ShowYTickLabels;
        end

        % XLimitPickerBase
        function XLimitPickerBase = get.XLimitPickerBase(this)
            XLimitPickerBase = this.AxesGrid.XLimitPickerBase;
        end

        % YLimitPickerBase
        function YLimitPickerBase = get.YLimitPickerBase(this)
            YLimitPickerBase = this.AxesGrid.YLimitPickerBase;
        end        

        % XTickLabelFormat
        function XTickLabelFormat = get.XTickLabelFormat(this)
            XTickLabelFormat = this.AxesGrid.XTickLabelFormat;
        end

        % YTickLabelFormat
        function YTickLabelFormat = get.YTickLabelFormat(this)
            YTickLabelFormat = this.AxesGrid.YTickLabelFormat;
        end

        % SubGridRowVisible
        function SubGridRowVisible = get.SubGridRowVisible(this)
            SubGridRowVisible = this.AxesGrid.SubGridRowVisible;
        end

        % SubGridColumnVisible
        function SubGridColumnVisible = get.SubGridColumnVisible(this)
            SubGridColumnVisible = this.AxesGrid.SubGridColumnVisible;
        end

        % NVisibleSubGridRows
        function NVisibleSubGridRows = get.NVisibleSubGridRows(this)
            NVisibleSubGridRows = this.AxesGrid.NVisibleSubGridRows;
        end

        % NVisibleSubGridColumns
        function NVisibleSubGridColumns = get.NVisibleSubGridColumns(this)
            NVisibleSubGridColumns = this.AxesGrid.NVisibleSubGridColumns;
        end
    end

    %% AxesGrid methods
    methods (Access = ?controllib.chart.internal.layout.AxesGrid)
        function updateXLimits(this)
            if this.Enabled
                % Convert ruler type and scale
                ax = this.Axes;
                switch this.XRulerType
                    case "numeric"
                        dummyData = NaN;
                    case "duration"
                        dummyData = duration(NaN,NaN,NaN);
                    case "datetime"
                        dummyData = NaT;
                        dummyData.Format = 'dd-MMM-uuuu';
                end
                for ii = 1:size(ax,1)
                    for jj = 1:size(ax,2)
                        matlab.graphics.internal.configureAxes(ax(ii,jj),dummyData,[]);
                        if this.XRulerType == "numeric" % only set for numeric
                            subGridIdx = mod(jj-1,this.SubGridSize(2))+1;
                            ax(ii,jj).XScale = this.XScale(subGridIdx);
                        end
                    end
                end
                ax = this.VisibleAxes;
                if isempty(ax)
                    return;
                end

                set([this.Axes.XAxis],TickLabels={});
                switch this.XLimitsSharing
                    case 'none'
                        xRulers = [ax.XAxis];
                    otherwise
                        xRulers = [ax(end,:).XAxis];
                end

                % Set limits based on sharing

                xLimits = reshape(this.AllXLimits(this.AllRowVisible,this.AllColumnVisible),size(ax));
                xLimitsMode = reshape(this.AllXLimitsMode(this.AllRowVisible,this.AllColumnVisible),size(ax));
                xLimitsFocus = reshape(this.XLimitsFocus(this.AllRowVisible,this.AllColumnVisible),size(ax));
                xScale = this.XScale(this.SubGridColumnVisible);
                xLimitPickerBase = this.XLimitPickerBase(this.SubGridColumnVisible);

                switch this.XLimitsSharing
                    case 'all'
                        for jj = 1:this.NVisibleSubGridColumns
                            switch xLimitsMode{1,jj}
                                case 'auto'
                                    this.shareLimits(ax(:,jj:this.SubGridSize(2):end),xLimitsFocus(:,jj:this.SubGridSize(2):end),...
                                        AutoAdjust=this.AutoAdjustXLimits,Scale=xScale(jj),...
                                        AutoLimitBase=xLimitPickerBase(jj),Axis="x");
                                case 'manual'
                                    this.shareLimits(ax(:,jj:this.SubGridSize(2):end),xLimits(:,jj:this.SubGridSize(2):end),...
                                        AutoAdjust=false,Scale=xScale(jj),...
                                        AutoLimitBase=xLimitPickerBase(jj),Axis="x");
                            end
                        end

                        if this.ShowXTickLabels
                            set(xRulers,TickLabelMode="auto",TickLabelFormat=this.XTickLabelFormat);
                        end
                    case 'column'
                        for jj = 1:size(ax,2)
                            kc = mod(jj-1,this.NVisibleSubGridColumns)+1;
                            switch xLimitsMode{1,jj}
                                case 'auto'
                                    this.shareLimits(ax(:,jj),xLimitsFocus(:,jj),...
                                        AutoAdjust=this.AutoAdjustXLimits,Scale=xScale(kc),...
                                        AutoLimitBase=xLimitPickerBase(kc),Axis="x");
                                case 'manual'
                                    this.shareLimits(ax(:,jj),xLimits(:,jj),...
                                        AutoAdjust=false,Scale=xScale(kc),...
                                        AutoLimitBase=xLimitPickerBase(kc),Axis="x");
                            end
                        end

                        if this.ShowXTickLabels
                            set(xRulers,TickLabelMode="auto",TickLabelFormat=this.XTickLabelFormat);
                        end
                    case 'none'
                        for ii = 1:size(ax,1)
                            for jj = 1:size(ax,2)
                                kc = mod(jj-1,this.NVisibleSubGridColumns)+1;
                                switch xLimitsMode{ii,jj}
                                    case 'auto'
                                        this.shareLimits(ax(ii,jj),xLimitsFocus(ii,jj),...
                                            AutoAdjust=this.AutoAdjustXLimits,Scale=xScale(kc),...
                                            AutoLimitBase=xLimitPickerBase(kc),Axis="x");
                                    case 'manual'
                                        ax(ii,jj).XLim=xLimits{ii,jj};
                                end
                            end
                        end

                        if this.ShowXTickLabels
                            set(xRulers,TickLabelMode="auto",TickLabelFormat=this.XTickLabelFormat);
                        end
                end

                ax = this.Axes;
                xLim = cell(size(ax));
                for ii = 1:numel(ax)
                    xLim{ii} = ax(ii).XLim;
                end
                this.AllXLimits = xLim;

                updateTicks(this,UpdateYTicks=false);
            end
        end

        function updateYLimits(this)
            if this.Enabled
                % Convert ruler type and scale
                ax = this.Axes;
                switch this.YRulerType
                    case "numeric"
                        dummyData = NaN;
                    case "duration"
                        dummyData = duration(NaN,NaN,NaN);
                    case "datetime"
                        dummyData = NaT;
                        dummyData.Format = 'dd-MMM-uuuu';
                end
                for ii = 1:size(ax,1)
                    subGridIdx = mod(ii-1,this.SubGridSize(1))+1;
                    for jj = 1:size(ax,2)
                        matlab.graphics.internal.configureAxes(ax(ii,jj),[],dummyData);
                        if this.YRulerType == "numeric" % only set for numeric
                            ax(ii,jj).YScale = this.YScale(subGridIdx);
                        end
                    end
                end
                ax = this.VisibleAxes;
                if isempty(ax)
                    return;
                end
                
                % Set TickLabels for only the left Y ruler
                allRulers = localGetLeftYAxis(this.Axes);
                set(allRulers,'TickLabels',{});

                switch this.YLimitsSharing
                    case 'none'
                        yRulers = localGetLeftYAxis(ax);
                    otherwise
                        yRulers = localGetLeftYAxis(ax(:,1));
                end

                % Set limits based on sharing
                
                yLimits = reshape(this.AllYLimits(this.AllRowVisible,this.AllColumnVisible),size(ax));
                yLimitsMode = reshape(this.AllYLimitsMode(this.AllRowVisible,this.AllColumnVisible),size(ax));
                yLimitsFocus = reshape(this.YLimitsFocus(this.AllRowVisible,this.AllColumnVisible),size(ax));
                yScale = this.YScale(this.SubGridRowVisible);
                yLimitPickerBase = this.YLimitPickerBase(this.SubGridRowVisible);

                switch this.YLimitsSharing
                    case 'all'
                        for ii = 1:this.NVisibleSubGridRows
                            switch yLimitsMode{ii,1}
                                case 'auto'
                                    this.shareLimits(ax(ii:this.SubGridSize(1):end,:),yLimitsFocus(ii:this.SubGridSize(1):end,:),...
                                        AutoAdjust=this.AutoAdjustYLimits,Scale=yScale(ii),...
                                        AutoLimitBase=yLimitPickerBase(ii),Axis="y");
                                case 'manual'
                                    this.shareLimits(ax(ii:this.SubGridSize(1):end,:),yLimits(ii:this.SubGridSize(1):end,:),...
                                        AutoAdjust=false,Scale=yScale(ii),...
                                        AutoLimitBase=yLimitPickerBase(ii),Axis="y");
                            end
                        end

                        if this.ShowYTickLabels
                            set(yRulers,TickLabelMode="auto",TickLabelFormat=this.YTickLabelFormat);
                        end
                    case 'row'
                        for ii = 1:size(ax,1)
                            kr = mod(ii-1,this.NVisibleSubGridRows)+1;
                            switch yLimitsMode{ii,1}
                                case 'auto'
                                    this.shareLimits(ax(ii,:),yLimitsFocus(ii,:),...
                                        AutoAdjust=this.AutoAdjustYLimits,Scale=yScale(kr),...
                                        AutoLimitBase=yLimitPickerBase(kr),Axis="y");
                                case 'manual'
                                    this.shareLimits(ax(ii,:),yLimits(ii,:),...
                                        AutoAdjust=false,Scale=yScale(kr),...
                                        AutoLimitBase=yLimitPickerBase(kr),Axis="y");
                            end
                        end

                        if this.ShowYTickLabels
                            set(yRulers,TickLabelMode="auto",TickLabelFormat=this.YTickLabelFormat);
                        end
                    case 'none'
                        for ii = 1:size(ax,1)
                            kr = mod(ii-1,this.NVisibleSubGridRows)+1;
                            for jj = 1:size(ax,2)
                                switch yLimitsMode{ii,jj}
                                    case 'auto'
                                        this.shareLimits(ax(ii,jj),yLimitsFocus(ii,jj),...
                                            AutoAdjust=this.AutoAdjustYLimits,Scale=yScale(kr),...
                                            AutoLimitBase=yLimitPickerBase(kr),Axis="y");
                                    case 'manual'
                                        ax(ii,jj).YLim=yLimits{ii,jj};
                                end
                            end
                        end

                        if this.ShowYTickLabels
                            set(yRulers,TickLabelMode="auto",TickLabelFormat=this.YTickLabelFormat);
                        end
                end

                ax = this.Axes;
                yLim = cell(size(ax));
                for ii = 1:numel(ax)
                    yLim{ii} = ax(ii).YLim;
                end
                this.AllYLimits = yLim;

                updateTicks(this,UpdateXTicks=false);
            end
        end

        function updateTicks(this,optionalArguments)
            arguments
                this (1,1) controllib.chart.internal.layout.LimitManager
                optionalArguments.UpdateXTicks (1,1) logical = true
                optionalArguments.UpdateYTicks (1,1) logical = true
            end
            ax = this.VisibleAxes;
            if isempty(ancestor(this.TiledLayout,'figure')) || isempty(ax)
                return; % auto tick values not computed until figure exists
            end
            % Add custom tick if base/increment is anything other than 10
            if optionalArguments.UpdateXTicks && this.XRulerType == "numeric"
                % Set tickMode to 'auto'
                set(ax,XTickMode="auto");
                bases = zeros(size(ax,2),1);
                for ii = 1:size(ax,2)
                    bases(ii) = this.XLimitPickerBase(mod(ii-1,this.NVisibleSubGridColumns)+1);
                end
                customTickAx = ax(:,bases~=10);
                if ~isempty(customTickAx)
                    bases = bases(bases~=10);
                    xLimits = get(customTickAx,"XLim");
                    if iscell(xLimits)
                        xLimits = reshape(xLimits,size(customTickAx));
                    else
                        xLimits = {xLimits};
                    end
                    % Get XTickValues (do not need to query all axes if
                    % XLimitsSharing is not "none" - this improves
                    % performance due to fewer updates)
                    switch this.AxesGrid.XLimitsSharing
                        case "all"
                            xTickValues = {get(customTickAx(1,1),"XTick")};
                        case "column"
                            xTickValues = get(customTickAx(1,:),"XTick");
                            if iscell(xTickValues)
                                xTickValues = repmat(xTickValues(:)',size(customTickAx,1),1);
                            else
                                xTickValues = {xTickValues};
                            end
                        case "none"
                            xTickValues = get(customTickAx,"XTick");
                            if iscell(xTickValues)
                                xTickValues = reshape(xTickValues,size(customTickAx));
                            else
                                xTickValues = {xTickValues};
                            end
                    end

                    newTickValues = cell(size(xTickValues));
                    % Compute new tick values based on increment and tick values picked by axes
                    for ii = 1:size(xTickValues,1)
                        for jj = 1:size(xTickValues,2)
                            newTickValues{ii,jj} = this.getTicks(xTickValues{ii,jj},xLimits{ii,jj},bases(jj));
                        end
                    end
                    set(customTickAx(:),{"XTick"},newTickValues(:));
                end
            end
            % Add custom tick if base/increment is anything other than 10
            if optionalArguments.UpdateYTicks && this.YRulerType == "numeric"
                % Set tickMode to 'auto'
                set(ax,YTickMode="auto");
                bases = zeros(size(ax,1),1);
                for ii = 1:size(ax,1)
                    bases(ii) = this.YLimitPickerBase(mod(ii-1,this.NVisibleSubGridRows)+1);
                end
                customTickAx = ax(bases~=10,:);
                if ~isempty(customTickAx)
                    bases = bases(bases~=10);
                    yLimits = get(customTickAx,"YLim");
                    if iscell(yLimits)
                        yLimits = reshape(yLimits,size(customTickAx));
                    else
                        yLimits = {yLimits};
                    end
                    
                    % Get YTickValues (do not need to query all axes if
                    % YLimitsSharing is not "none" - this improves
                    % performance due to fewer updates)
                    switch this.AxesGrid.YLimitsSharing
                        case "all"
                            yTickValues = {get(customTickAx(1,end),"YTick")};
                        case "row"
                            yTickValues = get(customTickAx(:,end),"YTick");
                            if iscell(yTickValues)
                                yTickValues = repmat(yTickValues,1,size(customTickAx,2));
                            else
                                yTickValues = {yTickValues};
                            end
                        case "none"
                            yTickValues = get(customTickAx,"YTick");
                            if iscell(yTickValues)
                                yTickValues = reshape(yTickValues,size(customTickAx));
                            else
                                yTickValues = {yTickValues};
                            end
                    end

                    newTickValues = cell(size(yTickValues));
                    % Compute new tick values based on increment and tick values picked by axes
                    for ii = 1:size(yTickValues,1)
                        for jj = 1:size(yTickValues,2)
                            newTickValues{ii,jj} = this.getTicks(yTickValues{ii,jj},yLimits{ii,jj},bases(ii));
                        end
                    end
                    set(customTickAx(:),{"YTick"},newTickValues(:));
                end
            end
        end

        function xlimits = computeInitialXLimits(this)
            xlimits = this.XLimitsFocus;
            switch this.XLimitsSharing
                case 'all'
                    for jj = 1:this.SubGridSize(2)
                        subXLimits = xlimits(:,jj:this.GridSize(2):end);
                        xRangeValue = cell2mat(subXLimits(:));
                        xRangeMin = min(xRangeValue(:,1));
                        xRangeMax = max(xRangeValue(:,2));
                        if this.XRulerType == "numeric" && this.AutoAdjustXLimits
                            xLim = this.getAutoAdjustedLimits([xRangeMin, xRangeMax],Scale=this.XScale(jj));
                        else
                            xLim = [xRangeMin, xRangeMax];
                        end
                        xlimits(:,jj:this.GridSize(2):end) = {xLim};
                    end
                case 'column'
                    for ii = 1:size(xlimits,1)
                        for jj = 1:this.SubGridSize(2)
                            subXLimits = xlimits(ii,jj:this.GridSize(2):end);
                            xRangeValue = cell2mat(subXLimits(:));
                            xRangeMin = min(xRangeValue(:,1));
                            xRangeMax = max(xRangeValue(:,2));
                            if this.XRulerType == "numeric" && this.AutoAdjustXLimits
                                xLim = this.getAutoAdjustedLimits([xRangeMin, xRangeMax],Scale=this.XScale(jj));
                            else
                                xLim = [xRangeMin, xRangeMax];
                            end
                            xlimits(ii,jj:this.GridSize(2):end) = {xLim};
                        end
                    end
                case 'none'
                    for ii = 1:size(xlimits,1)
                        for jj = 1:size(xlimits,2)
                            kc = mod(jj-1,this.SubGridSize(2))+1;
                            if this.XRulerType == "numeric" && this.AutoAdjustXLimits
                                xLim = this.getAutoAdjustedLimits(xlimits{ii,jj},Scale=this.XScale(kc));
                            else
                                xLim = xlimits{ii,jj};
                            end
                            xlimits(ii,jj) = {xLim};
                        end
                    end
            end
        end

        function ylimits = computeInitialYLimits(this)
            ylimits = this.YLimitsFocus;
            switch this.YLimitsSharing
                case 'all'
                    for ii = 1:this.SubGridSize(1)
                        subYLimits = ylimits(ii:this.GridSize(1):end,:);
                        yRangeValue = cell2mat(subYLimits(:));
                        yRangeMin = min(yRangeValue(:,1));
                        yRangeMax = max(yRangeValue(:,2));
                        if this.YRulerType == "numeric" && this.AutoAdjustYLimits
                            yLim = this.getAutoAdjustedLimits([yRangeMin, yRangeMax],Scale=this.YScale(ii));
                        else
                            yLim = [yRangeMin, yRangeMax];
                        end
                        ylimits(ii:this.GridSize(1):end,:) = {yLim};
                    end
                case 'row'
                    for ii = 1:this.SubGridSize(1)
                        for jj = 1:size(ylimits,2)
                            subYLimits = ylimits(ii:this.GridSize(1):end,jj);
                            yRangeValue = cell2mat(subYLimits(:));
                            yRangeMin = min(yRangeValue(:,1));
                            yRangeMax = max(yRangeValue(:,2));
                            if this.YRulerType == "numeric" && this.AutoAdjustYLimits
                                yLim = this.getAutoAdjustedLimits([yRangeMin, yRangeMax],Scale=this.YScale(ii));
                            else
                                yLim = [yRangeMin, yRangeMax];
                            end
                            ylimits(ii:this.GridSize(1):end,jj) = {yLim};
                        end
                    end
                case 'none'
                    for ii = 1:size(ylimits,1)
                        kr = mod(ii-1,this.SubGridSize(1))+1;
                        for jj = 1:size(ylimits,2)
                            if this.YRulerType == "numeric" && this.AutoAdjustYLimits
                                yLim = this.getAutoAdjustedLimits(ylimits{ii,jj},Scale=this.YScale(kr));
                            else
                                yLim = ylimits{ii,jj};
                            end
                            ylimits(ii,jj) = {yLim};
                        end
                    end
            end
        end
    end

    %% Hidden static methods
    methods (Hidden,Static)
        function shareLimits(ax,limitValue,optionalArguments)
            arguments
                ax (:,:) matlab.graphics.axis.Axes {mustBeNonempty}
                limitValue (:,:) cell {mustBeNonempty}
                optionalArguments.Axis (1,1) string {mustBeMember(optionalArguments.Axis,["x";"y"])} = "x"
                optionalArguments.AutoAdjust (1,1) logical = true
                optionalArguments.Scale (1,1) string {mustBeMember(optionalArguments.Scale,["linear";"log"])} = "linear"
                optionalArguments.AutoLimitBase (1,1) double = 10
            end

            switch optionalArguments.Axis
                case "x"
                    rulers = [ax.XAxis];
                case "y"
                    % Only use left Y ruler
                    rulers = localGetLeftYAxis(ax);
            end

            switch class(rulers)
                case "matlab.graphics.axis.decorator.NumericRuler"
                    rulerType = "numeric";
                case "matlab.graphics.axis.decorator.DurationRuler"
                    rulerType = "duration";
                case "matlab.graphics.axis.decorator.DatetimeRuler"
                    rulerType = "datetime";
            end

            % Get range from min/max of limitValue
            switch rulerType
                case "numeric"
                    rangeMin = NaN;
                    rangeMax = NaN;
                case "duration"
                    rangeMin = duration(NaN,NaN,NaN);
                    rangeMax = duration(NaN,NaN,NaN);
                case "datetime"
                    rangeMin = NaT;
                    rangeMax = NaT;
            end

            for k = 1:numel(limitValue(:))
                rangeMin = min([rangeMin,limitValue{k}(1)]);
                rangeMax = max([rangeMax,limitValue{k}(2)]);
            end

            % Check for NaNs
            switch rulerType
                case "numeric"
                    if isnan(rangeMin) && isnan(rangeMax)
                        switch optionalArguments.Scale
                            case "linear"
                                rangeMin = 0;
                            case "log"
                                rangeMin = 0;
                        end
                        rangeMax = 1;
                    elseif isnan(rangeMin)
                        switch optionalArguments.Scale
                            case "linear"
                                rangeMin = min(0,0.1*rangeMax);
                            case "log"
                                rangeMin = min(0,0.1*rangeMax);
                        end
                    elseif isnan(rangeMax)
                        rangeMax = max(1,10*rangeMin);
                    end
                    if optionalArguments.Scale == "log"
                        if rangeMin < 0 
                            rangeMin = 0;
                        end
                        if rangeMax <= rangeMin
                            rangeMax = 10*rangeMin;
                            if rangeMax == 0
                                rangeMax = realmin;
                            end
                        end
                    end
                case "duration"
                    if isnan(rangeMin) && isnan(rangeMax)
                        rangeMin = days(0);
                        rangeMax = days(1);
                    elseif isnan(rangeMin)
                        rangeMin = days(min(0,0.1*days(rangeMax)));
                    elseif isnan(rangeMax)
                        rangeMax = days(max(1,10*days(rangeMin)));
                    end
                case "datetime"
                    timeStart = datetime(0,ConvertFrom='posixtime');
                    if isnat(rangeMin) && isnat(rangeMax)
                        rangeMin = timeStart;
                        rangeMax = timeStart+days(1);
                    elseif isnat(rangeMin)
                        if timeStart < rangeMax
                            rangeMin = timeStart;
                        else
                            rangeMin = rangeMax-days(1);
                        end
                    elseif isnat(rangeMax)
                        if timeStart+days(1) > rangeMin
                            rangeMax = timeStart+days(1);
                        else
                            rangeMax = rangeMin+days(1);
                        end
                    end
            end

            % Get limits from range
            if rulerType == "numeric" && optionalArguments.AutoAdjust
                limitsToSet = controllib.chart.internal.layout.LimitManager.getAutoAdjustedLimits([rangeMin, rangeMax],...
                    Scale=optionalArguments.Scale,Base=optionalArguments.AutoLimitBase);
            else
                limitsToSet = [rangeMin, rangeMax];
            end

            % Set limits on rulers
            try
                set(rulers,Limits=limitsToSet);
            catch ME
                throw(ME)
            end
        end

        function [limits,tickSpacing] = getAutoAdjustedLimits(range,optionalArguments)
            % getAutoAdjustedLimits Get rounded numeric limit values based on data range for plotting purposes
            %
            % limits = getAutoAdjustedLimits(range) outputs the rounded limits based on input
            % range. range must be a 2 element, monotonically increasing, numeric
            % vector of real values.
            %
            % limits = getAutoAdjustedLimits(range,MaxTicks=numberOfMaximumTicks) will use the
            % numberOfMaximumTicks to compute the spacing between the tick values.
            % numberOfMaximumTicks must be a positive, real integer and the default
            % value is 10.
            %
            % limits = getAutoAdjustedLimits(range,Scale=scale) will use the scale ("linear" or
            % "log") to compute the rounded limits appropriately. The default value is
            % "linear".
            %
            % limits = getAutoAdjustedLimits(range,Base=baseValue) will use baseValue to compute
            % the exponent and fraction values used to round the the range. baseValue
            % must be numeric, positive value and the default is 10.
            arguments
                range (1,2)
                optionalArguments.MaxTicks (1,1) double {mustBePositive,mustBeInteger} = 10
                optionalArguments.Scale (1,1) string {mustBeMember(optionalArguments.Scale,["linear";"log"])} = "linear"
                optionalArguments.Base (1,1) = 10
            end
            maxTicks = optionalArguments.MaxTicks;
            scale = optionalArguments.Scale;
            base = optionalArguments.Base;

            switch scale
                case 'linear'
                    minRange = range(1);
                    maxRange = range(2);
                case 'log'
                    minRange = log10(range(1));
                    maxRange = log10(range(2));
            end

            if isinf(minRange) || isinf(maxRange)
                % If range contains Inf, set the limits to realmin/realmax
                limits = range;
                tickSpacing = [];
                if isinf(minRange)
                    if strcmp(scale,'linear')
                        limits(1) = realmin;
                    else
                        limits(1) = 0;
                    end
                    limits(2) = max(limits(2),10*limits(1));
                end
                if isinf(maxRange)
                    limits(2) = realmax;
                    limits(1) = min(limits(1),limits(2)/10);
                end
                return
            elseif minRange == maxRange
                minRange = 0.9*minRange;
                maxRange = 1.1*maxRange;
            end

            range = localRounding(maxRange - minRange,false,base);
            tickSpacing = localRounding(range/(maxTicks-1),true,base);
            minLim = floor(minRange/tickSpacing)*tickSpacing;
            maxLim = ceil(maxRange/tickSpacing)*tickSpacing;
            limits = [minLim,maxLim];

            if strcmpi(scale,"log")
                limits = [10^minLim, 10^maxLim];
            end

            function roundValue = localRounding(value,roundFlag,base)
                exponent = floor(log10(value)/(log10(base)));
                fraction = value / (base^exponent);
                if roundFlag
                    if fraction < 1.5
                        niceFraction = 1;
                    elseif fraction < 3
                        niceFraction = 2;
                    elseif fraction < 7
                        niceFraction = 5;
                    else
                        niceFraction = 10;
                    end
                else
                    if fraction <= 1
                        niceFraction = 1;
                    elseif fraction <= 2
                        niceFraction = 2;
                    elseif fraction <= 5
                        niceFraction = 5;
                    else
                        niceFraction = 10;
                    end
                end
                roundValue = niceFraction * base^exponent;
            end
        end

        function ticks = getTicks(ticks,limits,increment)
            arguments
                ticks (1,:) double
                limits (1,2) double
                increment (1,1) double
            end

            % Determine range within axes limits
            if abs(limits(2) - limits(1)) < increment/5
                % Min range to prevent 0 extent and noisy display
                limits = round((limits(1)+limits(2))/2) + [-increment/10, increment/10];
            end

            % Determine number of sections
            ns = (limits(2) - limits(1))/increment;

            % Determine maximum number of tick sections
            nticks = max([1, ((limits(2)-limits(1))./(max(diff(ticks))))]);

            % If both limits are multiple of 2*increment, then reduce the number of ticks by 2.
            if ~any(logical(mod(limits,2*increment))) && nticks > 4
                nticks = nticks - 2;
            end
            % Override axes default when variation exceeds increment
            if ns > 1
                if ns <= 2
                    if mod(increment,3) == 0
                        period = (2/3)*increment;
                    else
                        period = (1/2)*increment;
                    end
                else
                    k = round(log2(ns/nticks));
                    period = increment * 2^max(0,k);
                end

                % Reset limits taking true range into account
                limits(1) = period*floor(limits(1)/period);
                limits(2) = period*ceil(limits(2)/period);

                % Generate new ticks
                ticks = limits(1):period:limits(2);
            end
        end
    end
end

function yRulers = localGetLeftYAxis(ax)
allRulers = get(ax,'YAxis');
if ~isscalar(ax)
    allRulers = reshape(allRulers,size(ax));
else
    allRulers = {allRulers};
end

yRulers = [];
for k = 1:length(allRulers(:))
    yRulers = [yRulers; allRulers{k}(1)]; %#ok<AGROW>
end
end