function [XData, YData, ZData, EdgeCoords, EdgeCoordsIndex, Layout, LayoutParameters, CirclePerm] = ...
    layout(BasicGraph, NodeNames, EdgeWeights, varargin)
%LAYOUT Calculate graph layout data
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%
%   [XDATA, YDATA, ZDATA, EDGECOORDS, EDGECOORDSINDEX, LAYOUT, LAYOUTPARAMETERS, ...
%   CIRCLEPERM] = layout(BASICGRAPH, NODENAMES, EDGEWEIGHTS, VARARGIN)
%   Calculates various properties of the plot layout of a graph.
%
%   BASICGRAPH is the underlying MLGraph or MLDigraph to a graph or
%   digraph. NODENAMES is empty or a cell array of size NUMNODES-by-1
%   containing the names of the nodes of the graph. EDGEWEIGHTS is empty or
%   a NUMEDGES-by-1 numeric vector containing the weights of the edges of
%   the graph. VARARGIN optionally contains the desired layout, along with
%   any user-specified Name-Value arguments.
%
%   XDATA, YDATA, and ZDATA are each size 1-by-NUMNODES, and contain the
%   x-, y-, and z-coordinates of each node when plotted, respectively.
%   EDGECOORDS has size NUMPOINTS-by-3, and contains the coordinates of the
%   points that make up each edge. EDGECOORDSINDEX has size NUMPOINTS-by-1,
%   and gives the edge index of each point specified in EDGECOORDS. LAYOUT
%   is a char vector of one of the six possible graph plot layouts.
%   LAYOUTPARAMETERS is a cell array of the Name-Value arguments used to
%   create the plot. CIRCLEPERM has size 1-by-NUMNODES, and gives the
%   permutation order for the circle layout.

%   Copyright 2024 The MathWorks, Inc.
arguments
    BasicGraph {mustBeA(BasicGraph,["matlab.internal.graph.MLGraph","matlab.internal.graph.MLDigraph"])}
    NodeNames
    EdgeWeights
end
arguments (Repeating)
    varargin
end

CirclePerm = [];

if nargin == 3
    Layout = layoutauto(BasicGraph);
else
    Layout = validatestring(varargin{1}, ...
        {'auto','circle','force','layered','subspace','force3','subspace3'});
    if strcmp(Layout, 'auto')
        if numel(varargin) > 1
            error(message('MATLAB:graphfun:plot:NoOptionalInput','auto'));
        end
        Layout = layoutauto(BasicGraph);
    end
end

switch Layout
    case 'circle'
        [XData, YData, ZData, EdgeCoords, EdgeCoordsIndex, LayoutParameters, CirclePerm] = layoutcircle(BasicGraph, NodeNames, varargin{2:end});
    case 'force'
        [XData, YData, ZData, EdgeCoords, EdgeCoordsIndex, LayoutParameters] = layoutforce(BasicGraph, EdgeWeights,varargin{2:end});
    case 'force3'
        [XData, YData, ZData, EdgeCoords, EdgeCoordsIndex, LayoutParameters] = layoutforce3(BasicGraph, EdgeWeights,varargin{2:end});
    case 'layered'
        [XData, YData, ZData, EdgeCoords, EdgeCoordsIndex, LayoutParameters] = layoutlayered(BasicGraph, NodeNames, varargin{2:end});
    case 'subspace'
        [XData, YData, ZData, EdgeCoords, EdgeCoordsIndex, LayoutParameters] = layoutsubspace(BasicGraph, varargin{2:end});
    case 'subspace3'
        [XData, YData, ZData, EdgeCoords, EdgeCoordsIndex, LayoutParameters] = layoutsubspace3(BasicGraph, varargin{2:end});
end
end % END layout

function method = layoutauto(BasicGraph)
% Determine default layout
LargeGraphThreshold = 100;
% LargeGraphThreshold has the same value as GraphPlot.LargeGraphThreshold_
if numnodes(BasicGraph) <= LargeGraphThreshold
    if isa(BasicGraph, 'matlab.internal.graph.MLDigraph')
        hascycles = ~dfsTopologicalSort(BasicGraph);
    else
        hascycles = hasCycles(BasicGraph);
    end
    if hascycles
        method = 'force';
    else
        method = 'layered';
    end
else
    method = 'subspace';
end
end % END layoutauto

function [XData, YData, ZData, EdgeCoords, EdgeCoordsIndex, LayoutParameters, CirclePerm] = ...
    layoutcircle(BasicGraph, NodeNames, varargin)
center = NaN;

nvarargin = length(varargin);
if rem(nvarargin,2) ~= 0
    error(message('MATLAB:graphfun:plot:ArgNameValueMismatch'));
end
layoutparams = varargin;
for i = 1:2:nvarargin
    name = validatestring(varargin{i}, {'Center'});
    layoutparams{i} = name;  %make sure to store full parameter names, not partially matched ones

    center = validateNodeID(BasicGraph, NodeNames, varargin{i+1});
    if ~isscalar(center)
        error(message('MATLAB:graphfun:graphbuiltin:InvalidCenterScalar'));
    end
end

nn = numnodes(BasicGraph);

if ~isnan(center)
    A = adjacency(BasicGraph);
    ncids = 1:nn;
    ncids(center) = [];
    % Compute permutation vector for symmetric reverse Cuthill-McGee ordering
    % If A is non-symmetric, works on the structure of A + A'.
    permnc = symrcm(A(ncids, ncids));

    w = linspace(0,360,nn);
    w(ncids) = w(1:nn-1);
    w(center) = 0;
    XData = zeros(1, nn);
    YData = zeros(1, nn);
    XData(ncids(permnc)) = cosd(w(ncids));
    YData(ncids(permnc)) = sind(w(ncids));

    CirclePerm = zeros(1,nn);
    %Store permutation matrix as [center permutation].
    CirclePerm(1) = center;
    CirclePerm(2:end) = permnc;
else
    w = linspace(0,360,nn+1);
    w = w(1:nn).';
    XData = cosd(w);
    YData = sind(w);
    CirclePerm = [];
end

Layout = 'circle';
LayoutParameters = layoutparams;
ZData = zeros(size(XData));
[EdgeCoords, EdgeCoordsIndex] = matlab.internal.graph.updateEdgeCoords(BasicGraph, Layout, XData, YData, ZData);
end % END layoutcircle

function [XData, YData, ZData, EdgeCoords, EdgeCoordsIndex, LayoutParameters] = ...
    layoutforce(BasicGraph, EdgeWeights,varargin)
iterations = 100;
usedefaultX = true;
usedefaultY = true;
weightEffect = 'none';
gravity = 'off';
% Just validate the optional input names here. For repeated N-V pairs, the
% V of the last N-V pair gets validated in forceLayout.
nvarargin = length(varargin);
if rem(nvarargin,2) ~= 0
    error(message('MATLAB:graphfun:plot:ArgNameValueMismatch'));
end
layoutparams = varargin;
for i = 1:2:nvarargin
    name = validatestring(varargin{i}, {'Iterations','XStart','YStart','WeightEffect','UseGravity'});
    layoutparams{i} = name;  %make sure to store full parameter names, not partially matched ones
    switch name
        case 'Iterations'
            iterations = varargin{i+1};
        case 'XStart'
            usedefaultX = false;
            x0 = varargin{i+1};
        case 'YStart'
            usedefaultY = false;
            y0 = varargin{i+1};
        case 'WeightEffect'
            weightEffect = varargin{i+1};
        case 'UseGravity'
            gravity = varargin{i+1};
    end
end

% Returns a simple, undirected graph with weights kw determined based on weightEffect
[G, kw] = matlab.internal.graph.forceLayoutReweightAndSimplify(BasicGraph,EdgeWeights,weightEffect);

if usedefaultX && usedefaultY
    % Subspace is a fast and effective way to get good initial coordinates.
    [x0,y0] = subspaceLayout(G,min(20,numnodes(G)),2);
    % For subspace, results may differ across platforms due to roundoff.
    % We don't want this to propagate to force.
    x0 = double(single(x0));
    y0 = double(single(y0));
    % Rotate 45 degrees so the line graph 1<->2<->3<->4 has nice Y ticks.
    [XData, YData] = forceLayout(G,x0-y0,x0+y0,iterations,kw,gravity);
elseif ~usedefaultX && ~usedefaultY
    [XData, YData] = forceLayout(G,x0,y0,iterations,kw,gravity);
else
    error(message('MATLAB:graphfun:plot:MissingXStartOrYStart'));
end

% Validate results for node coordinates (must be finite)
if ~allfinite(XData) || ~allfinite(YData)
    error(message('MATLAB:graphfun:graphbuiltin:WEffLayoutFailed'))
end

Layout = 'force';
LayoutParameters = layoutparams;
ZData = zeros(size(XData));
[EdgeCoords, EdgeCoordsIndex] = matlab.internal.graph.updateEdgeCoords(BasicGraph, Layout, XData, YData, ZData);
end % END layoutforce

function [XData, YData, ZData, EdgeCoords, EdgeCoordsIndex, LayoutParameters] = ...
    layoutforce3(BasicGraph, EdgeWeights, varargin)
iterations = 100;
usedefaultX = true;
usedefaultY = true;
usedefaultZ = true;
weightEffect = 'none';
gravity = 'off';
% Just validate the optional input names here. For repeated N-V pairs, the
% V of the last N-V pair gets validated in forceLayout.
nvarargin = length(varargin);
if rem(nvarargin,2) ~= 0
    error(message('MATLAB:graphfun:plot:ArgNameValueMismatch'));
end
layoutparams = varargin;
for i = 1:2:nvarargin
    name = validatestring(varargin{i}, {'Iterations','XStart','YStart','ZStart','WeightEffect','UseGravity'});
    layoutparams{i} = name;  %make sure to store full parameter names, not partially matched ones
    switch name
        case 'Iterations'
            iterations = varargin{i+1};
        case 'XStart'
            usedefaultX = false;
            x0 = varargin{i+1};
        case 'YStart'
            usedefaultY = false;
            y0 = varargin{i+1};
        case 'ZStart'
            usedefaultZ = false;
            z0 = varargin{i+1};
        case 'WeightEffect'
            weightEffect = varargin{i+1};
        case 'UseGravity'
            gravity = varargin{i+1};
    end
end

% Returns a simple, undirected graph with weights kw determined based on weightEffect
[G, kw] = matlab.internal.graph.forceLayoutReweightAndSimplify(BasicGraph,EdgeWeights,weightEffect);

if usedefaultX && usedefaultY && usedefaultZ
    % Subspace is a fast and effective way to get good initial coordinates.
    [x0,y0,z0] = subspaceLayout(G,min(20,numnodes(G)),3);
    % For subspace, results may differ across platforms due to roundoff.
    % We don't want this to propagate to force.
    x0 = double(single(x0));
    y0 = double(single(y0));
    z0 = double(single(z0));
    % Rotate 45 degrees in the xy plane, for consistency with 2-D layout.
    [XData, YData, ZData] = forceLayout3(G,x0-y0,x0+y0,z0,iterations,kw,gravity);
elseif ~usedefaultX && ~usedefaultY && ~usedefaultZ
    [XData, YData, ZData] = forceLayout3(G,x0,y0,z0,iterations,kw,gravity);
else
    error(message('MATLAB:graphfun:plot:MissingXStartYStartOrZStart'));
end

% Validate results for node coordinates (must be finite)
if ~allfinite(XData) || ~allfinite(YData) || ~allfinite(ZData)
    error(message('MATLAB:graphfun:graphbuiltin:WEffLayoutFailed'))
end

Layout = 'force3';
LayoutParameters = layoutparams;
[EdgeCoords, EdgeCoordsIndex] = matlab.internal.graph.updateEdgeCoords(BasicGraph, Layout, XData, YData, ZData);
end % END layoutforce3

function [XData, YData, ZData, EdgeCoords, EdgeCoordsIndex, LayoutParameters] = ...
    layoutlayered(BasicGraph, NodeNames, varargin)
nvarargin = length(varargin);
if rem(nvarargin,2) ~= 0
    error(message('MATLAB:graphfun:plot:ArgNameValueMismatch'));
end

direction = 'down';
sources = [];
sinks = [];
asgnLay = 'auto';

layoutparams = varargin;
for i = 1:2:nvarargin
    name = validatestring(varargin{i}, {'Direction', 'Sources', 'Sinks', 'AssignLayers'});
    layoutparams{i} = name; %make sure to store full parameter names, not partially matched ones
    value = varargin{i+1};
    switch name
        case 'Direction'
            direction = validatestring(value, {'up', 'down', 'left', 'right'});
            layoutparams{i+1} = direction;
        case 'AssignLayers'
            asgnLay = validatestring(value, {'asap', 'alap', 'auto'});
            layoutparams{i+1} = asgnLay;
        case 'Sources'
            % sources = validateNodeID(BasicGraph, NodeNames, value);
            sources = validateNodeID(BasicGraph, NodeNames, value);
            if isempty(sources) || ~allunique(sources)
                error(message('MATLAB:graphfun:plot:InvalidSources'));
            end
        case 'Sinks'
            % sinks = validateNodeID(BasicGraph, NodeNames, value);
            sinks = validateNodeID(BasicGraph, NodeNames, value);
            if isempty(sinks) || ~allunique(sinks)
                error(message('MATLAB:graphfun:plot:InvalidSinks'));
            end
    end
end

% Compute simplified graph and edge multiplicities
[gs, edgeind] = matlab.internal.graph.simplify(BasicGraph);
edgemult = accumarray(edgeind, 1);

[nodeCoords, edgeCoords] = layeredLayout(gs, sources, sinks, asgnLay, edgemult);

ee = numedges(BasicGraph);
blockSizes = cellfun('size', edgeCoords, 1);
edgeCoords = cell2mat(edgeCoords);
edgeCoords = reshape(edgeCoords, [], 2); % needed for empty case
edgeCoordsIndex = repelem((1:ee)', blockSizes);
edgeCoordsIndex = edgeCoordsIndex(:);

switch direction
    case 'up'
        maxY = max([nodeCoords(:, 2); edgeCoords(:, 2)]);
        nodeCoords(:, 2) = maxY - nodeCoords(:, 2) + 1;
        edgeCoords(:, 2) = maxY - edgeCoords(:, 2) + 1;
    case 'left'
        nodeCoords = nodeCoords(:, [2 1]);
        edgeCoords = edgeCoords(:, [2 1]);
    case 'right'
        nodeCoords = nodeCoords(:, [2 1]);
        edgeCoords = edgeCoords(:, [2 1]);
        maxX = max([nodeCoords(:, 1); edgeCoords(:, 1)]);
        nodeCoords(:, 1) = maxX - nodeCoords(:, 1) + 1;
        edgeCoords(:, 1) = maxX - edgeCoords(:, 1) + 1;
end

LayoutParameters = layoutparams;
XData = nodeCoords(:, 1).';
YData = nodeCoords(:, 2).';
ZData = zeros(size(XData));
EdgeCoords = [edgeCoords zeros(size(edgeCoords, 1), 1)];
EdgeCoordsIndex = edgeCoordsIndex;
end % END layoutlayered

function [XData, YData, ZData, EdgeCoords, EdgeCoordsIndex, LayoutParameters] = ...
    layoutsubspace(BasicGraph, varargin)
nn = numnodes(BasicGraph);
layoutparams = {};
if nargin <= 1
    dim = min(100,nn); % default
else
    nvarargin = length(varargin);
    if rem(nvarargin,2) ~= 0
        error(message('MATLAB:graphfun:plot:ArgNameValueMismatch'));
    end
    layoutparams = varargin;
    for i = 1:2:nvarargin
        name = validatestring(varargin{i}, {'Dimension'});
        layoutparams{i} = name; %make sure to store full parameter names, not partially matched ones
        validateattributes(varargin{i+1},{'numeric'}, ...
            {'scalar','nonnan','real','integer','>=',min(2,nn),'<=',nn});
        dim = varargin{i+1};
    end
end

G = BasicGraph;
if isa(G, 'matlab.internal.graph.MLDigraph')
    G = constructUndirectedGraph(G);
end
[XData, YData] = subspaceLayout(G,dim,2);

Layout = 'subspace';
LayoutParameters = layoutparams;
ZData = zeros(size(XData));
[EdgeCoords, EdgeCoordsIndex] = matlab.internal.graph.updateEdgeCoords(BasicGraph, Layout, XData, YData, ZData);
end % END layoutsubspace

function [XData, YData, ZData, EdgeCoords, EdgeCoordsIndex, LayoutParameters] = ...
    layoutsubspace3(BasicGraph, varargin)
nn = numnodes(BasicGraph);
layoutparams = {};
if nargin <= 1
    dim = min(100,nn); % default
else
    nvarargin = length(varargin);
    if rem(nvarargin,2) ~= 0
        error(message('MATLAB:graphfun:plot:ArgNameValueMismatch'));
    end
    layoutparams = varargin;
    for i = 1:2:nvarargin
        name = validatestring(varargin{i}, {'Dimension'});
        layoutparams{i} = name; %make sure to store full parameter names, not partially matched ones
        validateattributes(varargin{i+1},{'numeric'}, ...
            {'scalar','nonnan','real','integer','>=',min(3,nn),'<=',nn});
        dim = varargin{i+1};
    end
end

G = BasicGraph;
if isa(G, 'matlab.internal.graph.MLDigraph')
    G = constructUndirectedGraph(G);
end
[XData, YData, ZData] = subspaceLayout(G,dim,3);

Layout = 'subspace3';
LayoutParameters = layoutparams;
[EdgeCoords, EdgeCoordsIndex] = matlab.internal.graph.updateEdgeCoords(BasicGraph, Layout, XData, YData, ZData);
end % END layoutsubspace3

function src = validateNodeID(G, NodeNames, s)
% This is based on the code in digraph/validateNodeID and digraph/findnode
nrNodes = numnodes(G);
if matlab.internal.datatypes.isCharStrings(s, false, false) || isstring(s)
    s = cellstr(s);
    if isempty(NodeNames)
        error(message('MATLAB:graphfun:findnode:NoNames'));
    end
    [~,src] = ismember(s(:), NodeNames);
elseif isnumeric(s)
    s = s(:);
    if ~isreal(s) || ~allfinite(s) || any(fix(s)~=s) || any(s<1)
        error(message('MATLAB:graphfun:findnode:PosInt'));
    end
    src = s;
    src(src>nrNodes) = 0;
else
    error(message('MATLAB:graphfun:findnode:ArgType'));
end

if any(src==0) % at this point s is either cellstr or numeric
    if isnumeric(s)
        error(message('MATLAB:graphfun:graph:InvalidNodeID', nrNodes));
    else % iscellstr(s)
        i = find(src==0,1);
        s = s{i};
        error(message('MATLAB:graphfun:graph:UnknownNodeName', s));
    end
end
end % END validateNodeID

function BasicGraph = constructUndirectedGraph(BasicGraph)
% Symmetrize directed graph into an undirected graph. Also removes parallel
% edges, which is fine because they are treated as simple edges by
% subspaceLayout.
A = adjacency(BasicGraph);
if ~issymmetric(A)
    A = A + A';
end
BasicGraph = matlab.internal.graph.MLGraph(A);
end % END constructUndirectedGraph
