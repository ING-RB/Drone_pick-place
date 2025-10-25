function varargout = axis(varargin)
%AXIS  Control axis scaling and appearance.
%   AXIS([XMIN XMAX YMIN YMAX]) sets scaling for the x- and y-axes
%      on the current plot.
%   AXIS([XMIN XMAX YMIN YMAX ZMIN ZMAX]) sets the scaling for the
%      x-, y- and z-axes on the current 3-D plot.
%   AXIS([XMIN XMAX YMIN YMAX ZMIN ZMAX CMIN CMAX]) sets the
%      scaling for the x-, y-, z-axes and color scaling limits on
%      the current axis (see CLIM).
%   V = AXIS returns a row vector containing the scaling for the
%      current plot.  If the current view is 2-D, V has four
%      components; if it is 3-D, V has six components.
%
%   AXIS AUTO  returns the axis scaling to its default, automatic
%      mode where, for each dimension, 'nice' limits are chosen based
%      on the extents of all line, surface, patch, and image children.
%   AXIS MANUAL  freezes the scaling at the current limits, so that if
%      HOLD is turned on, subsequent plots will use the same limits.
%   AXIS TIGHT  sets the axis limits to the range of the data.
%   AXIS FILL  sets the axis limits and PlotBoxAspectRatio so that
%      the axis fills the position rectangle.  This option only has
%      an effect if PlotBoxAspectRatioMode or DataAspectRatioMode are
%      manual.
%
%   AXIS IJ  puts MATLAB into its "matrix" axes mode.  The coordinate
%      system origin is at the upper left corner.  The i axis is
%      vertical and is numbered from top to bottom.  The j axis is
%      horizontal and is numbered from left to right.
%   AXIS XY  puts MATLAB into its default "Cartesian" axes mode.  The
%      coordinate system origin is at the lower left corner.  The x
%      axis is horizontal and is numbered from left to right.  The y
%      axis is vertical and is numbered from bottom to top.
%
%   AXIS EQUAL  sets the aspect ratio so that equal tick mark
%      increments on the x-,y- and z-axis are equal in size. This
%      makes SPHERE(25) look like a sphere, instead of an ellipsoid.
%   AXIS IMAGE  is the same as AXIS EQUAL except that the plot
%      box fits tightly around the data.
%   AXIS SQUARE  makes the current axis box square in size.
%   AXIS NORMAL  restores the current axis box to full size and
%       removes any restrictions on the scaling of the units.
%       This undoes the effects of AXIS SQUARE and AXIS EQUAL.
%   AXIS VIS3D  freezes aspect ratio properties to enable rotation of
%       3-D objects and overrides stretch-to-fill.
%
%   AXIS OFF  turns off all axis labeling, tick marks and background.
%   AXIS ON  turns axis labeling, tick marks and background back on.
%
%   AXIS(H,...) changes the axes handles listed in vector H.
%
%   See also AXES, GRID, SUBPLOT, XLIM, YLIM, ZLIM, RLIM

%   Copyright 1984-2024 The MathWorks, Inc.

[varargin{:}] = convertStringsToChars(varargin{:});

% Get the list of objects to operate upon. Only support double handles for
% Cartesian axes, but otherwise accept any graphics object as a target.
if nargin > 0 && ...
        (all(isgraphics(varargin{1}, 'axes'),'all') ...
        || isa(varargin{1},'matlab.graphics.Graphics'))
    ax = varargin{1}(:);
    if isa(ax,'double') && isempty(ax)
        % Treat [] like an empty axes array.
        ax = matlab.graphics.axis.Axes.empty(size(ax));
    else
        ax = handle(ax);
    end
    varargin=varargin(2:end);
else
    ax = gca;
    if isa(ax,'matlab.graphics.chart.Chart')
        try
            [varargout{1:nargout}] = axis(ax, varargin{:});
            return
        catch err
            % Unless the axis method was restricted, pretend it does not
            % exist and the next check will throw an error.
            if err.identifier ~= "MATLAB:class:MethodRestricted"
                rethrow(err)
            end
        end
    end
end

if any(isgraphics(ax,'matlab.graphics.axis.GeographicAxes'),'all')
    error(message('MATLAB:Chart:UnsupportedConvenienceFunction', 'axis', 'geoaxes'));
elseif any(isgraphics(ax,'map.graphics.axis.MapAxes'),'all')
    error(message('MATLAB:Chart:UnsupportedConvenienceFunction', 'axis', 'mapaxes'));
elseif ~isa(ax,'matlab.graphics.axis.AbstractAxes')
    for n = 1:numel(ax)
        axisInfo = findobj(metaclass(ax(n)).MethodList, "Name", "axis");
        if isempty(axisInfo) || all(axisInfo.Access ~= "public")
            error(message('MATLAB:Chart:UnsupportedConvenienceFunction', 'axis', ax(n).Type));
        end
    end
end

varargout = cell(1,0);
pbarlimit = 0.1;

%---Check for bypass option (only supported for single axes)
nax = numel(ax); 
if isscalar(ax) && isappdata(ax,'MWBYPASS_axis')
    if isempty(varargin)
        varargout{1} = mwbypass(ax,'MWBYPASS_axis');
    else
        mwbypass(ax,'MWBYPASS_axis',varargin{:});
    end
elseif isempty(varargin)
    if isscalar(ax)
        error(LocCheckCompatibleLimits(ax));
        varargout{1} = LocGetLimits(ax);
    else
        lims = cell(nax,1);
        for i=1:nax
            error(LocCheckCompatibleLimits(ax(i)));
            lims{i}=LocGetLimits(ax(i));
        end
        varargout{1} = lims;
    end
else
    for j=1:nax
        matlab.graphics.internal.markFigure(ax(j));
        names = get(ax(j),'DimensionNames');
        for i = 1:numel(varargin)
            cur_arg = varargin{i};
            % If cur_arg can be cast to a OnOffSwitchState, do it now.
            % Values that cannot be cast will be handled later
            if isscalar(cur_arg)
                try %#ok<TRYNC>
                    cur_arg = matlab.lang.OnOffSwitchState(cur_arg);
                end
            end
            % Set limits manually with 4/6/8 element vector
            if ~ischar(cur_arg) && ~isa(cur_arg,'matlab.lang.OnOffSwitchState')
                error(LocCheckCompatibleLimits(ax(j)));
                LocSetLimits(ax(j),cur_arg,names);
            else    
                switch lower(cur_arg)
                    case 'tight'
                        LocSetLimitMethod(ax(j),names,'tight');

                    case 'padded'
                        LocSetLimitMethod(ax(j),names,'padded');

                    case 'tickaligned'
                        LocSetLimitMethod(ax(j),names,'tickaligned');

                    case 'fill'
                        if ~iscartesian(ax(j))
                            error(message('MATLAB:axis:CartesianAxes', cur_arg));
                        end
                        if ~isnumericAxes(ax(j))
                            error(message('MATLAB:axis:NumericAxes', cur_arg));
                        end
                        LocSetFill(ax(j),pbarlimit);

                    case 'manual'
                        LocSetManual(ax(j),names);

                    case 'ij'
                        if ~iscartesian(ax(j))
                            error(message('MATLAB:axis:CartesianAxes', cur_arg));
                        end
                        set(ax(j),...
                            'XDir','normal',...
                            'YDir','reverse');

                    case 'xy'
                        if ~iscartesian(ax(j))
                            error(message('MATLAB:axis:CartesianAxes', cur_arg));
                        end
                        set(ax(j),...
                            'XDir','normal',...
                            'YDir','normal');

                    case 'square'
                        if ~iscartesian(ax(j))
                            error(message('MATLAB:axis:CartesianAxes', cur_arg));
                        end
                        set(ax(j),...
                            'PlotBoxAspectRatio',[1 1 1],...
                            'DataAspectRatioMode','auto')

                    case 'equal'
                        if ~iscartesian(ax(j))
                            error(message('MATLAB:axis:CartesianAxes', cur_arg));
                        end
                        if ~isnumericAxes(ax(j))
                            error(message('MATLAB:axis:NumericAxes', cur_arg));
                        end
                        if isyyaxis(ax(j))
                            % yyaxis does not support changes to DataAspectRatio
                            warning(message('MATLAB:Chart:UnsupportedAxisStyle',lower(cur_arg)))
                        else
                            LocSetEqual(ax(j),pbarlimit);
                        end

                    case 'image'
                        if ~iscartesian(ax(j))
                            error(message('MATLAB:axis:CartesianAxes', cur_arg));
                        end
                        if ~isnumericAxes(ax(j))
                            error(message('MATLAB:axis:NumericAxes', cur_arg));
                        end
                        if isyyaxis(ax(j))
                            % yyaxis does not support changes to DataAspectRatio
                            warning(message('MATLAB:Chart:UnsupportedAxisStyle',lower(cur_arg)))
                        else
                            LocSetImage(ax(j),pbarlimit);
                        end

                    case 'normal'
                        hax = ax(j);
                        if isprop(hax,'PlotBoxAspectRatioMode')
                            set(ax(j),'PlotBoxAspectRatioMode','auto');
                        end
                        if isprop(hax,'DataAspectRatioMode')
                            set(ax(j),'DataAspectRatioMode','auto');
                        end
                        if isprop(hax,'CameraViewAngleMode')
                            set(ax(j),'CameraViewAngleMode','auto');
                        end

                    case 'off'
                        set(ax(j),'Visible','off');
                        set(get(ax(j),'Title'),'Visible','on');
                        set(get(ax(j),'Subtitle'),'Visible','on');

                    case 'on'
                        set(ax(j),'Visible','on');

                    case 'vis3d'
                        if ~iscartesian(ax(j))
                            error(message('MATLAB:axis:CartesianAxes', cur_arg));
                        end
                        if isyyaxis(ax(j))
                            % yyaxis does not support changes to DataAspectRatio
                            warning(message('MATLAB:Chart:UnsupportedAxisStyle',lower(cur_arg)))
                        else
                            set(ax(j),'CameraViewAngle',get(ax(j),'CameraViewAngle'));
                            set(ax(j),'PlotBoxAspectRatio',get(ax(j),'PlotBoxAspectRatio'));
                            set(ax(j),'DataAspectRatio',get(ax(j),'DataAspectRatio'));
                        end

                    otherwise
                        if startsWith(cur_arg,'auto','IgnoreCase',true)
                            % auto, auto x, autox, autoxyz, auto x y z,auto x zy, etc.
                            LocSetAuto(ax(j),cur_arg,names);
                        else
                            error(message('MATLAB:axis:UnknownOption', cur_arg));
                        end
                end
            end
        end
    end
end

if nargout > 0 && isempty(varargout)
    nargoutchk(0, 0);
end

end

function ans1=LocCheckCompatibleLimits(axH)
%returns error message or empty

ans1 = '';
names = get(axH,'DimensionNames');
v1 = get(axH,[names{1} 'Lim']);
v2 = get(axH,[names{2} 'Lim']);
if is2D(axH)
    if isnumeric(v1) && isnumeric(v2)
        return;
    end
    if ~strcmp(class(v1),class(v2))
        ans1 = message('MATLAB:axis:Mixed2D');
    end
else
    v3 = get(axH,[names{3} 'Lim']);
    if isnumeric(v1) && isnumeric(v2) && isnumeric(v3)
        return;
    end
    if ~strcmp(class(v1),class(v2)) || ~strcmp(class(v1),class(v3))
        ans1 = message('MATLAB:axis:Mixed3D');
    end
end

end

function ans1=LocGetLimits(axH)
%returns a 4 or 6 element vector of limits for a single axis

names = get(axH,'DimensionNames');
ans1 = [get(axH,[names{1} 'Lim']) get(axH,[names{2} 'Lim'])];
if ~is2D(axH)
    ans1 = [ans1 get(axH,[names{3} 'Lim'])];
end

end

function LocSetLimits(ax,lims,names)
nlims = numel(lims);
if any(nlims == [4 6 8])
    set(ax,...
        [names{1} 'Lim'],lims(1:2),...
        [names{2} 'Lim'],lims(3:4),...
        [names{1} 'LimMode'],'manual',...
        [names{2} 'LimMode'],'manual');

    if hasZProperties(ax) && nlims > 4
        set(ax,...
            [names{3} 'Lim'],lims(5:6),...
            [names{3} 'LimMode'],'manual');
    end

    if nlims == 8
        set(ax,...
            'CLim',lims(7:8),...
            'CLimMode','manual');
    end

    if nlims == 4 && ~strcmp(get(ax,'NextPlot'),'add')
        if hasCameraProperties(ax)
            set(ax,'CameraPositionMode','auto',...
                'CameraTargetMode','auto',...
                'CameraUpVectorMode','auto')
        end
    elseif nlims == 6 && ...
            isequal(get(ax,'View'),[0 90]) && ...
            ~strcmp(get(ax,'NextPlot'),'add')
        if hasCameraProperties(ax)
            set(ax,'CameraPositionMode','auto',...
                'CameraTargetMode','auto',...
                'CameraUpVectorMode','auto')
        end
    end
else
    error(message('MATLAB:axis:WrongNumberElements'));
end

end

function LocSetAuto(ax,cur_arg,names)
%called in response to axis auto[xyz]

do_all = strcmpi(cur_arg,'auto');
do_x = contains(cur_arg,'x','IgnoreCase',true);
do_y = contains(cur_arg,'y','IgnoreCase',true);
do_z = contains(cur_arg,'z','IgnoreCase',true);
if(do_all || do_x)
    set(ax,[names{1} 'LimitMethod'],'tickaligned');
    set(ax,[names{1} 'LimMode'],'auto');
else
    set(ax,[names{1} 'LimMode'],'manual');
end
if(do_all || do_y)
    set(ax,[names{2} 'LimitMethod'],'tickaligned');
    limitmethodfanout(ax)
    set(ax,[names{2} 'LimMode'],'auto');
else
    set(ax,[names{2} 'LimMode'],'manual');
end
if hasZProperties(ax)
    if(do_all || do_z)
        set(ax,[names{3} 'LimitMethod'],'tickaligned');
        set(ax,[names{3} 'LimMode'],'auto');
    else
        set(ax,[names{3} 'LimMode'],'manual');
    end
end

end

function LocSetManual(ax,names)
get(ax,{[names{1} 'Lim'],[names{2} 'Lim']});
hasZ = hasZProperties(ax);
if hasZ
    get(ax, [names{3} 'Lim']);
end
set(ax,...
    [names{1} 'LimMode'],'manual',...
    [names{2} 'LimMode'],'manual');
if hasZ
    set(ax, [names{3} 'LimMode'], 'manual');
end

end

function LocSetLimitMethod(ax,names,meth)
set(ax,[names{1} 'LimitMethod'],meth,[names{2} 'LimitMethod'],meth);
set(ax,[names{1} 'LimMode'],'auto',[names{2} 'LimMode'],'auto')
limitmethodfanout(ax)
if hasZProperties(ax)
    set(ax,[names{3} 'LimitMethod'],meth);
    set(ax,[names{3} 'LimMode'],'auto');
end


end

function LocSetFill(ax,pbarlimit)
%called in response to axis fill

if strcmp(get(ax,'PlotBoxAspectRatioMode'),'manual') || ...
        strcmp(get(ax,'DataAspectRatioMode'),'manual')
    % Check for 3-D plot
    if all(rem(get(ax,'view'),90)~=0)
        a = axis(ax);
        axis(ax,'auto');
        axis(ax,'image');
        pbar = get(ax,'PlotBoxAspectRatio');

        if pbar(1)~=pbarlimit, set(ax,'xlim',a(1:2)); end
        if pbar(2)~=pbarlimit, set(ax,'ylim',a(3:4)); end
        if pbar(3)~=pbarlimit, set(ax,'zlim',a(5:6)); end
        return
    end

    a = getpixelposition(ax);
    % Change the unconstrained axis limit to 'auto'
    % based on the axis position.  Also set the pbar.
    set(ax,'PlotBoxAspectRatio',a([3 4 4]))
    if a(3) > a(4)
        set(ax,'xlimmode','auto')
    else
        set(ax,'ylimmode','auto')
    end
end

end

function LocSetEqual(ax,pbarlimit)
%called in response to axis equal

% Check for 3-D plot.  If so, use AXIS IMAGE.
if all(rem(get(ax,'view'),90)~=0)
    LocSetImage(ax,pbarlimit);
    return
end

if isa(ax.Parent,'matlab.graphics.layout.Layout')
    % getpixelposition won't provide an appropriate measure for an axes in
    % a layout because: constrained aspect ratio axes in layouts report
    % plotbox position, getpixelposition doesn't take layout position into
    % account
    set(ax, 'DataAspectRatioMode', 'auto', 'PlotBoxAspectRatioMode', 'auto')
    ax.Position; % query position to force autocalc
    up = ax.Camera.Viewport;
    up.Units='pixels';
    a = up.Position;
else
    a = getpixelposition(ax);
end

set(ax,'DataAspectRatio',[1 1 1]);

% if axes size is non-0 in both dimensions, set the PBAR
if a(3) > 0 && a(4) > 0
    dx = diff(get(ax,'xlim'));
    dy = diff(get(ax,'ylim'));
    dz = 1;
    if hasZProperties(ax)
        dz = diff(get(ax,'ZLim'));
    end
    set(ax,'PlotBoxAspectRatioMode','auto')
    pbar = get(ax,'PlotBoxAspectRatio');
    set(ax,'PlotBoxAspectRatio', ...
        [a(3) a(4) dz*min(a(3),a(4))/min(dx,dy)]);

    % Change the unconstrained axis limit to auto based
    % on the PBAR.
    if pbar(1)/a(3) < pbar(2)/a(4)
        set(ax,'xlimmode','auto')
    else
        set(ax,'ylimmode','auto')
    end
end

end

function LocSetImage(ax,pbarlimit)

set(ax,...
    'DataAspectRatio',[1 1 1], ...
    'PlotBoxAspectRatioMode','auto')

% Limit plotbox aspect ratio to 1 to 25 ratio.
pbar = get(ax,'PlotBoxAspectRatio');
pbar = max(pbarlimit,pbar / max(pbar));
if any(pbar(1:2) == pbarlimit)
    set(ax,'PlotBoxAspectRatio',pbar)
end

names = get(ax,'DimensionNames');
LocSetLimitMethod(ax,names,'tight');

end

function result = allAxes(h)

result = all(ishghandle(h(:))) && ...
    length(findobj(h(:),'-regexp','Type','.*axes','-depth',0)) == length(h(:));
if any(isgraphics(h(:),'geoaxes'))
    error(message('MATLAB:Chart:UnsupportedConvenienceFunction', 'axis', 'geoaxes'));
elseif any(isgraphics(h(:),'map.graphics.axis.MapAxes'))
    error(message('MATLAB:Chart:UnsupportedConvenienceFunction', 'axis', 'mapaxes'));
end

end

function result = iscartesian(h)

ds = get(h,'DataSpace');
result = strcmp(ds(1).isCurvilinear,'off');

end

function result = isnumericAxes(h)
result = isnumeric(get(h,'XLim'));
result = result && isnumeric(get(h,'YLim'));
if hasZProperties(h)
    result = result && isnumeric(get(h,'ZLim'));
end

end

function limitmethodfanout(ax)
% fan out limit method in the case of yyaxis
tm=ax.TargetManager;
if isempty(tm) || isscalar(ax.TargetManager.Children)
    return
end

targets = tm.Children;
for i=1:numel(targets)
    ds=targets(i).DataSpace;
    ds.YLimSpec=ax.YLimitMethod;
end

end

function TF = isyyaxis(ax)
% Returns true when scalar ax handle is yyaxis.
TF = isprop(ax,'TargetManager') && ~isempty(ax.TargetManager) && numel(ax.TargetManager.Targets) > 1;
end