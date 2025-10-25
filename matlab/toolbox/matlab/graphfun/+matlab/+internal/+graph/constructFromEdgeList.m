function [G, EdgeProps, NodeProps] = ...
    constructFromEdgeList(isDirected, s, t, varargin)
% CONSTRUCTFROMEDGELIST Construct graph/digraph from edge list representation.

% Copyright 2015-2024 The MathWorks, Inc.

if isDirected
    errTag = 'digraph';
else
    errTag = 'graph';
end

if numel(varargin) > 3
    error(message('MATLAB:maxrhs'));
end

% Check for ambiguous case: graph(s, t, w, "omit"), where (s,t) define a
% graph with <= 1 nodes. Is "omit" an option or a node name?
% Treatment of this case:
% - 'omit' is an option, {'omit'} is a node name (as previous).
% - "omit" is a node name, but "omitselfloops" (complete length) is an option.
if numel(varargin) == 2 && isstring(varargin{2}) && isscalar(varargin{2})
    in = varargin{2};
    if strncmpi(in, 'omitselfloops', max(1, strlength(in)))
        oneNodeGraph = false;
        if isempty(s) || isempty(t)
            oneNodeGraph = true;
        elseif isnumeric(s) && isnumeric(t)
            oneNodeGraph = ((max(s) == 1) && (max(t) == 1));
        elseif (ischar(s) || iscellstr(s) || isstring(t)) && (ischar(t) || iscellstr(t) || isstring(t))
            oneNodeGraph = all(string(s) == in) && all(string(t) == in);
        end
        if oneNodeGraph
            if strcmpi(in, 'omitselfloops')
                % Match complete length: treat as an option
                varargin{2} = char(in);
            else
                % Treat as a node
                varargin{2} = cellstr(in);
            end
        else
            % Treat as option
            varargin{2} = char(in);
        end
    else
        if ~matlab.internal.graph.isValidName(in)
            error(message(['MATLAB:graphfun:' errTag ':InvalidNames']));
        end
        varargin{2} = cellstr(in);
    end
end

% Peel off the last arg, and check it for omitselfloops.
omitLoops = false;
if numel(varargin) > 0
    flag = varargin{end};
    if (ischar(flag) && isrow(flag)) || (isstring(flag) && isscalar(flag))
        omitLoops = startsWith("omitselfloops", flag, 'IgnoreCase', true) && strlength(flag) > 0;
        if ~omitLoops
            error(message(['MATLAB:graphfun:' errTag ':InvalidFlag']));
        end
        varargin(end) = [];
    elseif numel(varargin) == 3
        error(message(['MATLAB:graphfun:' errTag ':InvalidFlag']));
    end
end
% Discover and set NodeProps.
NodeProps = [];
% NodeStuff is the input, if present.  It may be
%  * A collection of Node Names.
%  * A numeric scalar indicating the number of nodes.
%  * A table containing node properties.
NodeStuff = {};
totalNodes = [];
userSetNumNodes = false;
explicitNodeNames = false;
if numel(varargin) > 1
    NodeStuff = varargin{2};
    if iscellstr(NodeStuff) || isstring(NodeStuff)
        if ~matlab.internal.graph.isValidName(NodeStuff)
            error(message(['MATLAB:graphfun:' errTag ':InvalidNames']));
        end
        NodeStuff = cellstr(NodeStuff(:));
        if ~allunique(NodeStuff)
            error(message(['MATLAB:graphfun:' errTag ':NonUniqueNames']));
        end
        totalNodes = numel(NodeStuff);
        explicitNodeNames = true;
        NodeProps = NodeStuff;
    elseif isnumeric(NodeStuff) && isscalar(NodeStuff)
        totalNodes = NodeStuff;
        if ~isreal(totalNodes) || ~isfinite(totalNodes) ...
                || fix(totalNodes) ~= totalNodes
            error(message(['MATLAB:graphfun:' errTag ':InvalidNumNodesProps']));
        end
        userSetNumNodes = true;
        NodeStuff = [];
    elseif istable(NodeStuff)
        totalNodes = size(NodeStuff,1);
        % Validate Nodes Table.
        if matlab.internal.graph.hasvar(NodeStuff, "Name")
            name = NodeStuff.Name;
            if ~matlab.internal.graph.isValidNameType(name)
                error(message(['MATLAB:graphfun:' errTag ':InvalidNameType']));
            elseif ~matlab.internal.graph.isValidName(name)
                error(message(['MATLAB:graphfun:' errTag ':InvalidNames']));
            end
            if ~iscolumn(name)
                error(message(['MATLAB:graphfun:' errTag ':NodesTableNameShape']));
            end
            if ~allunique(name)
                error(message(['MATLAB:graphfun:' errTag ':NonUniqueNames']));
            end
            NodeStuff.Name = cellstr(name);
            explicitNodeNames = true;
        end
        NodeProps = NodeStuff;
    else
        error(message(['MATLAB:graphfun:' errTag ':EdgeListFourthArg']));
    end
end
if matlab.internal.graph.isValidNameType(s) && matlab.internal.graph.isValidNameType(t)
    if userSetNumNodes
        error(message(['MATLAB:graphfun:' errTag ':EdgeListNumNodes']));
    end
    if ~matlab.internal.graph.isValidName(s) || ~matlab.internal.graph.isValidName(t)
        error(message(['MATLAB:graphfun:' errTag ':InvalidNames']));
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
    if explicitNodeNames
        if iscell(NodeProps)
            Name = NodeProps;
        else
            Name = NodeProps.Name;
        end
        [present, s] = ismember(s(:), Name);
        if ~all(present)
            error(message(['MATLAB:graphfun:' errTag ':InvalidNodeRefd']));
        end
        [present, t] = ismember(t(:), Name);
        if ~all(present)
            error(message(['MATLAB:graphfun:' errTag ':InvalidNodeRefd']));
        end
    else
        if istable(NodeStuff)
            error(message(['MATLAB:graphfun:' errTag ':NodesTableNeedsName']));
        end
        if numel(t) == 1 && numel(s) >= 1
            Name = [t; s(:)]; Name(1:2) = Name([2 1]);
        elseif numel(s) == numel(t)
            Name = [s(:).'; t(:).'];
        else
            Name = [s(:); t(:)];
        end
        Name = unique(Name(:), 'stable');
        [~, s] = ismember(s(:), Name);
        [~, t] = ismember(t(:), Name);
        NodeProps = Name;
        totalNodes = numel(Name);
    end
elseif isnumeric(s) && isnumeric(t)
    s = double(s);
    t = double(t);
elseif iscategorical(s) && iscategorical(t)
    if userSetNumNodes
        error(message(['MATLAB:graphfun:' errTag ':EdgeListNumNodes']));
    end
    if any(ismissing(s), 'all') || any(ismissing(t), 'all')
        error(message(['MATLAB:graphfun:' errTag ':InvalidCategorical']));
    end
    if ~explicitNodeNames
        if xor(isordinal(s), isordinal(t))
            error(message(['MATLAB:graphfun:' errTag ':CategoricalMixedOrdinal']));
        elseif isordinal(s) && ~isequal(categories(s), categories(t))
            error(message(['MATLAB:graphfun:' errTag ':CategoricalOrdinalMismatch']));
        end
        Name = categories([s([]), t([])]);
        Name = Name(:);
        NodeProps = Name;
        totalNodes = numel(Name);
    else
        if iscell(NodeStuff)
            Name = NodeStuff;
        else
            Name = NodeStuff.Name;
        end
    end
    
    [present, s] = ismember(s(:), Name);
    if ~all(present)
        error(message(['MATLAB:graphfun:' errTag ':InvalidNodeRefd']));
    end
    [present, t] = ismember(t(:), Name);
    if ~all(present)
        error(message(['MATLAB:graphfun:' errTag ':InvalidNodeRefd']));
    end
else
    error(message(['MATLAB:graphfun:' errTag ':InvalidEdges']));
end
implicitTotal = max([max(s(:)); max(t(:))]);
if isempty(totalNodes)
    totalNodes = implicitTotal;
elseif totalNodes < implicitTotal
    if explicitNodeNames
        error(message(['MATLAB:graphfun:' errTag ':InvalidNumNodeNames'], implicitTotal));
    elseif istable(NodeStuff)
        error(message(['MATLAB:graphfun:' errTag ':InvalidNumNodesTable'], implicitTotal));
    else
        error(message(['MATLAB:graphfun:' errTag ':InvalidNumNodes'], implicitTotal));
    end
end
% Need the following for when we cope with weights below...
specifiedEdges = max(numel(s), numel(t));
if omitLoops
    omittedRows = (s == t);
    if isscalar(s) && ~isscalar(t)
        t(omittedRows) = [];
    elseif isscalar(t) && ~isscalar(s)
        s(omittedRows) = [];
    else
        s(omittedRows) = [];
        t(omittedRows) = [];
    end
end

if numel(varargin) == 0
    if ~isDirected
        G = matlab.internal.graph.MLGraph(s, t, totalNodes);
    else
        G = matlab.internal.graph.MLDigraph(s, t, totalNodes);
    end
else
    if ~isDirected
        [G, ind] = matlab.internal.graph.MLGraph.edgesConstrWithIndex(s, t, totalNodes);
    else
        [G, ind] = matlab.internal.graph.MLDigraph.edgesConstrWithIndex(s, t, totalNodes);
    end
end

% Set Edge properties.
EdgeProps = [];
if numel(varargin) > 0
    w = varargin{1};
    ignoreWeights = false;
    if ~isfloat(w)
        if ~istable(w)
            error(message(['MATLAB:graphfun:' errTag ':InvalidWeights']));
        end
    else
        % We do not support subclasses of single or double for w.
        if ~isequal(class(w), 'double') && ~isequal(class(w), 'single')
            error(message(['MATLAB:graphfun:' errTag ':InvalidWeights']));
        end
        % Look for [] meaning ignore weights.
        ignoreWeights = isequal(w,[]);
        w = w(:);
    end
    if ~ignoreWeights
        if (size(w,1) ~= specifiedEdges) && ~(isscalar(w) && isnumeric(w))
            error(message(['MATLAB:graphfun:' errTag ':InvalidSizeWeight']));
        end
        if omitLoops && ~isscalar(w)
            w(omittedRows,:) = [];
        end
        if isscalar(w)
            w = repmat(w, length(ind), 1);
        else
            w = w(ind, :);
        end
        EdgeProps = w;
    end
end
end
