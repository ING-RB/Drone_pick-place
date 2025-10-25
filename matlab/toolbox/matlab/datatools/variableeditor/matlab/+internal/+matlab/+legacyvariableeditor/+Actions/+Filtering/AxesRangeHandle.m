classdef AxesRangeHandle < handle
    %AXESRANGEHANDLE This class draws the grippers for FilterFigure to
    %indicate selection    
    
    properties (Constant)
        DefaultColor = [128/256 128/256 128/256];
        RectangleFillColor = [230/256 230/256 230/256];
        SelectedColor = [0 153/256 255/256];
        HoverColor = [128/256 128/256 128/256];
        LineHitTolerance = 5; % Pixels
        LineWidth = 1;
        RectHeight = 8;
    end
    
    properties(SetAccess = 'protected')
        Figure;
        Axes;
        Rectangle;
        Arrow;
        Line;
    end
    
    properties(Hidden=true, SetAccess='protected')
        Position_I;
        Selected_I = false;
        Hover_I;
        AxesPixelPosition;
    end
    
    properties(Dependent=true)
        Position;
        Selected = false;
        Hover;
        Visible;
    end
    methods
        function val = get.Position(this)
            val = this.Position_I;
        end
        function set.Position(this, val)
            if isdatetime(val) || isduration(val)
                r = this.Axes.XRuler;
                val = ruler2num(val, r);
            end
            this.Position_I = val;
            this.updatePosition();
        end
        function val = get.Selected(this)
            val = this.Selected_I;
        end
        function set.Selected(this, val)
            this.Selected_I = val;
            this.updateColors();
        end
        function val = get.Hover(this)
            val = this.Hover_I;
        end
        function set.Hover(this, val)
            this.Hover_I = val;
            this.updateColors();
        end
        function val = get.Visible(this)
            val = this.Rectangle.Visible;
        end
        function set.Visible(this, val)
            this.Rectangle.Visible = val;
            this.Arrow.Visible = val;
            this.Line.Visible = val;
        end
    end
    
    methods
        function this = AxesRangeHandle(axes)
            this.Axes = axes;
            this.Figure = axes.Parent;
            this.AxesPixelPosition = getpixelposition(this.Axes);
            this.setupShapes();
            this.Position = this.Axes.XLim(1); % This will call set position
        end
    
        function mouseOver = isMouseOver(this, mousePoint)
            mouseOver = false;
            mouseOver = mouseOver || this.isMouseOverLine(mousePoint);
            mouseOver = mouseOver || this.isMouseOverArrow(mousePoint);
            mouseOver = mouseOver || this.isMouseOverRectangle(mousePoint);
        end
    end
    
    methods(Access='protected')
        function setupShapes(this)
            this.Line = annotation(this.Figure, 'line', [0 0], [0 0], 'Color', this.DefaultColor, 'LineWidth', this.LineWidth);
            this.Arrow = annotation(this.Figure, 'arrow', [0 0], [0 0], 'Color', this.DefaultColor, 'LineStyle', 'none');
            this.Rectangle = annotation(this.Figure, 'rectangle', [0 0 0 0], 'Color', this.DefaultColor, 'FaceColor', this.RectangleFillColor, 'LineWidth', this.LineWidth);
            this.Line.Units = 'pixels';
            this.Arrow.Units = 'pixels';
            this.Rectangle.Units = 'pixels';
        end
        
        function updatePosition(this)
            xPosition = this.Position_I;
            pos = [xPosition;0;0];
            axesPos = this.AxesPixelPosition;
            axesHPos = axesPos(2)+axesPos(4);
            pixelPos = matlab.graphics.chart.internal.convertDataSpaceCoordsToViewerCoords(this.Axes, pos);
            this.Rectangle.Position = [pixelPos(1)-(this.RectHeight/2) axesHPos+(this.RectHeight-1) this.RectHeight this.RectHeight];
            this.Arrow.Position = [pixelPos(1) axesHPos+this.RectHeight 0 -(this.RectHeight-1)];
            this.Line.Position = [pixelPos(1) axesPos(2) 0 axesPos(4)];
        end
        
        function updateColors(this)
            color = this.DefaultColor;
            if this.Selected_I
                color = this.SelectedColor;
            elseif this.Hover_I
                color = this.HoverColor;
            end
            this.Rectangle.Color = color;
            this.Arrow.Color = color;
            this.Line.Color = color;
        end
        
        function pointOver = isMouseOverLine(this, mousePoint)
            tolerance = this.LineHitTolerance;
            pixelPos = this.Line.Position;
            axesPos = getpixelposition(this.Axes);
            pointOver = (pixelPos(1)-tolerance) <= mousePoint(1) && ...
                        (pixelPos(1)+tolerance) >= mousePoint(1) && ...
                        mousePoint(2) >= axesPos(2) && ...
                        mousePoint(2) <= (axesPos(2)+axesPos(4));
        end

        function pointOver = isMouseOverArrow(this, mousePoint)
            pixelPos = this.Rectangle.Position;
            axesPos = getpixelposition(this.Axes);
            pointOver = (pixelPos(1)) <= mousePoint(1) && ...
                        (pixelPos(1)+pixelPos(3)) >= mousePoint(1) && ...
                        (axesPos(2)+axesPos(4)) <= mousePoint(2) && ...
                        (axesPos(2)+axesPos(4)+(this.RectHeight)) >= mousePoint(2);
        end

        function pointOver = isMouseOverRectangle(this, mousePoint)
            pixelPos = this.Rectangle.Position;
            pointOver = (pixelPos(1)-this.LineWidth) <= mousePoint(1) && ...
                        (pixelPos(1)+pixelPos(3)+this.LineWidth) >= mousePoint(1) && ...
                        (pixelPos(2)-this.LineWidth) <= mousePoint(2) && ...
                        (pixelPos(2)+pixelPos(4)+this.LineWidth) >= mousePoint(2);
        end
    end
end
