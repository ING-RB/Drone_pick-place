classdef LabelStyle < matlab.mixin.SetGet & matlab.mixin.Copyable
    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent)
        FontSize
        FontWeight
        FontAngle
        FontName
        Color
        Interpreter
        Rotation
    end

    properties (Hidden,Dependent)
        ColorMode
    end

    properties (Access=private)
        FontSize_I
        FontWeight_I
        FontAngle_I
        Color_I
        Interpreter_I
        FontName_I
        ColorMode_I
        Rotation_I
    end

    properties (Dependent,Access=private)
        Theme
    end

    properties (Access=private,Transient,WeakHandle)
        TiledLayout matlab.graphics.layout.TiledChartLayout {mustBeScalarOrEmpty} = matlab.graphics.layout.TiledChartLayout.empty
    end

    properties (Hidden)
        DefaultColor = "--mw-graphics-borderColor-axes-primary"
    end
    
    %% Events
    events
        LabelStyleChanged
    end

    %% Constructor
    methods
        function this = LabelStyle(optionalArguments)
            arguments
                optionalArguments.TiledLayout matlab.graphics.layout.TiledChartLayout {mustBeScalarOrEmpty} = matlab.graphics.layout.TiledChartLayout.empty
                optionalArguments.FontSize (1,1) double {mustBePositive,mustBeFinite} = get(groot,'DefaultTextFontSize')
                optionalArguments.FontWeight (1,1) string {mustBeMember(optionalArguments.FontWeight,["normal","bold"])} = get(groot,'DefaultTextFontWeight')
                optionalArguments.FontAngle (1,1) string {mustBeMember(optionalArguments.FontAngle,["normal","italic"])} = get(groot,'DefaultTextFontAngle')
                optionalArguments.FontName (1,1) string = get(groot,'DefaultTextFontName')
                optionalArguments.Color {validatecolor(optionalArguments.Color)} = get(groot,'DefaultTextColor')
                optionalArguments.Interpreter (1,1) string {mustBeMember(optionalArguments.Interpreter,["none","tex","latex"])} = get(groot,'DefaultTextInterpreter')
                optionalArguments.Rotation (1,1) double {mustBeReal,mustBeNonNan,mustBeFinite} = get(groot,'DefaultTextRotation')
            end

            this.TiledLayout = optionalArguments.TiledLayout;

            this.FontSize = optionalArguments.FontSize;
            this.FontWeight = optionalArguments.FontWeight;
            this.FontAngle = optionalArguments.FontAngle;
            this.FontName = optionalArguments.FontName;
            this.Color = optionalArguments.Color;
            this.Interpreter = optionalArguments.Interpreter;
            this.Rotation = optionalArguments.Rotation;

            if isequal(this.Color,get(groot,'DefaultTextColor'))
                this.ColorMode = "auto";
            else
                this.ColorMode = "manual";
            end
        end
    end
    
    %% Get/Set
    methods
        % FontSize
        function FontSize = get.FontSize(this)
            FontSize = this.FontSize_I;
        end

        function set.FontSize(this,FontSize)
            arguments
                this (1,1) controllib.chart.internal.options.LabelStyle
                FontSize (1,1) double {mustBePositive,mustBeFinite}
            end
            this.FontSize_I = FontSize;
            ed = this.createEventData("FontSize");
            notify(this,'LabelStyleChanged',ed);
        end

        % FontWeight
        function FontWeight = get.FontWeight(this)
            FontWeight = this.FontWeight_I;
        end

        function set.FontWeight(this,FontWeight)
            arguments
                this (1,1) controllib.chart.internal.options.LabelStyle
                FontWeight (1,1) string {mustBeMember(FontWeight,["normal","bold"])}
            end
            this.FontWeight_I = FontWeight;
            ed = this.createEventData("FontWeight");
            notify(this,'LabelStyleChanged',ed);
        end

        % FontAngle
        function FontAngle = get.FontAngle(this)
            FontAngle = this.FontAngle_I;
        end

        function set.FontAngle(this,FontAngle)
            arguments
                this (1,1) controllib.chart.internal.options.LabelStyle
                FontAngle (1,1) string {mustBeMember(FontAngle,["normal","italic"])}
            end
            this.FontAngle_I = FontAngle;
            ed = this.createEventData("FontAngle");
            notify(this,'LabelStyleChanged',ed);
        end

        % FontName
        function FontName = get.FontName(this)
            FontName = this.FontName_I;
        end

        function set.FontName(this,FontName)
            arguments
                this (1,1) controllib.chart.internal.options.LabelStyle
                FontName (1,1) string
            end
            this.FontName_I = FontName;
            ed = this.createEventData("FontName");
            notify(this,'LabelStyleChanged',ed);
        end

        % Color
        function Color = get.Color(this)
            switch this.ColorMode
                case "auto"
                    Color = matlab.graphics.internal.themes.getAttributeValue(this.Theme,this.DefaultColor);
                case "manual"
                    Color = this.Color_I;
            end
        end

        function set.Color(this,Color)
            arguments
                this (1,1) controllib.chart.internal.options.LabelStyle
                Color {validatecolor(Color)}
            end
            this.Color_I = validatecolor(Color);
            this.ColorMode_I = "manual";
            ed = this.createEventData("Color");
            notify(this,'LabelStyleChanged',ed);
        end

        % ColorMode
        function ColorMode = get.ColorMode(this)
            ColorMode = this.ColorMode_I;
        end

        function set.ColorMode(this,ColorMode)
            arguments
                this (1,1) controllib.chart.internal.options.LabelStyle
                ColorMode (1,1) string {mustBeMember(ColorMode,["auto","manual"])}
            end
            this.ColorMode_I = ColorMode;
            ed = this.createEventData("ColorMode");
            notify(this,'LabelStyleChanged',ed);
        end

        % Interpreter
        function Interpreter = get.Interpreter(this)
            Interpreter = this.Interpreter_I;
        end

        function set.Interpreter(this,Interpreter)
            arguments
                this (1,1) controllib.chart.internal.options.LabelStyle
                Interpreter (1,1) string {mustBeMember(Interpreter,["none","tex","latex"])}
            end
            this.Interpreter_I = Interpreter;
            ed = this.createEventData("Interpreter");
            notify(this,'LabelStyleChanged',ed);
        end

        % Rotation
        function Rotation = get.Rotation(this)
            Rotation = this.Rotation_I;
        end

        function set.Rotation(this,Rotation)
            arguments
                this (1,1) controllib.chart.internal.options.LabelStyle
                Rotation (1,1) double {mustBeReal,mustBeNonNan,mustBeFinite}
            end
            this.Rotation_I = Rotation;
            ed = this.createEventData("Rotation");
            notify(this,'LabelStyleChanged',ed)
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

    %% Static private methods
    methods (Static,Access=private)
        function ed = createEventData(propertyName)
            ed = controllib.chart.internal.utils.GenericEventData;
            addprop(ed,"PropertyChanged");
            ed.PropertyChanged = propertyName;
        end
    end
end
