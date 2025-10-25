function grid(varargin)
%GRID   Grid lines.
%   GRID ON adds major grid lines to the current axes.
%   GRID OFF removes major and minor grid lines from the current axes.
%   GRID MINOR toggles the minor grid lines of the current axes.
%   GRID, by itself, toggles the major grid lines of the current axes.
%   GRID(AX,...) uses axes AX instead of the current axes.
%
%   GRID sets the XGrid, YGrid, and ZGrid properties of
%   the current axes. If the axes is a polar axes then GRID sets
%   the ThetaGrid and RGrid properties. If the axes is a geoaxes, then GRID
%   sets the Grid property.
%
%   AX.XMinorGrid = 'on' turns on the minor grid.
%
%   See also TITLE, XLABEL, YLABEL, ZLABEL, AXES, PLOT, BOX, POLARAXES.

%   Copyright 1984-2023 The MathWorks, Inc.

% To ensure the correct current handle is taken in all situations.

isaxarr=matlab.graphics.chart.internal.objArrayDispatch(@grid,varargin{:});
if isaxarr
    return
end

narginchk(0,2)

opt_grid = 0;
if nargin == 0
    ax = gca;

    % Chart subclass support
    if isa(ax,'matlab.graphics.chart.Chart') ...
            || isa(ax,'map.graphics.axis.MapAxes')
        grid(ax);
        return
    end
else
    arg1=varargin{1};
    % Update input to OnOffSwitchState if possible. 
    % Invalid values will be handled later.
    if ~isempty(arg1) && ~any(isgraphics(arg1,'matlab.graphics.axis.AbstractAxes'),'all')
        try %#ok<TRYNC>
            opt_grid = matlab.lang.OnOffSwitchState(arg1);
        end
    end
    if matlab.graphics.internal.isCharOrString(arg1) || isa(opt_grid, 'matlab.lang.OnOffSwitchState')
        if nargin == 2
            error(message('MATLAB:grid:FirstArgAxes'))
        end
        ax = gca;

        if strcmpi(arg1, 'minor')
            opt_grid = 'minor';
        elseif ~isa(opt_grid, 'matlab.lang.OnOffSwitchState') || ~isscalar(opt_grid)
            error(message('MATLAB:grid:UnknownOption'));
        end

        % Chart subclass support
        if isa(ax,'matlab.graphics.chart.Chart') ...
                || isa(ax,'map.graphics.axis.MapAxes')
            grid(ax,opt_grid);
            return
        end
    else
        if ~any(isgraphics(arg1,'matlab.graphics.axis.AbstractAxes'),'all')
            error(message('MATLAB:grid:FirstArgAxes'));
        end
        ax = arg1;

        % check for string option
        if nargin == 2
            in2 = varargin{2};
            if strcmpi(in2, 'minor')
                opt_grid = 'minor';
            else
                try
                    opt_grid = matlab.lang.OnOffSwitchState(in2);
                    assert(isscalar(opt_grid));
                catch
                    error(message('MATLAB:grid:UnknownOption'));
                end
            end
        end
    end
end

if isempty(opt_grid)
    error(message('MATLAB:grid:UnknownOption'));
end

names = get(ax,'DimensionNames');
xgrid = [names{1} 'Grid'];
ygrid = [names{2} 'Grid'];
zgrid = [names{3} 'Grid'];
xminorgrid = [names{1} 'MinorGrid'];
yminorgrid = [names{2} 'MinorGrid'];
zminorgrid = [names{3} 'MinorGrid'];

matlab.graphics.internal.markFigure(ax);

%---Check for bypass option
if isappdata(ax,'MWBYPASS_grid')
    mwbypass(ax,'MWBYPASS_grid',opt_grid);
elseif isgraphics(ax,'geoaxes')
    % geoaxes only has 1 Grid property and does not have a minor grid
    if isnumeric(opt_grid) % opt_grid == 0
        set(ax,'Grid', ~get(ax,'Grid'));
    elseif (strcmp(opt_grid, 'minor'))
        error(message('MATLAB:Chart:UnsupportedArgument','grid','geoaxes'));
    else % opt_grid == OnOffSwitchState on/off
        set(ax,'Grid', opt_grid)
    end
elseif strcmp(opt_grid, 'minor')
    set(ax,xminorgrid, ~get(ax,xminorgrid));
    set(ax,yminorgrid, ~get(ax,yminorgrid));

    if hasZProperties(handle(ax))
        set(ax,zminorgrid, ~get(ax,zminorgrid));
    end
elseif isequal(opt_grid, 0)&& ~isa(opt_grid, 'matlab.lang.OnOffSwitchState')
    set(ax,xgrid,~get(ax,xgrid));
    set(ax,ygrid,~get(ax,ygrid));

    if hasZProperties(handle(ax))
        set(ax,zgrid,~get(ax,zgrid));
    end
else
    set(ax, xgrid, opt_grid, ygrid, opt_grid);
    if ~opt_grid
        set(ax, xminorgrid, opt_grid, yminorgrid, opt_grid);
    end
    if hasZProperties(handle(ax))
        set(ax, zgrid, opt_grid);
        if ~opt_grid
            set(ax,zminorgrid, opt_grid);
        end
    end
end
