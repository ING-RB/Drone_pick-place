function H = addedge(G, s, t, weights)
%ADDEDGE Add edges to a graph
%   H = ADDEDGE(G,s,t) returns graph H that is equivalent to G but with
%   edges specified by s and t added to it. s and t must both refer to
%   node names or numeric node indices. If a node specified by s or
%   t is not present in the graph G, that node is added as well.
%
%   H = ADDEDGE(G,s,t,w), where G is a weighted graph, adds edges with
%   corresponding edge weights defined by w. w must be numeric.
%
%   H = ADDEDGE(G,EdgeTable) adds edges with attributes specified by
%   the table EdgeTable. EdgeTable must be able to be concatenated with
%   G.Edges.
%
%   H = ADDEDGE(G,s,t,EdgeTable) adds edges with attributes specified by
%   the table EdgeTable. EdgeTable must not contain a variable EndNodes,
%   and must be able to be concatenated with G.Edges(:, 2:end).
%
%   Example:
%       % Construct a graph with three edges, then add two new edges.
%       G = graph([1 2 3],[2 3 4])
%       G.Edges
%       G = addedge(G,[2 1],[4 6])
%       G.Edges
%
%   See also GRAPH, NUMEDGES, RMEDGE, ADDNODE

%   Copyright 2014-2023 The MathWorks, Inc.

weightsProvided = nargin >= 4 || istable(s);
[~, hasEdgeWeights] = getEdgeWeights(G);

if istable(s)
    if nargin > 2
        error(message('MATLAB:graphfun:addedge:TableMaxRHS'));
    end
    if size(s,2) < 1
        error(message('MATLAB:graphfun:addedge:TableSize'));
    end
    varnames = s.Properties.VariableNames;
    if "EndNodes" ~= varnames{1}
        error(message('MATLAB:graphfun:addedge:TableFirstVar'));
    end
    endNodes = s.EndNodes;
    if size(endNodes,2) ~= 2 || ~(isnumeric(endNodes) || ...
            iscellstr(endNodes) || isstring(endNodes))
        error(message('MATLAB:graphfun:addedge:BadEndNodes'));
    end
    % Extract into s, t, w.
    t = endNodes(:,2);
    weights = s(:,2:end);
    s = endNodes(:,1);
elseif nargin >= 4 && istable(weights)
    if matlab.internal.graph.hasvar(weights, "EndNodes")
        error(message('MATLAB:graphfun:addedge:DuplicateEndNodes'));
    end
elseif nargin < 4 && hasEdgeWeights
    error(message('MATLAB:graphfun:addedge:SpecifyWeight'));
end


% Basic checks of inputs s and t
inputsAreStrings = matlab.internal.graph.isValidNameType(s) && matlab.internal.graph.isValidNameType(t);
if inputsAreStrings
    if ~matlab.internal.graph.isValidName(s) || ~matlab.internal.graph.isValidName(t)
        error(message('MATLAB:graphfun:graph:InvalidNames'));
    end
    if ischar(s)
        s = {s};
    else
        s = cellstr(s);
    end
    if ischar(t)
        t = {t};
    else
        t = cellstr(t);
    end
elseif ~(isnumeric(s) && isnumeric(t)) && ~(iscategorical(s) && iscategorical(t))
    error(message('MATLAB:graphfun:addedge:InconsistentNodeNames'));
end

if numel(s) ~= numel(t) && ~isscalar(s) && ~isscalar(t)
    error(message('MATLAB:graphfun:graphbuiltin:EqualNumel'));
end

% Add any nodes that are not present.
s = s(:);
t = t(:);
H = G;
[names, hasNodeNames] = getNodeNames(G);
if inputsAreStrings
    if isscalar(t) && numel(s) >= 1
        refdNodes = [s(1); t; s(2:end)];
        fromS = true(size(refdNodes));
        fromS(2) = false;
    elseif numel(s) == numel(t)
        refdNodes = [s, t].';
        fromS = repmat([true; false], 1, size(refdNodes, 2));
    else
        refdNodes = [s; t];
        fromS = false(size(refdNodes));
        fromS(1) = true;
    end
    if hasNodeNames
        % Lookup node names and add any that we might need.
        ind = findnode(G, refdNodes(:));
        [newNodes, ~, newInd] = unique(refdNodes(ind==0), 'stable');
        ind(ind==0) = newInd + numnodes(G);
    else
        [refdNodes, ~, ind] = unique(refdNodes(:), 'stable');
        ind = ind + numnodes(G);
        newNodes = refdNodes;
    end
    s = ind(fromS);
    t = ind(~fromS);
    H.NodeProperties = addToNodeProperties(G, newNodes, false);
elseif isnumeric(s) && isnumeric(t)
    s = double(s);
    t = double(t);
    maxs = validateNodeIDs(s);
    maxt = validateNodeIDs(t);
    N = max(maxs, maxt);
    if N > numnodes(G)
        H.NodeProperties = addToNodeProperties(G, N-numnodes(G));
    end
else % iscategorical(s) && iscategorical(t)
    if xor(isordinal(s), isordinal(t))
        error(message('MATLAB:graphfun:graph:CategoricalMixedOrdinal'));
    elseif isordinal(s) && ~isequal(categories(s), categories(t))
        error(message('MATLAB:graphfun:graph:CategoricalOrdinalMismatch'));
    end
    newNodes = categories([s([]), t([])]);
    if hasNodeNames
        newNodes = setdiff(newNodes, names, 'stable');
    end
    H.NodeProperties = addToNodeProperties(G, newNodes, false);
    names = getNodeNames(H);
    [~,s] = ismember(s, names);
    [~,t] = ismember(t, names);
end

if weightsProvided || hasEdgeProperties(G)
    [H.Underlying, p] = addedge(G.Underlying, s, t);
else
    H.Underlying = addedge(G.Underlying, s, t);
end

if weightsProvided
    if isnumeric(weights)
        if ~hasEdgeWeights && numedges(G) ~= 0
            error(message('MATLAB:graphfun:addedge:NoWeights'));
        end
        if ~isscalar(weights) && numel(p) ~= numel(weights)
            error(message('MATLAB:graphfun:addedge:NumWeightsMismatch'));
        end
        EdgePropTable = expandEdgeProperties(G.EdgeProperties, p, weights(:));
    elseif istable(weights)
        EdgePropTable = getEdgePropertiesTable(G);
        if numedges(G) ~= 0
            origVarnames = EdgePropTable.Properties.VariableNames;
            weightVarnames = weights.Properties.VariableNames;
            if ~isequal(origVarnames, weightVarnames)
                error(message('MATLAB:table:VarDimensionMismatch'));
            end
        end
        EdgePropTable = expandEdgeProperties(EdgePropTable, p, weights);
    else
        error(message('MATLAB:graphfun:addedge:FourthInput'));
    end
else
    if ~hasEdgeProperties(G)
        EdgePropTable = [];
    else
        EdgePropTable = expandEdgeProperties(G.EdgeProperties, p);
    end
end

H.EdgeProperties = EdgePropTable;
if nargout < 1
    warning(message('MATLAB:graphfun:addedge:NoOutput'));
end

function m = validateNodeIDs(ids)
if ~isreal(ids) || any(fix(ids)~=ids) || any(ids < 1)
    error(message('MATLAB:graphfun:addedge:InvalidNodeID'));
end
m = max(ids(:));
if isempty(m)
    m = 0;
end


function props = expandEdgeProperties(props, p, newprops)
% props represents edge properties, and p the rows of the new edges table
% at which each new edge is placed.
% Optional input newprops represents the new properties to be written into
% the edges p - if it isn't provided, default values are inserted, matching
% what table indexing uses as default values.

nold = size(props, 1);
nnew = size(props, 1) + length(p);

if ~isnumeric(props) % props is a table

    % Add new rows at the bottom of table props
    if nargin == 2
        % Note: This may error for some classes if props has no rows, when
        % there isn't a default constructor for example.
        props = matlab.internal.datatypes.lengthenVar(props, nnew);
    else
        if ~isnumeric(newprops)
            if isrow(newprops)
                newprops = repmat(newprops, length(p), 1);
            end
            props = [props; newprops];
        else
            % Assign numeric weight values, expand other variables
            props = matlab.internal.datatypes.lengthenVar(props, nnew);
            props{nold+1:nnew,'Weight'} = newprops;
        end
    end

    % Permute rows of props so newly added rows are in the spaces indicated
    % by p. First, construct an index to do this permutation:

    ind = zeros(nnew, 1);
    ind(p) = nold+1:nnew;
    % The following for-loop corresponds to the line
    %    ind(ind==0) = 1:nold;
    % The loop avoids extra copies for performance reasons.
    next = 1;
    for ii=1:nnew
        if ind(ii) == 0
            ind(ii) = next;
            next = next + 1;
        end
    end

    props = props(ind, :);

else % numeric array
    q = true(nnew, 1);
    q(p) = false;
    propsBoth = zeros(nnew, 1, 'like', props);
    propsBoth(q, :) = props;
    propsBoth(p, :) = newprops;
    props = propsBoth;
end
