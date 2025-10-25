classdef AxesGrid < matlab.mixin.SetGet & controllib.chart.internal.foundation.MixInListeners & matlab.mixin.CustomDisplay
    % AxesGrid - object to create and manage axes for a tiled layout

    % Copyright 2022-2024 The MathWorks, Inc.
    
    %% Properties
    properties (Dependent,SetObservable)
        NextPlot

        XLimits
        XLimitsMode
        YLimits
        YLimitsMode
        XLimitsFocus
        YLimitsFocus
    end
    
    properties (Dependent, SetObservable, AbortSet)
        Parent
        Position
        OuterPosition
        Padding
        Spacing
        Visible

        Title
        TitleVisible
        Subtitle
        SubtitleVisible
        XLabel
        XLabelVisible
        YLabel
        YLabelVisible

        GridRowLabels
        GridColumnLabels
        GridRowLabelsVisible
        GridColumnLabelsVisible
        SubGridRowLabels
        SubGridColumnLabels
        SubGridRowLabelsVisible
        SubGridColumnLabelsVisible

        GridSize
        GridRowVisible
        GridColumnVisible

        SubGridSize
        SubGridRowVisible
        SubGridColumnVisible

        XRulerType
        XLimitsSharing
        XScale
        XLimitPickerBase
        AutoAdjustXLimits
        ShowXTickLabels
        XTickLabelFormat

        YRulerType
        YLimitsSharing
        YScale
        YLimitPickerBase
        AutoAdjustYLimits
        ShowYTickLabels
        YTickLabelFormat

        TitleStyle
        SubtitleStyle
        XLabelStyle
        YLabelStyle
        RowLabelStyle
        ColumnLabelStyle
        SubGridRowLabelStyle
        SubGridColumnLabelStyle
        AxesStyle

        InteractionOptions
        ToolbarButtons
        RestoreButtonPushedFcn
        CurrentInteractionMode
    end

    properties (Hidden,Dependent,SetObservable,AbortSet)
        LayoutManagerEnabled
        LimitManagerEnabled
        LabelManagerEnabled
    end

    properties (Hidden,Dependent,SetAccess = private)
        VisibleSubTiledLayouts
        VisibleAxes
        Toolbar

        NVisibleGridRows
        NVisibleGridColumns
        NVisibleSubGridRows
        NVisibleSubGridColumns

        AllRowVisible
        AllColumnVisible
    end

    properties (Dependent,Access={?controllib.chart.internal.layout.LimitManager})
        AllXLimits
        AllXLimitsMode
        AllYLimits
        AllYLimitsMode
    end

    properties (Dependent,Hidden)
        Serializable
    end

    properties (Access={?controllib.chart.internal.layout.TiledLayoutManager,...
            ?controllib.chart.internal.layout.LimitManager,...
            ?controllib.chart.internal.layout.LabelManager},WeakHandle)
        TiledLayout matlab.graphics.layout.TiledChartLayout {mustBeScalarOrEmpty}
    end

    properties (Access={?controllib.chart.internal.layout.TiledLayoutManager,...
            ?controllib.chart.internal.layout.LimitManager,...
            ?controllib.chart.internal.layout.LabelManager})
        SubTiledLayouts
        Axes
    end

    properties (Access=private)
        LayoutManager
        LimitManager
        LabelManager

        NeedsLayoutUpdate = false
        NeedsXLimitUpdate = false
        NeedsYLimitUpdate = false
        NeedsLabelUpdate = false

        NextPlot_I

        GridRowLabels_I
        GridColumnLabels_I
        SubGridRowLabels_I
        SubGridColumnLabels_I
        
        NGridRows_I
        NGridColumns_I
        GridRowsVisible_I
        GridColumnsVisible_I
        GridRowLabelVisible_I
        GridColumnLabelVisible_I

        NSubGridRows_I
        NSubGridColumns_I
        SubGridRowsVisible_I
        SubGridColumnsVisible_I
        SubGridRowLabelVisible_I
        SubGridColumnLabelVisible_I

        XRulerType_I
        XLimits_I
        XLimitsSharing_I
        XLimitsMode_I
        XLimitsFocus_I
        XScale_I
        XLimitPickerBase_I
        AutoAdjustXLimits_I
        ShowXTickLabels_I
        XTickLabelFormat_I

        YRulerType_I
        YLimits_I
        YLimitsSharing_I
        YLimitsMode_I
        YLimitsFocus_I
        YScale_I
        YLimitPickerBase_I
        AutoAdjustYLimits_I        
        ShowYTickLabels_I
        YTickLabelFormat_I

        TitleStyle_I
        SubtitleStyle_I
        XLabelStyle_I
        YLabelStyle_I
        RowLabelStyle_I
        ColumnLabelStyle_I
        SubGridRowLabelStyle_I
        SubGridColumnLabelStyle_I
        AxesStyle_I

        InteractionOptions_I
        ToolbarButtons_I
        RestoreButtonPushedFcn_I
    end

    events (NotifyAccess=private)
        GridSizeChanged
        LayoutChanged
        LabelsChanged
        XLimitsChanged
        YLimitsChanged
        AxesHit
        AxesReset
    end

    %% Constructor/destructor
    methods
        function this = AxesGrid(tiledLayout,gridSize,subGridSize,optionalInputs)
            % Constructor "AxesGrid":
            %   AxesGrid =
            %   controllib.chart.internal.layout.AxesGrid([2,3],...
            %                                                        'SubGridSize',[2
            %                                                        1],...
            %                                                        'Container',f,...
            %                                                        'Axes',ax)
            arguments
                tiledLayout (1,1) matlab.graphics.layout.TiledChartLayout
                gridSize (1,2) {mustBeInteger,mustBePositive} = [1 1]
                subGridSize (1,2) {mustBeInteger,mustBePositive} = [1 1]

                optionalInputs.Axes matlab.graphics.axis.Axes {mustBeScalarOrEmpty} = matlab.graphics.axis.Axes.empty

                optionalInputs.Padding (1,1) string {mustBeMember(optionalInputs.Padding,["loose";"compact";"tight"])} = "loose"
                optionalInputs.Spacing (1,1) string {mustBeMember(optionalInputs.Spacing,["loose";"compact";"tight";"none"])} = "compact"
                optionalInputs.Visible (1,1) matlab.lang.OnOffSwitchState = true
                optionalInputs.NextPlot (1,1) string {mustBeMember(optionalInputs.NextPlot,["add";"replace"])} = "replace"

                optionalInputs.Title (1,1) string = ""
                optionalInputs.Subtitle (1,1) string = ""
                optionalInputs.XLabel (1,1) string = ""
                optionalInputs.YLabel (1,1) string = ""

                optionalInputs.TitleVisible (1,1) matlab.lang.OnOffSwitchState = true
                optionalInputs.SubtitleVisible (1,1) matlab.lang.OnOffSwitchState = true
                optionalInputs.XLabelVisible (1,1) matlab.lang.OnOffSwitchState = true
                optionalInputs.YLabelVisible (1,1) matlab.lang.OnOffSwitchState = true

                optionalInputs.RowLabels (:,1) string ...
                    {controllib.chart.internal.layout.AxesGrid.mustBeInitRowSize(optionalInputs.RowLabels,gridSize)} = strings([gridSize(1) 1])
                optionalInputs.ColumnLabels (1,:) string ...
                    {controllib.chart.internal.layout.AxesGrid.mustBeInitColumnSize(optionalInputs.ColumnLabels,gridSize)} = strings([1 gridSize(2)])
                optionalInputs.SubGridRowLabels (:,1) string ...
                    {controllib.chart.internal.layout.AxesGrid.mustBeInitRowSize(optionalInputs.SubGridRowLabels,subGridSize)} = strings([subGridSize(1) 1])
                optionalInputs.SubGridColumnLabels (1,:) string ...
                    {controllib.chart.internal.layout.AxesGrid.mustBeInitColumnSize(optionalInputs.SubGridColumnLabels,subGridSize)} = strings([1 subGridSize(2)])              
                optionalInputs.RowLabelsVisible (1,1) matlab.lang.OnOffSwitchState = true
                optionalInputs.ColumnLabelsVisible (1,1) matlab.lang.OnOffSwitchState = true
                optionalInputs.SubGridRowLabelsVisible (1,1) matlab.lang.OnOffSwitchState = true
                optionalInputs.SubGridColumnLabelsVisible (1,1) matlab.lang.OnOffSwitchState = true

                optionalInputs.GridRowVisible (:,1) matlab.lang.OnOffSwitchState ...
                    {controllib.chart.internal.layout.AxesGrid.mustBeInitRowSize(optionalInputs.GridRowVisible,gridSize)} = true(gridSize(1),1)
                optionalInputs.GridColumnVisible (1,:) matlab.lang.OnOffSwitchState ...
                    {controllib.chart.internal.layout.AxesGrid.mustBeInitColumnSize(optionalInputs.GridColumnVisible,gridSize)} = true(1,gridSize(2))
                optionalInputs.SubGridRowVisible (:,1) matlab.lang.OnOffSwitchState ...
                    {controllib.chart.internal.layout.AxesGrid.mustBeInitRowSize(optionalInputs.SubGridRowVisible,subGridSize)} = true(subGridSize(1),1)
                optionalInputs.SubGridColumnVisible (1,:) matlab.lang.OnOffSwitchState ...
                    {controllib.chart.internal.layout.AxesGrid.mustBeInitColumnSize(optionalInputs.SubGridColumnVisible,subGridSize)} = true(1,subGridSize(2))

                optionalInputs.XRulerType (1,1) string {mustBeMember(optionalInputs.XRulerType,["numeric";"duration";"datetime"])} = "numeric"
                optionalInputs.XLimitsSharing (1,1) string {mustBeMember(optionalInputs.XLimitsSharing,["none";"column";"all"])} = "all"
                optionalInputs.XLimitsFocus (:,:) cell ...
                    {controllib.chart.internal.layout.AxesGrid.mustBeInitFocusSize(optionalInputs.XLimitsFocus,gridSize,subGridSize)} = {}
                optionalInputs.XScale (1,:) string {mustBeMember(optionalInputs.XScale,["linear";"log"]) ...
                    controllib.chart.internal.layout.AxesGrid.mustBeInitColumnSize(optionalInputs.XScale,subGridSize)} = repmat("linear",1,subGridSize(2))
                optionalInputs.XLimitPickerBase (1,:) double {mustBePositive,...
                    controllib.chart.internal.layout.AxesGrid.mustBeInitColumnSize(optionalInputs.XLimitPickerBase,subGridSize)} = 10*ones(1,subGridSize(2))
                optionalInputs.ShowXTickLabels (1,1) matlab.lang.OnOffSwitchState = true
                optionalInputs.AutoAdjustXLimits (1,1) matlab.lang.OnOffSwitchState = true
                optionalInputs.XTickLabelFormat (1,1) string = "%g"

                optionalInputs.YRulerType (1,1) string {mustBeMember(optionalInputs.YRulerType,["numeric";"duration";"datetime"])} = "numeric"
                optionalInputs.YLimitsSharing (1,1) string {mustBeMember(optionalInputs.YLimitsSharing,["none";"row";"all"])} = "all"
                optionalInputs.YLimitsFocus (:,:) cell ...
                    {controllib.chart.internal.layout.AxesGrid.mustBeInitFocusSize(optionalInputs.YLimitsFocus,gridSize,subGridSize)} = {}
                optionalInputs.YScale (:,1) string {mustBeMember(optionalInputs.YScale,["linear";"log"]) ...
                    controllib.chart.internal.layout.AxesGrid.mustBeInitRowSize(optionalInputs.YScale,subGridSize)} = repmat("linear",subGridSize(1),1)
                optionalInputs.YLimitPickerBase (:,1) double {mustBePositive,...
                    controllib.chart.internal.layout.AxesGrid.mustBeInitRowSize(optionalInputs.YLimitPickerBase,subGridSize)} = 10*ones(subGridSize(1),1)
                optionalInputs.ShowYTickLabels (1,1) matlab.lang.OnOffSwitchState = true
                optionalInputs.AutoAdjustYLimits (1,1) matlab.lang.OnOffSwitchState = true
                optionalInputs.YTickLabelFormat (1,1) string = "%g"

                optionalInputs.TitleStyle (1,1) controllib.chart.internal.options.LabelStyle = ...
                    controllib.chart.internal.options.LabelStyle(TiledLayout=tiledLayout)
                optionalInputs.SubtitleStyle (1,1) controllib.chart.internal.options.LabelStyle = ...
                    controllib.chart.internal.options.LabelStyle(TiledLayout=tiledLayout)
                optionalInputs.XLabelStyle (1,1) controllib.chart.internal.options.LabelStyle = ...
                    controllib.chart.internal.options.LabelStyle(TiledLayout=tiledLayout)
                optionalInputs.YLabelStyle (1,1) controllib.chart.internal.options.LabelStyle = ...
                    controllib.chart.internal.options.LabelStyle(TiledLayout=tiledLayout,Rotation=90)
                optionalInputs.RowLabelStyle (1,1) controllib.chart.internal.options.LabelStyle = ...
                    controllib.chart.internal.options.LabelStyle(TiledLayout=tiledLayout,Rotation=90)
                optionalInputs.ColumnLabelStyle (1,1) controllib.chart.internal.options.LabelStyle = ...
                    controllib.chart.internal.options.LabelStyle(TiledLayout=tiledLayout)
                optionalInputs.SubGridRowLabelStyle (1,1) controllib.chart.internal.options.LabelStyle = ...
                    controllib.chart.internal.options.LabelStyle(TiledLayout=tiledLayout,Rotation=90)
                optionalInputs.SubGridColumnLabelStyle (1,1) controllib.chart.internal.options.LabelStyle = ...
                    controllib.chart.internal.options.LabelStyle(TiledLayout=tiledLayout)

                optionalInputs.AxesStyle (1,1) controllib.chart.internal.options.AxesGridStyle = ...
                    controllib.chart.internal.options.AxesGridStyle(TiledLayout=tiledLayout)

                optionalInputs.InteractionOptions (1,1) matlab.graphics.interaction.interactionoptions.CartesianAxesInteractionOptions = matlab.graphics.interaction.interactionoptions.CartesianAxesInteractionOptions()
                optionalInputs.ToolbarButtons (1,:) string {mustBeNonempty,...
                    controllib.chart.internal.layout.AxesGrid.mustBeToolbarButtons} = "default"
                optionalInputs.RestoreButtonPushedFcn function_handle {mustBeScalarOrEmpty} = function_handle.empty
            end

            delete(allchild(tiledLayout)); % clear layout
            this.TiledLayout = tiledLayout;
            this.TiledLayout.Padding = optionalInputs.Padding;
            this.TiledLayout.TileSpacing = optionalInputs.Spacing;
            this.TitleVisible = optionalInputs.TitleVisible;
            this.SubtitleVisible = optionalInputs.SubtitleVisible;
            this.XLabelVisible = optionalInputs.XLabelVisible;
            this.YLabelVisible = optionalInputs.YLabelVisible;
            weakThis = matlab.lang.WeakReference(this);
            L = addlistener(this.TiledLayout,'ObjectBeingDestroyed',@(es,ed) delete(weakThis.Handle));
            registerListeners(this,L,'TiledLayoutDeleted');

            this.NextPlot_I = optionalInputs.NextPlot;

            % Axes Interactions
            this.InteractionOptions_I = optionalInputs.InteractionOptions;
            this.ToolbarButtons_I = optionalInputs.ToolbarButtons;
            this.RestoreButtonPushedFcn_I = optionalInputs.RestoreButtonPushedFcn;    

            % Labels
            this.Title = optionalInputs.Title;
            this.Subtitle = optionalInputs.Subtitle;
            this.XLabel = optionalInputs.XLabel;
            this.YLabel = optionalInputs.YLabel;
            
            % Grid
            this.NGridRows_I = gridSize(1);
            this.NGridColumns_I = gridSize(2);
            this.GridRowsVisible_I = optionalInputs.GridRowVisible;
            this.GridColumnsVisible_I = optionalInputs.GridColumnVisible;
            this.GridRowLabels_I = optionalInputs.RowLabels;
            this.GridColumnLabels_I = optionalInputs.ColumnLabels;            
            this.GridRowLabelVisible_I = optionalInputs.RowLabelsVisible;
            this.GridColumnLabelVisible_I = optionalInputs.ColumnLabelsVisible;

            % SubGrid
            this.NSubGridRows_I = subGridSize(1);
            this.NSubGridColumns_I  = subGridSize(2);
            this.SubGridRowsVisible_I = optionalInputs.SubGridRowVisible;
            this.SubGridColumnsVisible_I = optionalInputs.SubGridColumnVisible;
            this.SubGridRowLabels_I = optionalInputs.SubGridRowLabels;
            this.SubGridColumnLabels_I = optionalInputs.SubGridColumnLabels;
            this.SubGridRowLabelVisible_I = optionalInputs.SubGridRowLabelsVisible;
            this.SubGridColumnLabelVisible_I = optionalInputs.SubGridColumnLabelsVisible;

            % XRuler
            this.XRulerType_I = optionalInputs.XRulerType;
            this.XLimitsSharing_I = optionalInputs.XLimitsSharing;
            this.XLimitsMode_I = repmat({"auto"},gridSize.*subGridSize);
            this.XLimitsFocus_I = optionalInputs.XLimitsFocus;
            this.XScale_I = optionalInputs.XScale;
            this.XLimitPickerBase_I = optionalInputs.XLimitPickerBase;
            this.AutoAdjustXLimits_I = optionalInputs.AutoAdjustXLimits;
            this.ShowXTickLabels_I = optionalInputs.ShowXTickLabels;
            this.XTickLabelFormat_I = optionalInputs.XTickLabelFormat;

            % YRuler
            this.YRulerType_I = optionalInputs.YRulerType;
            this.YLimitsSharing_I = optionalInputs.YLimitsSharing;
            this.YLimitsMode_I = repmat({"auto"},gridSize.*subGridSize);
            this.YLimitsFocus_I = optionalInputs.YLimitsFocus;
            this.YScale_I = optionalInputs.YScale;
            this.YLimitPickerBase_I = optionalInputs.YLimitPickerBase;
            this.AutoAdjustYLimits_I = optionalInputs.AutoAdjustYLimits;
            this.ShowYTickLabels_I = optionalInputs.ShowYTickLabels;
            this.YTickLabelFormat_I = optionalInputs.YTickLabelFormat;

            % Create managers
            this.LayoutManager = controllib.chart.internal.layout.TiledLayoutManager(this,optionalInputs.Axes);
            this.LimitManager = controllib.chart.internal.layout.LimitManager(this);
            this.LabelManager = controllib.chart.internal.layout.LabelManager(this);
            
            % Set styles
            this.TitleStyle = optionalInputs.TitleStyle;
            this.SubtitleStyle = optionalInputs.SubtitleStyle;
            this.XLabelStyle = optionalInputs.XLabelStyle;
            this.YLabelStyle = optionalInputs.YLabelStyle;
            this.RowLabelStyle = optionalInputs.RowLabelStyle;
            this.ColumnLabelStyle = optionalInputs.ColumnLabelStyle;
            this.SubGridRowLabelStyle = optionalInputs.SubGridRowLabelStyle;
            this.SubGridColumnLabelStyle = optionalInputs.SubGridColumnLabelStyle;
            this.AxesStyle = optionalInputs.AxesStyle;

            % Set XLimitsFocus and YLimitsFocus if needed
            if isempty(this.XLimitsFocus)
                xLimitsFocus = cell(size(this.Axes));
                for ii = 1:numel(this.Axes)
                    xLimitsFocus{ii} = this.Axes(ii).XLim;
                end
                this.XLimitsFocus_I = xLimitsFocus;
            end
            if isempty(this.YLimitsFocus)
                yLimitsFocus = cell(size(this.Axes));
                for ii = 1:numel(this.Axes)
                    yLimitsFocus{ii} = this.Axes(ii).YLim;
                end
                this.YLimitsFocus_I = yLimitsFocus;
            end

            this.XLimits_I = computeInitialXLimits(this.LimitManager);
            this.YLimits_I = computeInitialYLimits(this.LimitManager);

            % Update
            update(this,true);  

            addManagerListeners(this);

            this.Visible = optionalInputs.Visible;
        end

        function delete(this)
            delete@controllib.chart.internal.foundation.MixInListeners(this);
            delete(this.LayoutManager);
            delete(this.LimitManager);
            delete(this.LabelManager);
        end
    end

    %% Public methods
    methods
        function update(this,forceUpdate,optionalArguments)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                forceUpdate (1,1) logical = false
                optionalArguments.UpdateLayout (1,1) logical = false
                optionalArguments.UpdateLimits (1,1) logical = false
                optionalArguments.UpdateLabels (1,1) logical = false
            end

            if this.NeedsLayoutUpdate || forceUpdate || optionalArguments.UpdateLayout
                updateLayout(this);
            end

            if this.NeedsXLimitUpdate || forceUpdate || optionalArguments.UpdateLimits
                updateXLimits(this);
            end

            if this.NeedsYLimitUpdate || forceUpdate || optionalArguments.UpdateLimits
                updateYLimits(this);
            end

            if this.NeedsLabelUpdate || forceUpdate || optionalArguments.UpdateLabels
                updateLabels(this);
            end
        end

        function syncTiledLayoutParent(this)
            if ~isempty(this.LimitManager) && isvalid(this.LimitManager)
                updateTicks(this.LimitManager);
            end
        end
    end

    %% Get/Set
    methods
        % Parent
        function Parent = get.Parent(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            Parent = this.TiledLayout.Parent;
        end

        function set.Parent(this,Parent)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                Parent {mustBeScalarOrEmpty}
            end
            this.TiledLayout.Parent = Parent;
        end

        % Position
        function Position = get.Position(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            Position = this.TiledLayout.Position;
        end

        function set.Position(this,Position)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                Position (1,4) double
            end
            this.TiledLayout.Position = Position;
        end

        % OuterPosition
        function OuterPosition = get.OuterPosition(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            OuterPosition = this.TiledLayout.OuterPosition;
        end

        function set.OuterPosition(this,OuterPosition)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                OuterPosition (1,4) double
            end
            this.TiledLayout.OuterPosition = OuterPosition;
        end

        % Padding
        function Padding = get.Padding(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            Padding = string(this.TiledLayout.Padding);
        end

        function set.Padding(this,Padding)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                Padding (1,1) string
            end
            this.TiledLayout.Padding = Padding;
        end

        % Spacing
        function Spacing = get.Spacing(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            Spacing = string(this.TiledLayout.TileSpacing);
        end

        function set.Spacing(this,Spacing)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                Spacing (1,1) string
            end
            this.TiledLayout.TileSpacing = Spacing;
        end

        % Visible
        function Visible = get.Visible(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            Visible = this.TiledLayout.Visible;
        end

        function set.Visible(this,Visible)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                Visible (1,1) matlab.lang.OnOffSwitchState
            end
            this.TiledLayout.Visible = Visible;
        end

        % NextPlot
        function NextPlot = get.NextPlot(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            NextPlot = this.NextPlot_I;
        end

        function set.NextPlot(this,NextPlot)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                NextPlot (1,1) string {mustBeMember(NextPlot,["add";"replace"])}
            end
            disableListeners(this,'AxesNextPlotListener');
            set(this.Axes,NextPlot=NextPlot);
            enableListeners(this,'AxesNextPlotListener');
            this.NextPlot_I = NextPlot;
        end

        % Title
        function Title = get.Title(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            str = string(this.TiledLayout.Title.String);
            title = str(1);
            for ii = 2:numel(str)
                title = title + newline + str(ii);
            end
            Title = title;
        end

        function set.Title(this,Title)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                Title (1,1) string
            end
            this.TiledLayout.Title.String = Title;
        end

        % TitleVisible
        function TitleVisible = get.TitleVisible(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            TitleVisible = this.TiledLayout.Title.Visible;
        end

        function set.TitleVisible(this,TitleVisible)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                TitleVisible (1,1) matlab.lang.OnOffSwitchState
            end
            this.TiledLayout.Title.Visible = TitleVisible;
        end

        % Subtitle
        function Subtitle = get.Subtitle(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            str = string(this.TiledLayout.Subtitle.String);
            subtitle = str(1);
            for ii = 2:numel(str)
                subtitle = subtitle + newline + str(ii);
            end
            Subtitle = subtitle;
        end

        function set.Subtitle(this,Subtitle)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                Subtitle (1,1) string
            end
            this.TiledLayout.Subtitle.String = Subtitle;
        end

        % SubtitleVisible
        function SubtitleVisible = get.SubtitleVisible(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            SubtitleVisible = this.TiledLayout.Subtitle.Visible;
        end

        function set.SubtitleVisible(this,SubtitleVisible)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                SubtitleVisible (1,1) matlab.lang.OnOffSwitchState
            end
            this.TiledLayout.Subtitle.Visible = SubtitleVisible;
        end

        % XLabel
        function XLabel = get.XLabel(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            str = string(this.TiledLayout.XLabel.String);
            xlabel = str(1);
            for ii = 2:numel(str)
                xlabel = xlabel + newline + str(ii);
            end
            XLabel = xlabel;
        end

        function set.XLabel(this,XLabel)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                XLabel (1,1) string
            end
            this.TiledLayout.XLabel.String = XLabel;
        end

        % XLabelVisible
        function XLabelVisible = get.XLabelVisible(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            XLabelVisible = this.TiledLayout.XLabel.Visible;
        end

        function set.XLabelVisible(this,XLabelVisible)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                XLabelVisible (1,1) matlab.lang.OnOffSwitchState
            end
            this.TiledLayout.XLabel.Visible = XLabelVisible;
        end

        % YLabel
        function YLabel = get.YLabel(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            str = string(this.TiledLayout.YLabel.String);
            ylabel = str(1);
            for ii = 2:numel(str)
                ylabel = ylabel + newline + str(ii);
            end
            YLabel = ylabel;
        end

        function set.YLabel(this,YLabel)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                YLabel (1,1) string
            end
            this.TiledLayout.YLabel.String = YLabel;
        end

        % YLabelVisible
        function YLabelVisible = get.YLabelVisible(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            YLabelVisible = this.TiledLayout.YLabel.Visible;
        end

        function set.YLabelVisible(this,YLabelVisible)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                YLabelVisible (1,1) matlab.lang.OnOffSwitchState
            end
            this.TiledLayout.YLabel.Visible = YLabelVisible;
        end

        % GridRowLabels
        function GridRowLabels = get.GridRowLabels(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            GridRowLabels = this.GridRowLabels_I;
        end

        function set.GridRowLabels(this,GridRowLabels)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                GridRowLabels (:,1) string {mustBeRowSize(this,GridRowLabels)}
            end
            this.GridRowLabels_I = GridRowLabels;
            this.NeedsLabelUpdate = true;
        end

        % GridColumnLabels
        function ColumnLabels = get.GridColumnLabels(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            ColumnLabels = this.GridColumnLabels_I;
        end

        function set.GridColumnLabels(this,GridColumnLabels)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                GridColumnLabels (1,:) string {mustBeColumnSize(this,GridColumnLabels)}
            end
            this.GridColumnLabels_I = GridColumnLabels;
            this.NeedsLabelUpdate = true;
        end

        % GridRowLabelsVisible
        function GridRowLabelsVisible = get.GridRowLabelsVisible(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            GridRowLabelsVisible = this.GridRowLabelVisible_I;
        end

        function set.GridRowLabelsVisible(this,GridRowLabelsVisible)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                GridRowLabelsVisible (1,1) matlab.lang.OnOffSwitchState
            end
            this.GridRowLabelVisible_I = GridRowLabelsVisible;
            this.NeedsLabelUpdate = true;
        end

        % GridColumnLabelsVisible
        function GridColumnLabelsVisible = get.GridColumnLabelsVisible(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            GridColumnLabelsVisible = this.GridColumnLabelVisible_I;
        end

        function set.GridColumnLabelsVisible(this,GridColumnLabelsVisible)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                GridColumnLabelsVisible (1,1) matlab.lang.OnOffSwitchState
            end
            this.GridColumnLabelVisible_I = GridColumnLabelsVisible;
            this.NeedsLabelUpdate = true;
        end

        % SubGridRowLabels
        function SubGridRowLabels = get.SubGridRowLabels(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            SubGridRowLabels = this.SubGridRowLabels_I;
        end

        function set.SubGridRowLabels(this,SubGridRowLabels)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                SubGridRowLabels (:,1) string {mustBeSubGridRowSize(this,SubGridRowLabels)}
            end
            this.SubGridRowLabels_I = SubGridRowLabels;
            this.NeedsLabelUpdate = true;
        end

        % SubGridColumnLabels
        function SubGridColumnLabels = get.SubGridColumnLabels(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            SubGridColumnLabels = this.SubGridColumnLabels_I;
        end

        function set.SubGridColumnLabels(this,SubGridColumnLabels)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                SubGridColumnLabels (1,:) string {mustBeSubGridColumnSize(this,SubGridColumnLabels)}
            end
            this.SubGridColumnLabels_I = SubGridColumnLabels;
            this.NeedsLabelUpdate = true;
        end

        % SubGridRowLabelsVisible
        function SubGridRowLabelsVisible = get.SubGridRowLabelsVisible(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            SubGridRowLabelsVisible = this.SubGridRowLabelVisible_I;
        end

        function set.SubGridRowLabelsVisible(this,SubGridRowLabelsVisible)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                SubGridRowLabelsVisible (1,1) matlab.lang.OnOffSwitchState
            end
            this.SubGridRowLabelVisible_I = SubGridRowLabelsVisible;
            this.NeedsLabelUpdate = true;
        end

        % SubGridColumnLabelsVisible
        function SubGridColumnLabelsVisible = get.SubGridColumnLabelsVisible(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            SubGridColumnLabelsVisible = this.SubGridColumnLabelVisible_I;
        end

        function set.SubGridColumnLabelsVisible(this,SubGridColumnLabelsVisible)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                SubGridColumnLabelsVisible (1,1) matlab.lang.OnOffSwitchState
            end
            this.SubGridColumnLabelVisible_I = SubGridColumnLabelsVisible;
            this.NeedsLabelUpdate = true;
        end

        % GridSize
        function GridSize = get.GridSize(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            GridSize = [this.NGridRows_I, this.NGridColumns_I];
        end

        function set.GridSize(this,GridSize)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                GridSize (1,2) double {mustBeInteger,mustBePositive}
            end
            diff = GridSize-this.GridSize;
            this.NGridRows_I = GridSize(1);
            this.NGridColumns_I = GridSize(2);
            if diff(1) > 0 % rows added
                this.GridRowVisible = [this.GridRowVisible;true([diff(1) 1])];
                this.GridRowLabels = [this.GridRowLabels;strings([diff(1) 1])];
            elseif diff(1) < 0 % rows removed
                this.GridRowVisible = this.GridRowVisible(1:end+diff(1));
                this.GridRowLabels = this.GridRowLabels(1:end+diff(1));
            end
            if diff(2) > 0 % columns added
                this.GridColumnVisible = [this.GridColumnVisible,true([1 diff(2)])];
                this.GridColumnLabels = [this.GridColumnLabels,strings([1 diff(2)])];
            elseif diff(2) < 0 % columns removed
                this.GridColumnVisible = this.GridColumnVisible(1:end+diff(2));
                this.GridColumnLabels = this.GridColumnLabels(1:end+diff(2));
            end

            totalGridSize = this.GridSize.*this.SubGridSize;
            switch this.XRulerType
                case "numeric"
                    defaultXLimits = repmat({[0 1]},totalGridSize);
                    for ii = 1:length(this.XScale)
                        if this.XScale(ii) == "log"
                            defaultXLimits(:,ii:this.SubGridSize(2):end) = {[realmin 1]};
                        end
                    end
                case "duration"
                    defaultXLimits = repmat({days([0 1])},totalGridSize);
                case "datetime"
                    defaultXLimits = repmat({datetime(0,ConvertFrom='posixtime')+days([0 1])},totalGridSize);
            end
            switch this.YRulerType
                case "numeric"
                    defaultYLimits = repmat({[0 1]},totalGridSize);
                    for ii = 1:length(this.YScale)
                        if this.YScale(ii) == "log"
                            defaultXLimits(ii:this.SubGridSize(1):end,:) = {[realmin 1]};
                        end
                    end
                case "duration"
                    defaultYLimits = repmat({days([0 1])},totalGridSize);
                case "datetime"
                    defaultYLimits = repmat({datetime(0,ConvertFrom='posixtime')+days([0 1])},totalGridSize);
            end
            defaultLimitsMode = repmat({"auto"},totalGridSize);

            xLimitsOverLap = {1:min(size(this.XLimitsFocus,1),size(defaultXLimits,1)) 1:min(size(this.XLimitsFocus,2),size(defaultXLimits,2))};
            xlim = defaultXLimits;
            xlim(xLimitsOverLap{:}) = this.AllXLimits(xLimitsOverLap{:});
            this.AllXLimits = xlim;
            xlimmode = defaultLimitsMode;
            xlimmode(xLimitsOverLap{:}) = this.AllXLimitsMode(xLimitsOverLap{:});
            this.AllXLimitsMode = xlimmode;
            xlimfocus = defaultXLimits;
            xlimfocus(xLimitsOverLap{:}) = this.XLimitsFocus(xLimitsOverLap{:});
            this.XLimitsFocus_I = xlimfocus;

            yLimitsOverLap = {1:min(size(this.YLimitsFocus,1),size(defaultXLimits,1)) 1:min(size(this.YLimitsFocus,2),size(defaultXLimits,2))};
            ylim = defaultYLimits;
            ylim(yLimitsOverLap{:}) = this.AllYLimits(yLimitsOverLap{:});
            this.AllYLimits = ylim;
            ylimmode = defaultLimitsMode;
            ylimmode(yLimitsOverLap{:}) = this.AllYLimitsMode(yLimitsOverLap{:});
            this.AllYLimitsMode = ylimmode;
            ylimfocus = defaultYLimits;
            ylimfocus(yLimitsOverLap{:}) = this.YLimitsFocus(yLimitsOverLap{:});
            this.YLimitsFocus_I = ylimfocus;

            this.NeedsLayoutUpdate = true;
            this.NeedsLabelUpdate = true;
            this.NeedsXLimitUpdate = true;
            this.NeedsYLimitUpdate = true;
        end

        % GridRowVisible
        function GridRowVisible = get.GridRowVisible(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            GridRowVisible = this.GridRowsVisible_I;
        end

        function set.GridRowVisible(this,RowVisible)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                RowVisible (:,1) matlab.lang.OnOffSwitchState {mustBeRowSize(this,RowVisible)}
            end
            % Will need updates if any columns are visible
            if any(this.GridColumnVisible)
                this.NeedsLayoutUpdate = true;
                this.NeedsXLimitUpdate = true;
                this.NeedsYLimitUpdate = true;

                % Check if label update needed (if column labels need to be
                % moved to a different row)
                if any(RowVisible) && (~any(this.GridRowsVisible_I) || (find(this.GridRowsVisible_I,1)~=find(RowVisible,1)))
                    this.NeedsLabelUpdate = true;
                end
            end
            this.GridRowsVisible_I = RowVisible;
        end

        % GridColumnVisible
        function GridColumnVisible = get.GridColumnVisible(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            GridColumnVisible = this.GridColumnsVisible_I;
        end

        function set.GridColumnVisible(this,ColumnVisible)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                ColumnVisible (1,:) matlab.lang.OnOffSwitchState {mustBeColumnSize(this,ColumnVisible)}
            end
            % Will need updates if any rows are visible
            if any(this.GridRowVisible)
                this.NeedsLayoutUpdate = true;
                this.NeedsXLimitUpdate = true;
                this.NeedsYLimitUpdate = true;

                % Check if label update needed (if row labels need to be moved
                % to a different column);
                if any(ColumnVisible) && (~any(this.GridColumnsVisible_I) || (find(this.GridColumnsVisible_I,1)~=find(ColumnVisible,1)))
                    this.NeedsLabelUpdate = true;
                end
            end
            this.GridColumnsVisible_I = ColumnVisible;
        end

        % SubGridSize
        function SubGridSize = get.SubGridSize(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            SubGridSize = [this.NSubGridRows_I, this.NSubGridColumns_I];
        end

        function set.SubGridSize(this,SubGridSize)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                SubGridSize (1,2) double {mustBeInteger,mustBePositive}
            end
            diff = SubGridSize-this.SubGridSize;
            this.NSubGridRows_I = SubGridSize(1);
            this.NSubGridColumns_I = SubGridSize(2);
            if diff(1) > 0 % rows added
                this.SubGridRowVisible = [this.SubGridRowVisible;true([diff(1) 1])];
                this.SubGridRowLabels = [this.SubGridRowLabels;strings([diff(1) 1])];
                this.YScale = [this.YScale;repmat("linear",[diff(1) 1])];
                this.YLimitPickerBase = [this.YLimitPickerBase;10*ones([diff(1) 1])];
            elseif diff(1) < 0 % rows removed
                this.SubGridRowVisible = this.SubGridRowVisible(1:end+diff(1));
                this.SubGridRowLabels = this.SubGridRowLabels(1:end+diff(1));
                this.YScale = this.YScale(1:end+diff(1));
                this.YLimitPickerBase = this.YLimitPickerBase(1:end+diff(1));
            end
            if diff(2) > 0 % columns added
                this.SubGridColumnVisible = [this.SubGridColumnVisible,true([1 diff(2)])];
                this.SubGridColumnLabels = [this.SubGridColumnLabels,strings([1 diff(2)])];
                this.XScale = [this.XScale,repmat("linear",[1 diff(2)])];
                this.XLimitPickerBase = [this.XLimitPickerBase,10*ones([1 diff(2)])];
            elseif diff(2) < 0 % columns removed
                this.SubGridColumnVisible = this.SubGridColumnVisible(1:end+diff(2));
                this.SubGridColumnLabels = this.SubGridColumnLabels(1:end+diff(2));
                this.XScale = this.XScale(1:end+diff(2));
                this.XLimitPickerBase = this.XLimitPickerBase(1:end+diff(2));
            end

            totalGridSize = this.GridSize.*this.SubGridSize;
            switch this.XRulerType
                case "numeric"
                    defaultXLimits = repmat({[0 1]},totalGridSize);
                    for ii = 1:length(this.XScale)
                        if this.XScale(ii) == "log"
                            defaultXLimits(:,ii:this.SubGridSize(2):end) = {[realmin 1]};
                        end
                    end
                case "duration"
                    defaultXLimits = repmat({days([0 1])},totalGridSize);
                case "datetime"
                    defaultXLimits = repmat({datetime(0,ConvertFrom='posixtime')+days([0 1])},totalGridSize);
            end
            switch this.YRulerType
                case "numeric"
                    defaultYLimits = repmat({[0 1]},totalGridSize);
                    for ii = 1:length(this.YScale)
                        if this.YScale(ii) == "log"
                            defaultXLimits(ii:this.SubGridSize(1):end,:) = {[realmin 1]};
                        end
                    end
                case "duration"
                    defaultYLimits = repmat({days([0 1])},totalGridSize);
                case "datetime"
                    defaultYLimits = repmat({datetime(0,ConvertFrom='posixtime')+days([0 1])},totalGridSize);
            end
            defaultLimitsMode = repmat({"auto"},totalGridSize);

            xLimitsOverLap = {1:min(size(this.XLimitsFocus,1),size(defaultXLimits,1)) 1:min(size(this.XLimitsFocus,2),size(defaultXLimits,2))};
            xlim = defaultXLimits;
            xlim(xLimitsOverLap{:}) = this.AllXLimits(xLimitsOverLap{:});
            this.AllXLimits = xlim;
            xlimmode = defaultLimitsMode;
            xlimmode(xLimitsOverLap{:}) = this.AllXLimitsMode(xLimitsOverLap{:});
            this.AllXLimitsMode = xlimmode;
            xlimfocus = defaultXLimits;
            xlimfocus(xLimitsOverLap{:}) = this.XLimitsFocus(xLimitsOverLap{:});
            this.XLimitsFocus_I = xlimfocus;

            yLimitsOverLap = {1:min(size(this.YLimitsFocus,1),size(defaultXLimits,1)) 1:min(size(this.YLimitsFocus,2),size(defaultXLimits,2))};
            ylim = defaultYLimits;
            ylim(yLimitsOverLap{:}) = this.AllYLimits(yLimitsOverLap{:});
            this.AllYLimits = ylim;
            ylimmode = defaultLimitsMode;
            ylimmode(yLimitsOverLap{:}) = this.AllYLimitsMode(yLimitsOverLap{:});
            this.AllYLimitsMode = ylimmode;
            ylimfocus = defaultYLimits;
            ylimfocus(yLimitsOverLap{:}) = this.YLimitsFocus(yLimitsOverLap{:});
            this.YLimitsFocus_I = ylimfocus;

            this.NeedsLayoutUpdate = true;
            this.NeedsLabelUpdate = true;
            this.NeedsXLimitUpdate = true;
            this.NeedsYLimitUpdate = true;
        end

        % SubGridRowVisible
        function SubGridRowVisible = get.SubGridRowVisible(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            SubGridRowVisible = this.SubGridRowsVisible_I;
        end

        function set.SubGridRowVisible(this,SubGridRowVisible)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                SubGridRowVisible (:,1) matlab.lang.OnOffSwitchState {mustBeSubGridRowSize(this,SubGridRowVisible)}
            end
            % Will need updates if any columns are visible
            if any(this.SubGridColumnVisible)
                this.NeedsLayoutUpdate = true;
                this.NeedsXLimitUpdate = true;
                this.NeedsYLimitUpdate = true;

                % Check if label update needed (if column labels need to be
                % moved to a different row)
                if any(SubGridRowVisible) && (~any(this.SubGridRowsVisible_I) || (find(this.SubGridRowsVisible_I,1)~=find(SubGridRowVisible,1)))
                    this.NeedsLabelUpdate = true;
                end
            end
            this.SubGridRowsVisible_I = SubGridRowVisible;
        end

        % SubGridColumnVisible
        function SubGridColumnVisible = get.SubGridColumnVisible(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            SubGridColumnVisible = this.SubGridColumnsVisible_I;
        end

        function set.SubGridColumnVisible(this,SubGridColumnVisible)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                SubGridColumnVisible (1,:) matlab.lang.OnOffSwitchState {mustBeSubGridColumnSize(this,SubGridColumnVisible)}
            end
            % Will need updates if any rows are visible
            if any(this.SubGridRowVisible)
                this.NeedsLayoutUpdate = true;
                this.NeedsXLimitUpdate = true;
                this.NeedsYLimitUpdate = true;

                % Check if label update needed (if column labels need to be
                % moved to a different row)
                if any(SubGridColumnVisible) && (~any(this.SubGridColumnsVisible_I) || (find(this.SubGridColumnsVisible_I,1)~=find(SubGridColumnVisible,1)))
                    this.NeedsLabelUpdate = true;
                end
            end
            this.SubGridColumnsVisible_I = SubGridColumnVisible;
        end

        % XRulerType
        function XRulerType = get.XRulerType(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            XRulerType = this.XRulerType_I;
        end

        function set.XRulerType(this,XRulerType)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                XRulerType (1,1) string {mustBeMember(XRulerType,["numeric";"duration";"datetime"])}
            end
            this.XRulerType_I = XRulerType;
            totalGridSize = this.GridSize.*this.SubGridSize;
            switch XRulerType
                case "numeric"
                    defaultXLimits = repmat({[0 1]},totalGridSize);
                    for ii = 1:length(this.XScale)
                        if this.XScale(ii) == "log"
                            defaultXLimits(:,ii:this.SubGridSize(2):end) = {[realmin 1]};
                        end
                    end
                    this.XTickLabelFormat = "%g";
                case "duration"
                    defaultXLimits = repmat({days([0 1])},totalGridSize);
                    this.XTickLabelFormat = "hh:mm:ss";
                case "datetime"
                    defaultXLimits = repmat({datetime(0,ConvertFrom='posixtime')+days([0 1])},totalGridSize);
                    this.XTickLabelFormat = "MMM dd, uuuu";
            end
            this.AllXLimits = defaultXLimits;
            this.XLimitsFocus = defaultXLimits;
            this.NeedsXLimitUpdate = true;
            this.NeedsLabelUpdate = true;
        end

        % XLimitsSharing
        function XLimitsSharing = get.XLimitsSharing(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            XLimitsSharing = this.XLimitsSharing_I;
        end

        function set.XLimitsSharing(this,XLimitsSharing)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                XLimitsSharing (1,1) string {mustBeMember(XLimitsSharing,["none";"column";"all"])}
            end
            this.XLimitsSharing_I = XLimitsSharing;
            this.NeedsXLimitUpdate = true;
        end

        % XLimits
        function XLimits = get.XLimits(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            visibleIdx = this.AllRowVisible & this.AllColumnVisible;
            if any(visibleIdx,'all')
                XLimits = reshape(this.XLimits_I(visibleIdx),size(this.VisibleAxes));
                switch this.XLimitsSharing
                    case 'all'
                        XLimits = XLimits(1,1:this.NVisibleSubGridColumns);
                    case 'column'
                        XLimits = XLimits(1,:);
                end
            else
                XLimits = {};
            end
        end

        function set.XLimits(this,XLimits)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                XLimits (:,:)
            end
            try
                XLimits = validateXLimits(this,XLimits);
            catch ME
                throw(ME);
            end
            if ~isempty(XLimits)
                XLimits = repmat(XLimits,size(this.VisibleAxes)./size(XLimits));
                visibleIdx = this.AllRowVisible & this.AllColumnVisible;
                oldXLimits = this.XLimits_I(visibleIdx);
                newXLimitsMode = this.XLimitsMode_I(visibleIdx);
                for ii = 1:numel(oldXLimits)
                    if ~isequal(oldXLimits{ii},XLimits{ii})
                        newXLimitsMode{ii} = "manual";
                    end
                end
                this.XLimitsMode_I(visibleIdx) = newXLimitsMode;
                this.XLimits_I(visibleIdx) = XLimits;
                this.NeedsXLimitUpdate = true;
            end
        end

        % XLimitsMode
        function XLimitsMode = get.XLimitsMode(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            visibleIdx = this.AllRowVisible & this.AllColumnVisible;
            if any(visibleIdx,'all')
                XLimitsMode = reshape(this.XLimitsMode_I(visibleIdx),size(this.VisibleAxes));
                switch this.XLimitsSharing
                    case 'all'
                        XLimitsMode = XLimitsMode(1,1:this.NVisibleSubGridColumns);
                    case 'column'
                        XLimitsMode = XLimitsMode(1,:);
                end
            else
                XLimitsMode = {};
            end
        end

        function set.XLimitsMode(this,XLimitsMode)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                XLimitsMode (:,:)
            end
            try
                XLimitsMode = validateXLimitsMode(this,XLimitsMode);
            catch ME
                throw(ME);
            end
            if ~isempty(XLimitsMode)
                visibleIdx = this.AllRowVisible & this.AllColumnVisible;
                this.XLimitsMode_I(visibleIdx) = repmat(XLimitsMode,size(this.VisibleAxes)./size(XLimitsMode));
                this.NeedsXLimitUpdate = true;
            end
        end

        % XLimitsFocus
        function XLimitsFocus = get.XLimitsFocus(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            XLimitsFocus = this.XLimitsFocus_I;
        end

        function set.XLimitsFocus(this,XLimitsFocus)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                XLimitsFocus (:,:)
            end
            try
                XLimitsFocus = validateXLimitsFocus(this,XLimitsFocus);
            catch ME
                throw(ME);
            end
            this.XLimitsFocus_I = XLimitsFocus;
            this.NeedsXLimitUpdate = true;
        end
        
        % XScale
        function XScale = get.XScale(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            XScale = this.XScale_I;
        end

        function set.XScale(this,XScale)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                XScale (1,:) string {mustBeMember(XScale,["linear";"log"]),mustBeSubGridColumnSize(this,XScale)}
            end
            this.XScale_I = XScale;
            this.NeedsXLimitUpdate = true;
        end

        % XLimitPickerBase
        function XLimitPickerBase = get.XLimitPickerBase(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            XLimitPickerBase = this.XLimitPickerBase_I;
        end

        function set.XLimitPickerBase(this,XLimitPickerBase)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                XLimitPickerBase (1,:) double {mustBePositive,mustBeSubGridColumnSize(this,XLimitPickerBase)}
            end
            this.XLimitPickerBase_I = XLimitPickerBase;
            this.NeedsXLimitUpdate = true;
        end

        % AutoAdjustXLimits
        function AutoAdjustXLimits = get.AutoAdjustXLimits(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            AutoAdjustXLimits = this.AutoAdjustXLimits_I;
        end

        function set.AutoAdjustXLimits(this,AutoAdjustXLimits)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                AutoAdjustXLimits (1,1) matlab.lang.OnOffSwitchState
            end
            this.AutoAdjustXLimits_I = AutoAdjustXLimits;
            this.NeedsXLimitUpdate = true;
        end

        % ShowXTickLabels
        function ShowXTickLabels = get.ShowXTickLabels(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            ShowXTickLabels = this.ShowXTickLabels_I;
        end

        function set.ShowXTickLabels(this,ShowXTickLabels)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                ShowXTickLabels (1,1) matlab.lang.OnOffSwitchState
            end
            this.ShowXTickLabels_I = ShowXTickLabels;
            this.NeedsXLimitUpdate = true;
        end

        % XTickLabelFormat
        function XTickLabelFormat = get.XTickLabelFormat(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            XTickLabelFormat = this.XTickLabelFormat_I;
        end

        function set.XTickLabelFormat(this,XTickLabelFormat)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                XTickLabelFormat (1,1) string
            end
            this.XTickLabelFormat_I = XTickLabelFormat;
            this.NeedsXLimitUpdate = true;
        end

        % AllXLimits
        function XLimits = get.AllXLimits(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            XLimits = this.XLimits_I;
        end

        function set.AllXLimits(this,XLimits)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                XLimits (:,:) cell
            end
            this.XLimits_I = XLimits;
        end
        
        % AllXLimitsMode
        function XLimitsMode = get.AllXLimitsMode(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            XLimitsMode = this.XLimitsMode_I;
        end

        function set.AllXLimitsMode(this,XLimitsMode)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                XLimitsMode (:,:) cell
            end
            this.XLimitsMode_I = XLimitsMode;
        end

        % YRulerType
        function YRulerType = get.YRulerType(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            YRulerType = this.YRulerType_I;
        end

        function set.YRulerType(this,YRulerType)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                YRulerType (1,1) string {mustBeMember(YRulerType,["numeric";"duration";"datetime"])}
            end
            this.YRulerType_I = YRulerType;
            totalGridSize = this.GridSize.*this.SubGridSize;
            switch YRulerType
                case "numeric"
                    defaultYLimits = repmat({[0 1]},totalGridSize);
                    for ii = 1:length(this.YScale)
                        if this.YScale(ii) == "log"
                            defaultYLimits(:,ii:this.SubGridSize(2):end) = {[realmin 1]};
                        end
                    end
                    this.YTickLabelFormat = "%g";
                case "duration"
                    defaultYLimits = repmat({days([0 1])},totalGridSize);
                    this.YTickLabelFormat = "hh:mm:ss";
                case "datetime"
                    defaultYLimits = repmat({datetime(0,ConvertFrom='posixtime')+days([0 1])},totalGridSize);
                    this.YTickLabelFormat = "MMM dd, uuuu";
            end
            this.AllYLimits = defaultYLimits;
            this.YLimitsFocus = defaultYLimits;
            this.NeedsYLimitUpdate = true;
            this.NeedsLabelUpdate = true;
        end

        % YLimitsSharing
        function YLimitsSharing = get.YLimitsSharing(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            YLimitsSharing = this.YLimitsSharing_I;
        end

        function set.YLimitsSharing(this,YLimitsSharing)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                YLimitsSharing (1,1) string {mustBeMember(YLimitsSharing,["none";"row";"all"])}
            end
            this.YLimitsSharing_I = YLimitsSharing;
            this.NeedsYLimitUpdate = true;
        end

        % YLimits
        function YLimits = get.YLimits(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            visibleIdx = this.AllRowVisible & this.AllColumnVisible;
            if any(visibleIdx,'all')
                YLimits = reshape(this.YLimits_I(visibleIdx),size(this.VisibleAxes));
                switch this.YLimitsSharing
                    case 'all'
                        YLimits = YLimits(1:this.NVisibleSubGridRows,1);
                    case 'row'
                        YLimits = YLimits(:,1);
                end
            else
                YLimits = {};
            end
        end

        function set.YLimits(this,YLimits)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                YLimits (:,:)
            end
            try
                YLimits = validateYLimits(this,YLimits);
            catch ME
                throw(ME);
            end
            if ~isempty(YLimits)
                YLimits = repmat(YLimits,size(this.VisibleAxes)./size(YLimits));
                visibleIdx = this.AllRowVisible & this.AllColumnVisible;
                oldYLimits = this.YLimits_I(visibleIdx);
                newYLimitsMode = this.YLimitsMode_I(visibleIdx);
                for ii = 1:numel(oldYLimits)
                    if ~isequal(oldYLimits{ii},YLimits{ii})
                        newYLimitsMode{ii} = "manual";
                    end
                end
                this.YLimitsMode_I(visibleIdx) = newYLimitsMode;
                this.YLimits_I(visibleIdx) = YLimits;
                this.NeedsYLimitUpdate = true;
            end
        end

        % YLimitsMode
        function YLimitsMode = get.YLimitsMode(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            visibleIdx = this.AllRowVisible & this.AllColumnVisible;
            if any(visibleIdx,'all')
                YLimitsMode = reshape(this.YLimitsMode_I(visibleIdx),size(this.VisibleAxes));
                switch this.YLimitsSharing
                    case 'all'
                        YLimitsMode = YLimitsMode(1:this.NVisibleSubGridRows,1);
                    case 'row'
                        YLimitsMode = YLimitsMode(:,1);
                end
            else
                YLimitsMode = {};
            end
        end

        function set.YLimitsMode(this,YLimitsMode)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                YLimitsMode (:,:)
            end
            try
                YLimitsMode = validateYLimitsMode(this,YLimitsMode);
            catch ME
                throw(ME);
            end
            if ~isempty(YLimitsMode)
                visibleIdx = this.AllRowVisible & this.AllColumnVisible;
                this.YLimitsMode_I(visibleIdx) = repmat(YLimitsMode,size(this.VisibleAxes)./size(YLimitsMode));
                this.NeedsYLimitUpdate = true;
            end
        end

        % YLimitsFocus
        function YLimitsFocus = get.YLimitsFocus(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            YLimitsFocus = this.YLimitsFocus_I;
        end

        function set.YLimitsFocus(this,YLimitsFocus)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                YLimitsFocus (:,:)
            end
            try
                YLimitsFocus = validateYLimitsFocus(this,YLimitsFocus);
            catch ME
                throw(ME);
            end
            this.YLimitsFocus_I = YLimitsFocus;
            this.NeedsYLimitUpdate = true;
        end

        % YScale
        function YScale = get.YScale(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            YScale = this.YScale_I;
        end

        function set.YScale(this,YScale)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                YScale (:,1) string {mustBeMember(YScale,["linear";"log"]),mustBeSubGridRowSize(this,YScale)}
            end
            this.YScale_I = YScale;
            this.NeedsYLimitUpdate = true;
        end

        % YLimitPickerBase
        function YLimitPickerBase = get.YLimitPickerBase(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            YLimitPickerBase = this.YLimitPickerBase_I;
        end

        function set.YLimitPickerBase(this,YLimitPickerBase)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                YLimitPickerBase (:,1) double {mustBePositive,mustBeSubGridRowSize(this,YLimitPickerBase)}
            end
            this.YLimitPickerBase_I = YLimitPickerBase;
            this.NeedsYLimitUpdate = true;
        end

        % AutoAdjustYLimits
        function AutoAdjustYLimits = get.AutoAdjustYLimits(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            AutoAdjustYLimits = this.AutoAdjustYLimits_I;
        end

        function set.AutoAdjustYLimits(this,AutoAdjustYLimits)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                AutoAdjustYLimits (1,1) matlab.lang.OnOffSwitchState
            end
            this.AutoAdjustYLimits_I = AutoAdjustYLimits;
            this.NeedsYLimitUpdate = true;
        end

        % ShowYTickLabels
        function ShowYTickLabels = get.ShowYTickLabels(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            ShowYTickLabels = this.ShowYTickLabels_I;
        end

        function set.ShowYTickLabels(this,ShowYTickLabels)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                ShowYTickLabels (1,1) matlab.lang.OnOffSwitchState
            end
            this.ShowYTickLabels_I = ShowYTickLabels;
            this.NeedsYLimitUpdate = true;
        end

        % YTickLabelFormat
        function YTickLabelFormat = get.YTickLabelFormat(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            YTickLabelFormat = this.YTickLabelFormat_I;
        end

        function set.YTickLabelFormat(this,YTickLabelFormat)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                YTickLabelFormat (1,1) string
            end
            this.YTickLabelFormat_I = YTickLabelFormat;
            this.NeedsYLimitUpdate = true;
        end
        
        % AllYLimits
        function YLimits = get.AllYLimits(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            YLimits = this.YLimits_I;
        end

        function set.AllYLimits(this,YLimits)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                YLimits (:,:) cell
            end
            this.YLimits_I = YLimits;
        end

        % AllYLimitsMode
        function YLimitsMode = get.AllYLimitsMode(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            YLimitsMode = this.YLimitsMode_I;
        end

        function set.AllYLimitsMode(this,YLimitsMode)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                YLimitsMode (:,:) cell
            end
            this.YLimitsMode_I = YLimitsMode;
        end

        % TitleStyle
        function TitleStyle = get.TitleStyle(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            TitleStyle = this.TitleStyle_I;
        end

        function set.TitleStyle(this,TitleStyle)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                TitleStyle (1,1) controllib.chart.internal.options.LabelStyle
            end
            unregisterListeners(this,'TitleStyle')
            this.TitleStyle_I = TitleStyle;
            weakThis = matlab.lang.WeakReference(this);
            L = addlistener(TitleStyle,'LabelStyleChanged',@(es,ed) set(weakThis.Handle,NeedsLabelUpdate=true));
            registerListeners(this,L,'TitleStyle');
            this.NeedsLabelUpdate = true;
        end

        % SubtitleStyle
        function SubtitleStyle = get.SubtitleStyle(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            SubtitleStyle = this.SubtitleStyle_I;
        end

        function set.SubtitleStyle(this,SubtitleStyle)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                SubtitleStyle (1,1) controllib.chart.internal.options.LabelStyle
            end
            unregisterListeners(this,'SubtitleStyle')
            this.SubtitleStyle_I = SubtitleStyle;
            weakThis = matlab.lang.WeakReference(this);
            L = addlistener(SubtitleStyle,'LabelStyleChanged',@(es,ed) set(weakThis.Handle,NeedsLabelUpdate=true));
            registerListeners(this,L,'SubtitleStyle');
            this.NeedsLabelUpdate = true;
        end

        % XLabelStyle
        function XLabelStyle = get.XLabelStyle(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            XLabelStyle = this.XLabelStyle_I;
        end

        function set.XLabelStyle(this,XLabelStyle)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                XLabelStyle (1,1) controllib.chart.internal.options.LabelStyle
            end
            unregisterListeners(this,'XLabelStyle')
            this.XLabelStyle_I = XLabelStyle;
            weakThis = matlab.lang.WeakReference(this);
            L = addlistener(XLabelStyle,'LabelStyleChanged',@(es,ed) set(weakThis.Handle,NeedsLabelUpdate=true));
            registerListeners(this,L,'XLabelStyle');
            this.NeedsLabelUpdate = true;
        end

        % YLabelStyle
        function YLabelStyle = get.YLabelStyle(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            YLabelStyle = this.YLabelStyle_I;
        end

        function set.YLabelStyle(this,YLabelStyle)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                YLabelStyle (1,1) controllib.chart.internal.options.LabelStyle
            end
            unregisterListeners(this,'YLabelStyle')
            this.YLabelStyle_I = YLabelStyle;
            weakThis = matlab.lang.WeakReference(this);
            L = addlistener(YLabelStyle,'LabelStyleChanged',@(es,ed) set(weakThis.Handle,NeedsLabelUpdate=true));
            registerListeners(this,L,'YLabelStyle');
            this.NeedsLabelUpdate = true;
        end

        % RowLabelStyle
        function RowLabelStyle = get.RowLabelStyle(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            RowLabelStyle = this.RowLabelStyle_I;
        end

        function set.RowLabelStyle(this,RowLabelStyle)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                RowLabelStyle (1,1) controllib.chart.internal.options.LabelStyle
            end
            unregisterListeners(this,'RowLabelStyle')
            this.RowLabelStyle_I = RowLabelStyle;
            weakThis = matlab.lang.WeakReference(this);
            L = addlistener(RowLabelStyle,'LabelStyleChanged',@(es,ed) set(weakThis.Handle,NeedsLabelUpdate=true));
            registerListeners(this,L,'RowLabelStyle');
            this.NeedsLabelUpdate = true;
        end

        % ColumnLabelStyle
        function ColumnLabelStyle = get.ColumnLabelStyle(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            ColumnLabelStyle = this.ColumnLabelStyle_I;
        end

        function set.ColumnLabelStyle(this,ColumnLabelStyle)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                ColumnLabelStyle (1,1) controllib.chart.internal.options.LabelStyle
            end
            unregisterListeners(this,'ColumnLabelStyle')
            this.ColumnLabelStyle_I = ColumnLabelStyle;
            weakThis = matlab.lang.WeakReference(this);
            L = addlistener(ColumnLabelStyle,'LabelStyleChanged',@(es,ed) set(weakThis.Handle,NeedsLabelUpdate=true));
            registerListeners(this,L,'ColumnLabelStyle');
            this.NeedsLabelUpdate = true;
        end

        % SubGridRowLabelStyle
        function SubGridRowLabelStyle = get.SubGridRowLabelStyle(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            SubGridRowLabelStyle = this.SubGridRowLabelStyle_I;
        end

        function set.SubGridRowLabelStyle(this,SubGridRowLabelStyle)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                SubGridRowLabelStyle (1,1) controllib.chart.internal.options.LabelStyle
            end
            unregisterListeners(this,'SubGridRowLabelStyle')
            this.SubGridRowLabelStyle_I = SubGridRowLabelStyle;
            weakThis = matlab.lang.WeakReference(this);
            L = addlistener(SubGridRowLabelStyle,'LabelStyleChanged',@(es,ed) set(weakThis.Handle,NeedsLabelUpdate=true));
            registerListeners(this,L,'SubGridRowLabelStyle');
            this.NeedsLabelUpdate = true;
        end

        % SubGridColumnLabelStyle
        function SubGridColumnLabelStyle = get.SubGridColumnLabelStyle(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            SubGridColumnLabelStyle = this.SubGridColumnLabelStyle_I;
        end

        function set.SubGridColumnLabelStyle(this,SubGridColumnLabelStyle)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                SubGridColumnLabelStyle (1,1) controllib.chart.internal.options.LabelStyle
            end
            unregisterListeners(this,'SubGridColumnLabelStyle')
            this.SubGridColumnLabelStyle_I = SubGridColumnLabelStyle;
            weakThis = matlab.lang.WeakReference(this);
            L = addlistener(SubGridColumnLabelStyle,'LabelStyleChanged',@(es,ed) set(weakThis.Handle,NeedsLabelUpdate=true));
            registerListeners(this,L,'SubGridColumnLabelStyle');
            this.NeedsLabelUpdate = true;
        end

        % AxesStyle
        function AxesStyle = get.AxesStyle(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            AxesStyle = this.AxesStyle_I;
        end

        function set.AxesStyle(this,AxesStyle)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                AxesStyle (1,1) controllib.chart.internal.options.AxesGridStyle
            end
            unregisterListeners(this,'AxesStyle')
            this.AxesStyle_I = AxesStyle;
            weakThis = matlab.lang.WeakReference(this);
            L = addlistener(AxesStyle,'AxesStyleChanged',@(es,ed) set(weakThis.Handle,NeedsLabelUpdate=true));
            registerListeners(this,L,'AxesStyle');
        end

        % InteractionOptions
        function InteractionOptions = get.InteractionOptions(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            InteractionOptions = this.InteractionOptions_I;
        end

        function set.InteractionOptions(this,InteractionOptions)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                InteractionOptions (1,1) matlab.graphics.interaction.interactionoptions.CartesianAxesInteractionOptions
            end
            this.InteractionOptions_I = InteractionOptions;
            disableListeners(this,"InteractionOptionsChangedListener");
            if ~isempty(this.LayoutManager) && isvalid(this.LayoutManager)
                updateInteractions(this.LayoutManager);
            end
            enableListeners(this,"InteractionOptionsChangedListener");  
        end

        % ToolbarButtons
        function ToolbarButtons = get.ToolbarButtons(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            ToolbarButtons = this.ToolbarButtons_I;
        end

        function set.ToolbarButtons(this,ToolbarButtons)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                ToolbarButtons (1,:) string {mustBeNonempty,controllib.chart.internal.layout.AxesGrid.mustBeToolbarButtons}
            end
            this.ToolbarButtons_I = ToolbarButtons;
            if ~isempty(this.LayoutManager) && isvalid(this.LayoutManager)
                updateToolbar(this.LayoutManager);
            end
        end    

        % RestoreButtonPushedFcn
        function RestoreButtonPushedFcn = get.RestoreButtonPushedFcn(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            RestoreButtonPushedFcn = this.RestoreButtonPushedFcn_I;
        end

        function set.RestoreButtonPushedFcn(this,RestoreButtonPushedFcn)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                RestoreButtonPushedFcn function_handle {mustBeScalarOrEmpty}
            end
            this.RestoreButtonPushedFcn_I = RestoreButtonPushedFcn;
        end


        % Toolbar
        function Toolbar = get.Toolbar(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            Toolbar = this.TiledLayout.Toolbar;
        end

        % CurrentInteractionMode
        function currentInteractionMode = get.CurrentInteractionMode(this)
            currentInteractionMode = this.LayoutManager.CurrentInteractionMode;
        end

        function set.CurrentInteractionMode(this,currentInteractionMode)
            this.LayoutManager.CurrentInteractionMode = currentInteractionMode;
        end

        % NVisibleRows
        function NVisibleRows = get.NVisibleGridRows(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            NVisibleRows = nnz(this.GridRowsVisible_I);
        end

        % NVisibleColumns
        function NVisibleColumns = get.NVisibleGridColumns(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            NVisibleColumns = nnz(this.GridColumnsVisible_I);
        end

        % NVisibleSubGridRows
        function NVisibleSubGridRows = get.NVisibleSubGridRows(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            NVisibleSubGridRows = nnz(this.SubGridRowsVisible_I);
        end

        % NVisibleSubGridColumns
        function NVisibleSubGridColumns = get.NVisibleSubGridColumns(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            NVisibleSubGridColumns = nnz(this.SubGridColumnsVisible_I);
        end

        % AllRowVisible
        function AllRowVisible = get.AllRowVisible(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            AllRowVisible = this.SubGridRowVisible & this.GridRowVisible';
            AllRowVisible = AllRowVisible(:);
        end

        % AllColumnVisible
        function AllColumnVisible = get.AllColumnVisible(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            AllColumnVisible = this.SubGridColumnVisible' & this.GridColumnVisible;
            AllColumnVisible = AllColumnVisible(:)';
        end

        % VisibleSubTiledLayouts
        function VisibleSubTiledLayouts = get.VisibleSubTiledLayouts(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            visibleIdx = this.GridRowVisible & this.GridColumnVisible;
            VisibleSubTiledLayouts = reshape(this.SubTiledLayouts(visibleIdx),this.NVisibleGridRows,this.NVisibleGridColumns);
        end

        % VisibleAxes
        function VisibleAxes = get.VisibleAxes(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            visibleIdx = this.AllRowVisible & this.AllColumnVisible;
            VisibleAxes = reshape(this.Axes(visibleIdx),this.NVisibleGridRows*this.NVisibleSubGridRows,this.NVisibleGridColumns*this.NVisibleSubGridColumns);
        end

        % LayoutManagerEnabled
        function Enabled = get.LayoutManagerEnabled(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            Enabled = this.LayoutManager.Enabled;
        end

        function set.LayoutManagerEnabled(this,value)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                value (1,1) matlab.lang.OnOffSwitchState
            end
            this.LayoutManager.Enabled = value;
        end

        % LimitManagerEnabled
        function Enabled = get.LimitManagerEnabled(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            Enabled = this.LimitManager.Enabled;
        end

        function set.LimitManagerEnabled(this,value)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                value (1,1) matlab.lang.OnOffSwitchState
            end
            this.LimitManager.Enabled = value;
        end

        % LabelManagerEnabled
        function Enabled = get.LabelManagerEnabled(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            Enabled = this.LabelManager.Enabled;
        end

        function set.LabelManagerEnabled(this,value)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                value (1,1) matlab.lang.OnOffSwitchState
            end
            this.LabelManager.Enabled = value;
        end

        % Serializable
        function Serializable = get.Serializable(this)
            Serializable = this.TiledLayout.Serializable;
        end

        function set.Serializable(this,Serializable)
            this.TiledLayout.Serializable = Serializable;
        end
    end

    %% Protected methods
    methods (Access = protected)
        function propgrp = getPropertyGroups(this)
            if isscalar(this)
                layoutList = ["Parent","Position","OuterPosition","Padding","Spacing","Visible","NextPlot"];
                layoutTitle = "Layout";
                layoutGrp = matlab.mixin.util.PropertyGroup(layoutList,layoutTitle);
                labelsList = ["Title","Subtitle","XLabel","YLabel","GridRowLabels","GridColumnLabels","SubGridRowLabels","SubGridColumnLabels"];
                labelsTitle = "Labels";
                labelsGrp = matlab.mixin.util.PropertyGroup(labelsList,labelsTitle);
                labelVisList = ["TitleVisible","SubtitleVisible","XLabelVisible","YLabelVisible","GridRowLabelsVisible","GridColumnLabelsVisible","SubGridRowLabelsVisible","SubGridColumnLabelsVisible"];
                labelVisTitle = "Label Visibility";
                labelVisGrp = matlab.mixin.util.PropertyGroup(labelVisList,labelVisTitle);
                gridList = ["GridSize","GridRowVisible","GridColumnVisible","SubGridSize","SubGridRowVisible","SubGridColumnVisible"];
                gridTitle = "Grid Sizing";
                gridGrp = matlab.mixin.util.PropertyGroup(gridList,gridTitle);
                xRulerList = ["XRulerType","XLimitsSharing","XLimits","XLimitsMode","XLimitsFocus","XScale","XLimitPickerBase","AutoAdjustXLimits","ShowXTickLabels","XTickLabelFormat"];
                xRulerTitle = "XRulers";
                xRulerGrp = matlab.mixin.util.PropertyGroup(xRulerList,xRulerTitle);
                yRulerList = ["YRulerType","YLimitsSharing","YLimits","YLimitsMode","YLimitsFocus","YScale","YLimitPickerBase","AutoAdjustYLimits","ShowYTickLabels","YTickLabelFormat"];
                yRulerTitle = "YRulers";
                yRulerGrp = matlab.mixin.util.PropertyGroup(yRulerList,yRulerTitle);
                stylesList = ["TitleStyle","SubtitleStyle","XLabelStyle","YLabelStyle","RowLabelStyle","ColumnLabelStyle","SubGridRowLabelStyle","SubGridColumnLabelStyle","AxesStyle"];
                stylesTitle = "Styles";
                stylesGrp = matlab.mixin.util.PropertyGroup(stylesList,stylesTitle);
                interactionsList = ["ToolbarButtons","RestoreButtonPushedFcn","Interactions"];
                interactionsTitle = "Toolbar and Interactions";
                interactionsGrp = matlab.mixin.util.PropertyGroup(interactionsList,interactionsTitle);
                propgrp = [layoutGrp,labelsGrp,labelVisGrp,gridGrp,xRulerGrp,yRulerGrp,stylesGrp,interactionsGrp];
            else
                propgrp = getPropertyGroups@matlab.mixin.CustomDisplay(this);
            end
        end
    end

    %% Private methods
    methods (Access = private)
        function updateLayout(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end            
            if ~isempty(this.LayoutManager) && isvalid(this.LayoutManager)
                this.NeedsLayoutUpdate = false;
                update(this.LayoutManager);
                notify(this,'LayoutChanged');
            end
        end

        function updateLabels(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end            
            if ~isempty(this.LabelManager) && isvalid(this.LabelManager)
                this.NeedsLabelUpdate = false;
                update(this.LabelManager);
                notify(this,'LabelsChanged');
            end
        end

        function updateXLimits(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            if ~isempty(this.LimitManager) && this.LimitManager.Enabled
                this.NeedsXLimitUpdate = false;
                disableListeners(this,"AxesXLimListener");
                updateXLimits(this.LimitManager);
                enableListeners(this,"AxesXLimListener");
                notify(this,'XLimitsChanged');
            end
        end

        function updateYLimits(this)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
            end
            if ~isempty(this.LimitManager) && this.LimitManager.Enabled
                this.NeedsYLimitUpdate = false;
                disableListeners(this,"AxesYLimListener");
                updateYLimits(this.LimitManager);
                enableListeners(this,"AxesYLimListener");
                notify(this,'YLimitsChanged');
            end
        end

        function addManagerListeners(this)
            weakThis = matlab.lang.WeakReference(this);

            % Layout Manager
            L1 = addlistener(this.LayoutManager,'NextPlotSet',@(es,ed) cbNextPlotSet(weakThis.Handle,ed));
            L2 = addlistener(this.LayoutManager,'XLimChanged',@(es,ed) cbXLimChanged(weakThis.Handle,ed));
            L3 = addlistener(this.LayoutManager,'YLimChanged',@(es,ed) cbYLimChanged(weakThis.Handle,ed));
            L4 = addlistener(this.LayoutManager,'XLimModeChanged',@(es,ed) cbXLimModeChanged(weakThis.Handle,ed));
            L5 = addlistener(this.LayoutManager,'YLimModeChanged',@(es,ed) cbYLimModeChanged(weakThis.Handle,ed));
            L6 = addlistener(this.LayoutManager,'AxesHit',@(es,ed) cbAxesHit(weakThis.Handle,ed));
            L7 = addlistener(this.LayoutManager,'AxesReset',@(es,ed) notify(weakThis.Handle,'AxesReset'));
            L8 = addlistener(this.LayoutManager,'RestoreBtnPushed',@(es,ed) cbRestoreButton(weakThis.Handle,ed));
            L9 = addlistener(this.LayoutManager,'GridSizeChanged',@(es,ed) notify(weakThis.Handle,'GridSizeChanged'));
            L10 = addlistener(this.LayoutManager,'InteractionOptionsChanged',@(es,ed) cbInteractionOptionsChanged(weakThis.Handle,ed));
            registerListeners(this,[L1;L2;L3;L4;L5;L6;L7;L8;L9;L10],["AxesNextPlotListener";"AxesXLimListener";...
                "AxesYLimListener";"AxesXLimModeListener";"AxesYLimModeListener";"AxesHitListener";...
                "AxesResetListener";"RestoreBtnPushedListener";"GridSizeChangedListener";"InteractionOptionsChangedListener"]);
        end

        function cbNextPlotSet(this,ed)
            if strcmp(ed.Data.Axes.NextPlot,'add')
                np = "add";
            else
                np = "replace";
            end
            this.NextPlot = np;
        end

        function cbXLimChanged(this,ed)
            ax = ed.Data.Axes;
            ind = find(ax==this.Axes,1);
            [row,column] = ind2sub(size(this.Axes),ind);
            switch this.XLimitsSharing
                case 'none'
                    this.XLimits_I(row,column) = {ax.XLim};
                    this.XLimitsMode_I(row,column) = {"manual"};
                case 'column'
                    this.XLimits_I(:,column) = {ax.XLim};
                    this.XLimitsMode_I(:,column) = {"manual"};
                case 'all'
                    columns = (1:this.NSubGridColumns_I:this.NGridColumns_I*this.NSubGridColumns_I)+mod(column-1,this.NSubGridColumns_I);
                    this.XLimits_I(:,columns) = {ax.XLim};
                    this.XLimitsMode_I(:,columns) = {"manual"};
            end
            updateXLimits(this);
        end

        function cbYLimChanged(this,ed)
            ax = ed.Data.Axes;
            ind = find(ax==this.Axes,1);
            [row,column] = ind2sub(size(this.Axes),ind);
            switch this.YLimitsSharing
                case 'none'
                    this.YLimits_I(row,column) = {ax.YLim};
                    this.YLimitsMode_I(row,column) = {"manual"};
                case 'row'
                    this.YLimits_I(row,:) = {ax.YLim};
                    this.YLimitsMode_I(row,:) = {"manual"};
                case 'all'
                    rows = (1:this.NSubGridRows_I:this.NGridRows_I*this.NSubGridRows_I)+mod(row-1,this.NSubGridRows_I);
                    this.YLimits_I(rows,:) = {ax.YLim};
                    this.YLimitsMode_I(rows,:) = {"manual"};
            end
            updateYLimits(this);
        end

        function cbXLimModeChanged(this,ed)
            ax = ed.Data.Axes;
            ind = find(ax==this.Axes,1);
            [row,column] = ind2sub(size(this.Axes),ind);
            switch this.XLimitsSharing
                case 'none'
                    this.XLimitsMode_I(row,column) = {string(ax.XLimMode)};
                case 'column'
                    this.XLimitsMode_I(:,column) = {string(ax.XLimMode)};
                case 'all'
                    columns = (1:this.NSubGridColumns_I:this.NGridColumns_I*this.NSubGridColumns_I)+mod(column-1,this.NSubGridColumns_I);
                    this.XLimitsMode_I(:,columns) = {string(ax.XLimMode)};
            end
            updateXLimits(this);
        end

        function cbYLimModeChanged(this,ed)
            ax = ed.Data.Axes;
            ind = find(ax==this.Axes,1);
            [row,column] = ind2sub(size(this.Axes),ind);
            switch this.YLimitsSharing
                case 'none'
                    this.YLimitsMode_I(row,column) = {string(ax.YLimMode)};
                case 'row'
                    this.YLimitsMode_I(row,:) = {string(ax.YLimMode)};
                case 'all'
                    rows = (1:this.NSubGridRows_I:this.NGridRows_I*this.NSubGridRows_I)+mod(row-1,this.NSubGridRows_I);
                    this.YLimitsMode_I(rows,:) = {string(ax.YLimMode)};
            end
            updateYLimits(this);
        end

        function cbAxesHit(this,ed)
            ax = ed.Data.Axes;
            ind = find(ax==this.VisibleAxes,1);
            [row,column] = ind2sub(size(this.VisibleAxes),ind);
            Data = struct("Axes",ax,"Row",row,"Column",column);
            ed = controllib.chart.internal.utils.GenericEventData(Data);
            notify(this,"AxesHit",ed);
        end

        function cbInteractionOptionsChanged(this,ed)
            ax = ed.Data.Axes;
            this.InteractionOptions = ax.InteractionOptions;          
        end

        function cbRestoreButton(this,ed)
            % Check if AxesGrid has custom restore button callback,
            % otherwise set to XLimitsMode/YLimitsMode to 'auto'
            if isempty(this.RestoreButtonPushedFcn)
                this.XLimitsMode = "auto";
                this.YLimitsMode = "auto";
                update(this);
            else
                this.RestoreButtonPushedFcn(this,ed);
            end
        end

        function mustBeRowSize(this,value)
            controllib.chart.internal.utils.validators.mustBeSize(value,[this.NGridRows_I 1]);
        end

        function mustBeColumnSize(this,value)
            controllib.chart.internal.utils.validators.mustBeSize(value,[1 this.NGridColumns_I]);
        end

        function mustBeSubGridRowSize(this,value)
            controllib.chart.internal.utils.validators.mustBeSize(value,[this.NSubGridRows_I 1]);
        end

        function mustBeSubGridColumnSize(this,value)
            controllib.chart.internal.utils.validators.mustBeSize(value,[1 this.NSubGridColumns_I]);
        end

        function XLimits = validateXLimits(this,XLimits)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                XLimits (:,:)
            end
            sz = size(this.XLimits);
            try
                if iscell(XLimits)
                    controllib.chart.internal.utils.validators.mustBeSize(XLimits,sz);
                else
                    XLimits = repmat({XLimits},sz);
                end
                for ii = 1:numel(XLimits)
                    controllib.chart.internal.utils.validators.mustBeLimit(XLimits{ii},this.XRulerType);
                end
            catch
                error(message('Controllib:plots:mustBeLimitArray',this.XRulerType,sz(1),sz(2)));
            end
        end

        function XLimitsMode = validateXLimitsMode(this,XLimitsMode)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                XLimitsMode (:,:)
            end
            sz = size(this.XLimitsMode);
            try
                if iscell(XLimitsMode)
                    controllib.chart.internal.utils.validators.mustBeSize(XLimitsMode,sz);
                else
                    XLimitsMode = repmat({XLimitsMode},sz);
                end
                for ii = 1:numel(XLimitsMode)
                    mustBeMember(XLimitsMode{ii},["auto","manual"]);
                    XLimitsMode{ii} = string(XLimitsMode{ii});
                    controllib.chart.internal.utils.validators.mustBeSize(XLimitsMode{ii},[1 1]);
                end
            catch
                error(message('Controllib:plots:mustBeLimitModeArray',sz(1),sz(2)));
            end
        end

        function XLimitsFocus = validateXLimitsFocus(this,XLimitsFocus)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                XLimitsFocus (:,:)
            end
            sz = size(this.XLimitsFocus);
            try
                if iscell(XLimitsFocus)
                    controllib.chart.internal.utils.validators.mustBeSize(XLimitsFocus,sz);
                else
                    XLimitsFocus = repmat({XLimitsFocus},sz);
                end
                for ii = 1:numel(XLimitsFocus)
                    controllib.chart.internal.utils.validators.mustBeLimit(XLimitsFocus{ii},this.XRulerType);
                end
            catch
                error(message('Controllib:plots:mustBeLimitArray',this.XRulerType,sz(1),sz(2)));
            end
        end

        function YLimits = validateYLimits(this,YLimits)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                YLimits (:,:)
            end
            sz = size(this.YLimits);
            try
                if iscell(YLimits)
                    controllib.chart.internal.utils.validators.mustBeSize(YLimits,sz);
                else
                    YLimits = repmat({YLimits},sz);
                end
                for ii = 1:numel(YLimits)
                    controllib.chart.internal.utils.validators.mustBeLimit(YLimits{ii},this.YRulerType);
                end
            catch
                error(message('Controllib:plots:mustBeLimitArray',this.YRulerType,sz(1),sz(2)));
            end
        end

        function YLimitsMode = validateYLimitsMode(this,YLimitsMode)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                YLimitsMode (:,:)
            end
            sz = size(this.YLimitsMode);
            try
                if iscell(YLimitsMode)
                    controllib.chart.internal.utils.validators.mustBeSize(YLimitsMode,sz);
                else
                    YLimitsMode = repmat({YLimitsMode},sz);
                end
                for ii = 1:numel(YLimitsMode)
                    mustBeMember(YLimitsMode{ii},["auto","manual"]);
                    YLimitsMode{ii} = string(YLimitsMode{ii});
                    controllib.chart.internal.utils.validators.mustBeSize(YLimitsMode{ii},[1 1]);
                end
            catch
                error(message('Controllib:plots:mustBeLimitModeArray',sz(1),sz(2)));
            end
        end

        function YLimitsFocus = validateYLimitsFocus(this,YLimitsFocus)
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                YLimitsFocus (:,:)
            end
            sz = size(this.YLimitsFocus);
            try
                if iscell(YLimitsFocus)
                    controllib.chart.internal.utils.validators.mustBeSize(YLimitsFocus,sz);
                else
                    YLimitsFocus = repmat({YLimitsFocus},sz);
                end
                for ii = 1:numel(YLimitsFocus)
                    controllib.chart.internal.utils.validators.mustBeLimit(YLimitsFocus{ii},this.YRulerType);
                end
            catch
                error(message('Controllib:plots:mustBeLimitArray',this.YRulerType,sz(1),sz(2)));
            end
        end
    end

    %% Static private methods
    methods (Static,Access=private)
        function mustBeInitFocusSize(value,gridSize,subGridSize)
            if ~isempty(value)
                controllib.chart.internal.utils.validators.mustBeSize(value,gridSize.*subGridSize);
            end
        end

        function mustBeInitRowSize(value,gridSize)
            controllib.chart.internal.utils.validators.mustBeSize(value,[gridSize(1) 1]);
        end

        function mustBeInitColumnSize(value,gridSize)
            controllib.chart.internal.utils.validators.mustBeSize(value,[1 gridSize(2)]);
        end

        function mustBeToolbarButtons(toolbarButtons)
            mustBeMember(toolbarButtons,["default","none","export","brush",...
                "datacursor","zoomin","zoomout","pan","rotate","restoreview"])
            if any(ismember(toolbarButtons,["default","none"]))
                mustBeScalarOrEmpty(toolbarButtons);
            else
                controllib.chart.internal.utils.validators.mustBeSize(toolbarButtons,size(unique(toolbarButtons)));                
            end
        end
    end

    %% Hidden methods
    methods (Hidden)
        function hAxes = getAxes(this,idxInfo)
            % ax = getAxes(AxesGrid,"Row",rowIdx,"Column",columnIdx)
            %
            % Returns the axes stored in AxesGrid.
            %
            % getAxes(AxesGrid) returns all axes getAxes(AxesGrid,"Row",1)
            % returns the first row getAxes(AxesGrid,"Row",2,"Column"1)
            % returns the axes in
            %   second row and first column
            arguments
                this (1,1) controllib.chart.internal.layout.AxesGrid
                idxInfo.Row (1,:) double {mustBePositive,mustBeInteger} = 1:this.NGridRows_I
                idxInfo.Column (1,:) double {mustBePositive,mustBeInteger} = 1:this.NGridColumns_I
                idxInfo.SubGridRow (1,:) double {mustBePositive,mustBeInteger} = 1:this.NSubGridRows_I
                idxInfo.SubGridColumn (1,:) double {mustBePositive,mustBeInteger} = 1:this.NSubGridColumns_I
            end
            axesRowIdx = zeros(length(idxInfo.Row)*length(idxInfo.SubGridRow),1);
            axesColumnIdx = zeros(length(idxInfo.Column)*length(idxInfo.SubGridColumn),1);
            for ii = 1:length(idxInfo.Row)
                row = idxInfo.Row(ii);
                for jj = 1:length(idxInfo.SubGridRow)
                    subGridRow = idxInfo.SubGridRow(jj);
                    axesRowIdx((ii-1)*length(idxInfo.SubGridRow)+jj) = (row-1)*this.SubGridSize(1)+subGridRow;
                end
            end
            for ii = 1:length(idxInfo.Column)
                column = idxInfo.Column(ii);
                for jj = 1:length(idxInfo.SubGridColumn)
                    subGridColumn = idxInfo.SubGridColumn(jj);
                    axesColumnIdx((ii-1)*length(idxInfo.SubGridColumn)+jj) = (column-1)*this.SubGridSize(2)+subGridColumn;
                end
            end
            hAxes = this.Axes(axesRowIdx,axesColumnIdx);
        end

        function tcl = qeGetLayout(this)
            tcl = this.TiledLayout;
        end

        function subTCLs = qeGetSubLayouts(this)
            subTCLs = this.SubTiledLayouts;
        end

        function ax = qeGetAxes(this)
            ax = this.Axes;
        end

        function layoutManager = qeGetLayoutManager(this)
            layoutManager = this.LayoutManager;
        end

        function limitManager = qeGetLimitManager(this)
            limitManager = this.LimitManager;
        end

        function labelManager = qeGetLabelManager(this)
            labelManager = this.LabelManager;
        end

        function enableDisableAxesLimitModeListeners(this)
            % Workaround for CSD and axis('equal')
            if isListenerEnabled(this,"AxesXLimModeListener")
                disableListeners(this,["AxesXLimModeListener";"AxesYLimModeListener"]);
            else
                enableListeners(this,["AxesXLimModeListener";"AxesYLimModeListener"]);
            end
        end

        function qePushRestoreButton(this)
            ed = controllib.chart.internal.utils.GenericEventData();
            cbRestoreButton(this,ed);
        end
    end
end