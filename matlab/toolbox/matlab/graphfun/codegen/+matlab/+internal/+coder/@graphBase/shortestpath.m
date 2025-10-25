function [path, d, edgepath] = shortestpath(G, s, t, varargin)
% SHORTESTPATH Compute shortest path between two nodes

% Limitations:
% * Name value pairs must be constant
% * Only the 'positive', 'unweighted' and 'auto' methods are supported
% * When there is no path between the specified nodes, path and edgepath will have
%   size 1x0 (the in-memory version returns 0x0 matrices for this case)

%   Copyright 2021-2022 The MathWorks, Inc.
%#codegen

coder.internal.prefer_const(varargin);
coder.internal.assert(coder.internal.get_eml_option('NonFinitesSupport'),'MATLAB:graphfun:shortestpath:NonFiniteSupportRequired');

src = validateNodeID(G, s);
coder.internal.assert(numel(src) == 1, 'MATLAB:graphfun:shortestpath:NonScalarSource');
src = src(1); % Guarantee that Coder sees src as a scalar, even if it's specified as varsize

targ = validateNodeID(G, t);
coder.internal.assert(numel(targ) == 1, 'MATLAB:graphfun:shortestpath:NonScalarTarg');
targ = targ(1); % Guarantee that Coder sees targ as a scalar, even if it's specified as varsize

% Process Name-Value pair options
METHOD_ = parseFlags(G.errTag, varargin{:});

hasEdgeWeights = G.EdgeProperties.checkVariables('Weight');

weightCheckForNonNegatives = false;
if strncmpi(METHOD_,'auto',4)
    if ~hasEdgeWeights
        METHOD = 'unweighted';
    elseif strcmp(G.errTag,'graph')
        METHOD = 'positive';
    else
        if isNonNegative(G.EdgeProperties.getByName('Weight'))
            METHOD = 'positive';
        else
            METHOD = 'mixed';
        end
        weightCheckForNonNegatives = true;
    end
else
    METHOD = METHOD_;
end

% Only the 'positive' and 'unweighted' methods are currently supported
coder.internal.assert(strcmp(METHOD, 'positive') || ...
    strcmp(METHOD, 'unweighted'), ...
    'MATLAB:graphfun:shortestpath:CodegenMethodUnsupported',METHOD);

if hasEdgeWeights && strcmp(METHOD, 'positive')
    weight = G.EdgeProperties.getByName('Weight');
    if ~weightCheckForNonNegatives
        coder.internal.assert(isNonNegative(weight), ...
            'MATLAB:graphfun:shortestpath:DijkstraNonNegative')
    end
else
    weight = ones(numedges(G), 1);
end

inTargetSubset = false(1,numnodes(G));
inTargetSubset(targ) = true;
if nargin < 3
    [dist, pred] = matlab.internal.coder.dijkstraShortestPathImpl(G.Underlying, weight, src, false, inTargetSubset, 1, inf);
else
    [dist, pred, edgepred] = matlab.internal.coder.dijkstraShortestPathImpl(G.Underlying, weight, src, false, inTargetSubset, 1, inf);
end

d = dist(targ);

path = constructPath(pred, targ);

if nargout > 2
    edgepath = constructEdgePath(pred, edgepred, targ);
end


end

%--------------------------------------------------------------------------

function p = constructPath(pred, t)
ONE = coder.internal.indexInt(1);
pBuffer = coder.nullcopy(zeros(1,numel(pred)));
pBufferStart = coder.internal.indexInt(numel(pred)) + ONE;
% pBuffer is filled from right to left (from pBuffer(end) to pBuffer(1)) to
% avoid flipping it later on
tnext = pred(t);
if ~isnan(tnext)
    while tnext ~= 0
        pBufferStart = pBufferStart - ONE;
        pBuffer(pBufferStart) = t;
        t = tnext;
        tnext = pred(t);
    end
    pBufferStart = pBufferStart - ONE;
    pBuffer(pBufferStart) = t;
    p = pBuffer(pBufferStart:end);
else
    p = zeros(1,0);
end
end

%--------------------------------------------------------------------------

function ep = constructEdgePath(pred, edgepred, t)
ep = zeros(1,numel(pred)); %#ok<PREALL> Force ep to be varsize with the upper bound numel(pred)
ep = zeros(1,0);
tnext = pred(t);
if ~isnan(tnext)
    while tnext ~= 0
        ep = [ep, edgepred(t)]; %#ok<AGROW>
        t = tnext;
        tnext = pred(t);
    end
    ep = reshape(ep, 1, []); % For path of length 1, ep = zeros(1, 0), not [].
    ep = flip(ep);
end
end

%--------------------------------------------------------------------------

function METHOD = parseFlags(errTag, varargin)
coder.internal.prefer_const(errTag, varargin);
if nargin == 1
    METHOD = 'auto';
    return
end

if strcmp(errTag, 'digraph')
    parseMethodErrorID = 'MATLAB:graphfun:shortestpath:ParseMethodDir';
    methodNames = {'positive', 'unweighted', 'auto', 'mixed', 'acyclic'};
else
    parseMethodErrorID = 'MATLAB:graphfun:shortestpath:ParseMethodUndir';
    methodNames = {'positive', 'unweighted', 'auto'};
end

coder.unroll();
for ii = coder.internal.indexInt(1):2:numel(varargin)
    name = varargin{ii};
    coder.internal.assert( ...
        matlab.internal.coder.graphBase.isvalidoption(name), ...
        'MATLAB:graphfun:shortestpath:ParseFlags');
    coder.internal.assert( ...
        matlab.internal.coder.graphBase.partialMatch(name,'Method'), ...
        'MATLAB:graphfun:shortestpath:ParseFlags');
    coder.internal.assert(ii + 1 <= numel(varargin), ...
        'MATLAB:graphfun:shortestpath:KeyWithoutValue');
    value = varargin{ii + 1};
    coder.internal.assert( ...
        matlab.internal.coder.graphBase.isvalidoption(value), parseMethodErrorID);
    match = matlab.internal.coder.graphBase.partialMatch(value, methodNames);
    coder.internal.assert(nnz(match) == 1, parseMethodErrorID);
    if ii + 1 == numel(varargin)
        METHOD = methodNames{match};
    end
end
coder.assumeDefined(METHOD);
end

%--------------------------------------------------------------------------

function tf = isNonNegative(weight)
tf = true;
for ii = coder.internal.indexInt(1):numel(weight)
    if ~(weight(ii) >= 0)
        tf = false;
        return
    end
end
end
