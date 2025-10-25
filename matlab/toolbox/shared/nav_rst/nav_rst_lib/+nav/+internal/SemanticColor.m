classdef SemanticColor
%   This class is for internal use only. It may be removed in the future.

%SEMANTICCOLOR Defines the alias for semantic colors and provides some
%   utilities to set the colors and themes.

%   Copyright 2023 The MathWorks, Inc.

    methods (Static)

        function name = graphicColor(order,ordinal)
        %graphColor Returns the Graphics color order name in semantic color
        %name format eg. --mw-graphics-colorOrder-1-primary
        %
        % order     : Color order to be selected.
        % ordinal   : Variant of color order amongst the four.
            validateattributes(order,{'double'},{'<=',12})
            validateattributes(ordinal,{'double'},{'<=',4})
            name = "--mw-graphics-colorOrder-"+num2str(order)+"-";
            switch(ordinal)
              case 1
                name = name+"primary";
              case 2
                name = name+"secondary";
              case 3
                name = name+"tertiary";
              case 4
                name = name+"quaternary";
            end
        end

        function [hex,rgb] = semanticColor2hex(name)
        %semanticColor2hex Converts semantic color names to corresponding
        % hex values

        % Set default mode to light theme
            mode = matlab.graphics.internal.themes.lightTheme;

            % Fetch current figure without creating new one.
            currFig = get(groot,"CurrentFigure");

            % If theme on current figure is dark, switch to it.
            if(isprop(currFig,'Theme'))
                if(~isempty(currFig.Theme))
                    if(strcmp(currFig.Theme.BaseColorStyle,'dark'))
                        mode = matlab.graphics.internal.themes.darkTheme;
                    end
                end
            end

            % Fetches color value from the semantic colors
            rgb = matlab.graphics.internal.themes.getAttributeValue(mode, name);

            % Converting rgb values to hex.
            st = dec2hex(rgb*255);
            hex= strcat('#',st(1,:),st(2,:),st(3,:));
        end
    end
end
