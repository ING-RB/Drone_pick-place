classdef FillAxes < handle
    % FillAxes is a mixin to be used with Zoom when you have a locked
    % DataAspectRatio axes that you want to fill the available space 
        
    %   Copyright 2020 The MathWorks, Inc.
    methods (Hidden)
        function updateLimits(this, ax)
            if nargin < 2
                ax = getAxes(this);
            end
            pos = getpixelposition(ax);
            
            % Avoid errors by removing the chance for a 0 or negative width
            % or height. These values mean the axes isnt visible because it
            % is smooshed too far in 1 direction.
            if pos(3) <= 0
                pos(3) = 1;
            end
            if pos(4) <= 0
                pos(4) = 1;
            end
            
            center = this.Center;
            unitsPerPixel = getUnitsPerPixel(this, ax);
            range = [-1 1] * unitsPerPixel / 2;
            
            view = ax.View;
            if isequal(view, [0 90])
                set(ax, ...
                    'XLim', center(1) + range * pos(3), ...
                    'YLim', center(2) + range * pos(4));
            elseif isequal(view, [0 0])
                set(ax, ...
                    'XLim', center(1) + range * pos(3), ...
                    'ZLim', center(3) + range * pos(4));
            elseif isequal(view, [90 0])
                set(ax, ...
                    'YLim', center(2) + range * pos(3), ...
                    'ZLim', center(3) + range * pos(4));
            elseif isequal(view, [-90 90])
                set(ax, ...
                    'XLim', center(1) + range * pos(4), ...
                    'YLim', center(2) + range * pos(3));
            end
        end
        
        function captureAxesLimits(this)
            dims = getHVDimensions(this);
            axes = getAxes(this);
            applyAxesLimits(this, axes.([dims(1) 'Lim']), axes.([dims(2) 'Lim'])); 
        end
        
        function applyAxesLimits(this, hLim, vLim)
            dims = getHVDimensions(this);
            center = this.Center;
            ax = getAxes(this);
            pos = getpixelposition(ax);
            if strcmp(dims, 'XY')
                % Convert limits to centers and unitsPerPixel;
                
                center(1) = mean(hLim);
                center(2) = mean(vLim);
                
            elseif strcmp(dims, 'YZ')
                center(2) = mean(hLim);
                center(3) = mean(vLim);
            elseif strcmp(dims, 'XZ')
                center(1) = mean(hLim);
                center(3) = mean(vLim);
            elseif strcmp(dims, 'YX')
                center(1) = mean(vLim);
                center(2) = mean(hLim);
            end
            if pos(3) > pos(4)
                unitsPerPixel = diff(hLim) / pos(3);
            else
                unitsPerPixel = diff(vLim) / pos(4);
            end
            setCenterAndUnitsPerPixel(this, center, unitsPerPixel, ax);
        end
        
        function setCenterAndUnitsPerPixel(this, center, unitsPerPixel, ~)
            this.Center = center;
            this.UnitsPerPixel = unitsPerPixel;
            updateLimits(this);
        end
        
        function upp = getUnitsPerPixel(this, ~)
            upp = this.UnitsPerPixel;
        end
    end
end

% [EOF]
