function hout = streamparticles(varargin)
%STREAMPARTICLES  Display stream particles.
%   STREAMPARTICLES(VERTICES) draws stream particles of a vector
%   field. Stream particles are usually represented by markers and
%   can show the position and velocity of a streamline. VERTICES
%   is a cell array of 2D or 3D vertices (as if produced by STREAM2
%   or STREAM3).
%
%   STREAMPARTICLES(VERTICES, N) uses N to determine how many
%   stream particles are drawn. The 'ParticleAlignment' property
%   controls how N is interpreted. If 'ParticleAlignment' is 'off'
%   (the default) and N is greater than 1, then approximately N
%   particles are drawn evenly spaced over the streamline vertices;
%   if N is less than or equal to 1, N is interpreted as a fraction
%   of the original stream vertices; for example, if N is 0.2,
%   approximately 20% of the vertices will be used.  N determines
%   the upper bound for the number of particles drawn. Note that
%   the actual number of particles may deviate from N by as much
%   as a factor of 2. If 'ParticleAlignment' is 'on', N determines
%   the number of particles on the streamline with the most
%   vertices; the spacing on the other streamlines is set to this
%   value. The default value is N=1.
%
%   STREAMPARTICLES(...,'NAME1',VALUE1,'NAME2',VALUE2,...) controls
%   the stream particles by using named properties and specified
%   values.  Any unspecified properties have default values.  Case
%   is ignored for property names.
%
%STREAMPARTICLES PROPERTIES
%
%Animate - Stream particles motion [ non-negative integer ]
%   The number of times to animate the stream particles. The
%   default is 0 which does not animate. Inf will animate until
%   ctrl-c is hit.
%
%FrameRate - Animation frames per second [ non-negative integer ]
%   The number of frames per second for the animation. Inf, the
%   default will draw the animation as fast as possible. Note: the
%   framerate can not speed up an animation.
%
%ParticleAlignment - Align particles with streamlines [ on | {off} ]
%   Set this property to 'on' to force particles to be drawn at the
%   beginning of the streamlines. This property controls how N is
%   interpreted.
%
%Also, any line property/value pairs such as 'linestyle' or
%   'marker' can be used.  The following is the default list of
%   line properties set by STREAMPARTICLES. These can be overridden
%   by passing in property/value pairs.
%
%   Property           Value
%   --------           -----
%   'LineStyle'        'none'
%   'Marker'           'o'
%   'MarkerEdgeColor'  'none'
%   'MarkerFaceColor'  'red'
%
%   STREAMPARTICLES(H,...) uses the LINE object H to draw the
%   stream particles.
%
%   STREAMPARTICLES(AX,...) plots into AX instead of GCA.  This option is
%   ignored if you specify H as well.
%
%   H = STREAMPARTICLES(...) returns a vector of handles to LINE
%   objects.
%
%   Example 1:
%      load wind
%      [sx sy sz] = meshgrid(80, 20:1:55, 5);
%      verts = stream3(x,y,z,u,v,w,sx,sy,sz);
%      sl = streamline(verts);
%      iverts = interpstreamspeed(x,y,z,u,v,w,verts,.025);
%      axis tight; view(30,30); daspect([1 1 .125])
%      haxes = gca;
%      haxes.SortMethod = 'ChildOrder';
%      camproj perspective; box on
%      camva(44); camlookat; camdolly(0,0,.4, 'f');
%      h = line;
%      streamparticles(h, iverts, 35, 'animate', 10, ...
%                      'ParticleAlignment', 'on');
%
%   Example 2:
%      load wind
%      daspect([1 1 1]); view(2)
%      [verts averts] = streamslice(x,y,z,u,v,w,[],[],[5]);
%      sl = streamline([verts averts]);
%      axis tight manual off;
%      set(sl,'LineWidth',2);
%      set(sl,'Color','r');
%      set(sl,'Visible','off');
%      iverts = interpstreamspeed(x,y,z,u,v,w,verts,.05);
%      haxes = gca;
%      haxes.SortMethod = 'ChildOrder';
%      haxes.Position = [0 0 1 1];
%      zlim([4.9 5.1]);
%      hfig = gcf;
%      hfig.Color = 'k';
%      h = line;
%      streamparticles(h, iverts, 200, ...
%                      'animate', 100, 'framerate',40, ...
%                      'markers', 10, 'markerf', 'y');
%
%   See also INTERPSTREAMSPEED, STREAMLINE, STREAM3, STREAM2.

%   Copyright 1984-2023 The MathWorks, Inc.

import matlab.graphics.chart.internal.inputparsingutils.getParent

if nargin > 0
    [varargin{:}] = convertStringsToChars(varargin{:});
end

% Check for first argument parent.
[target, args] = checkForParentOrLine(varargin);

% Process positional arguments.
[verts, n, animate, framerate, partalign, props] = parseargs(args);

% Set default values
if isempty(n)
    n = 1;
end

if isempty(animate)
    animate = 0;
end

if isempty(framerate)
    framerate = inf;
end
framerate = 1/framerate;

if isempty(partalign)
    partalign = 'off';
end

% Check for a "Parent" name/value pair. "ParticleAlignment" matches the
% first three characters of "Parent", so require a 4 character match.
[target, hasTarget, props] = getParent(target, props, 4);

if ~hasTarget
    target = gca;
end

% Create a line, unless the target specified was a line.
if isempty(target) || ~isgraphics(target, 'line')
    h = line(target, NaN, NaN);
else
    h = target;
end

set(h, 'LineStyle', 'none', 'Marker', 'o', ...
    'MarkerEdgeColor', 'none', 'MarkerFaceColor', 'red');

if ~isempty(props)
    set(h, props{:})
end

% if it's 2D, make it 3D
vv=cat(1, verts{:});
if size(vv,2)==2
    vv(:,3) = 0;
end

% This try/catch block helps to close the figure gracefully
% during the streamparticles animation.
try
    if strcmp(partalign, 'off')
        % Evenly distributed particles
        len = size(vv,1);
        if n<=1
            n = n*len;
        end
        inc = ceil(len/n);

        set(h, 'xdata', vv(1:inc:end,1), ...
            'ydata', vv(1:inc:end,2), ...
            'zdata', vv(1:inc:end,3))
        for j = 1:animate
            for k = 1:inc
                if framerate>0
                    t0 = tic();
                    while(toc(t0)<framerate);end
                end
                set(h, 'xdata', vv(k:inc:end,1), ...
                    'ydata', vv(k:inc:end,2), ...
                    'zdata', vv(k:inc:end,3))
                set(hggetbehavior(h,'DataCursor'), 'Enable', false);
                setInteractionHint(h, 'DataCursor', false);
                drawnow;
            end
        end
    else
        % Particles aligned with start of streamlines
        lengths = cellfun('size', verts,1);
        endpos = cumsum(lengths);
        startpos = [1 endpos(1:end-1)+1];
        inc = ceil(max(lengths)/n);
        index = [];
        for j = 1:length(startpos)
            index = [index startpos(j):inc:endpos(j)]; %#ok<AGROW>
        end
        set(h, 'xdata', vv(index,1), ...
            'ydata', vv(index,2), ...
            'zdata', vv(index,3))

        for i = 1:animate
            for k = 1:inc
                index = [];
                for j = 1:length(startpos)
                    index = [index startpos(j)+k:inc:endpos(j)]; %#ok<AGROW>
                end
                if framerate>0
                    t0 = tic();
                    while(toc(t0)<framerate);end
                end
                set(h, 'xdata', vv(index,1), ...
                    'ydata', vv(index,2), ...
                    'zdata', vv(index,3))
                drawnow;

            end
        end
    end
catch E
    if ~strcmp(E.identifier, 'MATLAB:class:InvalidHandle')
        rethrow(E);
    end
end

% Disable data tips
for idx = 1:numel(h)
    set(hggetbehavior(h(idx), 'DataCursor'), 'Enable', false);
    setInteractionHint(h(idx), 'DataCursor', false);
end

if nargout > 0
    hout = h;
end

end

function [target, args] = checkForParentOrLine(args)
% streamparticles accepts either an axes handle or line handle as the first
% input argument.

import matlab.graphics.chart.internal.inputparsingutils.peelFirstArgParent

% First check for either an axes or line graphics object.
supportDoubleAxesHandle = true;
[target, args] = peelFirstArgParent(args, supportDoubleAxesHandle);

% peelFirstArgParent will accept a double axes handle, but won't accept a
% double line handle, so check now in case the first input is a double
% handle to a line object. For consistency with older releases, if both an
% axes and line are provided, accept both, but don't allow two lines. If
% both an axes and line are specified, the axes will be ignored.
if ~any(isgraphics(target, 'line'), 'all') ...
        && ~isempty(args) ...
        && isscalar(args{1}) ...
        && isgraphics(args{1}, 'line')

    % Throw a warning indicating that the previously specified parent was
    % ignored. peelFirstArgParent will return empty double if no first
    % argument parent was specified, otherwise it will return a graphics
    % object handle (which may be empty).
    if ~isequal(target, [])
        warning(message('MATLAB:streamparticles:BothParentAndLine'))
    end

    target = handle(args{1});
    args(1) = [];
end

end

function [verts, n, animate, framerate, partalign, props] = parseargs(args)

n = [];
animate = [];
framerate = [];
partalign = [];
props = struct();

nargs = numel(args);
if nargs==0
    error(message('MATLAB:streamparticles:WrongNumberOfInputs'));
else
    % streamparticles(verts) or streamparticles(verts,n)
    verts = args{1};

    if nargs >= 2
        if ischar(args{2}) || (isstring(args{2}) && isscalar(args{2}))
            % streamparticles(verts, name, value, ...)
            pos = 2;
        else
            % streamparticles(verts, n, name, value, ...)
            n = args{2};
            pos = 3;
            if nargs == 3
                error(message('MATLAB:streamparticles:WrongNumberOfInputs'));
            end
        end

        % Look for and remove the "Animate", "FrameRate" and
        % "ParticleAlignment" name/value pairs.
        while pos < nargs
            name = args{pos};
            if ~ischar(name) && ~(isstring(name) && isscalar(name))
                error(message('MATLAB:streamparticles:NonStringPVPair'));
            end

            if pos+1 > nargs
                error(message('MATLAB:streamparticles:MissingPVPair'));
            end

            value = args{pos+1};

            if strcmpi(name, 'animate')
                animate = value;
            elseif strcmpi(name, 'framerate')
                framerate = value;
            elseif strcmpi(name, 'particlealignment')
                partalign = lower(value);
            else
                props.(name) = value;
            end
            pos = pos+2;
        end
    end    
end

props = namedargs2cell(props);

end
