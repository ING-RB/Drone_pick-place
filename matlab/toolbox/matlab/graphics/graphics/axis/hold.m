function hold(varargin)
%

%   Copyright 1984-2024 The MathWorks, Inc.

narginchk(0,2);

import matlab.graphics.chart.internal.inputparsingutils.peelFirstArgParent
import matlab.graphics.chart.internal.inputparsingutils.getParent

% Check for first argument target.
supportDoubleAxesHandle = true;
[target, args] = peelFirstArgParent(varargin, supportDoubleAxesHandle);

if numel(args) == 2
    % If two arguments were provided and the first argument is not a
    % graphics object (removed by peelFirstArgParent), then throw an error.
    error(message('MATLAB:hold:InvalidFirstArg'));
end

cls = class(target);
if isequal(target, [])
    target = gca;
    cls = class(target);
elseif numel(target) > 1
    isHomogeneous = all(arrayfun(@(x)strcmp(class(x),cls),target), 'all');
    if ~isHomogeneous
        error(message('MATLAB:rulerFunctions:MixedAxesVector'));
    end
    for t = 1:numel(target)
        hold(target(t), args{:})
    end
    return
end

if ~isa(target, 'matlab.graphics.mixin.CurrentAxes') || ~target.isHoldSupported()
    if ~isempty(target) && isprop(target, 'Type')
        cls = target.Type;
    end
    error(message('MATLAB:hold:UnsupportedCurrentAxes',cls));
end

% Use getParent to check for empty or deleted handles.
getParent(target, {});

matlab.graphics.internal.markFigure(target);

fig = ancestor(target, 'figure');

doDisp = false;
if numel(args) == 0
    % Toggle the current hold state.
    currentHoldState = isscalar(fig) && fig.NextPlot == "add" ...
        && target.isHoldEnabled();
    if currentHoldState
        newHoldState = 'off';
    else
        newHoldState = 'on';
    end
    doDisp = true;
else
    newHoldState = args{1};
end

% For compatibility accept 'all' and treat it like 'on'.
if strcmpi(newHoldState, 'all')
    newHoldState = matlab.lang.OnOffSwitchState.on;
end

try
    newHoldState = matlab.lang.OnOffSwitchState(newHoldState);
    assert(isscalar(newHoldState))
catch
    error(message('MATLAB:hold:UnknownOption'));
end

if newHoldState
    if isscalar(fig)
        fig.NextPlot = 'add';
    end
    target.setHoldState(true);
    if doDisp
        disp(getString(message('MATLAB:hold:CurrentPlotHeld')));
    end
else
    target.setHoldState(false);
    if doDisp
        disp(getString(message('MATLAB:hold:CurrentPlotReleased')));
    end
end

end
