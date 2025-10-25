classdef AxesTooltip < handle
    %
    
    %   Copyright 2020 The MathWorks, Inc.
    properties (SetAccess = protected, Hidden)
        hTooltip;
    end
    
    methods
        function setTooltipString(this, newString, interpreter)
            tooltip = this.hTooltip;
            if isempty(newString)
                if ~isempty(tooltip) && ishghandle(tooltip)
                    set(tooltip, 'Visible', 'off');
                end
            else
                hAxes = getAxes(this);
                if isempty(tooltip) || ~ishghandle(tooltip)
                    tooltip = text(hAxes, ...
                        'Tag', 'Tooltip', ...
                        'HitTest', 'off', ...
                        'HorizontalAlignment', 'left', ...
                        'VerticalAlignment', 'bottom', ...
                        'Color', [0 0 0], ...
                        'BackgroundColor', [253 253 204]/255, ...
                        'Visible', 'off');
                    this.hTooltip = tooltip;
                end
                set(tooltip, 'Parent', hAxes);
                if nargin < 3
                    interpreter = 'none';
                end
                tooltip.Interpreter = interpreter;
                [cp, unitsPerPixel] = getCurrentPoint(this);
                view = hAxes.View;
                xlim = hAxes.XLim;
                ylim = hAxes.YLim;
                zlim = hAxes.ZLim;
                if isequal(view, [0 90]) % xy
                    if strcmp(hAxes.YDir, 'normal')
                        top = ylim(2);
                    else
                        top = ylim(1);
                    end
                    if strcmp(hAxes.ZDir, 'normal')
                        cp(3) = zlim(2);
                    else
                        cp(3) = zlim(1);
                    end
                    indx = 2;
                elseif isequal(view, [-90 90]) % yx
                    if strcmp(hAxes.XDir, 'normal')
                        top = xlim(2);
                    else
                        top = xlim(1);
                    end
                    if strcmp(hAxes.ZDir, 'normal')
                        cp(3) = zlim(2);
                    else
                        cp(3) = zlim(1);
                    end
                    indx = 1;
                elseif isequal(view, [0 0]) % xz
                    if strcmp(hAxes.ZDir, 'normal')
                        top = zlim(2);
                    else
                        top = zlim(1);
                    end
                    cp(2) = ylim(1); % The bottom ylimit is "closer" to the screen
                    indx = 3;
                elseif isequal(view, [90 0]) % yz
                    if strcmp(hAxes.ZDir, 'normal')
                        top = zlim(2);
                    else
                        top = zlim(1);
                    end
                    cp(1) = xlim(2);
                    indx = 3;
                end
                
                modifier = [0 0 0];
                if cp(indx) > top
                    modifier(indx) = -50*unitsPerPixel;
                else
                    modifier(indx) = 20*unitsPerPixel;
                end
                pos = cp + modifier;
                
                pos(1) = keepInRange(pos(1), xlim);
                pos(2) = keepInRange(pos(2), ylim);
                pos(3) = keepInRange(pos(3), zlim);
                
                set(tooltip, 'Position', pos, 'Visible', 'on', 'String', newString);
            end
        end
        
        function [cp,hUnitsPerPixel,vUnitsPerPixel,N] = getCurrentPoint(this, shouldNotRound)
            % Get the current mouse point on the axes
            hAxes = getAxes(this);
            cp = get(hAxes, 'CurrentPoint');
            cp = cp([1 3 5]);
            % We round the current point to N digits to the
            % right of the decimal point. N is set based on the
            % units per pixel. The CurrentPoint has only 4
            % digits of precision. So maximum N used is 4.
            view = hAxes.View;
            if isequal(view, [0 90]) || isequal(view, [-90 90])
                cp(3) = 0;
            elseif isequal(view, [0 0])
                cp(2) = 0;
            elseif isequal(view, [90 0])
                cp(1) = 0;
            end
            if nargout > 1 || nargin < 2 || ~shouldNotRound
                [hUnitsPerPixel,vUnitsPerPixel] = getHVUnitsPerPixel(this);
                N = getRoundingFactor(this,hUnitsPerPixel);
                cp = round(cp,N);
            end
        end
        
        function [hUnitsPerPixel,vUnitsPerPixel] = getHVUnitsPerPixel(this)
            % Get Horizontal and Vertical units per pixel
            hAxes = getAxes(this);
            layoutInfo = hAxes.GetLayoutInformation;
            box = layoutInfo.PlotBox;
            view = hAxes.View;
            
            if isequal(view, [0 90])
                hRange = diff(hAxes.XLim);
                vRange = diff(hAxes.YLim);
            elseif isequal(view, [0 0])
                hRange = diff(hAxes.XLim);
                vRange = diff(hAxes.ZLim);
            elseif isequal(view, [90 0])
                hRange = diff(hAxes.YLim);
                vRange = diff(hAxes.ZLim);
            elseif isequal(view, [-90 90])
                hRange = diff(hAxes.YLim);
                vRange = diff(hAxes.XLim);
            end
            hUnitsPerPixel = hRange/box(3);
            vUnitsPerPixel = vRange/box(4);
        end
        
        function N = getRoundingFactor(~,unitsPerPixel)
            % We round the current point to N digits to the
            % right of the decimal point. N is set based on the
            % units per pixel. The CurrentPoint has only 4
            % digits of precision. So maximum N used is 4.
            N = -floor(log10(unitsPerPixel));
            if N < 0
                N = 0;
            elseif N > 4
                N = 4;
            end
        end
        function b = isOverAxes(this)

            fig = getFigure(this);
            hAxes = getAxes(this);
            layoutInfo = hAxes.GetLayoutInformation;
            box = layoutInfo.PlotBox;
            
            point = get(fig, 'CurrentPoint');
            
            b = point(1) > box(1) && point(1) < (box(1) + box(3)) && point(2) > box(2) && point(2) < (box(2) + box(4));
        end
    end
    
    methods (Abstract)
        a = getAxes(this)
    end
end

function pos = keepInRange(pos, lim)

if pos > lim(2)
    pos = lim(2);
elseif pos < lim(1)
    pos = lim(1);
end

end

% [EOF]
