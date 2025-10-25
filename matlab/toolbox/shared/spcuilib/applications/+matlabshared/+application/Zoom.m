classdef Zoom < handle
    %
    
    %   Copyright 2020 The MathWorks, Inc.
    properties (SetAccess = protected, Hidden)
        PanController
        FloatingPalette
    end
    
    methods
        function initializeZoom(this)
            fig = getFigure(this);
            ax  = getAxes(this);
            
            disableDefaultInteractivity(ax);
            initializeScrollZoom(this);
            initializePan(this)
            initializeFloatingPalette(this, fig, ax);
        end
        function initializeScrollZoom(this)
            set(getFigure(this), 'WindowScrollWheelFcn', @this.scrollWheelCallback);
        end
        function initializePan(this)
            % Setup panning and enable it
            ax = getAxes(this);
            fig = getFigure(this);
            pan = matlab.graphics.interaction.uiaxes.Pan3D(ax, fig, ...
                'WindowMousePress', 'WindowMouseMotion', 'WindowMouseRelease');
            pan.strategy = matlab.graphics.interaction.uiaxes.AxesInteractionStrategy(ax);
            pan.enable();
            this.PanController = pan;
        end
    end
    
    methods (Hidden)
        function pan(this, direction)
            % pan(this, direction) shifts the axes center in the specified
            % direction. The direction input can be one of the following
            % strings: "east", "west", "north", or "south". The magnitude
            % of the shift is a small fraction of the current east-west or
            % north-south map extent.
            stepfactor = 0.1;
            zoomLevel = 0.5;
            [hRange,vRange,hLim,vLim] = getAxesRangeAndLimits(this);
            hCenter = sum(hLim)/2;
            vCenter = sum(vLim)/2;
            switch direction
                case "west"
                    dy = stepfactor * hRange;
                    hCenter = hCenter + dy;
                case "east"
                    dy = stepfactor * hRange;
                    hCenter = hCenter - dy;
                case "north"
                    dx = stepfactor * vRange;
                    vCenter = vCenter + dx;
                case "south"
                    dx = stepfactor * vRange;
                    vCenter = vCenter - dx;
            end
            hLim = hCenter + [-hRange*zoomLevel hRange*zoomLevel];
            vLim = vCenter + [-vRange*zoomLevel vRange*zoomLevel];
            applyAxesLimits(this,hLim,vLim);
        end

        function zoomIn(this)
            % Zoom in towards scenario canvas center
            performZoom(this,0.25);
        end
        
        function zoomOut(this)
            % Zoom out from scenario canvas center
            performZoom(this,1);
        end
        
        function performZoom(this,zoomLevel)
            % Perform a zoom on the canvas
            [hRange,vRange,hLim,vLim] = getAxesRangeAndLimits(this);
            center = [sum(hLim)/2 sum(vLim)/2];
            hLim = center(1) + [-hRange hRange]*zoomLevel;
            vLim = center(2) + [-vRange vRange]*zoomLevel;
            applyAxesLimits(this,hLim,vLim);
        end
        
        function applyAxesLimits(this, hLim, vLim)
            dims = getHVDimensions(this);
            set(getAxes(this), [dims(1) 'Lim'], hLim, [dims(2) 'Lim'], vLim);
        end
        
        function scrollWheelCallback(this, ~, ev)
            % Scroll wheel callback for scenario figure
            % If the mouse is not over the inner position of the axes, do
            % not do the zoom.
            hAxes = getAxes(this);
            axesPos = getpixelposition(hAxes);
            mousePoint = get(getFigure(this), 'CurrentPoint');
            if mousePoint(1) < axesPos(1) || ...
                    mousePoint(2) < axesPos(2) || ...
                    mousePoint(1) > axesPos(1) + axesPos(3) || ...
                    mousePoint(2) > axesPos(2) + axesPos(4)
                return
            end
            center = get(hAxes, 'CurrentPoint');
            center = center([1 3]);
            if any(isnan(center))
                % We should not let this happen as scroll will get stuck.
                return;
            end
            if strcmp(getHVDimensions(this), 'YX')
                center = fliplr(center);
            end
            [hRange,vRange,hLim,vLim] = getAxesRangeAndLimits(this,false);
            hPercent = (center(1) - hLim(1)) / hRange;
            vPercent = (center(2) - vLim(1)) / vRange;
            amount = ev.VerticalScrollCount * ev.VerticalScrollAmount;
          
            if abs(amount) < 3
                amount = sign(amount) * 3;
            end
            zoomFactor = (1 + amount / getScrollWheelFactor(this));
            hRange = hRange * zoomFactor;
            vRange = vRange * zoomFactor;
            [hRange,vRange] = fixAxesRange(this,hRange,vRange);
            hLim = center(1) + [-hRange * hPercent hRange * (1 - hPercent)];
            vLim = center(2) + [-vRange * vPercent vRange * (1 - vPercent)];
            applyAxesLimits(this,hLim,vLim);
        end
        
        function [hRange,vRange,hLim,vLim] = getAxesRangeAndLimits(this,fixRange)
            %getAxesRangeAndLimits Get the axes range and limits
            hAxes = getAxes(this);
            dims = getHVDimensions(this);
            hLim = hAxes.([dims(1) 'Lim']);
            vLim = hAxes.([dims(2) 'Lim']);
            hRange = diff(hLim);
            vRange = diff(vLim);
            if nargin < 2 || fixRange
                [hRange,vRange] = fixAxesRange(this,hRange,vRange);
            end
        end
        
        function [hRange,vRange] = fixAxesRange(this,hRange,vRange)
            %fixAxesRange Ensure axes range is within allowed bounds
            % Check minimum span
            [min, max] = getAxesSpan(this);
            if hRange < min
                hRange = min;
            end
            if vRange < min
                vRange = min;
            end
            % Check maximum span
            if hRange > max
                hRange = max;
            end
            if vRange > max
                vRange = max;
            end
        end
        
        function [min, max] = getAxesSpan(~)
            min = 0;
            max = inf;
        end
        
        function initializeFloatingPalette(this, fig, ~)
            if nargin < 2
                fig = getFigure(this);
            end
            this.FloatingPalette = controllib.plot.internal.FloatingPalette(fig);
        end
        
        function dims = getHVDimensions(this)
            view = get(getAxes(this), 'View');
            if isequal(view, [0 90])
                dims = 'XY';
            elseif isequal(view, [0 0])
                dims = 'XZ';
            elseif isequal(view, [90 0])
                dims = 'YZ';
            elseif isequal(view, [-90 90])
                dims = 'YX';
            end
        end
        
        function f = getScrollWheelFactor(~)
            f = 50;
        end
    end
    
    methods (Abstract)
        hAxes = getAxes(this);
        hFigure = getFigure(this);
    end
end

% [EOF]
