classdef ControlsFigureTool <  controllib.ui.internal.figuretool.FigureTool  &  matlab.mixin.Heterogeneous
    %

    %Provides common parent for app plot classes, to allow them to be
    %concatenated in regular arrays

    % Copyright 2022-2024 The MathWorks, Inc.

    methods (Access = public)
        function this = ControlsFigureTool(tag, numTabs)
            %Construct object

            %Call parent constructor
            this = this@controllib.ui.internal.figuretool.FigureTool(tag,numTabs);

            %Enable theming for contained figure.  Make sure graphics
            %complete (g3493375).
            if(hasFigure(this))
                fig = getFigure(this);
                matlab.graphics.internal.themes.figureUseDesktopTheme(fig);
                drawnow;
            end
        end

        function tf = hasFigure(this)
            %HASFIGURE Determine if the plot object has a figure
            tf = isvalid(this.Document)  &&  isvalid(this.Document.Figure);
        end
    end

    methods (Access = public, Abstract)   % API methods for child classes
        close(this)
    end

    methods(Access = public, Sealed = true)
        function fig = getFigure(this)
            %GETFIGURE Get figure
            %

            %Method is sealed as can work on heterogeneous arrays of
            %subclasses.

            if isempty(this)
                fig = [];
                return
            end

            if isvalid(this)
                %Handle case where "this" is an array
                fig = gobjects(size(this));
                for ct = 1:numel(this)
                    fig(ct) = this(ct).Document.Figure;
                end
            else
                fig = [];
            end
        end
    end
end
