function box(varargin)
%BOX Display axes outline.
%   BOX ON adds a box to the current axes.
%   BOX OFF removes the box from the current axes.
%   BOX, by itself, toggles the box state of the current axes.
%   BOX(AX,...) uses axes AX instead of the current axes.
%
%   BOX sets the Box property of an axes.
%
%   See also GRID, AXES.

%   Copyright 1984-2023 The MathWorks, Inc.

% To ensure the correct current handle is taken in all situations.

narginchk(0,2)

isaxarr=matlab.graphics.chart.internal.objArrayDispatch(@box,varargin{:});
if isaxarr
    return
end

opt_box = false;
box_toggle = false;
if nargin == 0
    ax = gca;
    box_toggle = true;
else
    arg1=varargin{1};
    if isempty(arg1)
        opt_box = lower(arg1);
    end

    % Update input to OnOffSwitchState if possible. A check on GroupBase
    % allows for numeric handles to axes, colorbar and legend, without
    % catching integer handles for figures.
    if ~isempty(arg1) && ~isa(arg1,'matlab.graphics.Graphics') && ...
            any(~isgraphics(arg1,'matlab.graphics.primitive.world.GroupBase'),'all')
        if nargin == 2
            error(message('MATLAB:box:HandleExpected'));
        end
        try
            opt_box = matlab.lang.OnOffSwitchState(arg1);
            assert(isscalar(opt_box));
        catch
            error(message('MATLAB:box:CommandUnknown'));
        end
        ax = gca;
    else
        % Check that the first argument is a target of some sort (object or
        % double handle). While an axes is expected, the box function
        % supports colorbar and legend for compatibility. A target that
        % doesn't support box will throw below (during set or get) with a
        % reasonable error message.
        if ~isempty(arg1) && any(~ishghandle(arg1),'all')
            error(message('MATLAB:box:ExpectedAxesHandle'));
        end
        ax = arg1;

        % check for string option
        if nargin == 2
            if isempty(arg1)
                error(message('MATLAB:box:ExpectedAxesHandle'));
            end
            try
                opt_box = matlab.lang.OnOffSwitchState(varargin{2});
                assert(isscalar(opt_box));
            catch
                error(message('MATLAB:box:CommandUnknown'));
            end
        else
            box_toggle = true;
        end
    end
end

if isempty(opt_box)
    error(message('MATLAB:box:CommandUnknown'));
end

if isa(ax,'map.graphics.axis.MapAxes')
    box(ax, opt_box)
    return
end

matlab.graphics.internal.markFigure(ax);

if box_toggle
    set(ax,'Box',~get(ax,'Box'));
else
    set(ax,'Box', opt_box);
end
