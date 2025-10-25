classdef ViewStyle < matlab.mixin.SetGet
    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = immutable)
        Title
        Subtitle
        XLabel
        YLabel
        ColumnLabels
        RowLabels
        Axes
    end

    properties (Dependent,SetAccess = private)
        InputLabels
        OutputLabels
    end

    %% Constructor
    methods
        function this = ViewStyle(chart)
            tcl = getChartLayout(chart);
            this.Title = controllib.chart.internal.options.LabelStyle(TiledLayout=tcl);
            this.Subtitle = controllib.chart.internal.options.LabelStyle(TiledLayout=tcl);
            this.XLabel = controllib.chart.internal.options.LabelStyle(TiledLayout=tcl);
            this.YLabel = controllib.chart.internal.options.LabelStyle(TiledLayout=tcl);
            this.ColumnLabels = controllib.chart.internal.options.LabelStyle(TiledLayout=tcl);
            this.ColumnLabels.DefaultColor = "--mw-graphics-borderColor-axes-secondary";
            this.RowLabels = controllib.chart.internal.options.LabelStyle(TiledLayout=tcl);
            this.RowLabels.DefaultColor = "--mw-graphics-borderColor-axes-secondary";
            this.Axes = controllib.chart.internal.options.AxesGridStyle(TiledLayout=tcl);
            this.Axes.DefaultRulerColor = "--mw-graphics-borderColor-axes-secondary";
        end
    end

    %% Get/Set
    methods
        % InputLabels
        function InputLabels = get.InputLabels(this)
            InputLabels = this.ColumnLabels;
        end

        % OutputLabels
        function OutputLabels = get.OutputLabels(this)
            OutputLabels = this.RowLabels;
        end
    end
    
    %% Public methods
    methods
        function initialize(this,chart)
            % Label styles
            if isa(chart,'controllib.chart.internal.foundation.RowColumnPlot')
                labels = ["Title";"Subtitle";"XLabel";"YLabel";"RowLabels";"ColumnLabels"];
            elseif isa(chart,'controllib.chart.internal.foundation.SingleColumnPlot')
                labels = ["Title";"Subtitle";"XLabel";"YLabel";"RowLabels"];
            else
                labels = ["Title";"Subtitle";"XLabel";"YLabel"];
            end
            labelProps = controllib.chart.internal.options.AxesLabel.getCopyableProperties();
            labelProps = setdiff(labelProps,["String";"Visible"],'stable');
            for ii = 1:length(labels)
                for jj = 1:length(labelProps)
                    this.(labels(ii)).(labelProps(jj)) = chart.(labels(ii)).(labelProps(jj));
                end
            end
            % Axes style
            styleProps = controllib.chart.internal.options.AxesStyle.getCopyableProperties();
            customGridProps = controllib.chart.internal.options.AxesStyle.getCustomGridProperties();
            styleProps = setdiff(styleProps,["GridVisible";"MinorGridVisible";customGridProps],'stable');
            for ii = 1:length(styleProps)
                this.Axes.(styleProps(ii)) = chart.AxesStyle.(styleProps(ii));
            end
            this.Axes.XGrid = chart.AxesStyle.GridVisible;
            this.Axes.YGrid = chart.AxesStyle.GridVisible;
            this.Axes.XMinorGrid = chart.AxesStyle.MinorGridVisible;
            this.Axes.YMinorGrid = chart.AxesStyle.MinorGridVisible;
        end
    end
end
