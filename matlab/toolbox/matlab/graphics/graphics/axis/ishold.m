function holdstate = ishold(target)
%ISHOLD Return hold state.
%   ISHOLD returns 1 if hold is on, and 0 if it is off.
%   When HOLD is ON, the current plot and all axis properties
%   are held so that subsequent graphing commands add to the
%   existing graph.
%
%   ISHOLD(AX) returns the hold state of the axes specified by AX instead
%   of the current axes.
%
%   Hold on means the NextPlot property of both figure
%   and axes is set to "add".
%
%   See also HOLD, NEWPLOT, FIGURE, AXES.

%   Copyright 1984-2023 The MathWorks, Inc.

if nargin < 1
    fig = gcf;
    target = fig.CurrentAxes;
    if isempty(target)
        holdstate = false;
        return
    end
else
    if numel(target) > 1
        isHomogeneous = all(arrayfun(@(x)strcmp(class(x),class(target)),target), 'all');
        if ~isHomogeneous
            error(message('MATLAB:rulerFunctions:MixedAxesVector'));
        end
        holdstate=false(size(target));
        for i = 1:numel(target)
            holdstate(i) = ishold(target(i));
        end
        return
    end
    fig = ancestor(target,'figure');
end

if ~isa(target, 'matlab.graphics.mixin.CurrentAxes') || ~target.isHoldSupported()
    cls = class(target);
    if isa(target, 'handle') && ~isempty(target) && isprop(target, 'Type')
        cls = target(1).Type;
    end
    error(message('MATLAB:hold:UnsupportedCurrentAxes',cls));
end

figHold = ~isempty(fig) && fig.NextPlot == "add";
holdstate = figHold && target.isHoldEnabled();

end
