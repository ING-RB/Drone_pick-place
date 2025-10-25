function [G, EdgeProps, NodeProps] = ...
    constructFromEdgeList(underlyingCtor, errTag, s_in, t_in, varargin)
% CONSTRUCTFROMEDGELIST Construct graph/digraph from edge list representation.

% Copyright 2021 The MathWorks, Inc.
%#codegen

coder.internal.assert(numel(varargin)<=3,'MATLAB:maxrhs');

% Check for ambiguous case: graph(s, t, w, "omit"), where (s,t) define a
% graph with <= 1 nodes. Is "omit" an option or a node name?
% Treatment of this case:
% - 'omit' is an option, {'omit'} is a node name (as previous).
% - "omit" is a node name, but "omitselfloops" (complete length) is an option.

if numel(varargin) == 2 && isstring(varargin{2}) && isscalar(varargin{2})
    in = varargin{2};
    if strncmpi(in, 'omitselfloops', max(1, strlength(in)))
        oneNodeGraph = false;
        if isempty(s_in) || isempty(t_in)
            oneNodeGraph = true;
        elseif isnumeric(s_in) && isnumeric(t_in)
            oneNodeGraph = ((max(s_in) == 1) && (max(t_in) == 1));
        elseif (ischar(s_in) || iscellstr(s_in) || isstring(t_in)) && (ischar(t_in) || iscellstr(t_in) || isstring(t_in))
            oneNodeGraph = all(string(s_in) == in) && all(string(t_in) == in);
        end
        if oneNodeGraph
            coder.internal.assert(strcmpi(in, 'omitselfloops'),'MATLAB:graphfun:codegen:NodeNamesNotSupported');
        end
    else
        coder.internal.assert(matlab.internal.coder.isValidNameType(in), ...
            ['MATLAB:graphfun:' errTag ':InvalidNames']);
        coder.internal.assert(~matlab.internal.coder.isValidNameType(in), ...
            'MATLAB:graphfun:codegen:NodeNamesNotSupported');
    end
end

% Peel off the last arg, and check it for omitselfloops.
omitLoops = false;
if numel(varargin) > 0
    flag = varargin{end};
    if ischar(flag) || (isstring(flag) && isscalar(flag))
        coder.internal.assert(coder.internal.isConst(flag),'Coder:toolbox:OptionStringsMustBeConstant');
        omitLoops = startsWith("omitselfloops", flag, 'IgnoreCase', true) && strlength(flag) > 0;
        coder.internal.assert(omitLoops, ['MATLAB:graphfun:' errTag ':InvalidFlag']);
        if numel(varargin) > 1
            vararginPeeled = {varargin{1:end-1}};
        else
            vararginPeeled = {};
        end
    else
        coder.internal.assert(numel(varargin) ~= 3, ['MATLAB:graphfun:' errTag ':InvalidFlag']);
        vararginPeeled = varargin;
    end
else
    vararginPeeled = varargin;
end
% Discover and set NodeProps.
% NodeStuff is the input, if present.  It may be
%  * A collection of Node Names.
%  * A numeric scalar indicating the number of nodes.
%  * A table containing node properties.
userSetNumNodes = false;

if numel(vararginPeeled) > 1
    NodeStuff = vararginPeeled{2};
    coder.internal.assert(~iscellstr(NodeStuff) && ~isstring(NodeStuff), ...
        'MATLAB:graphfun:codegen:NodeNamesNotSupported');
    if isnumeric(NodeStuff)
        coder.internal.assert(isscalar(NodeStuff),['MATLAB:graphfun:' errTag ':EdgeListFourthArg']);
        totalNodes = NodeStuff(1); % NodeStuff must be a scalar to reach this point, this forces coder to recognize that
        coder.internal.assert(isreal(totalNodes) && isfinite(totalNodes) ...
                && fix(totalNodes) == totalNodes, ...
                ['MATLAB:graphfun:' errTag ':InvalidNumNodesProps']);
        userSetNumNodes = true;
        NodeProps = matlab.internal.coder.graphPropertyContainer('node',errTag,[],totalNodes);
    else
        coder.internal.assert(istable(NodeStuff),['MATLAB:graphfun:' errTag ':EdgeListFourthArg']);
        coder.internal.assert(~matches("Name", NodeStuff.Properties.VariableNames), ...
            'MATLAB:graphfun:codegen:NodeNamesNotSupported');
        NodeProps = matlab.internal.coder.graphPropertyContainer('node',errTag,NodeStuff);        
        totalNodes = size(NodeStuff,1);
    end
else
    NodeProps = matlab.internal.coder.graphPropertyContainer('node',errTag,[],0);
    NodeStuff = {};
    totalNodes = [];
end

if matlab.internal.coder.isValidNameType(s_in) && matlab.internal.coder.isValidNameType(t_in)
    coder.internal.assert(~userSetNumNodes,['MATLAB:graphfun:' errTag ':EdgeListNumNodes']);
    coder.internal.assert(matlab.internal.coder.isValidNameType(s_in) && ...
        matlab.internal.coder.isValidNameType(t_in), ...
        ['MATLAB:graphfun:' errTag ':InvalidNames']);
    coder.internal.assert(userSetNumNodes,'MATLAB:graphfun:codegen:NodeNamesNotSupported');
    % userSetNumNodes must be true (or the first assert here would have
    % failed). Functionally, this assert is really assert(false,...), but
    % that causes problems in codegen
    
elseif isnumeric(s_in) && isnumeric(t_in)
    s = double(s_in(:));
    t = double(t_in(:));
else
    s = s_in;
    t = t_in;
    coder.internal.assert(iscategorical(s) && iscategorical(t), ['MATLAB:graphfun:' errTag ':InvalidEdges']);
    coder.internal.assert(~userSetNumNodes, ['MATLAB:graphfun:' errTag ':EdgeListNumNodes']);
    coder.internal.assert(~any(ismissing(s), 'all') && ~any(ismissing(t), 'all'), ...
        ['MATLAB:graphfun:' errTag ':InvalidCategorical']);

    coder.internal.assert(~xor(isordinal(s), isordinal(t)), ...
        ['MATLAB:graphfun:' errTag ':CategoricalMixedOrdinal']);
    coder.internal.assert(~isordinal(s) || isequal(categories(s), categories(t)), ...
        ['MATLAB:graphfun:' errTag ':CategoricalOrdinalMismatch']);
    Name = categories([s([]), t([])]); % This is to establish the number of nodes only
    % Names will not be used
    Name = Name(:);        
    totalNodes = numel(Name);
    NodeProps = matlab.internal.coder.graphPropertyContainer('node',errTag,[],totalNodes);
end

if ~(isempty(s) && isempty(t))
    implicitTotal = max([s(:);t(:)]);
elseif ~isempty(s)
    implicitTotal = max(s(:));
elseif ~isempty(t)
    implicitTotal = max(t(:));
else
    implicitTotal = zeros('like',s);
end

if isempty(totalNodes)
    totalNodesNonEmpty = implicitTotal;
else
    coder.internal.assert(totalNodes >= implicitTotal || ~istable(NodeStuff), ...
        ['MATLAB:graphfun:' errTag ':InvalidNumNodesTable'], implicitTotal);
    coder.internal.assert( totalNodes >= implicitTotal, ...
        ['MATLAB:graphfun:' errTag ':InvalidNumNodes'], implicitTotal);
    totalNodesNonEmpty = totalNodes;
end
% Need the following for when we cope with weights below...
specifiedEdges = max(numel(s), numel(t));
if omitLoops
    omittedRows = (s == t);
    if isscalar(s) && ~isscalar(t)
        s_trimmed = s;
        t_trimmed = removeRows(t,omittedRows);
    elseif isscalar(t) && ~isscalar(s)
        s_trimmed = removeRows(s,omittedRows);
        t_trimmed = t;
    else
        s_trimmed = removeRows(s,omittedRows);
        t_trimmed = removeRows(t,omittedRows);
    end
else
    omittedRows = false(0,0);
    s_trimmed = s;
    t_trimmed = t;
end

coder.internal.assert(~issparse(s_trimmed) && ~issparse(t_trimmed),'MATLAB:graphfun:codegen:SparseNodePairs');

if numel(vararginPeeled) == 0
    G = underlyingCtor(s_trimmed, t_trimmed, totalNodesNonEmpty);
elseif errTag == "graph"
    [G, ind] = matlab.internal.coder.MLGraph.edgesConstrWithIndex(s_trimmed, t_trimmed, totalNodesNonEmpty);
else
    [G, ind] = matlab.internal.coder.MLDigraph.edgesConstrWithIndex(s_trimmed, t_trimmed, totalNodesNonEmpty);
end

% Set Edge properties.
if numel(vararginPeeled) > 0
    wTmp = vararginPeeled{1};
    if ~isfloat(wTmp)
        coder.internal.assert(istable(wTmp),['MATLAB:graphfun:' errTag ':InvalidWeights']);
        w = wTmp;        
        ignoreWeights = false;
    else
        % We do not support subclasses of single or double for w.
        coder.internal.assert(isequal(class(wTmp), 'double') || isequal(class(wTmp), 'single'), ...
            ['MATLAB:graphfun:' errTag ':InvalidWeights']);
        % Look for [] meaning ignore weights.
        ignoreWeights = isequal(wTmp,[]);
        if isnumeric(wTmp) && ismatrix(wTmp) && size(wTmp,1) == 0 && size(wTmp,2) == 0
            % Preserve wTmp = []
            w = wTmp;
        else
            w = wTmp(:);
        end
    end
    if coder.internal.isConstTrue(ignoreWeights)        
        EdgeProps = matlab.internal.coder.graphPropertyContainer('edge',errTag,[],G.numedges()); 
        % This can only be hit if w is numeric. Otherwise w has to be a table and ignoreWeights is always false in that case
    else
        if isnumeric(w) && ismatrix(w) && size(w,1) == 0 && size(w,2) == 0
            % Special case - varsized w is [] at runtime
            w = 1;
        end
        coder.internal.assert((size(w,1) == specifiedEdges) || (isscalar(w) && isnumeric(w)), ...
            ['MATLAB:graphfun:' errTag ':InvalidSizeWeight']);
        if omitLoops && ~isscalar(w)
            w(omittedRows,:) = [];
        end
        if isscalar(w) && ~istable(w) % scalar tables error out earlier, but codegen doesn't recognize that
            w = repmat(w, length(ind), 1);
        else
            w = w(ind, :);
        end
        EdgeProps = matlab.internal.coder.graphPropertyContainer('edge',errTag,w,[]);
    end
else
    EdgeProps = matlab.internal.coder.graphPropertyContainer('edge',errTag,[],G.numedges());
end

%TODO - make sure that I can remove the commented out bit
if isempty(NodeProps)% && ~isempty(EdgeProps)
    NodeProps = NodeProps.append([],G.numnodes());
end
end

function out = removeRows(in,omitRows)
% Codegen helper that removes rows from vectors with a fixed number of columns
% Elements in rowNum must be unique
coder.inline('always');

numRowsToOmit = sum(omitRows);

if numRowsToOmit == 0
    out = in;
    return
end

if size(in,1) > numRowsToOmit
    out = in;
    out(omitRows) = [];
else
    % All rows removed
    out = zeros(0,size(in,2),'like',in);
end
end