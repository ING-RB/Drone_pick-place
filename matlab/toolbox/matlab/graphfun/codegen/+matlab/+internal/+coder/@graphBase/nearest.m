function [nodeids, dOut] = nearest(G, s, d, varargin)
% NEAREST Compute nearest neighbors of a node

% Limitations:
% * Name value pairs must be constant
% * Only the 'positive', 'unweighted' and 'auto' methods are supported

%   Copyright 2022 The MathWorks, Inc.
%#codegen

coder.internal.prefer_const(varargin)
coder.internal.assert(coder.internal.get_eml_option('NonFinitesSupport'),'MATLAB:graphfun:nearest:NonFiniteSupportRequired');

% Parse inputs
narginchk(3,Inf)
src = validateNodeID(G, s);
coder.internal.assert(isscalar(src),'MATLAB:graphfun:nearest:NonScalarSource');
if strcmp(G.errTag,'digraph')
    ErrorIDEnding = 'Dir';
else
    ErrorIDEnding = 'Undir';
end

coder.internal.assert(isnumeric(d) && isreal(d) && isscalar(d) && ~isnan(d), ...
    ['MATLAB:graphfun:nearest:InvalidDistance' ErrorIDEnding]);

[METHOD_, DIRECTION] = parseInput(G.errTag, varargin{:});

hasEdgeWeights = G.EdgeProperties.checkVariables('Weight');

weightCheckForNonNegatives = false;
if strcmp(METHOD_,'auto')
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
    'MATLAB:graphfun:nearest:CodegenMethodUnsupported',METHOD);

if hasEdgeWeights && strcmp(METHOD, 'positive')
    weight_ = G.EdgeProperties.getByName('Weight');
    if ~weightCheckForNonNegatives
        if strcmp(G.errTag,'graph')
            coder.internal.assert(isNonNegative(weight_), ...
                'MATLAB:graphfun:nearest:NegativeWeights')
        else
            coder.internal.assert(isNonNegative(weight_), ...
                'MATLAB:graphfun:nearest:DijkstraNonNegative')
        end
    end
else
    weight_ = ones(numedges(G), 1);
end

% Flip edge weights if necessary
if strcmp(DIRECTION,'incoming')
    [GUnderlying,eind] = G.Underlying.flipedge();
    weight = weight_(eind);
else
    GUnderlying = G.Underlying;
    weight = weight_;
end

% apply the method
[nodeids_, d_] = applyOneToAll(GUnderlying, weight, src, d, METHOD);

nodeids = nodeids_(:);
dOut = d_(:);
end

%--------------------------------------------------------------------------


function [nodeids, d] = applyOneToAll(G, w, src, dist, METHOD)
coder.internal.prefer_const(METHOD);

n = coder.internal.indexInt(numnodes(G));
[d_, pred] = matlab.internal.coder.dijkstraShortestPathImpl(G, w, src, true, true(1,n), n, dist);
reachableNodes = coder.internal.indexInt(find(pred > 0 & d_ <= dist));
[d, ind] = sort(d_(reachableNodes));
nodeids = double(reachableNodes(ind));
end

%--------------------------------------------------------------------------

function [METHOD, DIRECTION] = parseInput(errTag, varargin)
coder.internal.prefer_const(errTag, varargin);
if nargin == 1
    METHOD = 'auto';
    DIRECTION = 'outgoing';
    return
end

if strcmp(errTag, 'digraph')
    ErrorIDEnding = 'Dir';
    methodNames = {'positive', 'unweighted', 'auto', 'mixed', 'acyclic'};
else
    ErrorIDEnding = 'Undir';
    methodNames = {'positive', 'unweighted', 'auto'};
end

% Parse name-value pairs
poptions = struct( ...
         'CaseSensitivity',false, ...
         'PartialMatching','unique', ...
         'StructExpand',false, ...
         'IgnoreNulls',false, ...
         'SupportOverrides',true);

pstruct = coder.internal.parseInputs({},{'Method','Direction'},poptions,varargin{:});

% Direction argument is not valid for graphs
coder.internal.assert(strcmp(errTag,'digraph') || pstruct.Direction == 0, ...
    'MATLAB:graphfun:nearest:ParseFlagsUndir');

METHOD_ = coder.internal.getParameterValue(pstruct.Method,'auto',varargin{:});
DIRECTION_ = coder.internal.getParameterValue(pstruct.Direction,'outgoing',varargin{:});

coder.internal.assert(matlab.internal.coder.graphBase.isvalidoption(METHOD_), ...
        ['MATLAB:graphfun:nearest:ParseMethod', ErrorIDEnding]);

coder.internal.assert(matlab.internal.coder.graphBase.isvalidoption(DIRECTION_), ...
        'MATLAB:graphfun:nearest:ParseDirection');

% Check that method is valid
methodMatch = matlab.internal.coder.graphBase.partialMatch(METHOD_, methodNames);
coder.internal.assert(nnz(methodMatch) == 1, ['MATLAB:graphfun:nearest:ParseMethod', ErrorIDEnding]);
METHOD = methodNames{methodMatch};

% Check that direction is valid
validDirections = {'incoming', 'outgoing'};
directionMatch = matlab.internal.coder.graphBase.partialMatch(DIRECTION_, validDirections);
coder.internal.assert(nnz(directionMatch) == 1, 'MATLAB:graphfun:nearest:ParseDirection');
DIRECTION = validDirections{directionMatch};
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