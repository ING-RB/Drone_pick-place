classdef AxesLabel < matlab.mixin.SetGet
    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent)
        String
        FontSize
        FontWeight
        FontAngle
        FontName
        Color
        Interpreter
        Rotation
        Visible
    end

    properties (Hidden,Dependent)
        ColorMode
    end


    properties (Dependent,Access=?controllib.chart.internal.foundation.AbstractPlot)
        NumStrings
    end

    properties (Access=private)
        String_I
        FontSize_I
        FontWeight_I
        FontAngle_I
        Color_I
        Interpreter_I
        Visible_I
        FontName_I
        ColorMode_I
        Rotation_I
        NumStrings_I
    end


    properties (Dependent,Access=private)
        Theme
    end

    properties (Access=private,Transient,WeakHandle)
        Chart controllib.chart.internal.foundation.AbstractPlot {mustBeScalarOrEmpty} = controllib.chart.internal.foundation.AbstractPlot.empty
    end

    properties (Hidden)
        DefaultColor = "--mw-graphics-borderColor-axes-primary"
    end

    %% Events
    events
        LabelChanged
        VisibilityChanged
    end

    %% Constructor
    methods
        function this = AxesLabel(numStrings,optionalInputs)
            arguments
                numStrings {mustBeInteger,mustBePositive} = 1
                optionalInputs.Chart = controllib.chart.internal.foundation.AbstractPlot.empty
                optionalInputs.String = strings(numStrings,1)
                optionalInputs.FontSize = get(groot,'DefaultTextFontSize')
                optionalInputs.FontWeight = get(groot,'DefaultTextFontWeight')
                optionalInputs.FontAngle = get(groot,'DefaultTextFontAngle')
                optionalInputs.FontName = get(groot,'DefaultTextFontName')
                optionalInputs.Color = get(groot,'DefaultTextColor')
                optionalInputs.Interpreter = get(groot,'DefaultTextInterpreter')
                optionalInputs.Rotation = get(groot,'DefaultTextRotation')
                optionalInputs.Visible = matlab.lang.OnOffSwitchState(true);
            end

            this.NumStrings_I = numStrings;

            this.Chart = optionalInputs.Chart;

            this.String = optionalInputs.String;
            this.FontName = optionalInputs.FontName;
            this.FontSize = optionalInputs.FontSize;
            this.FontWeight = optionalInputs.FontWeight;
            this.FontAngle = optionalInputs.FontAngle;
            this.Color = optionalInputs.Color;
            this.Interpreter = optionalInputs.Interpreter;
            this.Rotation = optionalInputs.Rotation;
            this.Visible = optionalInputs.Visible;

            if isequal(this.Color,get(groot,'DefaultTextColor'))
                this.ColorMode = "auto";
            else
                this.ColorMode = "manual";
            end
        end
    end

    %% Get/Set
    methods
        % NumStrings
        function NumStrings = get.NumStrings(this)
            NumStrings = this.NumStrings_I;
        end

        function set.NumStrings(this,NumStrings)
            arguments
                this (1,1) controllib.chart.internal.options.AxesLabel
                NumStrings (1,1) {mustBePositive,mustBeInteger}
            end
            if NumStrings > this.NumStrings
                this.String_I = [this.String_I;strings(NumStrings-this.NumStrings,1)];
            else
                this.String_I = this.String_I(1:NumStrings);
            end
            this.NumStrings_I = NumStrings;
        end

        % String
        function String = get.String(this)
            String = this.String_I;
        end

        function set.String(this,String)
            arguments
                this (1,1) controllib.chart.internal.options.AxesLabel
                String (:,1) string {mustBeStringLength(this,String)}
            end
            this.String_I = String;
            ed = this.createEventData("String");
            notify(this,'LabelChanged',ed);
        end

        % FontSize
        function FontSize = get.FontSize(this)
            FontSize = this.FontSize_I;
        end

        function set.FontSize(this,FontSize)
            arguments
                this (1,1) controllib.chart.internal.options.AxesLabel
                FontSize (1,1) double {mustBePositive,mustBeFinite}
            end
            this.FontSize_I = FontSize;
            ed = this.createEventData("FontSize");
            notify(this,'LabelChanged',ed);
        end

        % FontWeight
        function FontWeight = get.FontWeight(this)
            FontWeight = this.FontWeight_I;
        end

        function set.FontWeight(this,FontWeight)
            arguments
                this (1,1) controllib.chart.internal.options.AxesLabel
                FontWeight (1,1) string {mustBeMember(FontWeight,["normal","bold"])}
            end
            this.FontWeight_I = FontWeight;
            ed = this.createEventData("FontWeight");
            notify(this,'LabelChanged',ed);
        end

        % FontAngle
        function FontAngle = get.FontAngle(this)
            FontAngle = this.FontAngle_I;
        end

        function set.FontAngle(this,FontAngle)
            arguments
                this (1,1) controllib.chart.internal.options.AxesLabel
                FontAngle (1,1) string {mustBeMember(FontAngle,["normal","italic"])}
            end
            this.FontAngle_I = FontAngle;
            ed = this.createEventData("FontAngle");
            notify(this,'LabelChanged',ed);
        end

        % FontName
        function FontName = get.FontName(this)
            FontName = this.FontName_I;
        end

        function set.FontName(this,FontName)
            arguments
                this (1,1) controllib.chart.internal.options.AxesLabel
                FontName (1,1) string
            end
            this.FontName_I = FontName;
            ed = this.createEventData("FontName");
            notify(this,'LabelChanged',ed);
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
                this (1,1) controllib.chart.internal.options.AxesLabel
                Color {validatecolor(Color)}
            end
            this.Color_I = validatecolor(Color);
            this.ColorMode_I = "manual";
            ed = this.createEventData("Color");
            notify(this,'LabelChanged',ed);
        end

        % ColorMode
        function ColorMode = get.ColorMode(this)
            ColorMode = this.ColorMode_I;
        end

        function set.ColorMode(this,ColorMode)
            arguments
                this (1,1) controllib.chart.internal.options.AxesLabel
                ColorMode (1,1) string {mustBeMember(ColorMode,["auto","manual"])}
            end
            this.ColorMode_I = ColorMode;
            ed = this.createEventData("ColorMode");
            notify(this,'LabelChanged',ed);
        end

        % Interpreter
        function Interpreter = get.Interpreter(this)
            Interpreter = this.Interpreter_I;
        end

        function set.Interpreter(this,Interpreter)
            arguments
                this (1,1) controllib.chart.internal.options.AxesLabel
                Interpreter (1,1) string {mustBeMember(Interpreter,["none","tex","latex"])}
            end
            this.Interpreter_I = Interpreter;
            ed = this.createEventData("Interpreter");
            notify(this,'LabelChanged',ed);
        end

        % Rotation
        function Rotation = get.Rotation(this)
            Rotation = this.Rotation_I;
        end

        function set.Rotation(this,Rotation)
            arguments
                this (1,1) controllib.chart.internal.options.AxesLabel
                Rotation (1,1) double {mustBeReal,mustBeNonNan,mustBeFinite}
            end
            this.Rotation_I = Rotation;
            ed = this.createEventData("Rotation");
            notify(this,'LabelChanged',ed);
        end

        % Visible
        function Visible = get.Visible(this)
            Visible = this.Visible_I;
        end

        function set.Visible(this,Visible)
            arguments
                this (1,1) controllib.chart.internal.options.AxesLabel
                Visible (1,1) matlab.lang.OnOffSwitchState
            end
            this.Visible_I = Visible;
            notify(this,"VisibilityChanged");
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

    %% Static hidden methods
    methods (Static,Hidden)
        function props = getCopyableProperties()
            props = ["String";"FontSize";"FontWeight";"FontAngle";"FontName";"Color";...
                "Interpreter";"Rotation";"Visible";"ColorMode";"DefaultColor"];
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

    %% Private methods
    methods (Access=private)
        function mustBeStringLength(this,String)
            controllib.chart.internal.utils.validators.mustBeSize(String,[this.NumStrings 1]);
        end
    end
end