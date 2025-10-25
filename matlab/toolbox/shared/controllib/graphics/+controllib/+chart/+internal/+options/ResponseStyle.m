classdef ResponseStyle < matlab.mixin.SetGet & matlab.mixin.Copyable
    % Response styling for controllib.chart.internal.foundation.BaseResponse

    %   Copyright 2024 The MathWorks, Inc.

    %% Properties (notifies ResponseStyleChanged event)
    properties (Dependent,AbortSet)
        Color
        FaceColor
        EdgeColor
        LineStyle
        MarkerStyle
    end

    properties (AbortSet)
        FaceAlpha
        EdgeAlpha

        LineWidth
        MarkerSize
        CharacteristicsMarkerStyle
        CharacteristicsMarkerSize
    end

    properties (Hidden,AbortSet)
        ColorOrder
        FaceColorOrder
        EdgeColorOrder
        LineStyleOrder
        MarkerStyleOrder
    end

    properties (Hidden,Dependent,AbortSet)
        SemanticColor
        SemanticFaceColor
        SemanticEdgeColor        
    end

    %% Properties
    properties (Hidden,SetAccess = {?controllib.chart.internal.foundation.AbstractPlot,...
            ?controllib.chart.internal.foundation.BaseResponse,...
            ?controllib.chart.internal.options.ResponseStyleManager})
        Mode
        ColorMode       (1,1) string {mustBeMember(ColorMode,["auto","manual","semantic","semantic-auto"])} = "auto"
        LineStyleMode
        MarkerStyleMode
        FaceColorMode   (1,1) string {mustBeMember(FaceColorMode,["auto","manual","semantic"])} = "auto"
        EdgeColorMode   (1,1) string {mustBeMember(EdgeColorMode,["auto","manual","semantic"])} = "auto"
    end
    
    %% Events
    events
        ResponseStyleChanged
    end

    %% Constructor
    methods
        function this = ResponseStyle()
            defaultColorOrder = get(groot,'DefaultAxesColorOrder');
            this.ColorOrder = {defaultColorOrder(1,:)};
            this.FaceColorOrder = this.ColorOrder;
            this.EdgeColorOrder = this.ColorOrder;
            this.LineStyleOrder = {get(groot,'DefaultAxesLineStyleOrder')};
            this.MarkerStyleOrder = {get(groot,'DefaultLineMarker')};

            this.FaceAlpha = get(groot,'DefaultPatchFaceAlpha');
            this.EdgeAlpha = get(groot,'DefaultPatchEdgeAlpha');

            this.LineWidth = get(groot,'DefaultLineLineWidth');
            this.MarkerSize = get(groot,'DefaultLineMarkerSize');
            
            this.CharacteristicsMarkerStyle = get(groot,'DefaultScatterMarker');
            this.CharacteristicsMarkerSize = get(groot,'DefaultLineMarkerSize');

            this.Mode = "auto";
            this.ColorMode = "auto";
            this.LineStyleMode = "auto";
            this.MarkerStyleMode = "auto";
            this.FaceColorMode = "auto";
            this.EdgeColorMode = "auto";
        end
    end

    %% Public methods
    methods        
        function value = getValue(this,optionalInputs)
            % "getStyle" returns style for given I/O pair and model.
            %   getStyle(ResponseStyle,rowIdx,columnIdx,responseIdx)
            arguments
                this (1,1) controllib.chart.internal.options.ResponseStyle
                optionalInputs.InputIndex (1,1) double {mustBePositive,mustBeInteger} = 1
                optionalInputs.OutputIndex (1,1) double {mustBePositive,mustBeInteger} = 1
                optionalInputs.ArrayIndex (1,1) double {mustBePositive,mustBeInteger} = 1
            end
            rowIndex = optionalInputs.OutputIndex;
            columnIndex = optionalInputs.InputIndex;
            respIndex = optionalInputs.ArrayIndex;

            [s1,s2,s3] = size(this.ColorOrder);
            value.Color = this.ColorOrder{1+rem(rowIndex-1,s1),1+rem(columnIndex-1,s2),1+rem(respIndex-1,s3)};
            [s1,s2,s3] = size(this.FaceColorOrder);
            value.FaceColor = this.FaceColorOrder{1+rem(rowIndex-1,s1),1+rem(columnIndex-1,s2),1+rem(respIndex-1,s3)};
            [s1,s2,s3] = size(this.EdgeColorOrder);
            value.EdgeColor = this.EdgeColorOrder{1+rem(rowIndex-1,s1),1+rem(columnIndex-1,s2),1+rem(respIndex-1,s3)};
            value.FaceAlpha = this.FaceAlpha;
            value.EdgeAlpha = this.EdgeAlpha;

            [s1,s2,s3] = size(this.LineStyleOrder);
            value.LineStyle = this.LineStyleOrder{1+rem(rowIndex-1,s1),1+rem(columnIndex-1,s2),1+rem(respIndex-1,s3)};

            [s1,s2,s3] = size(this.MarkerStyleOrder);
            value.MarkerStyle = this.MarkerStyleOrder{1+rem(rowIndex-1,s1),1+rem(columnIndex-1,s2),1+rem(respIndex-1,s3)};

            value.LineWidth = this.LineWidth;
            value.MarkerSize = this.MarkerSize;
            value.CharacteristicsMarker = this.CharacteristicsMarkerStyle;
            value.CharacteristicsMarkerSize = this.CharacteristicsMarkerSize;
        end

        function setLineSpec(this,lineSpec)
            arguments
                this (1,1) controllib.chart.internal.options.ResponseStyle
                lineSpec (1,1) string
            end            
            % Parse line specification string
            [lineStyle,color,markerStyle,msg] = colstyle(lineSpec);

            % Throw error if needed
            if ~isempty(msg)
                error(message('Controllib:plots:PlotStyleString',StyleStr))
            end
            
            % Set properties
            if ~isempty(lineStyle)
                this.LineStyle = lineStyle;
            end
            if ~isempty(color)
                this.FaceColor = validatecolor(color);
                this.EdgeColor = validatecolor(color);
            end
            if ~isempty(markerStyle)
                this.MarkerStyle = markerStyle;
            end
        end
    end

    %% Get/Set
    methods
        % Color
        function Color = get.Color(this)
            if contains(this.ColorMode,"semantic")
                Color = string(this.ColorOrder);                
            else
                Color = cell2mat(this.ColorOrder(:));
            end
        end

        function set.Color(this,Color)
            arguments
                this (1,1) controllib.chart.internal.options.ResponseStyle
                Color {validateColorSupportingNone}
            end
            if ischar(Color) && strcmp(Color,'none')
                this.SemanticColor = 'none';
            else
                Color = validatecolor(Color);
                this.Mode = "manual";
                this.ColorMode = "manual";
                n = size(Color,1);
                this.ColorOrder = mat2cell(Color,ones(1,n),3);
                notify(this,'ResponseStyleChanged');
            end
        end

        % FaceColor
        function Color = get.FaceColor(this)
            if strcmp(this.FaceColorMode,"semantic")
                Color = string(this.FaceColorOrder);                
            else
                Color = cell2mat(this.FaceColorOrder(:));
            end
        end

        function set.FaceColor(this,Color)
            arguments
                this (1,1) controllib.chart.internal.options.ResponseStyle
                Color {validatecolor}
            end
            Color = validatecolor(Color);
            n = size(Color,1);
            this.Mode = "manual";
            this.FaceColorMode = "manual";
            this.FaceColorOrder = mat2cell(Color,ones(1,n),3);
            notify(this,'ResponseStyleChanged');
        end

        % EdgeColor
        function Color = get.EdgeColor(this)
            if strcmp(this.EdgeColorMode,"semantic")
                Color = string(this.EdgeColorOrder);                
            else
                Color = cell2mat(this.EdgeColorOrder(:));
            end
        end

        function set.EdgeColor(this,Color)
            arguments
                this (1,1) controllib.chart.internal.options.ResponseStyle
                Color {validatecolor}
            end
            Color = validatecolor(Color);
            n = size(Color,1);
            this.Mode = "manual";
            this.EdgeColorMode = "manual";
            this.EdgeColorOrder = mat2cell(Color,ones(1,n),3);
            notify(this,'ResponseStyleChanged');
        end

        % LineStyle
        function LineStyle = get.LineStyle(this)
            LineStyle = string(this.LineStyleOrder(:));
        end

        function set.LineStyle(this,LineStyle)
            arguments
                this (1,1) controllib.chart.internal.options.ResponseStyle
                LineStyle (1,1) string {mustBeMember(LineStyle,["none";"-";"--";"-.";":"])}
            end
            this.LineStyleOrder = cellstr(LineStyle);
            this.Mode = "manual";
            this.LineStyleMode = "manual";
            notify(this,'ResponseStyleChanged');
        end

        % MarkerStyle
        function MarkerStyle = get.MarkerStyle(this)
            MarkerStyle = string(this.MarkerStyleOrder(:));
        end

        function set.MarkerStyle(this,MarkerStyle)
            arguments
                this (1,1) controllib.chart.internal.options.ResponseStyle
                MarkerStyle (1,1) string {mustBeMember(MarkerStyle,["none";"o";"+";"*";".";...
                    "x";"_";"|";"^";"v";">";"<";"s";"d";"p";"h";"square";"diamond";"pentagram";"hexagram"])}
            end
            this.MarkerStyleOrder = cellstr(MarkerStyle);
            this.Mode = "manual";
            this.MarkerStyleMode = "manual";
            notify(this,'ResponseStyleChanged');
        end

        % SemanticColor
        function SemanticColor = get.SemanticColor(this)
            if strcmp(this.ColorMode,"semantic")
                SemanticColor = string(this.ColorOrder);
            else
                SemanticColor = "";
            end
        end

        function set.SemanticColor(this,SemanticColor)
            arguments
                this (1,1) controllib.chart.internal.options.ResponseStyle
                SemanticColor (1,1) string
            end
            this.ColorOrder = num2cell(SemanticColor);
            this.ColorMode = "semantic";
            notify(this,'ResponseStyleChanged');
        end

        % SemanticFaceColor
        function SemanticColor = get.SemanticFaceColor(this)
            if strcmp(this.FaceColorMode,"semantic")
                SemanticColor = string(this.FaceColorOrder);
            else
                SemanticColor = "";
            end
        end

        function set.SemanticFaceColor(this,SemanticColor)
            arguments
                this (1,1) controllib.chart.internal.options.ResponseStyle
                SemanticColor (1,1) string
            end
            this.FaceColorOrder = num2cell(SemanticColor);
            this.FaceColorMode = "semantic";
            notify(this,'ResponseStyleChanged');
        end

        % SemanticEdgeColor
        function SemanticColor = get.SemanticEdgeColor(this)
            if strcmp(this.EdgeColorMode,"semantic")
                SemanticColor = string(this.EdgeColorOrder);
            else
                SemanticColor = "";
            end
        end

        function set.SemanticEdgeColor(this,SemanticColor)
            arguments
                this (1,1) controllib.chart.internal.options.ResponseStyle
                SemanticColor (1,1) string
            end
            this.EdgeColorOrder = num2cell(SemanticColor);
            this.EdgeColorMode = "semantic";
            notify(this,'ResponseStyleChanged');
        end

        % FaceAlpha
        function set.FaceAlpha(this,FaceAlpha)
            arguments
                this (1,1) controllib.chart.internal.options.ResponseStyle
                FaceAlpha (1,1) double {mustBeInRange(FaceAlpha,0,1)}
            end
            this.FaceAlpha = FaceAlpha;
            this.Mode = "manual"; %#ok<MCSUP>
            notify(this,'ResponseStyleChanged');
        end

        % EdgeAlpha
        function set.EdgeAlpha(this,EdgeAlpha)
            arguments
                this (1,1) controllib.chart.internal.options.ResponseStyle
                EdgeAlpha (1,1) double {mustBeInRange(EdgeAlpha,0,1)}
            end
            this.EdgeAlpha = EdgeAlpha;
            this.Mode = "manual"; %#ok<MCSUP>
            notify(this,'ResponseStyleChanged');
        end

        % LineWidth
        function set.LineWidth(this,LineWidth)
            arguments
                this (1,1) controllib.chart.internal.options.ResponseStyle
                LineWidth (1,1) double {mustBePositive,mustBeFinite}
            end
            this.LineWidth = LineWidth;
            this.Mode = "manual"; %#ok<MCSUP>
            notify(this,'ResponseStyleChanged');
        end

        % MarkerSize
        function set.MarkerSize(this,MarkerSize)
            arguments
                this (1,1) controllib.chart.internal.options.ResponseStyle
                MarkerSize (1,1) double {mustBePositive,mustBeFinite}
            end
            this.MarkerSize = MarkerSize;
            this.Mode = "manual"; %#ok<MCSUP>
            notify(this,'ResponseStyleChanged');
        end

        % CharacteristicsMarkerStyle
        function set.CharacteristicsMarkerStyle(this,CharacteristicsMarkerStyle)
            arguments
                this (1,1) controllib.chart.internal.options.ResponseStyle
                CharacteristicsMarkerStyle (1,1) string {mustBeMember(CharacteristicsMarkerStyle,["none";"o";"+";"*";".";"x";"_";"|";"^";"v";">";"<";"s";"d";"p";"h"])}
            end
            this.CharacteristicsMarkerStyle = CharacteristicsMarkerStyle;
            this.Mode = "manual"; %#ok<MCSUP>
            notify(this,'ResponseStyleChanged');
        end

        % CharacteristicsMarkerSize
        function set.CharacteristicsMarkerSize(this,CharacteristicsMarkerSize)
            arguments
                this (1,1) controllib.chart.internal.options.ResponseStyle
                CharacteristicsMarkerSize (1,1) double {mustBePositive,mustBeFinite}
            end
            this.CharacteristicsMarkerSize = CharacteristicsMarkerSize;
            this.Mode = "manual"; %#ok<MCSUP>
            notify(this,'ResponseStyleChanged');
        end
    end
end

function color = validateColorSupportingNone(color)
if ~strcmp(color,'none')
    color = validatecolor(color);
else
    color = char(color);
end
end
