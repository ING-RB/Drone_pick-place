classdef (Abstract) EditorView < handle & matlab.mixin.SetGet
    % Editor Wrapper

    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent)        
        XLimits
        XLimitsMode
        YLimits
        YLimitsMode
    end

    properties (Dependent,SetAccess=private)
        Title
        Subtitle
        XLabel
        YLabel
        AxesStyle
    end

    properties (Access=protected,Transient,NonCopyable,WeakHandle)
        Chart controllib.chart.internal.foundation.AbstractPlot {mustBeScalarOrEmpty}
    end

    %% Constructor
    methods
        function this = EditorView(chart)
            arguments
                chart (1,1) controllib.chart.internal.foundation.AbstractPlot
            end
            this.Chart = chart;
        end
    end

    %% Get/Set
    methods
        % Title
        function Title = get.Title(this)
            Title = this.Chart.Title;
        end

        % Subtitle
        function Subtitle = get.Subtitle(this)
            Subtitle = this.Chart.Subtitle;
        end

        % XLabel
        function XLabel = get.XLabel(this)
            XLabel = this.Chart.XLabel;
        end

        % YLabel
        function YLabel = get.YLabel(this)
            YLabel = this.Chart.YLabel;
        end

        % AxesStyle
        function AxesStyle = get.AxesStyle(this)
            AxesStyle = this.Chart.AxesStyle;
        end

        % XLimits
        function XLimits = get.XLimits(this)
            XLimits = this.Chart.XLimits;
        end

        function set.XLimits(this,XLimits)
            try
                this.Chart.XLimits = XLimits;
            catch ME
                throw(ME);
            end
        end

        % XLimitsMode
        function XLimitsMode = get.XLimitsMode(this)
            XLimitsMode = this.Chart.XLimitsMode;
        end

        function set.XLimitsMode(this,XLimitsMode)
            try
                this.Chart.XLimitsMode = XLimitsMode;
            catch ME
                throw(ME);
            end
        end

        % YLimits
        function YLimits = get.YLimits(this)
            YLimits = this.Chart.YLimits;
        end

        function set.YLimits(this,YLimits)
            try
                this.Chart.YLimits = YLimits;
            catch ME
                throw(ME);
            end
        end

        % YLimitsMode
        function YLimitsMode = get.YLimitsMode(this)
            YLimitsMode = this.Chart.YLimitsMode;
        end

        function set.YLimitsMode(this,YLimitsMode)
            try
                this.Chart.YLimitsMode = YLimitsMode;
            catch ME
                throw(ME);
            end
        end
    end

    %% Static hidden methods
    methods (Static,Hidden)
        function props = getCopyableProperties()
            props = ["XLimits";"XLimitsMode";...
            "YLimits";"YLimitsMode"];
        end
    end
end