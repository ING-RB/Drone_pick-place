function H = addedge(G, sIn, tIn, weights)
%

%#codegen
%   Copyright 2021 The MathWorks, Inc.

useWeights = nargin >= 4 || istable(sIn);
[~, hasEdgeWeights] = getEdgeWeights(G);

if istable(sIn)
    coder.internal.assert(nargin <= 2, 'MATLAB:graphfun:addedge:TableMaxRHS');
    coder.internal.assert(size(sIn,2) >= 1, 'MATLAB:graphfun:addedge:TableSize');
    coder.internal.assert("EndNodes" == sIn.Properties.VariableNames{1}, ...
        'MATLAB:graphfun:addedge:TableFirstVar');
    coder.internal.assert(size(sIn.EndNodes,2) == 2 && (isnumeric(sIn.EndNodes) ...
        || iscellstr(sIn.EndNodes) || isstring(sIn.EndNodes)), 'MATLAB:graphfun:addedge:BadEndNodes');
    % Extract into s, t, w.
    t0 = sIn.EndNodes(:,2);
    weights = sIn(:,2:end);
    s0 = sIn.EndNodes(:,1);
else
    s0 = sIn;
    t0 = tIn;
    if nargin >= 4 && istable(weights)
        hasEndNodes = coder.const(feval('matches',"EndNodes", weights.Properties.VariableNames));
        coder.internal.assert(~hasEndNodes, 'MATLAB:graphfun:addedge:DuplicateEndNodes');
    else
        coder.internal.assert(nargin == 4 || ~hasEdgeWeights, 'MATLAB:graphfun:addedge:SpecifyWeight');
    end
end


% Basic checks of inputs s and t

% Specific error message for case supported in MATLAB but not in Coder
coder.internal.assert(~(matlab.internal.coder.isValidNameType(s0) && ...
    matlab.internal.coder.isValidNameType(t0)),'MATLAB:graphfun:codegen:NodeNamesNotSupported');

coder.internal.assert(~iscategorical(s0) && ...
    ~iscategorical(t0),'MATLAB:graphfun:codegen:NodeNamesNotSupported');

coder.internal.assert(isnumeric(s0) && isnumeric(t0), ...
    'MATLAB:graphfun:addedge:InconsistentNodeNames');

coder.internal.assert(numel(s0) == numel(t0) || isscalar(s0) || isscalar(t0), ...
    'MATLAB:graphfun:graphbuiltin:EqualNumel')

% Add any nodes that are not present.
s0 = s0(:);
t0 = t0(:);
H = G;
if isnumeric(s0) && isnumeric(t0)
    s = double(s0);
    t = double(t0);
    maxs = validateNodeIDs(s);
    maxt = validateNodeIDs(t);
    N = max(maxs, maxt);
    if N > numnodes(G)
        H.NodeProperties = G.addToNodeProperties(N-numnodes(G));
    end
else
    s = s0;
    t = t0;
end

if useWeights || hasEdgeProperties(G)
    [H.Underlying, p] = G.Underlying.addedge(s, t);
else
    H.Underlying = G.Underlying.addedge(s, t);
end

if useWeights
    coder.internal.assert(numel(p) == numel(weights) || istable(weights) && numel(p) == size(weights,1),'MATLAB:table:RowDimensionMismatch')
    [p,ind] = sort(p,'ascend');
    if isnumeric(weights)
        EdgePropG = G.EdgeProperties;
        EdgePropH = EdgePropG;
        if numedges(G) > 0
            coder.internal.assert(hasEdgeWeights, ...
                'MATLAB:graphfun:addedge:NoWeights');
        end
        coder.internal.assert(isscalar(weights) || ...
            numel(p) == numel(weights), ...
            'MATLAB:graphfun:addedge:NumWeightsMismatch');
        for ii = 1:numel(p)
            EdgePropH = EdgePropH.insertOneRow(p(ii),{weights(ind(ii))});
        end
    elseif istable(weights)
        EdgePropG = G.EdgeProperties;
        EdgePropH = EdgePropG;
        coder.internal.assert(EdgePropG.checkVariables( ...
            weights.Properties.VariableNames), ...
            'MATLAB:table:VarDimensionMismatch');
        for ii = 1:numel(p)
            EdgePropH = EdgePropH.insertOneRow(p(ii), ...
                table2cell(weights(ind(ii),:)));
        end
    else
        coder.internal.assert(false,'MATLAB:graphfun:addedge:FourthInput');
    end
else
    coder.internal.assert(~hasEdgeProperties(G),'MATLAB:graphfun:codegen:PropertiesMissing');
    EdgePropH = G.EdgeProperties.append([],numel(s));
end

H.EdgeProperties = EdgePropH;
if nargout < 1
    coder.internal.compileWarning('MATLAB:graphfun:rmnode:NoOutput');
end

function m = validateNodeIDs(ids)
coder.internal.assert(isreal(ids) && all(fix(ids) == ids) && all(ids >= 1), ...
    'MATLAB:graphfun:addedge:InvalidNodeID');
if isempty(ids)
    m = 0;
else
    m = max(ids(:));
end
