function axReturn = newplot(targetParent)
% NEWPLOT Determine where to draw graphics objects.
%
%    NEWPLOT prepares the current axes of the current figure for subsequent
%    graphics commands.
%
%    NEWPLOT(target) prepares the object specified by target for plotting
%    instead of the current axes of the current figure. The target object
%    can be a Cartesian axes, polar axes, or geographic axes object. If
%    target is empty, newplot behaves as if it were called without any inputs.
%
%    H = NEWPLOT(...) prepares a figure and axes for subsequent graphics
%    commands and returns the current axes.
%
%    To create a simple 2-D plot, use the plot function instead.
%
%    Use NEWPLOT at the beginning of high-level graphics code to determine
%    which figure and axes to target for graphics output. Calling NEWPLOT can
%    change the current figure and current axes.
%
%    The figure and axes NextPlot properties determine how NEWPLOT behaves
%    when you are drawing graphics in existing figures and axes:
%       - NextPlot 'new': Create a new figure and use it as the
%         current figure. This option is only available for the figure
%         NextPlot property.
%       - NextPlot 'add': Add the new graphics without changing any properties
%         or deleting any objects.
%       - NextPlot 'replacechildren': Delete all existing objects whose handles
%         are not hidden before drawing the new objects.
%       - NextPlot 'replace': Delete all existing objects
%         regardless of whether or not their handles are hidden, and reset
%         most properties to their defaults before drawing the new objects.
%       - NextPlot 'replaceall': Delete all existing objects and reset both
%         sides of an Axes object with two y-axes. This option is only
%         available for the axes NextPlot property, and is equivalent to
%         'replace' for Axes objects with a single y-axis.
%
%    See also axes, cla, clf, figure, hold, ishold, plot, reset.

%   Copyright 1984-2023 The MathWorks, Inc.
%   Built-in function.

import matlab.graphics.chart.internal.inputparsingutils.observeFigureNextPlot

if nargin == 0 || isempty(targetParent)
    targetParent = gobjects(0);
elseif ~isscalar(targetParent) || ~isgraphics(targetParent)
    error(message('MATLAB:newplot:InvalidHandle'))
else
    % Make sure we have an object handle.
    targetParent = handle(targetParent);
end

% Get the nearest ancestor current axes and figure from the input.
fig = gobjects(0);
ax = gobjects(0);
if ~isempty(targetParent)
    obj = targetParent;
    while ~isempty(obj)
        if isgraphics(obj, 'figure')
            fig = obj;
        elseif isempty(ax) && isgraphics(obj, 'matlab.graphics.mixin.CurrentAxes')
            ax = obj;
        end
        obj = obj.Parent;
    end
end

% If no axes or figure was found, create a new figure. Check if the axes is
% empty to avoid creating a figure if an unparented axes was provided.
if isempty(fig) && isempty(ax)
    fig = gcf;
end

if ~isempty(fig)
    % Prepare the figure based on the NextPlot property.
    fig = observeFigureNextPlot(fig, targetParent);
end

checkNextPlot=true;
if isempty(ax)
    ax = gca(fig);
    if ~isa(ax,'matlab.graphics.axis.Axes') && ~ax.isHoldEnabled()
        % The current axes either does not support hold or hold is off.
        ax = matlab.graphics.internal.swapaxes(ax, @axes);

        % We just created a new axes so there is no need to check NextPlot
        checkNextPlot = false;
    end
elseif ~isgraphics(ax)
    error(message('MATLAB:newplot:NoAxesParent'))
end

if checkNextPlot
    ax = ax.prepareForPlot(targetParent);

    % Calling prepareForPlot may have deleted the axes. Only create a new
    % axes if the parent was not explicity specified.
    if isempty(ax) || (~isgraphics(ax) && isempty(targetParent))
        if ~any(isgraphics(fig))
            ax = axes;
        else
            ax = axes('Parent',fig);
        end
    end
end

if nargout
    axReturn = ax;
end
