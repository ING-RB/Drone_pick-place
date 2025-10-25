classdef (ConstructOnLoad) AxesStyle < matlab.mixin.SetGet & dynamicprops & matlab.mixin.CustomDisplay
    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent,SetObservable,AbortSet)
        BackgroundColor
        Box
        BoxLineWidth
        FontSize
        FontWeight
        FontAngle
        FontName
        RulerColor
        GridVisible
        GridColor
        GridLineWidth
        GridLineStyle
    end

    properties (Hidden,Dependent)
        BackgroundColorMode
        RulerColorMode
        GridColorMode
        MinorGridColorMode
    end

    properties (Access=private)
        % Need to initialize "Mode_I" properties because when Dependent
        % properties are also AbortSet, it will do a "get" before the call
        % to "set" in the constructor
        BackgroundColor_I
        BackgroundColorMode_I = "auto"
        Box_I
        BoxLineWidth_I
        FontSize_I
        FontWeight_I
        FontAngle_I
        FontName_I
        RulerColor_I
        RulerColorMode_I = "auto"
        GridType_I
        GridDampingSpec_I
        GridFrequencySpec_I
        GridSampleTime_I
        GridLabelType_I        
        GridVisible_I
        GridColor_I
        GridColorMode_I = "auto"
        GridLineWidth_I
        GridLineStyle_I
        GridAlpha_I
        GridLabelsVisible_I
        MinorGridVisible_I
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
        Chart controllib.chart.internal.foundation.AbstractPlot {mustBeScalarOrEmpty} = controllib.chart.internal.foundation.AbstractPlot.empty
    end

    properties (Hidden)
        DefaultBackgroundColor = "--mw-graphics-backgroundColor-axes-primary"
        DefaultRulerColor = "--mw-graphics-borderColor-axes-primary"
        DefaultGridColor = "--mw-graphics-borderColor-axes-quaternary"
        DefaultMinorGridColor = "--mw-graphics-borderColor-axes-quaternary"
    end

    %% Events
    events
        AxesStyleChanged
    end

    %% Constructor
    methods
        function this = AxesStyle(optionalArguments)
            arguments
                optionalArguments.Chart controllib.chart.internal.foundation.AbstractPlot = controllib.chart.internal.foundation.AbstractPlot.empty
                optionalArguments.BackgroundColor {validatecolor(optionalArguments.BackgroundColor)} = get(groot,'DefaultAxesColor')
                optionalArguments.Box (1,1) matlab.lang.OnOffSwitchState = true
                optionalArguments.BoxLineWidth (1,1) double {mustBePositive,mustBeFinite} = get(groot,'DefaultAxesLineWidth')
                optionalArguments.FontSize (1,1) double {mustBePositive,mustBeFinite} = get(groot,'DefaultAxesFontSize')
                optionalArguments.FontWeight (1,1) string {mustBeMember(optionalArguments.FontWeight,["normal","bold"])} = get(groot,'DefaultAxesFontWeight')
                optionalArguments.FontAngle (1,1) string {mustBeMember(optionalArguments.FontAngle,["normal","italic"])} = get(groot,'DefaultAxesFontAngle')
                optionalArguments.FontName (1,1) string = get(groot,'DefaultAxesFontName')
                optionalArguments.RulerColor {validatecolor(optionalArguments.RulerColor)} = get(groot,'DefaultAxesXColor')
                optionalArguments.GridType (1,1) string {mustBeMember(optionalArguments.GridType,["default","s-plane","z-plane"])} = "default"
                optionalArguments.GridFrequencySpec (:,1) double {mustBePositive,mustBeFinite} = []
                optionalArguments.GridDampingSpec (:,1) double {mustBeInRange(optionalArguments.GridDampingSpec,0,1,'exclusive')} = []
                optionalArguments.GridSampleTime (1,1) double {controllib.chart.internal.options.AxesStyle.mustBeSampleTime(optionalArguments.GridSampleTime)} = -1
                optionalArguments.GridLabelType (1,1) string {mustBeMember(optionalArguments.GridLabelType,["damping","overshoot"])} = "damping"
                optionalArguments.GridVisible (1,1) matlab.lang.OnOffSwitchState = false
                optionalArguments.GridLabelsVisible (1,1) matlab.lang.OnOffSwitchState = true
                optionalArguments.GridColor {validatecolor(optionalArguments.GridColor)} = get(groot,'DefaultAxesGridColor')
                optionalArguments.GridLineWidth (1,1) double {mustBePositive,mustBeFinite} = get(groot,'DefaultAxesGridLineWidth')
                optionalArguments.GridLineStyle (1,1) string {mustBeMember(optionalArguments.GridLineStyle,["-","--",":","-.","none"])} = get(groot,'DefaultAxesGridLineStyle')
                optionalArguments.GridAlpha (1,1) double {mustBeInRange(optionalArguments.GridAlpha,0,1)} = get(groot,'DefaultAxesGridAlpha')
                optionalArguments.MinorGridVisible (1,1) matlab.lang.OnOffSwitchState = false
                optionalArguments.MinorGridColor {validatecolor(optionalArguments.MinorGridColor)} = get(groot,'DefaultAxesMinorGridColor')
                optionalArguments.MinorGridLineWidth (1,1) double {mustBePositive,mustBeFinite} = get(groot,'DefaultAxesMinorGridLineWidth')
                optionalArguments.MinorGridLineStyle (1,1) string {mustBeMember(optionalArguments.MinorGridLineStyle,["-","--",":","-.","none"])} = get(groot,'DefaultAxesMinorGridLineStyle')
                optionalArguments.MinorGridAlpha (1,1) double {mustBeInRange(optionalArguments.MinorGridAlpha,0,1)} = get(groot,'DefaultAxesMinorGridAlpha')
            end

            this.Chart = optionalArguments.Chart;

            p = addprop(this,"GridAlpha");
            p.Dependent = true;
            p.GetMethod = @getGridAlpha;
            p.SetMethod = @setGridAlpha;
            p = addprop(this,"GridLabelsVisible");
            p.Dependent = true;
            p.GetMethod = @getGridLabelsVisible;
            p.SetMethod = @setGridLabelsVisible;
            p = addprop(this,"MinorGridVisible");
            p.Dependent = true;
            p.GetMethod = @getMinorGridVisible;
            p.SetMethod = @setMinorGridVisible;
            p = addprop(this,"MinorGridColor");
            p.Dependent = true;
            p.GetMethod = @getMinorGridColor;
            p.SetMethod = @setMinorGridColor;
            p = addprop(this,"MinorGridLineWidth");
            p.Dependent = true;
            p.GetMethod = @getMinorGridLineWidth;
            p.SetMethod = @setMinorGridLineWidth;
            p = addprop(this,"GridType");
            p.Dependent = true;
            p.GetMethod = @getGridType;
            p.SetMethod = @setGridType;
            p = addprop(this,"GridFrequencySpec");
            p.Dependent = true;
            p.GetMethod = @getGridFrequencySpec;
            p.SetMethod = @setGridFrequencySpec;
            p = addprop(this,"GridDampingSpec");
            p.Dependent = true;
            p.GetMethod = @getGridDampingSpec;
            p.SetMethod = @setGridDampingSpec;
            p = addprop(this,"GridSampleTime");
            p.Dependent = true;
            p.GetMethod = @getGridSampleTime;
            p.SetMethod = @setGridSampleTime;
            p = addprop(this,"GridLabelType");
            p.Dependent = true;
            p.Hidden = true;
            p.GetMethod = @getGridLabelType;
            p.SetMethod = @setGridLabelType;
            p = addprop(this,"MinorGridLineStyle");
            p.Dependent = true;
            p.GetMethod = @getMinorGridLineStyle;
            p.SetMethod = @setMinorGridLineStyle;
            p = addprop(this,"MinorGridAlpha");
            p.Dependent = true;
            p.GetMethod = @getMinorGridAlpha;
            p.SetMethod = @setMinorGridAlpha;
            updateForCustomGrid(this)

            this.BackgroundColor = optionalArguments.BackgroundColor;
            this.Box = optionalArguments.Box;
            this.BoxLineWidth = optionalArguments.BoxLineWidth;
            this.FontName = optionalArguments.FontName;
            this.FontSize = optionalArguments.FontSize;
            this.FontWeight = optionalArguments.FontWeight;
            this.FontAngle = optionalArguments.FontAngle;
            this.RulerColor = optionalArguments.RulerColor;
            this.GridType = optionalArguments.GridType;
            this.GridFrequencySpec = optionalArguments.GridFrequencySpec;
            this.GridDampingSpec = optionalArguments.GridDampingSpec;
            this.GridSampleTime = optionalArguments.GridSampleTime;
            this.GridLabelType = optionalArguments.GridLabelType;
            this.GridVisible = optionalArguments.GridVisible;
            this.GridColor = optionalArguments.GridColor;
            this.GridLineWidth = optionalArguments.GridLineWidth;
            this.GridLineStyle = optionalArguments.GridLineStyle;
            this.GridAlpha = optionalArguments.GridAlpha;
            this.GridLabelsVisible = optionalArguments.GridLabelsVisible;
            this.MinorGridVisible = optionalArguments.MinorGridVisible;
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
                this (1,1) controllib.chart.internal.options.AxesStyle
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
                this (1,1) controllib.chart.internal.options.AxesStyle
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
                this (1,1) controllib.chart.internal.options.AxesStyle
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
                this (1,1) controllib.chart.internal.options.AxesStyle
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
                this (1,1) controllib.chart.internal.options.AxesStyle
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
                this (1,1) controllib.chart.internal.options.AxesStyle
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
                this (1,1) controllib.chart.internal.options.AxesStyle
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
                this (1,1) controllib.chart.internal.options.AxesStyle
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
                this (1,1) controllib.chart.internal.options.AxesStyle
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
                this (1,1) controllib.chart.internal.options.AxesStyle
                RulerColorMode (1,1) string {mustBeMember(RulerColorMode,["auto","manual"])}
            end
            this.RulerColorMode_I = RulerColorMode;
            ed = this.createEventData("RulerColorMode");
            notify(this,'AxesStyleChanged',ed);
        end

        % GridVisible
        function GridVisible = get.GridVisible(this)
            GridVisible = this.GridVisible_I;
        end

        function set.GridVisible(this,GridVisible)
            arguments
                this (1,1) controllib.chart.internal.options.AxesStyle
                GridVisible (1,1) matlab.lang.OnOffSwitchState
            end
            this.GridVisible_I = GridVisible;
            ed = this.createEventData("GridVisible");
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
                this (1,1) controllib.chart.internal.options.AxesStyle
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
                this (1,1) controllib.chart.internal.options.AxesStyle
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
                this (1,1) controllib.chart.internal.options.AxesStyle
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
                this (1,1) controllib.chart.internal.options.AxesStyle
                GridLineStyle (1,1) string {mustBeMember(GridLineStyle,["-","--",":","-.","none"])}
            end
            this.GridLineStyle_I = GridLineStyle;
            ed = this.createEventData("GridLineStyle");
            notify(this,'AxesStyleChanged',ed);
        end

        % MinorGridColorMode
        function MinorGridColorMode = get.MinorGridColorMode(this)
            MinorGridColorMode = this.MinorGridColorMode_I;
        end

        function set.MinorGridColorMode(this,MinorGridColorMode)
            arguments
                this (1,1) controllib.chart.internal.options.AxesStyle
                MinorGridColorMode (1,1) string {mustBeMember(MinorGridColorMode,["auto","manual"])}
            end
            this.MinorGridColorMode_I = MinorGridColorMode;
            ed = this.createEventData("MinorGridColorMode");
            notify(this,'AxesStyleChanged',ed);
        end

        % Theme
        function Theme = get.Theme(this)
            if isempty(this.Chart)
                Theme = matlab.graphics.internal.themes.lightTheme;
            else
                Theme = this.Chart.Theme;
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
                gridList = ["GridVisible","GridColor","GridLineWidth","GridLineStyle"];
                p = findprop(this,"GridType");
                if ~p.Hidden %IsPZ
                    gridList = ["GridType",gridList];
                end
                p = findprop(this,"GridDampingSpec");
                if ~p.Hidden %IsPZ with custom grid
                    gridList = [gridList,"GridFrequencySpec","GridDampingSpec","GridSampleTime"];
                end                
                p = findprop(this,"GridLabelsVisible");
                if p.Hidden %No custom grid
                    gridList = [gridList,"GridAlpha","MinorGridVisible","MinorGridColor",...
                        "MinorGridLineWidth","MinorGridLineStyle","MinorGridAlpha"];
                else %Custom grid
                    gridList = [gridList,"GridLabelsVisible"];
                end
                gridTitle = "Grids";
                gridGrp = matlab.mixin.util.PropertyGroup(gridList,gridTitle);
                propgrp = [fontGrp,boxGrp,gridGrp];
            else
                propgrp = getPropertyGroups@matlab.mixin.CustomDisplay(this);
            end
        end
    end

    %% Private methods
    methods (Access=private)
        % GridType
        function GridType = getGridType(this)
            GridType = this.GridType_I;
        end

        function setGridType(this,GridType)
            arguments
                this (1,1) controllib.chart.internal.options.AxesStyle
                GridType (1,1) string {mustBeMember(GridType,["default","s-plane","z-plane"])}
            end
            this.GridType_I = GridType;
            ed = this.createEventData("GridType");
            notify(this,'AxesStyleChanged',ed);
        end

        % GridFrequencySpec
        function GridFrequencySpec = getGridFrequencySpec(this)
            GridFrequencySpec = this.GridFrequencySpec_I;
        end

        function setGridFrequencySpec(this,GridFrequencySpec)
            arguments
                this (1,1) controllib.chart.internal.options.AxesStyle
                GridFrequencySpec (:,1) double {mustBePositive,mustBeFinite}
            end
            this.GridFrequencySpec_I = GridFrequencySpec;
            ed = this.createEventData("GridFrequencySpec");
            notify(this,'AxesStyleChanged',ed);
        end

        % GridDampingSpec
        function GridDampingSpec = getGridDampingSpec(this)
            GridDampingSpec = this.GridDampingSpec_I;
        end

        function setGridDampingSpec(this,GridDampingSpec)
            arguments
                this (1,1) controllib.chart.internal.options.AxesStyle
                GridDampingSpec (:,1) double {mustBeInRange(GridDampingSpec,0,1,'exclusive')}
            end
            this.GridDampingSpec_I = GridDampingSpec;
            ed = this.createEventData("GridDampingSpec");
            notify(this,'AxesStyleChanged',ed);
        end

        % GridSampleTime
        function GridSampleTime = getGridSampleTime(this)
            GridSampleTime = this.GridSampleTime_I;
        end

        function setGridSampleTime(this,GridSampleTime)
            arguments
                this (1,1) controllib.chart.internal.options.AxesStyle
                GridSampleTime (1,1) double {controllib.chart.internal.options.AxesStyle.mustBeSampleTime(GridSampleTime)}
            end
            this.GridSampleTime_I = GridSampleTime;
            ed = this.createEventData("GridSampleTime");
            notify(this,'AxesStyleChanged',ed);
        end

        % GridLabelType
        function GridLabelType = getGridLabelType(this)
            GridLabelType = this.GridLabelType_I;
        end

        function setGridLabelType(this,GridLabelType)
            arguments
                this (1,1) controllib.chart.internal.options.AxesStyle
                GridLabelType (1,1) string {mustBeMember(GridLabelType,["damping","overshoot"])}
            end
            this.GridLabelType_I = GridLabelType;
            ed = this.createEventData("GridLabelType");
            notify(this,'AxesStyleChanged',ed);
        end

        % GridLabelsVisible
        function GridLabelsVisible = getGridLabelsVisible(this)
            GridLabelsVisible = this.GridLabelsVisible_I;
        end

        function setGridLabelsVisible(this,GridLabelsVisible)
            arguments
                this (1,1) controllib.chart.internal.options.AxesStyle
                GridLabelsVisible (1,1) matlab.lang.OnOffSwitchState
            end
            this.GridLabelsVisible_I = GridLabelsVisible;
            ed = this.createEventData("GridLabelsVisible");
            notify(this,'AxesStyleChanged',ed);
        end

        % GridAlpha
        function GridAlpha = getGridAlpha(this)
            GridAlpha = this.GridAlpha_I;
        end

        function setGridAlpha(this,GridAlpha)
            arguments
                this (1,1) controllib.chart.internal.options.AxesStyle
                GridAlpha (1,1) double {mustBeInRange(GridAlpha,0,1)}
            end
            this.GridAlpha_I = GridAlpha;
            ed = this.createEventData("GridAlpha");
            notify(this,'AxesStyleChanged',ed);
        end

        % MinorGridVisible
        function MinorGridVisible = getMinorGridVisible(this)
            MinorGridVisible = this.MinorGridVisible_I;
        end

        function setMinorGridVisible(this,MinorGridVisible)
            arguments
                this (1,1) controllib.chart.internal.options.AxesStyle
                MinorGridVisible (1,1) matlab.lang.OnOffSwitchState
            end
            this.MinorGridVisible_I = MinorGridVisible;
            ed = this.createEventData("MinorGridVisible");
            notify(this,'AxesStyleChanged',ed);
        end

        % MinorGridColor
        function MinorGridColor = getMinorGridColor(this)
            switch this.MinorGridColorMode
                case "auto"
                    MinorGridColor = matlab.graphics.internal.themes.getAttributeValue(this.Theme,this.DefaultMinorGridColor);
                case "manual"
                    MinorGridColor = this.MinorGridColor_I;
            end
        end

        function setMinorGridColor(this,MinorGridColor)
            arguments
                this (1,1) controllib.chart.internal.options.AxesStyle
                MinorGridColor {validatecolor(MinorGridColor)}
            end
            this.MinorGridColor_I = validatecolor(MinorGridColor);
            this.MinorGridColorMode_I = "manual";
            ed = this.createEventData("MinorGridColor");
            notify(this,'AxesStyleChanged',ed);
        end

        % MinorGridLineWidth
        function MinorGridLineWidth = getMinorGridLineWidth(this)
            MinorGridLineWidth = this.MinorGridLineWidth_I;
        end

        function setMinorGridLineWidth(this,MinorGridLineWidth)
            arguments
                this (1,1) controllib.chart.internal.options.AxesStyle
                MinorGridLineWidth (1,1) double {mustBePositive,mustBeFinite}
            end
            this.MinorGridLineWidth_I = MinorGridLineWidth;
            ed = this.createEventData("MinorGridLineWidth");
            notify(this,'AxesStyleChanged',ed);
        end

        % MinorGridLineStyle
        function MinorGridLineStyle = getMinorGridLineStyle(this)
            MinorGridLineStyle = this.MinorGridLineStyle_I;
        end

        function setMinorGridLineStyle(this,MinorGridLineStyle)
            arguments
                this (1,1) controllib.chart.internal.options.AxesStyle
                MinorGridLineStyle (1,1) string {mustBeMember(MinorGridLineStyle,["-","--",":","-.","none"])}
            end
            this.MinorGridLineStyle_I = MinorGridLineStyle;
            ed = this.createEventData("MinorGridLineStyle");
            notify(this,'AxesStyleChanged',ed);
        end

        % MinorGridAlpha
        function MinorGridAlpha = getMinorGridAlpha(this)
            MinorGridAlpha = this.MinorGridAlpha_I;
        end

        function setMinorGridAlpha(this,MinorGridAlpha)
            arguments
                this (1,1) controllib.chart.internal.options.AxesStyle
                MinorGridAlpha (1,1) double {mustBeInRange(MinorGridAlpha,0,1)}
            end
            this.MinorGridAlpha_I = MinorGridAlpha;
            ed = this.createEventData("MinorGridAlpha");
            notify(this,'AxesStyleChanged',ed);
        end
    end

    %% Chart methods
    methods (Access=?controllib.chart.internal.foundation.AbstractPlot)
        function updateForCustomGrid(this)
            if ~isempty(this.Chart)
                p = findprop(this,"GridLabelsVisible");
                p.Hidden = ~this.Chart.HasCustomGrid;
                p = findprop(this,"GridAlpha");
                p.Hidden = this.Chart.HasCustomGrid;
                isPZChart = isa(this.Chart,'controllib.chart.PZPlot') || isa(this.Chart,'controllib.chart.IOPZPlot');
                p = findprop(this,"GridType");
                p.Hidden = ~isPZChart;
                p = findprop(this,"GridFrequencySpec");
                p.Hidden = ~isPZChart || ~this.Chart.HasCustomGrid;
                p = findprop(this,"GridDampingSpec");
                p.Hidden = ~isPZChart || ~this.Chart.HasCustomGrid;
                p = findprop(this,"GridSampleTime");
                p.Hidden = ~isPZChart || ~this.Chart.HasCustomGrid;
                p = findprop(this,"MinorGridVisible");
                p.Hidden = this.Chart.HasCustomGrid;
                p = findprop(this,"MinorGridColor");
                p.Hidden = this.Chart.HasCustomGrid;
                p = findprop(this,"MinorGridLineWidth");
                p.Hidden = this.Chart.HasCustomGrid;
                p = findprop(this,"MinorGridLineStyle");
                p.Hidden = this.Chart.HasCustomGrid;
                p = findprop(this,"MinorGridAlpha");
                p.Hidden = this.Chart.HasCustomGrid;
            end
        end
    end

    %% Static hidden methods
    methods (Static,Hidden)
        function props = getCopyableProperties()
            props = ["BackgroundColor";"BackgroundColorMode";"Box";"BoxLineWidth";...
                "FontSize";"FontWeight";"FontAngle";"FontName";"RulerColor";"RulerColorMode";...
                "GridVisible";"GridColor";"GridColorMode";...
                "GridLineWidth";"GridLineStyle";"GridAlpha";"GridLabelsVisible";...
                "GridType";"GridFrequencySpec";"GridDampingSpec";"GridSampleTime";...
                "MinorGridVisible";"MinorGridColor";"MinorGridColorMode";...
                "MinorGridLineWidth";"MinorGridLineStyle";"MinorGridAlpha";...
                "DefaultBackgroundColor";"DefaultRulerColor";...
                "DefaultGridColor";"DefaultMinorGridColor"];
        end

        function props = getCustomGridProperties()
            props = ["GridLabelsVisible";"GridType";"GridFrequencySpec";...
                "GridDampingSpec";"GridSampleTime"];
        end
    end

    %% Static private methods
    methods (Static,Access=private)
        function mustBeSampleTime(Ts)
            if Ts ~= -1
                mustBePositive(Ts);
            end
        end

        function ed = createEventData(propertyName)
            ed = controllib.chart.internal.utils.GenericEventData;
            addprop(ed,"PropertyChanged");
            ed.PropertyChanged = propertyName;
        end
    end
end
