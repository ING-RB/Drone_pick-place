function hout=streamline(varargin)
%

%   Copyright 1984-2024 The MathWorks, Inc.

[cax, args] = axescheck(varargin{:});
[args, pvpairs] = parseparams(args);
nargs = numel(args);
[verts, x, y, z, u, v, w, sx, sy, sz, options] = parseargs(nargs,args);

if isempty(cax)
    cax = gca;
end

if isempty(verts)
    if isempty(w)
        % 2D
        if isempty(x)
            verts = stream2(u,v,sx,sy,options);
        else
            verts = stream2(x,y,u,v,sx,sy,options);
        end
    else
        % 3D
        if isempty(x)
            verts = stream3(u,v,w,sx,sy,sz,options);
        else
            verts = stream3(x,y,z,u,v,w,sx,sy,sz,options);
        end
    end
end

h = gobjects(numel(verts),1);
ns = 0;
firstLine = true;
for k = 1:numel(verts)
    vv = verts{k};
    if ~isempty(vv)
        z = {};
        if size(vv,2)==3
            z = {'ZData', vv(:,3)};
        end
        h(k) = line('XData', vv(:,1), 'YData', vv(:,2), z{:}, ...
            'Parent', cax, 'SeriesIndex_I', ns, pvpairs{:});
        if firstLine
            ns = h(k).SeriesIndex_I;
            firstLine = false;
        end
    end
end
h(~isgraphics(h)) = [];

% Register handles with MATLAB code generator
if ~isempty(h)
    if ~isdeployed
        makemcode('RegisterHandle',h,'IgnoreHandle',h(1),'FunctionName','streamline');
    end
end
% Disable data tips
for i = 1:numel(h)
    set(hggetbehavior(h(i), 'DataCursor'), 'Enable', false);
    setInteractionHint(h(i), 'DataCursor', false);
    set(hggetbehavior(h(i), 'Brush'), 'Enable', false);
    setInteractionHint(h(i), 'Brush', false);
end


if nargout>0
    hout=h;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [verts, x, y, z, u, v, w, sx, sy, sz, options] = parseargs(nin, vargin)

[verts, x, y, z, u, v, w, sx, sy, sz, options] = deal([]);

if nin==1  % streamline(xyz) or  streamline(xy)
    verts = vargin{1};
    if ~iscell(verts)
        error(message('MATLAB:streamline:NonCellVertices'))
    end
elseif nin==4 || nin==5           % streamline(u,v,sx,sy)
    [u, v, sx, sy] = deal(vargin{1:4});
    if nin==5, options = vargin{5}; end
elseif nin==6 || nin==7        % streamline(u,v,w,sx,sy,sz) or streamline(x,y,u,v,sx,sy)
    u = vargin{1};
    v = vargin{2};
    if ndims(u)==3
        [w, sx, sy, sz] = deal(vargin{3:6});
    else
        x = u;
        y = v;
        [u, v, sx, sy] = deal(vargin{3:6});
    end
    if nin==7, options = vargin{7}; end
elseif nin==9 || nin==10     % streamline(x,y,z,u,v,w,sx,sy,sz)
    [x, y, z, u, v, w, sx, sy, sz] = deal(vargin{1:9});
    if nin==10, options = vargin{10}; end
else
    error(message('MATLAB:streamline:WrongNumberOfInputs'));
end

sx = sx(:);
sy = sy(:);
sz = sz(:);
