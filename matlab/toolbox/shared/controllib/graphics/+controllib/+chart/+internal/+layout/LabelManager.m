classdef LabelManager < matlab.mixin.SetGet
    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (Access=?controllib.chart.internal.layout.AxesGrid)
        Enabled (1,1) matlab.lang.OnOffSwitchState = true
    end

    % Read-only
    properties (Dependent,Access=private)
        Title
        Subtitle
        XLabel
        YLabel
        TiledLayout
        SubTiledLayouts
        Axes

        SubGridSize

        GridRowLabels
        GridColumnLabels
        SubGridRowLabels
        SubGridColumnLabels

        GridRowLabelsVisible
        GridColumnLabelsVisible
        SubGridRowLabelsVisible
        SubGridColumnLabelsVisible

        GridRowLabelsIndex
        GridColumnLabelsIndex
        SubGridRowLabelsIndex
        SubGridColumnLabelsIndex

        TitleStyle
        SubtitleStyle
        XLabelStyle
        YLabelStyle
        RowLabelStyle
        ColumnLabelStyle
        SubGridRowLabelStyle
        SubGridColumnLabelStyle
        AxesStyle
    end

    properties (Access=private,WeakHandle)
        AxesGrid controllib.chart.internal.layout.AxesGrid {mustBeScalarOrEmpty}
    end

    %% Constructor
    methods 
        function this = LabelManager(axesGrid)
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

        % SubTiledLayouts
        function SubTiledLayouts = get.SubTiledLayouts(this)
            SubTiledLayouts = this.AxesGrid.SubTiledLayouts;
        end

        % Axes
        function Axes = get.Axes(this)
            Axes = this.AxesGrid.Axes;
        end

        % Title
        function Title = get.Title(this)
            Title = this.TiledLayout.Title;
        end

        % Subtitle
        function Subtitle = get.Subtitle(this)
            Subtitle = this.TiledLayout.Subtitle;
        end

        % XLabel
        function XLabel = get.XLabel(this)
            XLabel = this.TiledLayout.XLabel;
        end

        % YLabel
        function YLabel = get.YLabel(this)
            YLabel = this.TiledLayout.YLabel;
        end

        % TitleStyle
        function TitleStyle = get.TitleStyle(this)
            TitleStyle = this.AxesGrid.TitleStyle;
        end

        % SubtitleStyle
        function SubtitleStyle = get.SubtitleStyle(this)
            SubtitleStyle = this.AxesGrid.SubtitleStyle;
        end

        % XLabelStyle
        function XLabelStyle = get.XLabelStyle(this)
            XLabelStyle = this.AxesGrid.XLabelStyle;
        end

        % YLabelStyle
        function YLabelStyle = get.YLabelStyle(this)
            YLabelStyle = this.AxesGrid.YLabelStyle;
        end

        % RowLabelStyle
        function RowLabelStyle = get.RowLabelStyle(this)
            RowLabelStyle = this.AxesGrid.RowLabelStyle;
        end

        % ColumnLabelStyle
        function ColumnLabelStyle = get.ColumnLabelStyle(this)
            ColumnLabelStyle = this.AxesGrid.ColumnLabelStyle;
        end

        % SubGridRowLabelStyle
        function SubGridRowLabelStyle = get.SubGridRowLabelStyle(this)
            SubGridRowLabelStyle = this.AxesGrid.SubGridRowLabelStyle;
        end

        % SubGridColumnLabelStyle
        function SubGridColumnLabelStyle = get.SubGridColumnLabelStyle(this)
            SubGridColumnLabelStyle = this.AxesGrid.SubGridColumnLabelStyle;
        end

        % RowLabels
        function RowLabels = get.GridRowLabels(this)
            RowLabels = this.AxesGrid.GridRowLabels;
        end

        % ColumnLabels
        function ColumnLabels = get.GridColumnLabels(this)
            ColumnLabels = this.AxesGrid.GridColumnLabels;
        end

        % SubGridRowLabels
        function SubGridRowLabels = get.SubGridRowLabels(this)
            SubGridRowLabels = this.AxesGrid.SubGridRowLabels;
        end

        % SubGridColumnLabels
        function SubGridColumnLabels = get.SubGridColumnLabels(this)
            SubGridColumnLabels = this.AxesGrid.SubGridColumnLabels;
        end

        % RowLabelsVisible
        function RowLabelsVisible = get.GridRowLabelsVisible(this)
            RowLabelsVisible = this.AxesGrid.GridRowLabelsVisible;
        end

        % ColumnLabelsVisible
        function ColumnLabelsVisible = get.GridColumnLabelsVisible(this)
            ColumnLabelsVisible = this.AxesGrid.GridColumnLabelsVisible;
        end

        % SubGridRowLabelsVisible
        function SubGridRowLabelsVisible = get.SubGridRowLabelsVisible(this)
            SubGridRowLabelsVisible = this.AxesGrid.SubGridRowLabelsVisible;
        end

        % SubGridColumnLabelsVisible
        function SubGridColumnLabelsVisible = get.SubGridColumnLabelsVisible(this)
            SubGridColumnLabelsVisible = this.AxesGrid.SubGridColumnLabelsVisible;
        end

        % RowLabelIndex
        function RowLabelIndex = get.GridRowLabelsIndex(this)
            RowLabelIndex = find(this.AxesGrid.GridColumnVisible,1);
            if isempty(RowLabelIndex)
                RowLabelIndex = 1;
            end
        end

        % ColumnLabelIndex
        function ColumnLabelIndex = get.GridColumnLabelsIndex(this)
            ColumnLabelIndex = find(this.AxesGrid.GridRowVisible,1);
            if isempty(ColumnLabelIndex)
                ColumnLabelIndex = 1;
            end
        end

        % SubGridRowLabelIndex
        function SubGridRowLabelIndex = get.SubGridRowLabelsIndex(this)
            SubGridRowLabelIndex = find(this.AxesGrid.SubGridColumnVisible,1);
            if isempty(SubGridRowLabelIndex)
                SubGridRowLabelIndex = 1;
            end
        end

        % SubGridColumnLabelIndex
        function SubGridColumnLabelIndex = get.SubGridColumnLabelsIndex(this)
            SubGridColumnLabelIndex = find(this.AxesGrid.SubGridRowVisible,1);
            if isempty(SubGridColumnLabelIndex)
                SubGridColumnLabelIndex = 1;
            end
        end

        % AxesStyle
        function AxesStyle = get.AxesStyle(this)
            AxesStyle = this.AxesGrid.AxesStyle;
        end

        % SubGridSize
        function SubGridSize = get.SubGridSize(this)
            SubGridSize = this.AxesGrid.SubGridSize;
        end
    end

    %% AxesGrid methods
    methods (Access = ?controllib.chart.internal.layout.AxesGrid)
        function update(this)
            if this.Enabled
                updateAxesStyle(this);
                updateTitle(this);
                updateSubtitle(this);
                updateXLabel(this);
                updateYLabel(this);
                updateRowLabels(this);
                updateColumnLabels(this);
                updateSubGridRowLabels(this);
                updateSubGridColumnLabels(this);
                for ii = 1:size(this.SubTiledLayouts,1)
                    for jj = 1:size(this.SubTiledLayouts,2)
                        this.SubTiledLayouts(ii,jj).Tag = getSubTCLTag(this,ii,jj);
                    end
                end
                for ii = 1:size(this.Axes,1)
                    for jj = 1:size(this.Axes,2)
                        this.Axes(ii,jj).Tag = getAxesTag(this,ii,jj);
                    end
                end
            end
        end
    end

    %% Private methods
    methods (Access=private)
        function updateTitle(this)
            if this.Enabled
                label = this.Title;
                style = this.TitleStyle;
                this.updateLabels(label,style);
            end
        end

        function updateSubtitle(this)
            if this.Enabled
                label = this.Subtitle;
                style = this.SubtitleStyle;
                this.updateLabels(label,style);
            end
        end

        function updateXLabel(this)
            if this.Enabled
                label = this.XLabel;
                style = this.XLabelStyle;
                this.updateLabels(label,style);
            end
        end

        function updateYLabel(this)
            if this.Enabled
                label = this.YLabel;
                style = this.YLabelStyle;
                this.updateLabels(label,style);
            end
        end

        function updateRowLabels(this)
            if this.Enabled
                labels = [this.SubTiledLayouts.YLabel];
                style = this.RowLabelStyle;
                this.updateLabels(labels,style);
                set(labels,Visible=this.GridRowLabelsVisible);
                set(labels,String="");
                activeLabels = [this.SubTiledLayouts(:,this.GridRowLabelsIndex).YLabel];
                for ii = 1:length(activeLabels)
                    activeLabels(ii).String = this.GridRowLabels(ii);
                end
            end
        end

        function updateColumnLabels(this)
            if this.Enabled
                labels = [this.SubTiledLayouts.Title];
                style = this.ColumnLabelStyle;
                this.updateLabels(labels,style);
                set(labels,Visible=this.GridColumnLabelsVisible);
                set(labels,String="");
                activeLabels = [this.SubTiledLayouts(this.GridColumnLabelsIndex,:).Title];
                for ii = 1:length(activeLabels)
                    activeLabels(ii).String = this.GridColumnLabels(ii);
                end
            end
        end

        function updateSubGridRowLabels(this)
            if this.Enabled
                labels = [this.Axes.YLabel];
                style = this.SubGridRowLabelStyle;
                this.updateLabels(labels,style);
                set(labels,Visible=this.SubGridRowLabelsVisible);
                set(labels,String="");
                activeLabels = [this.Axes(:,this.SubGridRowLabelsIndex).YLabel];
                for ii = 1:length(activeLabels)
                    idx = mod(ii-1,length(this.SubGridRowLabels))+1;
                    activeLabels(ii).String = this.SubGridRowLabels(idx);
                end
            end
        end

        function updateSubGridColumnLabels(this)
            if this.Enabled
                labels = [this.Axes.Title];
                style = this.SubGridColumnLabelStyle;
                this.updateLabels(labels,style);
                set(labels,Visible=this.SubGridColumnLabelsVisible);
                set(labels,String="");
                activeLabels = [this.Axes(this.SubGridColumnLabelsIndex,:).Title];
                for ii = 1:length(activeLabels)
                    idx = mod(ii-1,length(this.SubGridColumnLabels))+1;
                    activeLabels(ii).String = this.SubGridColumnLabels(idx);
                end
            end
        end

        function updateAxesStyle(this)
            if this.Enabled
                ax = this.Axes;

                % Set box on axes
                set(ax,Box=this.AxesStyle.Box,LineWidth=this.AxesStyle.BoxLineWidth);
                switch this.AxesStyle.BackgroundColorMode
                    case "auto"
                        controllib.plot.internal.utils.setColorProperty(ax,...
                            "Color",this.AxesStyle.DefaultBackgroundColor);
                    case "manual"
                        controllib.plot.internal.utils.setColorProperty(ax,...
                            "Color",this.AxesStyle.BackgroundColor);
                end

                % Set color on Axes Rulers
                switch this.AxesStyle.RulerColorMode
                    case "auto"
                        controllib.plot.internal.utils.setColorProperty(ax,...
                            ["XColor";"YColor"],this.AxesStyle.DefaultRulerColor);
                    case "manual"
                        controllib.plot.internal.utils.setColorProperty(ax,...
                            ["XColor";"YColor"],this.AxesStyle.RulerColor);
                end

                % Set grid visibility
                set(ax,XGrid=this.AxesStyle.XGrid);
                set(ax,YGrid=this.AxesStyle.YGrid);
                set(ax,XMinorGrid=this.AxesStyle.XMinorGrid);
                set(ax,YMinorGrid=this.AxesStyle.YMinorGrid);

                % Set grid color
                switch this.AxesStyle.GridColorMode
                    case "auto"
                        controllib.plot.internal.utils.setColorProperty(ax,...
                            "GridColor",this.AxesStyle.DefaultGridColor);
                    case "manual"
                        controllib.plot.internal.utils.setColorProperty(ax,...
                            "GridColor",this.AxesStyle.GridColor);
                end
                switch this.AxesStyle.MinorGridColorMode
                    case "auto"
                        controllib.plot.internal.utils.setColorProperty(ax,...
                            "MinorGridColor",this.AxesStyle.DefaultMinorGridColor);
                    case "manual"
                        controllib.plot.internal.utils.setColorProperty(ax,...
                            "MinorGridColor",this.AxesStyle.MinorGridColor);
                end

                % Set grid linewidth
                set(ax,GridLineWidth=this.AxesStyle.GridLineWidth);
                set(ax,MinorGridLineWidth=this.AxesStyle.MinorGridLineWidth);

                % Set grid linestyle
                set(ax,GridLineStyle=this.AxesStyle.GridLineStyle);
                set(ax,MinorGridLineStyle=this.AxesStyle.MinorGridLineStyle);

                % Set grid alpha
                if this.AxesStyle.HasCustomGrid %hide grid
                    set(ax,GridAlpha=0);
                    set(ax,MinorGridAlpha=0);
                else
                    set(ax,GridAlpha=this.AxesStyle.GridAlpha);
                    set(ax,MinorGridAlpha=this.AxesStyle.MinorGridAlpha);
                end

                % Set Style on Axes Rulers
                styleProps = string(properties(this.AxesStyle));
                styleProps = setdiff(styleProps,["BackgroundColor","Box",...
                    "BoxLineWidth","RulerColor","XGrid","YGrid","XMinorGrid",...
                    "YMinorGrid","GridColor","GridLineWidth","GridLineStyle",...
                    "GridAlpha","MinorGridColor","MinorGridLineWidth",...
                    "MinorGridLineStyle","MinorGridAlpha"],'stable');

                for ii = 1:length(styleProps)
                    set(ax,styleProps(ii),this.AxesStyle.(styleProps(ii)));
                end
            end
        end

        function tag = getSubTCLTag(this,row,column)
            rowLabel = this.GridRowLabels(row);
            columnLabel = this.GridColumnLabels(column);
            if rowLabel ~= "" && columnLabel ~= ""
                tag = rowLabel + ", " + columnLabel;
            elseif rowLabel ~= ""
                tag = rowLabel;
            elseif columnLabel ~= ""
                tag = columnLabel;
            else
                tag = "";
            end
        end

        function tag = getAxesTag(this,axrow,axcolumn)
            row = ceil(axrow/this.SubGridSize(1));
            column = ceil(axcolumn/this.SubGridSize(2));
            rowLabel = this.GridRowLabels(row);
            columnLabel = this.GridColumnLabels(column);
            if rowLabel ~= "" && columnLabel ~= ""
                tag = rowLabel + ", " + columnLabel;
            elseif rowLabel ~= ""
                tag = rowLabel;
            elseif columnLabel ~= ""
                tag = columnLabel;
            else
                tag = "";
            end
            subrow = mod(axrow-1,this.SubGridSize(1))+1;
            subcolumn = mod(axcolumn-1,this.SubGridSize(2))+1;
            subGridRowLabel = this.SubGridRowLabels(subrow);
            subGridColumnLabel = this.SubGridColumnLabels(subcolumn);
            if subGridRowLabel ~= "" && subGridColumnLabel ~= ""
                subtag = subGridRowLabel + ", " + subGridColumnLabel;
            elseif subGridRowLabel ~= ""
                subtag = subGridRowLabel;
            elseif subGridColumnLabel ~= ""
                subtag = subGridColumnLabel;
            else
                subtag = "";
            end
            if subtag ~= ""
                if tag == ""
                    tag = subtag;
                else
                    tag = tag + "; " + subtag;
                end
            end
        end
    end

    methods (Static,Access=private)
        function updateLabels(labels,style)
            % Color
            switch style.ColorMode
                case "auto"
                    controllib.plot.internal.utils.setColorProperty(labels,"Color",style.DefaultColor);
                case "manual"
                    controllib.plot.internal.utils.setColorProperty(labels,"Color",style.Color);
            end

            % Other properties
            styleProps = string(properties(style));
            styleProps = setdiff(styleProps,'Color','stable');
            
            for ii = 1:length(styleProps)
                set(labels,styleProps(ii),style.(styleProps(ii)));
            end
        end
    end
end