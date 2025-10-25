classdef FigureView < handle

    properties(SetAccess='private')
        EmbeddedFigure;
        EmbeddedFigureID;
        EmbeddedFigureCanvas;
        EmbeddedAxes;
    end
    
    properties (Constant)
        AxesScalingFactor = 0.98
    end
    
    methods
        function this = FigureView()
            this.intializeFigure();
        end
        
        function intializeFigure(this)
            % g2200216: The filtering figure should force it's WindowStyle
            % to normal to ensure no errors or warning in response to
            % global figure setting changes made by the user.
            this.EmbeddedFigure = matlab.ui.internal.embeddedfigure('Units', 'normalized');
            this.EmbeddedFigureCanvas = this.EmbeddedFigure.getCanvas();
            this.EmbeddedFigureID = this.EmbeddedFigureCanvas.ServerID;
            
            % g1875058: Scale down the width and height of the Axes so that the range
            % handles can fit. Do this by setting the outer position rather
            % than the inner position so as to scale the axes ticks and labels.
            this.EmbeddedAxes = axes(this.EmbeddedFigureCanvas);
            this.EmbeddedAxes.OuterPosition(3) = this.EmbeddedAxes.OuterPosition(3)*this.AxesScalingFactor;
            this.EmbeddedAxes.OuterPosition(4) = this.EmbeddedAxes.OuterPosition(4)*this.AxesScalingFactor;
            
            this.EmbeddedFigure.Units = 'pixels';
            disableDefaultInteractivity(this.EmbeddedAxes);
        end       
        
        function delete(this)
            if ~isempty(this.EmbeddedFigure) && isvalid(this.EmbeddedFigure)
                close(this.EmbeddedFigure, 'force');
                delete(this.EmbeddedFigure);
            end
            this.EmbeddedFigure = [];

            if ~isempty(this.EmbeddedFigureCanvas) && isvalid(this.EmbeddedFigureCanvas)
                delete(this.EmbeddedFigureCanvas);
            end
            this.EmbeddedFigureCanvas = [];

            this.EmbeddedFigureID = [];
        end
    end
end

