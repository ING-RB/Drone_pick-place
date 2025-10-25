classdef TiledLayoutManager < matlab.mixin.SetGet & controllib.chart.internal.foundation.MixInListeners
    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (Access=?controllib.chart.internal.layout.AxesGrid)
        Enabled (1,1) matlab.lang.OnOffSwitchState = true
        
    end

    properties (Dependent,Access=?controllib.chart.internal.layout.AxesGrid)
        CurrentInteractionMode (1,1) string
    end

    % Read & Write
    properties (Dependent,Access=private)
        SubTiledLayouts
        Axes
    end

    % Read-only
    properties (Dependent,Access=private)
        TiledLayout
        VisibleSubTiledLayouts
        VisibleAxes
        GridSize
        SubGridSize
        NVisibleGridRows
        NVisibleGridColumns
        NVisibleSubGridRows
        NVisibleSubGridColumns
        ToolbarButtons
        InteractionOptions
        NextPlot
        EnableDefaultInteractions
    end

    properties (Access=private,WeakHandle)
        AxesGrid controllib.chart.internal.layout.AxesGrid {mustBeScalarOrEmpty}
    end

    properties (Access=private)
        AxesForToolbar
        IsDefaultInteractionsEnabledForAxes
    end

    %% Events
    events (ListenAccess=?controllib.chart.internal.layout.AxesGrid,NotifyAccess=private)
        GridSizeChanged
        NextPlotSet
        XLimChanged
        YLimChanged
        XLimModeChanged
        YLimModeChanged
        AxesHit
        AxesReset
        InteractionOptionsChanged
        RestoreBtnPushed        
    end

    %% Constructor
    methods
        function this = TiledLayoutManager(axesGrid,savedAxes)
            arguments
                axesGrid (1,1) controllib.chart.internal.layout.AxesGrid
                savedAxes matlab.graphics.axis.Axes {mustBeScalarOrEmpty}
            end
            this.AxesGrid = axesGrid;

            this.TiledLayout.TileArrangementInternal = 'fixed';
            this.TiledLayout.Serializable = 'on';
            this.TiledLayout.PositionConstraint = 'outerposition';
            this.TiledLayout.TileIndexing = 'rowmajor';
            this.TiledLayout.GridSizeInternal = [1 1];

            updateToolbar(this);

            nRows = this.AxesGrid.GridSize(1);
            nColumns = this.AxesGrid.GridSize(2);
            this.SubTiledLayouts = createSubTiledChartLayouts(this,nRows,nColumns);

            nRows = nRows*this.AxesGrid.SubGridSize(1);
            nColumns = nColumns*this.AxesGrid.SubGridSize(2);
            this.Axes = createAxes(this,nRows,nColumns,savedAxes);

            if this.EnableDefaultInteractions
                this.IsDefaultInteractionsEnabledForAxes = true(size(this.Axes));
            else
                this.IsDefaultInteractionsEnabledForAxes = false(size(this.Axes));
            end
        end
    end

    %% Get/Set
    methods
        % TiledLayout
        function TiledLayout = get.TiledLayout(this)
            TiledLayout = this.AxesGrid.TiledLayout;
        end

        % SubTiledLayouts
        function SubTiledLayouts = get.SubTiledLayouts(this)
            SubTiledLayouts = this.AxesGrid.SubTiledLayouts;
        end

        function set.SubTiledLayouts(this,SubTiledLayouts)
            this.AxesGrid.SubTiledLayouts = SubTiledLayouts;
        end

        % Axes
        function Axes = get.Axes(this)
            Axes = this.AxesGrid.Axes;
        end

        function set.Axes(this,Axes)
            this.AxesGrid.Axes = Axes;
        end

        % VisibleSubTiledLayouts
        function VisibleSubTiledLayouts = get.VisibleSubTiledLayouts(this)
            VisibleSubTiledLayouts = this.AxesGrid.VisibleSubTiledLayouts;
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

        % NVisibleGridRows
        function NVisibleGridRows = get.NVisibleGridRows(this)
            NVisibleGridRows = this.AxesGrid.NVisibleGridRows;
        end

        % NVisibleGridColumns
        function NVisibleGridColumns = get.NVisibleGridColumns(this)
            NVisibleGridColumns = this.AxesGrid.NVisibleGridColumns;
        end

        % NVisibleSubGridRows
        function NVisibleSubGridRows = get.NVisibleSubGridRows(this)
            NVisibleSubGridRows = this.AxesGrid.NVisibleSubGridRows;
        end

        % NVisibleSubGridColumns
        function NVisibleSubGridColumns = get.NVisibleSubGridColumns(this)
            NVisibleSubGridColumns = this.AxesGrid.NVisibleSubGridColumns;
        end

        % ToolbarButtons
        function ToolbarButtons = get.ToolbarButtons(this)
            ToolbarButtons = this.AxesGrid.ToolbarButtons;
        end

        % InteractionOptions
        function InteractionOptions = get.InteractionOptions(this)
            InteractionOptions = this.AxesGrid.InteractionOptions;
        end

        % NextPlot
        function NextPlot = get.NextPlot(this)
            NextPlot = this.AxesGrid.NextPlot;
        end

        % EnableInteractions
        function EnableInteractions = get.EnableDefaultInteractions(this)
            nVisibleRows = this.NVisibleGridRows * this.NVisibleSubGridRows;
            nVisibleColumns = this.NVisibleGridColumns * this.NVisibleSubGridColumns;
            EnableInteractions = nVisibleRows < 10 & nVisibleColumns < 14;
        end

        % CurrentInteractionsMode
        function currentInteractionMode = get.CurrentInteractionMode(this)
            if ~isempty(this.Axes) && isvalid(this.Axes(1))
                currentInteractionMode = string(this.Axes(1).InteractionContainer.CurrentMode);
            else
                currentInteractionMode = "none";
            end
        end

        function set.CurrentInteractionMode(this,currentInteractionMode)
            arguments
                this
                currentInteractionMode (1,1) string ...
                    {mustBeMember(currentInteractionMode,["none","pan","zoom","datacursor"])}
            end
            setCurrentInteractionsModeOnAxes(this,currentInteractionMode);
            syncToolbarWithCurrentInteractionsMode(this,currentInteractionMode);
        end

    end

    %% AxesGrid methods
    methods (Access=?controllib.chart.internal.layout.AxesGrid)
        function update(this)
            if this.Enabled
                isVisible = this.TiledLayout.Visible;
                this.TiledLayout.Visible = false;
                this.TiledLayout.GridSizeInternal = max([this.NVisibleGridRows this.NVisibleGridColumns],1);
                numSubTCLChanged = updateSubTiledLayouts(this);
                numAxesChanged = updateAxes(this);
                this.TiledLayout.Visible = isVisible;
                if numSubTCLChanged || numAxesChanged
                    notify(this,"GridSizeChanged");
                end

                [nNewRows,nNewColumns] = size(this.Axes);
                [nRows,nColumns] = size(this.IsDefaultInteractionsEnabledForAxes);
                if nNewRows > nRows
                    this.IsDefaultInteractionsEnabledForAxes = [this.IsDefaultInteractionsEnabledForAxes; false(nNewRows-nRows,nColumns)];
                end

                nRows = size(this.IsDefaultInteractionsEnabledForAxes,1);
                if nNewColumns > nColumns
                    this.IsDefaultInteractionsEnabledForAxes = [this.IsDefaultInteractionsEnabledForAxes, false(nRows,nNewColumns-nColumns)];
                end

                this.IsDefaultInteractionsEnabledForAxes = this.IsDefaultInteractionsEnabledForAxes(1:nNewRows,1:nNewColumns);

                updateInteractions(this,UpdateOnlyVisibleAxes=true);
            end
        end

        function updateToolbar(this)
            % Create toolbar if ToolbarButtons is not "none"
            if any(strcmp(this.ToolbarButtons,"default"))
                % Need to use a custom default set because the
                % tiledlayout/axes does not have any data yet. This does
                % mean that AxesGrid 'default' could be different from a
                % regular 2d cartesian axes default in the future.
                [~,btns] = axtoolbar(this.TiledLayout,...
                    ["export","datacursor","pan","zoomin","zoomout","restoreview"]);
            elseif ~any(strcmp(this.ToolbarButtons,"none"))
                [~,btns] = axtoolbar(this.TiledLayout,cellstr(this.ToolbarButtons));
            else
                this.TiledLayout.Toolbar = [];
                btns = [];
            end

            if ~isempty(this.TiledLayout.Toolbar)
                % Customize the restoreview callback if a toolbar is
                % created.
                restoreBtn = findobj(btns, "Tag", "restoreview");
                if ~isempty(restoreBtn)
                    weakThis = matlab.lang.WeakReference(this);
                    restoreBtn.ButtonPushedFcn = @(es,ed) cbRestoreBtnPushed(weakThis.Handle,ed);
                end
            end
        end

        function updateInteractions(this,optionalArguments)
            arguments
                this
                optionalArguments.UpdateOnlyVisibleAxes = false
            end


            ax = this.Axes;
            allVisible = this.AxesGrid.AllRowVisible * this.AxesGrid.AllColumnVisible;

            if this.EnableDefaultInteractions
                for ii = 1:numel(ax)
                    if ~optionalArguments.UpdateOnlyVisibleAxes || (allVisible(ii) && ~this.IsDefaultInteractionsEnabledForAxes(ii))
                        enableDefaultInteractivity(ax(ii));
                        ax(ii).InteractionOptions = this.InteractionOptions;
                        this.IsDefaultInteractionsEnabledForAxes(ii) = true;
                    end
                end
            end
        end

        function disableInteractions(this)
            ax = this.Axes;
            for ii = 1:numel(ax)
                disableDefaultInteractivity(ax(ii));
            end
        end

    end

    %% Private methods
    methods (Access = private)
        function newTCLs = createSubTiledChartLayouts(this,nRows,nColumns)
            subGridSize = max([this.NVisibleSubGridRows, ...
                this.NVisibleSubGridColumns],1);
            newTCLs = gobjects([nRows,nColumns]);
            for ii = 1:numel(newTCLs)
                newTCLs(ii) = matlab.graphics.layout.TiledChartLayout(Padding="tight",TileSpacing="compact",GridSize=subGridSize);
            end
        end

        function newAxes = createAxes(this,nRows,nColumns,savedAxes)
            arguments
                this (1,1) controllib.chart.internal.layout.TiledLayoutManager
                nRows (1,1) double {mustBeInteger,mustBePositive}
                nColumns (1,1) double {mustBeInteger,mustBePositive}
                savedAxes matlab.graphics.axis.Axes {mustBeScalarOrEmpty} = matlab.graphics.axis.Axes.empty
            end
            % Create axes
            newAxes = gobjects([nRows,nColumns]);
            for ii = 1:numel(newAxes)
                if ii == 1 && ~isempty(savedAxes)
                    % Use saved axes
                    ax = savedAxes;
                    cla(ax,'reset');
                    ax.Parent = [];
                    ax.Layout = [];
                    ax.Visible = 'off';
                    ax.NextPlot = this.NextPlot;
                else
                    % Create single axes
                    ax = matlab.graphics.axis.Axes(Visible='off',NextPlot=this.NextPlot);
                end

                % Leave axes alone if DefaultAxesInteractionsSet, assign
                % appropriate Interactions objects otherwise
                if this.EnableDefaultInteractions
                    ax.InteractionOptions = this.InteractionOptions;
                else
                    disableDefaultInteractivity(ax);
                end

                % Remove toolbar (added to tiledlayout)
                ax.Toolbar = [];

                newAxes(ii) = ax;
            end
        end


        function numSubTCLChanged = updateSubTiledLayouts(this)
            % Adjust Rows
            rowDiff = this.GridSize(1) - size(this.SubTiledLayouts,1);
            if rowDiff > 0
                nCols = size(this.SubTiledLayouts,2);
                newTCLs = createSubTiledChartLayouts(this,rowDiff,nCols);
                this.SubTiledLayouts = [this.SubTiledLayouts;newTCLs];
            elseif rowDiff < 0
                delete(this.SubTiledLayouts(end+rowDiff+1:end,:));
                this.SubTiledLayouts = reshape(this.SubTiledLayouts(isvalid(this.SubTiledLayouts)),this.GridSize(1),[]);
            end

            % Adjust Columns
            colDiff = this.GridSize(2) - size(this.SubTiledLayouts,2);
            if colDiff > 0
                nRows = size(this.SubTiledLayouts,1);
                newTCLs = createSubTiledChartLayouts(this,nRows,colDiff);
                this.SubTiledLayouts = [this.SubTiledLayouts,newTCLs];
            elseif colDiff < 0
                delete(this.SubTiledLayouts(:,end+colDiff+1:end));
                this.SubTiledLayouts = reshape(this.SubTiledLayouts(isvalid(this.SubTiledLayouts)),this.GridSize(1),this.GridSize(2));
            end

            numSubTCLChanged = rowDiff ~= 0 || colDiff ~= 0;
            set(this.SubTiledLayouts,GridSizeInternal=max([this.NVisibleSubGridRows this.NVisibleSubGridColumns],1));

            % Parent
            visibleTCLs = this.VisibleSubTiledLayouts;
            set(setdiff(this.SubTiledLayouts,visibleTCLs),Parent=[],Visible=false);
            set(visibleTCLs,Parent=this.TiledLayout,Visible=true);
            for ii = 1:size(visibleTCLs,1)
                for jj = 1:size(visibleTCLs,2)
                    visibleTCLs(ii,jj).Layout.Tile = (ii-1)*size(visibleTCLs,2)+jj;
                end
            end
        end

        function numAxesChanged = updateAxes(this)
            % Adjust Rows
            rowDiff = this.GridSize(1)*this.SubGridSize(1) - size(this.Axes,1);
            if rowDiff > 0
                nCols = size(this.Axes,2);
                newAxes = createAxes(this,rowDiff,nCols);
                this.Axes = [this.Axes;newAxes];
            elseif rowDiff < 0
                delete(this.Axes(end+rowDiff+1:end,:));
                this.Axes = reshape(this.Axes(isvalid(this.Axes)),this.GridSize(1)*this.SubGridSize(1),[]);
            end

            % Adjust Columns
            colDiff = this.GridSize(2)*this.SubGridSize(2) - size(this.Axes,2);
            if colDiff > 0
                nRows = size(this.Axes,1);
                newAxes = createAxes(this,nRows,colDiff);
                this.Axes = [this.Axes,newAxes];
            elseif colDiff < 0
                delete(this.Axes(:,end+colDiff+1:end));
                this.Axes = reshape(this.Axes(isvalid(this.Axes)),this.GridSize(1)*this.SubGridSize(1),this.GridSize(2)*this.SubGridSize(2));
            end

            numAxesChanged = rowDiff ~= 0 || colDiff ~= 0;
            addAxesListeners(this);

            % Parent
            visibleAxes = this.VisibleAxes;
            set(setdiff(this.Axes,visibleAxes),Parent=[],Visible=false);

            for kr = 1:size(this.VisibleSubTiledLayouts,1)
                rowIdx = (kr-1)*this.NVisibleSubGridRows+1:kr*this.NVisibleSubGridRows;
                for kc = 1:size(this.VisibleSubTiledLayouts,2)
                    colIdx = (kc-1)*this.NVisibleSubGridColumns+1:kc*this.NVisibleSubGridColumns;
                    tclAx = this.VisibleAxes(rowIdx,colIdx);
                    set(tclAx,Parent=this.VisibleSubTiledLayouts(kr,kc),Visible=true);
                    for ii = 1:size(tclAx,1)
                        for jj = 1:size(tclAx,2)
                            tclAx(ii,jj).Layout.Tile = (ii-1)*size(tclAx,2)+jj;
                        end
                    end
                end
            end
        end

        function addAxesListeners(this)
            ax = this.Axes;
            weakThis = matlab.lang.WeakReference(this);
            unregisterListeners(this,["NextPlot";"XLim";"YLim";"AxesReset";"AxesHit"]);
            for kr = 1:size(ax,1)
                for kc = 1:size(ax,2)
                    ax_k = ax(kr,kc);
                    weakAx_k = matlab.lang.WeakReference(ax_k);
                    % NextPlot listener
                    L1 = addlistener(ax_k,'NextPlot','PostSet',@(es,ed) cbAxesEvent(weakThis.Handle,weakAx_k.Handle,'NextPlotSet'));
                    % XLim/YLim listener
                    L2 = addlistener(ax_k,'XLim','PostSet',@(es,ed) cbAxesEvent(weakThis.Handle,weakAx_k.Handle,'XLimChanged'));
                    L3 = addlistener(ax_k,'YLim','PostSet',@(es,ed) cbAxesEvent(weakThis.Handle,weakAx_k.Handle,'YLimChanged'));
                    % XLimMode/YLimMode listener
                    L4 = addlistener(ax_k,'XLimMode','PostSet',@(es,ed) cbAxesEvent(weakThis.Handle,weakAx_k.Handle,'XLimModeChanged'));
                    L5 = addlistener(ax_k,'YLimMode','PostSet',@(es,ed) cbAxesEvent(weakThis.Handle,weakAx_k.Handle,'YLimModeChanged'));
                    % Axes Hit Listener
                    L6 = addlistener(ax_k,'Hit',@(es,ed) cbAxesEvent(weakThis.Handle,weakAx_k.Handle,'AxesHit'));
                    % Reset Listener
                    L7 = addlistener(ax_k,'Cla',@(es,ed) cbAxesEvent(weakThis.Handle,weakAx_k.Handle,'AxesReset'));
                    % InteractionOptions listener
                    L8 = addlistener(ax_k,'InteractionOptions','PostSet',@(es,ed) cbAxesEvent(weakThis.Handle,weakAx_k.Handle,'InteractionOptionsChanged'));
                    registerListeners(this,[L1;L2;L3;L4;L5;L6;L7;L8],["NextPlot";"XLim";"YLim";"XLimMode";"YLimMode";"AxesHit";"AxesReset";"InteractionOptions"]);
                end
            end
        end

        function cbAxesEvent(this,ax,eventName)
            Data.Axes = ax;
            ed = controllib.chart.internal.utils.GenericEventData(Data);
            notify(this,eventName,ed);
        end

        function cbRestoreBtnPushed(this,ed)
            Data.Source = this.AxesGrid;
            Data.Axes = ed.Axes;
            Data.EventName = "RestoreBtnPushed";
            ed = controllib.chart.internal.utils.GenericEventData(Data);
            notify(this,"RestoreBtnPushed",ed);
        end

        function setCurrentInteractionsModeOnAxes(this,currentInteractionMode)
            if ~isempty(this.Axes)
                for k = 1:numel(this.Axes)
                    switch currentInteractionMode
                        case "zoom"
                            zoom(this.Axes(k),'on');
                        case "pan"
                            pan(this.Axes(k),'on');
                        case "datacursor"
                            datacursormode(this.Axes(k),'on');
                        case "none"
                            zoom(this.Axes(k),'off');
                            pan(this.Axes(k),'off');
                            datacursormode(this.Axes(k),'off');
                    end
                end
            end
        end

        function syncToolbarWithCurrentInteractionsMode(this,currentInteractionMode)
            if ~isempty(this.TiledLayout.Toolbar)
                panButton = findobj(this.TiledLayout.Toolbar.Children,Tag="pan");
                zoomInButton = findobj(this.TiledLayout.Toolbar.Children,Tag="zoomin");
                zoomOutButton = findobj(this.TiledLayout.Toolbar.Children,Tag="zoomout");
                dataCursorButton = findobj(this.TiledLayout.Toolbar.Children,Tag="datacursor");
                
                zoomOutButton.Value = 'off';
                switch currentInteractionMode
                    case "none"
                        dataCursorButton.Value = 'off';
                        panButton.Value = 'off';
                        zoomInButton.Value = 'off';
                    case "zoom"
                        dataCursorButton.Value = 'off';
                        zoomInButton.Value = 'on';
                        panButton.Value = 'off';
                    case "pan"
                        dataCursorButton.Value = 'off';
                        zoomInButton.Value = 'off';
                        panButton.Value = 'on';
                    case "datacursor"
                        panButton.Value = 'off';
                        zoomInButton.Value = 'off';
                        dataCursorButton.Value = 'on';
                end
            end
        end
    end

end
