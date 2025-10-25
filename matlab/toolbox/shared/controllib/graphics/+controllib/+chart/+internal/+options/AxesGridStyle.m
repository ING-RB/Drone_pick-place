classdef AxesGridStyle < matlab.mixin.SetGet & matlab.mixin.Copyable & matlab.mixin.CustomDisplay
    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent)
        BackgroundColor
        Box
        BoxLineWidth
        FontSize
        FontWeight
        FontAngle
        FontName
        RulerColor
        XGrid
        YGrid
        XMinorGrid
        YMinorGrid
        GridColor
        GridLineWidth
        GridLineStyle
        GridAlpha
        MinorGridColor
        MinorGridLineWidth
        MinorGridLineStyle
        MinorGridAlpha
    end

    properties (Hidden,Dependent)
        BackgroundColorMode
        RulerColorMode
        GridColorMode
        MinorGridColorMode
    end

    properties (Access=private)
        BackgroundColor_I
        BackgroundColorMode_I
        Box_I
        BoxLineWidth_I
        FontSize_I
        FontWeight_I
        FontAngle_I
        FontName_I
        RulerColor_I
        RulerColorMode_I
        XGrid_I
        YGrid_I
        XMinorGrid_I
        YMinorGrid_I
        GridColor_I
        GridColorMode_I
        GridLineWidth_I
        GridLineStyle_I
        GridAlpha_I
        MinorGridColor_I
        MinorGridColorMode_I
        MinorGridLineWidth_I
        MinorGridLineStyle_I
        MinorGridAlpha_I
    end
    
    properties (Dependent,Access=private)
        Theme
    end

    properties (Access=private,Transient,WeakHandle)
        TiledLayout matlab.graphics.layout.TiledChartLayout {mustBeScalarOrEmpty} = matlab.graphics.layout.TiledChartLayout.empty
    end

    properties (Hidden)
        DefaultBackgroundColor = "--mw-graphics-backgroundColor-axes-primary"
        DefaultRulerColor = "--mw-graphics-borderColor-axes-primary"
        DefaultGridColor = "--mw-graphics-borderColor-axes-quaternary"
        DefaultMinorGridColor = "--mw-graphics-borderColor-axes-quaternary"
        HasCustomGrid (1,1) matlab.lang.OnOffSwitchState = false
    end

    %% Events
    events
        AxesStyleChanged
    end

    %% Constructor
    methods
        function this = AxesGridStyle(optionalArguments)
            arguments
                optionalArguments.TiledLayout matlab.graphics.layout.TiledChartLayout {mustBeScalarOrEmpty} = matlab.graphics.layout.TiledChartLayout.empty
                optionalArguments.BackgroundColor {validatecolor(optionalArguments.BackgroundColor)} = get(groot,'DefaultAxesColor')
                optionalArguments.Box (1,1) matlab.lang.OnOffSwitchState = true
                optionalArguments.BoxLineWidth (1,1) double {mustBePositive,mustBeFinite} = get(groot,'DefaultAxesLineWidth')
                optionalArguments.FontSize (1,1) double {mustBePositive,mustBeFinite} = get(groot,'DefaultAxesFontSize')
                optionalArguments.FontWeight (1,1) string {mustBeMember(optionalArguments.FontWeight,["normal","bold"])} = get(groot,'DefaultAxesFontWeight')
                optionalArguments.FontAngle (1,1) string {mustBeMember(optionalArguments.FontAngle,["normal","italic"])} = get(groot,'DefaultAxesFontAngle')
                optionalArguments.FontName (1,1) string = get(groot,'DefaultAxesFontName')
                optionalArguments.RulerColor {validatecolor(optionalArguments.RulerColor)} = get(groot,'DefaultAxesXColor')
                optionalArguments.XGrid (1,1) matlab.lang.OnOffSwitchState = false
                optionalArguments.YGrid (1,1) matlab.lang.OnOffSwitchState = false
                optionalArguments.GridColor {validatecolor(optionalArguments.GridColor)} = get(groot,'DefaultAxesGridColor')
                optionalArguments.GridLineWidth (1,1) double {mustBePositive,mustBeFinite} = get(groot,'DefaultAxesGridLineWidth')
                optionalArguments.GridLineStyle (1,1) string {mustBeMember(optionalArguments.GridLineStyle,["-","--",":","-.","none"])} = get(groot,'DefaultAxesGridLineStyle')
                optionalArguments.GridAlpha (1,1) double {mustBeInRange(optionalArguments.GridAlpha,0,1)} = get(groot,'DefaultAxesGridAlpha')
                optionalArguments.XMinorGrid (1,1) matlab.lang.OnOffSwitchState = false
                optionalArguments.YMinorGrid (1,1) matlab.lang.OnOffSwitchState = false
                optionalArguments.MinorGridColor {validatecolor(optionalArguments.MinorGridColor)} = get(groot,'DefaultAxesMinorGridColor')
                optionalArguments.MinorGridLineWidth (1,1) double {mustBePositive,mustBeFinite} = get(groot,'DefaultAxesMinorGridLineWidth')
                optionalArguments.MinorGridLineStyle (1,1) string {mustBeMember(optionalArguments.MinorGridLineStyle,["-","--",":","-.","none"])} = get(groot,'DefaultAxesMinorGridLineStyle')
                optionalArguments.MinorGridAlpha (1,1) double {mustBeInRange(optionalArguments.MinorGridAlpha,0,1)} = get(groot,'DefaultAxesMinorGridAlpha')
            end

            this.TiledLayout = optionalArguments.TiledLayout;

            this.BackgroundColor = optionalArguments.BackgroundColor;
            this.Box = optionalArguments.Box;
            this.BoxLineWidth = optionalArguments.BoxLineWidth;
            this.FontName = optionalArguments.FontName;
            this.FontSize = optionalArguments.FontSize;
            this.FontWeight = optionalArguments.FontWeight;
            this.FontAngle = optionalArguments.FontAngle;
            this.RulerColor = optionalArguments.RulerColor;
            this.XGrid = optionalArguments.XGrid;
            this.YGrid = optionalArguments.YGrid;
            this.GridColor = optionalArguments.GridColor;
            this.GridLineWidth = optionalArguments.GridLineWidth;
            this.GridLineStyle = optionalArguments.GridLineStyle;
            this.GridAlpha = optionalArguments.GridAlpha;
            this.XMinorGrid = optionalArguments.XMinorGrid;
            this.YMinorGrid = optionalArguments.YMinorGrid;
            this.MinorGridColor = optionalArguments.MinorGridColor;
            this.MinorGridLineWidth = optionalArguments.MinorGridLineWidth;
            this.MinorGridLineStyle = optionalArguments.MinorGridLineStyle;
            this.MinorGridAlpha = optionalArguments.MinorGridAlpha;

            if isequal(this.BackgroundColor,get(groot,'DefaultAxesColor'))
                this.BackgroundColorMode = "auto";
            else
                this.BackgroundColorMode = "manual";
            end

            if isequal(this.RulerColor,get(groot,'DefaultAxesXColor'))
                this.RulerColorMode = "auto";
            else
                this.RulerColorMode = "manual";
            end

            if isequal(this.GridColor,get(groot,'DefaultAxesGridColor'))
                this.GridColorMode = "auto";
            else
                this.GridColorMode = "manual";
            end

            if isequal(this.MinorGridColor,get(groot,'DefaultAxesMinorGridColor'))
                this.MinorGridColorMode = "auto";
            else
                this.MinorGridColorMode = "manual";
            end
        end
    end
    
    % Get/Set
    methods
        % BackgroundColor
        function BackgroundColor = get.BackgroundColor(this)
            switch this.BackgroundColorMode
                case "auto"
                    BackgroundColor = matlab.graphics.internal.themes.getAttributeValue(this.Theme,this.DefaultBackgroundColor);
                case "manual"
                    BackgroundColor = this.BackgroundColor_I;
            end
        end

        function set.BackgroundColor(this,BackgroundColor)
            arguments
                this (1,1) controllib.chart.internal.options.AxesGridStyle
                BackgroundColor {validatecolor(BackgroundColor)}
            end
            this.BackgroundColor_I = validatecolor(BackgroundColor);
            this.BackgroundColorMode_I = "manual";
            ed = this.createEventData("BackgroundColor");
            notify(this,'AxesStyleChanged',ed);
        end

        % BackgroundColorMode
        function BackgroundColorMode = get.BackgroundColorMode(this)
            BackgroundColorMode = this.BackgroundColorMode_I;
        end

        function set.BackgroundColorMode(this,BackgroundColorMode)
            arguments
                this (1,1) controllib.chart.internal.options.AxesGridStyle
                BackgroundColorMode (1,1) string {mustBeMember(BackgroundColorMode,["auto","manual"])}
            end
            this.BackgroundColorMode_I = BackgroundColorMode;
            ed = this.createEventData("BackgroundColorMode");
            notify(this,'AxesStyleChanged',ed);
        end

        % Box
        function Box = get.Box(this)
            Box = this.Box_I;
        end

        function set.Box(this,Box)
            arguments
                this (1,1) controllib.chart.internal.options.AxesGridStyle
                Box (1,1) matlab.lang.OnOffSwitchState
            end
            this.Box_I = Box;
            ed = this.createEventData("Box");
            notify(this,'AxesStyleChanged',ed);
        end

        % BoxLineWidth
        function BoxLineWidth = get.BoxLineWidth(this)
            BoxLineWidth = this.BoxLineWidth_I;
        end

        function set.BoxLineWidth(this,BoxLineWidth)
            arguments
                this (1,1) controllib.chart.internal.options.AxesGridStyle
                BoxLineWidth (1,1) double {mustBePositive,mustBeFinite}
            end
            this.BoxLineWidth_I = BoxLineWidth;
            ed = this.createEventData("BoxLineWidth");
            notify(this,'AxesStyleChanged',ed);
        end

        % FontSize
        function FontSize = get.FontSize(this)
            FontSize = this.FontSize_I;
        end

        function set.FontSize(this,FontSize)
            arguments
                this (1,1) controllib.chart.internal.options.AxesGridStyle
                FontSize (1,1) double {mustBePositive,mustBeFinite}
            end
            this.FontSize_I = FontSize;
            ed = this.createEventData("FontSize");
            notify(this,'AxesStyleChanged',ed);
        end

        % FontAngle
        function FontAngle = get.FontAngle(this)
            FontAngle = this.FontAngle_I;
        end

        function set.FontAngle(this,FontAngle)
            arguments
                this (1,1) controllib.chart.internal.options.AxesGridStyle
                FontAngle (1,1) string {mustBeMember(FontAngle,["normal","italic"])}
            end
            this.FontAngle_I = FontAngle;
            ed = this.createEventData("FontAngle");
            notify(this,'AxesStyleChanged',ed);
        end

        % FontWeight
        function FontWeight = get.FontWeight(this)
            FontWeight = this.FontWeight_I;
        end

        function set.FontWeight(this,FontWeight)
            arguments
                this (1,1) controllib.chart.internal.options.AxesGridStyle
                FontWeight (1,1) string {mustBeMember(FontWeight,["normal","bold"])}
            end
            this.FontWeight_I = FontWeight;
            ed = this.createEventData("FontWeight");
            notify(this,'AxesStyleChanged',ed);
        end

        % FontName
        function FontName = get.FontName(this)
            FontName = this.FontName_I;
        end

        function set.FontName(this,FontName)
            arguments
                this (1,1) controllib.chart.internal.options.AxesGridStyle
                FontName (1,1) string
            end
            this.FontName_I = FontName;
            ed = this.createEventData("FontName");
            notify(this,'AxesStyleChanged',ed);
        end

        % RulerColor
        function RulerColor = get.RulerColor(this)
            switch this.RulerColorMode
                case "auto"
                    RulerColor = matlab.graphics.internal.themes.getAttributeValue(this.Theme,this.DefaultRulerColor);
                case "manual"
                    RulerColor = this.RulerColor_I;
            end
        end

        function set.RulerColor(this,RulerColor)
            arguments
                this (1,1) controllib.chart.internal.options.AxesGridStyle
                RulerColor {validatecolor(RulerColor)}
            end
            this.RulerColor_I = validatecolor(RulerColor);
            this.RulerColorMode_I = "manual";
            ed = this.createEventData("RulerColor");
            notify(this,'AxesStyleChanged',ed);
            
            % Set GridColor again since XColor/YColor overrides the
            % GridColor
            if strcmp(this.GridColorMode_I,"auto")
                ed = this.createEventData("GridColor");
                notify(this,'AxesStyleChanged',ed);
            end
        end

        % RulerColorMode
        function RulerColorMode = get.RulerColorMode(this)
            RulerColorMode = this.RulerColorMode_I;
        end

        function set.RulerColorMode(this,RulerColorMode)
            arguments
                this (1,1) controllib.chart.internal.options.AxesGridStyle
                RulerColorMode (1,1) string {mustBeMember(RulerColorMode,["auto","manual"])}
            end
            this.RulerColorMode_I = RulerColorMode;
            ed = this.createEventData("RulerColorMode");
            notify(this,'AxesStyleChanged',ed);
        end

        % XGrid
        function XGrid = get.XGrid(this)
            XGrid = this.XGrid_I;
        end

        function set.XGrid(this,XGrid)
            arguments
                this (1,1) controllib.chart.internal.options.AxesGridStyle
                XGrid (1,1) matlab.lang.OnOffSwitchState
            end
            this.XGrid_I = XGrid;
            ed = this.createEventData("XGrid");
            notify(this,'AxesStyleChanged',ed);
        end

        % YGrid
        function YGrid = get.YGrid(this)
            YGrid = this.YGrid_I;
        end

        function set.YGrid(this,YGrid)
            arguments
                this (1,1) controllib.chart.internal.options.AxesGridStyle
                YGrid (1,1) matlab.lang.OnOffSwitchState
            end
            this.YGrid_I = YGrid;
            ed = this.createEventData("YGrid");
            notify(this,'AxesStyleChanged',ed);
        end

        % XMinorGrid
        function XMinorGrid = get.XMinorGrid(this)
            XMinorGrid = this.XMinorGrid_I;
        end

        function set.XMinorGrid(this,XMinorGrid)
            arguments
                this (1,1) controllib.chart.internal.options.AxesGridStyle
                XMinorGrid (1,1) matlab.lang.OnOffSwitchState
            end
            this.XMinorGrid_I = XMinorGrid;
            ed = this.createEventData("XMinorGrid");
            notify(this,'AxesStyleChanged',ed);
        end

        % YMinorGrid
        function YMinorGrid = get.YMinorGrid(this)
            YMinorGrid = this.YMinorGrid_I;
        end

        function set.YMinorGrid(this,YMinorGrid)
            arguments
                this (1,1) controllib.chart.internal.options.AxesGridStyle
                YMinorGrid (1,1) matlab.lang.OnOffSwitchState
            end
            this.YMinorGrid_I = YMinorGrid;
            ed = this.createEventData("YMinorGrid");
            notify(this,'AxesStyleChanged',ed);
        end

        % GridColor
        function GridColor = get.GridColor(this)
            switch this.GridColorMode
                case "auto"
                    GridColor = matlab.graphics.internal.themes.getAttributeValue(this.Theme,this.DefaultGridColor);
                case "manual"
                    GridColor = this.GridColor_I;
            end
        end

        function set.GridColor(this,GridColor)
            arguments
                this (1,1) controllib.chart.internal.options.AxesGridStyle
                GridColor {validatecolor(GridColor)}
            end
            this.GridColor_I = validatecolor(GridColor);
            this.GridColorMode_I = "manual";
            ed = this.createEventData("GridColor");
            notify(this,'AxesStyleChanged',ed);
        end

        % GridColorMode
        function GridColorMode = get.GridColorMode(this)
            GridColorMode = this.GridColorMode_I;
        end

        function set.GridColorMode(this,GridColorMode)
            arguments
                this (1,1) controllib.chart.internal.options.AxesGridStyle
                GridColorMode (1,1) string {mustBeMember(GridColorMode,["auto","manual"])}
            end
            this.GridColorMode_I = GridColorMode;
            ed = this.createEventData("GridColorMode");
            notify(this,'AxesStyleChanged',ed);
        end

        % GridLineWidth
        function GridLineWidth = get.GridLineWidth(this)
            GridLineWidth = this.GridLineWidth_I;
        end

        function set.GridLineWidth(this,GridLineWidth)
            arguments
                this (1,1) controllib.chart.internal.options.AxesGridStyle
                GridLineWidth (1,1) double {mustBePositive,mustBeFinite}
            end
            this.GridLineWidth_I = GridLineWidth;
            ed = this.createEventData("GridLineWidth");
            notify(this,'AxesStyleChanged',ed);
        end

        % GridLineStyle
        function GridLineStyle = get.GridLineStyle(this)
            GridLineStyle = this.GridLineStyle_I;
        end

        function set.GridLineStyle(this,GridLineStyle)
            arguments
                this (1,1) controllib.chart.internal.options.AxesGridStyle
                GridLineStyle (1,1) string {mustBeMember(GridLineStyle,["-","--",":","-.","none"])}
            end
            this.GridLineStyle_I = GridLineStyle;
            ed = this.createEventData("GridLineStyle");
            notify(this,'AxesStyleChanged',ed);
        end

        % GridAlpha
        function GridAlpha = get.GridAlpha(this)
            GridAlpha = this.GridAlpha_I;
        end

        function set.GridAlpha(this,GridAlpha)
            arguments
                this (1,1) controllib.chart.internal.options.AxesGridStyle
                GridAlpha (1,1) double {mustBeInRange(GridAlpha,0,1)}
            end
            this.GridAlpha_I = GridAlpha;
            ed = this.createEventData("GridAlpha");
            notify(this,'AxesStyleChanged',ed);
        end

        % MinorGridColor
        function MinorGridColor = get.MinorGridColor(this)
            switch this.MinorGridColorMode
                case "auto"
                    MinorGridColor = matlab.graphics.internal.themes.getAttributeValue(this.Theme,this.DefaultMinorGridColor);
                case "manual"
                    MinorGridColor = this.MinorGridColor_I;
            end
        end

        function set.MinorGridColor(this,MinorGridColor)
            arguments
                this (1,1) controllib.chart.internal.options.AxesGridStyle
                MinorGridColor {validatecolor(MinorGridColor)}
            end
            this.MinorGridColor_I = validatecolor(MinorGridColor);
            this.MinorGridColorMode_I = "manual";
            ed = this.createEventData("MinorGridColor");
            notify(this,'AxesStyleChanged',ed);
        end

        % MinorGridColorMode
        function MinorGridColorMode = get.MinorGridColorMode(this)
            MinorGridColorMode = this.MinorGridColorMode_I;
        end

        function set.MinorGridColorMode(this,MinorGridColorMode)
            arguments
                this (1,1) controllib.chart.internal.options.AxesGridStyle
                MinorGridColorMode (1,1) string {mustBeMember(MinorGridColorMode,["auto","manual"])}
            end
            this.MinorGridColorMode_I = MinorGridColorMode;
            ed = this.createEventData("MinorGridColorMode");
            notify(this,'AxesStyleChanged',ed);
        end

        % MinorGridLineWidth
        function MinorGridLineWidth = get.MinorGridLineWidth(this)
            MinorGridLineWidth = this.MinorGridLineWidth_I;
        end

        function set.MinorGridLineWidth(this,MinorGridLineWidth)
            arguments
                this (1,1) controllib.chart.internal.options.AxesGridStyle
                MinorGridLineWidth (1,1) double {mustBePositive,mustBeFinite}
            end
            this.MinorGridLineWidth_I = MinorGridLineWidth;
            ed = this.createEventData("MinorGridLineWidth");
            notify(this,'AxesStyleChanged',ed);
        end

        % MinorGridLineStyle
        function MinorGridLineStyle = get.MinorGridLineStyle(this)
            MinorGridLineStyle = this.MinorGridLineStyle_I;
        end

        function set.MinorGridLineStyle(this,MinorGridLineStyle)
            arguments
                this (1,1) controllib.chart.internal.options.AxesGridStyle
                MinorGridLineStyle (1,1) string {mustBeMember(MinorGridLineStyle,["-","--",":","-.","none"])}
            end
            this.MinorGridLineStyle_I = MinorGridLineStyle;
            ed = this.createEventData("MinorGridLineStyle");
            notify(this,'AxesStyleChanged',ed);
        end

        % MinorGridAlpha
        function MinorGridAlpha = get.MinorGridAlpha(this)
            MinorGridAlpha = this.MinorGridAlpha_I;
        end

        function set.MinorGridAlpha(this,MinorGridAlpha)
            arguments
                this (1,1) controllib.chart.internal.options.AxesGridStyle
                MinorGridAlpha (1,1) double {mustBeInRange(MinorGridAlpha,0,1)}
            end
            this.MinorGridAlpha_I = MinorGridAlpha;
            ed = this.createEventData("MinorGridAlpha");
            notify(this,'AxesStyleChanged',ed);
        end

        % Theme
        function Theme = get.Theme(this)
            if isempty(this.TiledLayout)
                Theme = matlab.graphics.internal.themes.lightTheme;
            else
                fig = ancestor(this.TiledLayout,'figure');
                if isempty(fig)
                    Theme = matlab.graphics.internal.themes.lightTheme;
                else
                    Theme = fig.Theme;
                    if isempty(Theme)
                        Theme = matlab.graphics.internal.themes.lightTheme;
                    end
                end
            end
        end
    end

    %% Protected methods
    methods (Access=protected)
        function propgrp = getPropertyGroups(this)
            if isscalar(this)
                fontList = ["FontName","FontWeight","FontSize","FontAngle"];
                fontTitle = "Fonts";
                fontGrp = matlab.mixin.util.PropertyGroup(fontList,fontTitle);
                boxList = ["BackgroundColor","Box","BoxLineWidth","RulerColor"];
                boxTitle = "Box Styling";
                boxGrp = matlab.mixin.util.PropertyGroup(boxList,boxTitle);
                gridList = ["XGrid","YGrid","XMinorGrid","YMinorGrid",...
                    "GridColor","GridLineWidth","GridLineStyle","GridAlpha",...
                    "MinorGridColor","MinorGridLineWidth","MinorGridLineStyle","MinorGridAlpha"];
                gridTitle = "Grids";
                gridGrp = matlab.mixin.util.PropertyGroup(gridList,gridTitle);
                propgrp = [fontGrp,boxGrp,gridGrp];
            else
                propgrp = getPropertyGroups@matlab.mixin.CustomDisplay(this);
            end
        end
    end

    %% Static private methods
    methods (Static,Access=private)
        function ed = createEventData(propertyName)
            ed = controllib.chart.internal.utils.GenericEventData;
            addprop(ed,"PropertyChanged");
            ed.PropertyChanged = propertyName;
        end
    end
end
