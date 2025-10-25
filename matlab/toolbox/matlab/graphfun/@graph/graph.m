classdef (Sealed, SupportExtensionMethods=true, InferiorClasses = ...
        {?matlab.graphics.axis.Axes, ?matlab.ui.control.UIAxes}) graph ...
        < matlab.mixin.CustomDisplay & matlab.mixin.internal.Scalar & ...
        matlab.mixin.internal.indexing.RedefinesDotProperties
    %GRAPH Undirected Graph
    %   G = GRAPH builds an empty graph with no nodes and no edges.
    %
    %   G = GRAPH(A) uses the square symmetric matrix A as an adjacency matrix
    %   and constructs a weighted graph with edges corresponding to the nonzero
    %   entries of A. The weights of the edges are taken to be the nonzero
    %   values in A. If A is logical then no weights are added.
    %
    %   G = GRAPH(A,NAMES) additionally uses NAMES as the names of
    %   the nodes in G. NAMES must be a string vector or a cell array of
    %   character vectors, and must have as many elements as size(A,1).
    %
    %   G = GRAPH(A,...,TYPE) uses only a triangle of A to construct the graph.
    %   TYPE can be:
    %           'upper'  -  Use the upper triangle of A.
    %           'lower'  -  Use the lower triangle of A.
    %
    %   G = GRAPH(A,...,'omitselfloops') ignores the diagonal entries of the
    %   adjacency matrix A and does not add self-loops to the graph.
    %
    %   G = GRAPH(S,T) constructs a graph with edges specified by the node
    %   pairs (S,T). S and T must both be numeric, string vectors, or cell
    %   arrays of character vectors. S and T must have the same number of elements or be
    %   scalars.
    %
    %   G = GRAPH(S,T,WEIGHTS) also specifies edge weights with the numeric
    %   array WEIGHTS. WEIGHTS must have the same number of elements as S and
    %   T, or can be a scalar.
    %
    %   G = GRAPH(S,T,WEIGHTS,NAMES) additionally uses NAMES as the names of
    %   the nodes in G. NAMES must be a string vector or a cell array of character
    %   vectors. All nodes in S and T must also be present in NAMES.
    %
    %   G = GRAPH(S,T,WEIGHTS,NUM) specifies the number of nodes of the graph
    %   with the numeric scalar NUM. NUM must be greater than or equal to the
    %   largest elements in S and T.
    %
    %   G = GRAPH(S,T,...,'omitselfloops') does not add self-loops to the
    %   graph. That is, any edge k such that S(k) == T(k) is not added.
    %
    %   G = GRAPH(EdgeTable) uses the table EdgeTable to define the graph. The
    %   first variable in EdgeTable must be EndNodes, and it must be a
    %   two-column array defining the edge list of the graph. EdgeTable can
    %   contain any number of other variables to define attributes of the graph
    %   edges.
    %
    %   G = GRAPH(EdgeTable,NodeTable) additionally uses the table NodeTable to
    %   define attributes of the graph nodes. NodeTable can contain any number
    %   of variables to define attributes of the graph nodes. The number of
    %   nodes in the resulting graph is the number of rows in NodeTable.
    %
    %   G = GRAPH(EdgeTable,...,'omitselfloops') does not add self-loops to the
    %   graph.
    %
    %   Example:
    %       % Construct an undirected graph from an adjacency matrix.
    %       % View the edge list of the graph, and then plot the graph.
    %       A = [0 10 20 30; 10 0 2 0; 20 2 0 1; 30 0 1 0]
    %       G = graph(A)
    %       G.Edges
    %       plot(G)
    %
    %   Example:
    %       % Construct a graph using a list of the end nodes of each edge.
    %       % Also specify the weight of each edge and the name of each node.
    %       % View the Edges and Nodes tables of the graph, and then plot
    %       % G with the edge weights labeled.
    %       s = [1 1 1 2 2 3 3 4 5 5 6 7];
    %       t = [2 4 8 3 7 4 6 5 6 8 7 8];
    %       weights = [10 10 1 10 1 10 1 1 12 12 12 12];
    %       names = {'A' 'B' 'C' 'D' 'E' 'F' 'G' 'H'};
    %       G = graph(s,t,weights,names)
    %       G.Edges
    %       G.Nodes
    %       plot(G,'EdgeLabel',G.Edges.Weight)
    %
    %   Example:
    %       % Construct the same graph as in the previous example using two
    %       % tables to specify edge and node properties.
    %       s = [1 1 1 2 2 3 3 4 5 5 6 7]';
    %       t = [2 4 8 3 7 4 6 5 6 8 7 8]';
    %       weights = [10 10 1 10 1 10 1 1 12 12 12 12]';
    %       names = {'A' 'B' 'C' 'D' 'E' 'F' 'G' 'H'}';
    %       EdgeTable = table([s t],weights,'VariableNames',{'EndNodes' 'Weight'})
    %       NodeTable = table(names,'VariableNames',{'Name'})
    %       G = graph(EdgeTable,NodeTable)
    %
    %   graph properties:
    %      Edges            - Table containing edge information.
    %      Nodes            - Table containing node information.
    %
    %   graph methods:
    %      numnodes         - Number of nodes in a graph.
    %      numedges         - Number of edges in a graph.
    %      findnode         - Determine node ID given a name.
    %      findedge         - Determine edge index given node IDs.
    %      edgecount        - Determine number of edges between two nodes.
    %
    %      addnode          - Add nodes to a graph.
    %      rmnode           - Remove nodes from a graph.
    %      addedge          - Add edges to a graph.
    %      rmedge           - Remove edges from a graph.
    %
    %      ismultigraph     - Determine whether a graph has multiple edges.
    %      simplify         - Reduce multigraph to simple graph.
    %
    %      degree           - Degree of nodes in a graph.
    %      neighbors        - Neighbors of a node in a graph.
    %      outedges         - Edges connected to a node in a graph.
    %      reordernodes     - Reorder nodes in a graph.
    %      subgraph         - Extract an induced subgraph.
    %
    %      adjacency        - Adjacency matrix of a graph.
    %      incidence        - Incidence matrix of a graph.
    %      laplacian        - Graph Laplacian.
    %
    %      shortestpath     - Compute shortest path between two nodes.
    %      shortestpathtree - Compute single source shortest paths.
    %      distances        - Compute all pairs distances.
    %      nearest          - Compute nearest neighbors of a node.
    %
    %      bfsearch         - Breadth-first search.
    %      dfsearch         - Depth-first search.
    %      maxflow          - Compute maximum flows in a graph.
    %      conncomp         - Compute connected components of a graph.
    %      biconncomp       - Compute biconnected components of a graph.
    %      bctree           - Block-cut tree of a graph.
    %      minspantree      - Compute minimum spanning tree of a graph.
    %      centrality       - Node centrality for graph G.
    %      isisomorphic     - Determine whether two graphs are isomorphic.
    %      isomorphism      - Compute an isomorphism between G and G2.
    %      allpaths         - Compute all paths between two nodes.
    %      allcycles        - Compute all cycles in graph.
    %      cyclebasis       - Compute fundamental cycle basis of graph.
    %      hascycles        - Determine whether a graph has cycles.
    %
    %      plot             - Plot an undirected graph.
    %
    %   See also DIGRAPH
    
    %   Copyright 2014-2024 The MathWorks, Inc.
    
    properties (Dependent)
        %EDGES - Table containing graph edges.
        %   Edges is a table with numedges(G) rows containing variables
        %   describing attributes of edges. To add attributes to
        %   the edges of a graph, add a column to G.Edges.
        %
        %   See also GRAPH
        Edges
        %NODES - Table containing attributes for each node
        %   Nodes is a table with numnodes(G) rows containing variables
        %   describing attributes of nodes. To add attributes to
        %   the nodes of a graph, add a column to G.Nodes.
        %
        %   See also GRAPH
        Nodes
    end
    properties (Access = private)
        %UNDERLYING - Underlying graph representation
        %   Underlying is an instance of matlab.internal.graph.MLGraph
        %   holding all graph connectivity information.
        %
        %   See also GRAPH, ADDEDGE, FINDEDGE
        Underlying
        %EDGEPROPERTIES - Internal representation of Edges(:, 2:end)
        %   EdgeProperties may be
        %    - a table with numedges(G) rows containing variables describing
        %      attributes of edges.
        %    - a vector with numedges(G) numbers representing Weights, of
        %      type single or double.
        %    - [] if there are no edge properties.
        %
        %   See also GRAPH
        EdgeProperties
        %NODEPROPERTIES - Internal representation of Nodes
        %   NodeProperties may be
        %   - a table with numnodes(G) rows containing variables describing
        %     attributes of nodes.
        %    - a cellstr with numnodes(G) elements describing the node
        %      names.
        %    - [] if there are no node properties.
        %
        %   See also GRAPH
        NodeProperties
    end
    methods
        function G = graph(v1, v2, varargin)
            if nargin == 0
                G.Underlying = matlab.internal.graph.MLGraph;
                G.EdgeProperties = [];
                G.NodeProperties = [];
                return;
            end
            if isa(v1, 'matlab.internal.graph.MLGraph')
                G.Underlying = v1;
                if nargin >= 2
                    ep = v2;
                    if isa(ep, 'table')
                        if size(ep, 1) ~= numedges(G.Underlying)
                            error(message('MATLAB:graphfun:graph:InvalidSizeWeight'));
                        end
                        G.EdgeProperties = graph.minimizeEdgeProperties(ep);
                    elseif isequal(ep, [])
                        G.EdgeProperties = [];
                    else
                        if numel(ep) ~= numedges(G.Underlying)
                            error(message('MATLAB:graphfun:graph:InvalidSizeWeight'));
                        end
                        G.EdgeProperties = ep(:);
                    end
                else
                    G.EdgeProperties = [];
                end
                if nargin >= 3
                    np = varargin{1};
                    if iscell(np)
                        np = np(:);
                    end
                    if ~isequal(np, [])
                        np = graph.validateNodeProperties(np);
                        if size(np, 1) ~= numnodes(G)
                            error(message('MATLAB:graphfun:graph:InvalidNodeNames'));
                        end
                        np = graph.minimizeNodeProperties(np);
                    end
                    G.NodeProperties = np;
                else
                    G.NodeProperties = [];
                end
                return;
            end
            if (isnumeric(v1) || islogical(v1)) ...
                    && ((nargin == 1) || ~isnumeric(v2))
                % Adjacency matrix Constructor.
                A = v1;
                % Validation on A.
                if size(A,1) ~= size(A,2)
                    error(message('MATLAB:graphfun:graph:SquareAdjacency'));
                end
                if ~isfloat(A) && ~islogical(A)
                    error(message('MATLAB:graphfun:graph:InvalidAdjacencyType'));
                end
                if nargin > 4
                    error(message('MATLAB:maxrhs'));
                end
                % Set up defaults for flags.
                checksym = 0;
                omitLoops = false;
                nodePropsSet = false;
                % Second arg can be Cell Str of node names, Nodes table(?)
                % or one of trailing flags.
                if nargin > 1
                    nnames = v2;
                    if iscellstr(nnames) || (isstring(nnames) && ...
                            (~isscalar(nnames) || ...
                            (size(A,1) == 1 && ~any(strcmpi(nnames, {'omitselfloops', 'upper', 'lower'})))))
                        % Always assume node names.
                        if numel(nnames) ~= size(A,1)
                            error(message('MATLAB:graphfun:graph:InvalidNodeNames'));
                        end
                        G.NodeProperties = graph.validateNodeProperties(nnames(:));
                        nodePropsSet = true;
                    elseif istable(nnames)
                        if size(nnames,1) ~= size(A,1)
                            error(message('MATLAB:graphfun:graph:InvalidNumNodeTableRows'));
                        end
                        G.NodeProperties = graph.validateNodeProperties(nnames);
                        nodePropsSet = true;
                    else
                        % Look for 'upper', 'lower', 'omitselfloops'.
                        [checksym, omitLoops] = validateFlag(nnames, checksym, omitLoops);
                    end
                end
                if nargin > 2
                    [checksym, omitLoops] = validateFlag(varargin{1}, checksym, omitLoops);
                end
                if nargin > 3
                    [checksym, omitLoops] = validateFlag(varargin{2}, checksym, omitLoops);
                end
                useWeights = ~islogical(A);
                if checksym == 1
                    A = triu(A) + triu(A,1).';
                elseif checksym == -1
                    A = tril(A) + tril(A,-1).';
                else
                    if isnumeric(A) && ~issymmetric(A)
                        error(message('MATLAB:graphfun:graph:SymmetricAdjacency'));
                    end
                end
                if omitLoops
                    n = size(A,1);
                    if n < 2e24
                        A(1:n+1:end) = 0;
                    else
                        A = spdiags(0, 0, A);
                    end
                end
                G.Underlying = matlab.internal.graph.MLGraph(A);
                if useWeights
                    G.EdgeProperties = nonzeros(tril(A));
                else
                    G.EdgeProperties = [];
                end
                if ~nodePropsSet
                    G.NodeProperties = [];
                else
                    G.NodeProperties = graph.minimizeNodeProperties(G.NodeProperties);
                end
                return;
            end
            isDirected = false;
            if istable(v1)
                % Table based Constructor.
                if nargin == 1
                    [mlg, edgeprop, nodeprop] = ...
                        matlab.internal.graph.constructFromTable(isDirected, v1);
                else
                    [mlg, edgeprop, nodeprop] = ...
                        matlab.internal.graph.constructFromTable(isDirected, v1, v2, varargin{:});
                end
            else
                % Finally, assume Edge List Constructor.
                if nargin == 1
                    error(message('MATLAB:graphfun:graph:EdgesNeedTwoInputs'));
                end
                [mlg, edgeprop, nodeprop] = ...
                    matlab.internal.graph.constructFromEdgeList(...
                    isDirected, v1, v2, varargin{:});
            end
            edgeprop = graph.validateEdgeProperties(edgeprop);
            G.Underlying = mlg;
            G.NodeProperties = graph.minimizeNodeProperties(nodeprop);
            G.EdgeProperties = graph.minimizeEdgeProperties(edgeprop);
        end
        function E = get.Edges(G)
            % This is not called from outside G.Edges (which goes through
            % dotReference), but is used when calling G.Edges inside graph
            % methods and when calling struct on a graph.
            E = getEdgesTable(G);
        end
        % Setting Edges is handled through dotAssign
        function N = get.Nodes(G)
            % This is not called from outside G.Nodes (which goes through
            % dotReference), but is used when calling G.Nodes inside graph
            % methods and when calling struct on a graph.
            N = getNodePropertiesTable(G);
        end
        % Setting Nodes is handled through dotAssign
        function G = set.EdgeProperties(G, T)
            G.EdgeProperties = graph.validateEdgeProperties(T);
        end
    end
    methods (Access = protected) % Display helper
        function propgrp = getPropertyGroups(obj)
            % Construct cheatEdges, a table with the same size as
            % Edges, to save on having to construct Edges table:
            edgesColumns = repmat({zeros(numedges(obj), 0)}, 1, size(obj.EdgeProperties, 2)+1);
            cheatEdges = table(edgesColumns{:});
            nrVar = size(obj.NodeProperties, 2);
            if nrVar == 0
                cheatNodes = table.empty(numnodes(obj), 0);
            else
                nodesColumns = repmat({zeros(numnodes(obj), 0)}, 1, size(obj.NodeProperties, 2));
                cheatNodes = table(nodesColumns{:});
            end
            propList = struct('Edges',cheatEdges, 'Nodes',cheatNodes);
            propgrp = matlab.mixin.util.PropertyGroup(propList);
        end
    end
    methods (Static, Hidden) % helpers
        function T = validateNodeProperties(T)
            % This is run in the constructor, so only addresses inputs from
            % the user side (node table or cellstr, not []).
            if istable(T)
                if size(T, 2) > 0 && matlab.internal.graph.hasvar(T, "Name")
                    name = T.Name;
                    if ischar(name) && isrow(name)
                        name = {name};
                    end
                    if ~iscolumn(name)
                        error(message('MATLAB:graphfun:graph:NodesTableNameShape'));
                    end
                    T.Name = graph.validateName(name);
                end
            else
                % Store only the names in a cellstr
                T = graph.validateName(T);
            end
        end
        function Name = validateName(Name)
            if ~matlab.internal.graph.isValidNameType(Name)
                error(message('MATLAB:graphfun:graph:InvalidNameType'));
            elseif ~matlab.internal.graph.isValidName(Name)
                error(message('MATLAB:graphfun:graph:InvalidNames'));
            end
            if ~allunique(Name)
                error(message('MATLAB:graphfun:graph:NonUniqueNames'));
            end
            Name = cellstr(Name(:));
        end
        function s = validateEdgeProperties(s)
            % This is only called from set.EdgeProperties, so must allow in
            % all valid internal representations for EdgeProperties.
            if ~isobject(s)
                if ~isfloat(s) || ~isreal(s) || issparse(s)
                    error(message('MATLAB:graphfun:graph:InvalidWeights'));
                end
                if ~iscolumn(s) && ~(size(s, 1) == 0 && size(s, 2) == 0)
                    error(message('MATLAB:graphfun:graph:NonColumnWeights'));
                end
            else
                if ~istable(s)
                    error(message('MATLAB:graphfun:graph:InvalidEdgeProps'));
                end
                if size(s, 2) > 0
                    if matlab.internal.graph.hasvar(s, "EndNodes")
                        error(message('MATLAB:graphfun:graph:EdgePropsHasEndNodes'));
                    end
                    if matlab.internal.graph.hasvar(s, "Weight")
                        w = s.Weight;
                        if ~isnumeric(w) || ~isreal(w) || issparse(w) || ...
                                ~ismember(class(w), {'double', 'single'})
                            error(message('MATLAB:graphfun:graph:InvalidWeights'));
                        end
                        if ~iscolumn(w)
                            error(message('MATLAB:graphfun:graph:NonColumnWeights'));
                        end
                    end
                end
            end
        end
        function name = matlabCodegenRedirect(~)
             % Use the implementation in the class below when generating
            % code.
            name = 'matlab.internal.coder.graph';
        end
    end
    methods
        % Manipulate nodes.
        function nn = numnodes(G)
            %NUMNODES Number of nodes in a graph
            %   n = NUMNODES(G) returns the number of nodes in the graph.
            %
            %   Example:
            %       % Create a graph, and then determine the number of nodes.
            %       G = graph(bucky)
            %       n = numnodes(G)
            %
            %   See also GRAPH, NUMEDGES, ADDNODE, RMNODE
            nn = numnodes(G.Underlying);
        end
        ind = findnode(G, N);
        H = addnode(G, N);
        H = rmnode(G, N);
        d = degree(G, nodeids);
        n = neighbors(G, nodeid);
        [eid, n] = outedges(G, nodeid);
        % Manipulate edges.
        function ne = numedges(G)
            %NUMEDGES Number of edges in a graph
            %   n = NUMEDGES(G) returns the number of edges in the graph.
            %
            %   Example:
            %       % Create a graph, and then determine the number of edges.
            %       G = graph(bucky)
            %       n = numedges(G)
            %
            %   See also GRAPH, NUMNODES, ADDEDGE, RMEDGE
            ne = numedges(G.Underlying);
        end
        [t, h] = findedge(G, s, t);
        H = addedge(G, t, h, w);
        H = rmedge(G, t, h);
        A = adjacency(G, w);
        I = incidence(G);
        L = laplacian(G);
        % Algorithms
        D = distances(G, varargin);
        [path, d, edgepath] = shortestpath(G, s, t, varargin);
        [tree, d, isTreeEdge] = shortestpathtree(G, s, varargin);
        [H, ind] = reordernodes(G, order);
        H = subgraph(G, ind, varargin);
        [bins, binSize] = conncomp(G, varargin);
        [bins, cv] = biconncomp(G, varargin);
        [tree, ind] = bctree(G);
        [t, eidx] = bfsearch(G, s, varargin);
        [t, eidx] = dfsearch(G, s, varargin);
        [mf, FG, cs, ct] = maxflow(G, s, t);
        [t, pred] = minspantree(G, varargin);
        c = centrality(G, type, varargin);
        [nodeids, d] = nearest(G, s, d, varargin);
        [p, edgeperm] = isomorphism(G1, G2, varargin);
        isi = isisomorphic(G1, G2, varargin);
        c = edgecount(G, s, t);
        tf = ismultigraph(G);
        [gsimple, edgeind, edgecount] = simplify(G, FUN, varargin);
        [nodeCoords, edgeCoords] = layoutcoords(G, method, varargin);
    end
    methods (Access = protected)
        % dot reference and dot assignment
        G = dotAssign(G, indexOp, v)
        [varargout] = dotReference(G, indexOp)
        sz = dotListLength(g,indexOp,indexContext)
    end
    methods (Hidden)
        % isequal/isequaln
        tf = isequal(g1, g2, varargin)
        tf = isequaln(g1, g2, varargin)
        % Functions that we need to disable.
        function G = ctranspose(varargin) %#ok<*STOUT>
            throwAsCaller(bldUndefErr('ctranspose'));
        end
        function n = length(varargin)
            throwAsCaller(bldUndefErr('length'));
        end
        function G = permute(varargin)
            throwAsCaller(bldUndefErr('permute'));
        end
        function G = reshape(varargin)
            throwAsCaller(bldUndefErr('reshape'));
        end
        function G = transpose(varargin)
            throwAsCaller(bldUndefErr('transpose'));
        end
        % Functions of digraph that are not defined for graph.
        function varargout = condensation(varargin)
            error(message('MATLAB:graphfun:graph:OnlyDigraphSupported'));
        end
        function varargout = flipedge(varargin)
            error(message('MATLAB:graphfun:graph:OnlyDigraphSupported'));
        end
        function varargout = indegree(varargin)
            error(message('MATLAB:graphfun:graph:NoInDegreeUndir'));
        end
        function varargout = inedges(varargin)
            error(message('MATLAB:graphfun:graph:NoInEdgesUndir'));
        end
        function varargout = isdag(varargin)
            error(message('MATLAB:graphfun:graph:OnlyDigraphSupported'));
        end
        function varargout = outdegree(varargin)
            error(message('MATLAB:graphfun:graph:NoOutDegreeUndir'));
        end
        function varargout = predecessors(varargin)
            error(message('MATLAB:graphfun:graph:NoPredecessorsUndir'));
        end
        function varargout = successors(varargin)
            error(message('MATLAB:graphfun:graph:NoSuccessorsUndir'));
        end
        function varargout = toposort(varargin)
            error(message('MATLAB:graphfun:graph:OnlyDigraphSupported'));
        end
        function varargout = transclosure(varargin)
            error(message('MATLAB:graphfun:graph:OnlyDigraphSupported'));
        end
        function varargout = transreduction(varargin)
            error(message('MATLAB:graphfun:graph:OnlyDigraphSupported'));
        end
        % Hidden helper to construct MLGraph from graph
        function mlg = MLGraph(g)
            mlg = g.Underlying;
        end
    end
    methods (Access = private)
        function [names, hasNodeNames] = getNodeNames(G)
            np = G.NodeProperties;
            names = {};
            hasNodeNames = false;
            if iscell(np)
                names = np;
                hasNodeNames = true;
            elseif size(np, 2) > 0 && matlab.internal.graph.hasvar(np, "Name")
                names = np.Name;
                hasNodeNames = true;
            end
        end
        function tf = hasNodeProperties(G)
            tf = ~isequal(G.NodeProperties, []);
        end
        function nodeProps = getNodePropertiesTable(G)
            nodeProps = G.NodeProperties;
            if iscell(nodeProps)
                nodeProps = struct2table(struct('Name', {nodeProps}));
            elseif isnumeric(nodeProps)
                nodeProps = table.empty(numnodes(G.Underlying), 0);
            end
        end
        function [w, hasEdgeWeights] = getEdgeWeights(G)
            edgeProps = G.EdgeProperties;
            w = [];
            hasEdgeWeights = false;
            if isfloat(edgeProps)
                if iscolumn(edgeProps)
                    w = edgeProps;
                    hasEdgeWeights = true;
                end
            elseif size(edgeProps, 2) > 0 && matlab.internal.graph.hasvar(edgeProps, "Weight")
                w = edgeProps.Weight;
                hasEdgeWeights = true;
            end
        end
        function tf = hasEdgeProperties(G)
            tf = ~isequal(G.EdgeProperties, []);
        end
        function edgeProps = getEdgePropertiesTable(G)
            edgeProps = G.EdgeProperties;
            if isfloat(edgeProps)
                if iscolumn(edgeProps)
                    edgeProps = struct2table(struct('Weight', edgeProps));
                else
                    edgeProps = table.empty(numedges(G.Underlying), 0);
                end
            end
        end
        function E = getEdgesTable(G)
            EndNodes = G.Underlying.Edges;
            [names, hasNodeNames] = getNodeNames(G);
            if hasNodeNames
                EndNodes = {reshape(names(EndNodes), [], 2)};
            end
            edgeprop = G.EdgeProperties;
            if isnumeric(edgeprop) && iscolumn(edgeprop)
                E = struct2table(struct('EndNodes', EndNodes, 'Weight', edgeprop));
            else
                E = struct2table(struct('EndNodes', EndNodes));
                if ~isnumeric(edgeprop)
                    E = [E edgeprop];
                end
            end
        end
        function src = validateNodeID(G, s, allowCategorical)
            if isnumeric(s)
                s = s(:);
                if ~isreal(s) || any(fix(s) ~= s) || any(s < 1) || any(s > numnodes(G))
                    error(message('MATLAB:graphfun:graph:InvalidNodeID', numnodes(G)));
                end
                src = double(s);
            else
                isCategorical = nargin > 2 && allowCategorical && iscategorical(s);
                if ~isCategorical
                    src = findnode(G, s);
                else
                    [names, hasNodeNames] = getNodeNames(G);
                    if ~hasNodeNames
                        error(message('MATLAB:graphfun:findnode:NoNames'));
                    end
                    [~,src] = ismember(s(:), names);
                end
                if any(src == 0)
                    if ischar(s)
                        s = {s};
                    end
                    badNodes = s(src == 0);
                    if ~isCategorical && ~matlab.internal.graph.isValidName(badNodes)
                        error(message('MATLAB:graphfun:graph:InvalidNames'));
                    elseif isCategorical && any(ismissing(badNodes))
                        error(message('MATLAB:graphfun:graph:InvalidCategorical'));
                    else
                        error(message('MATLAB:graphfun:graph:UnknownNodeName', char(badNodes(1))));
                    end
                end
            end
        end
        [nodeProperties, nrNewNodes] = addToNodeProperties(G, N, checkN);
        t = search(G, s, varargin);
    end
    methods (Static, Access = private)
        function tf = isvalidoption(name)
            % Check for options and Name-Value pairs used in graph methods
            tf = (ischar(name) && isrow(name)) || (isstring(name) && isscalar(name));
        end
        function ind = partialMatch(name, candidates)
            len = max(strlength(name), 1);
            ind = strncmpi(name, candidates, len);
        end
        function nodeprop = minimizeNodeProperties(nodeprop)
            % If possible, replace NodeProperties table with a minimized
            % verison
            if ~isa(nodeprop, 'table')
                % Already minimized, nothing to do here.
                return;
            end
            nrVar = size(nodeprop, 2);
            if nrVar == 0
                tmin = [];
                nodePropsComp = table.empty(size(nodeprop));
            elseif nrVar == 1 && matlab.internal.graph.hasvar(nodeprop, "Name")
                tmin = nodeprop.Name;
                nodePropsComp = struct2table(struct('Name', tmin));
            else
                % Cannot be minimized
                return;
            end
            
            if isequal(nodeprop, nodePropsComp)
                % If not equal, nodeprop additionally contains properties
                % or row names, cannot be minimized.
                nodeprop = tmin;
            end
        end
        function edgeprop = minimizeEdgeProperties(edgeprop)
            % If possible, replace edgeProperties table with a minimized
            % verison
            if ~isa(edgeprop, 'table')
                % Already minimized, nothing to do here.
                return;
            end
            nrVar = size(edgeprop, 2);
            if nrVar == 0
                tmin = [];
                edgePropsComp = table.empty(size(edgeprop));
            elseif nrVar == 1 && matlab.internal.graph.hasvar(edgeprop, "Weight")
                tmin = edgeprop.Weight;
                edgePropsComp = struct2table(struct('Weight', tmin));
            else
                % Cannot be minimized
                return;
            end
            
            if isequal(edgeprop, edgePropsComp)
                % If not equal, edgeprop additionally contains properties
                % or row names, cannot be minimized.
                edgeprop = tmin;
            end
        end
    end
    %%%%% PERSISTENCE BLOCK ensures correct save/load across releases  %%%%%
    %%%%% These properties are only used in methods saveobj/loadobj, for %%%
    %%%%% correct loading behavior of MATLAB through several releases.  %%%%
    properties(Access='private')
        % ** DO NOT EDIT THIS LIST OR USE THESE PROPERTIES INSIDE GRAPH **
        
        % On saving to a .mat file, this struct is used to save
        % additional fields for forward and backward compatibility.
        % Fields that are used:
        % - WarnIfLoadingPreR2018a: Setting this property to a class not
        % known prior to 18a will cause old MATLAB versions to give a
        % warning.
        % - SaveMultigraph: Save properties Underlying, EdgeProperties and
        % NodeProperties for graphs with multiple edges.
        % - versionSavedFrom: Version of graph class from which this
        % instance is saved.
        % - minCompatibleVersion: Oldest version into which this graph
        % object can successfully be loaded.
        CompatibilityHelper = struct;
        
    end
    properties(Constant, Access='private')
        % Version of the graph serialization and deserialization
        % format. This is used for managing forward compatibility. Value is
        % saved in 'versionSavedFrom' when an instance is serialized.
        %
        %   N/A : original shipping version (R2015b)
        %   2.0 : Allow multiple edges between the same two nodes (R2018a)
        version = 2.0;
    end
    methods (Hidden)
        function s = saveobj(g)
            
            % Check if graph has multiple identical edges
            if ismultigraph(g)
                % When loading in MATLAB R2018a or later: load a graph with multiple edges.
                % When loading in MATLAB up to R2017b: warn and load an empty graph
                
                % Extract properties into a struct
                MultigraphStruct = struct('Underlying', g.Underlying, ...
                    'EdgeProperties', getEdgePropertiesTable(g), ...
                    'NodeProperties', getNodePropertiesTable(g));
                
                % Save the default graph
                s = graph;
                s.NodeProperties = table.empty;
                s.EdgeProperties = table.empty;
                
                % Warn in releases prior to 2018a
                s.CompatibilityHelper.WarnIfLoadingPreR2018a = matlab.internal.graph.Graph_with_multiple_edges_not_supported_prior_to_release_2018a;
                
                % Save multigraph in struct, to be extracted in loadobj for
                % R2018a and later:
                s.CompatibilityHelper.SaveMultigraph = MultigraphStruct;
            else
                g.EdgeProperties = getEdgePropertiesTable(g);
                g.NodeProperties = getNodePropertiesTable(g);
                s = g;
            end
            s.CompatibilityHelper.versionSavedFrom = graph.version;
            s.CompatibilityHelper.minCompatibleVersion = 2.0;
        end

        function t = keyMatch(~,~)
            %KEYMATCH True if two keys are the same.
            % Not supported for graph
            error(message("MATLAB:graphfun:graph:InvalidTypeKeyMatch"));
        end

        function h = keyHash(~)
            %KEYHASH Generates a hash code
            % Not supported for graph
            error(message("MATLAB:graphfun:graph:InvalidTypeKeyHash"));
        end
    end
    methods(Hidden, Static)
        function g = loadobj(s)
            
            if ~isfield(s.CompatibilityHelper, 'versionSavedFrom')
                % Loading a graph from R2015b-R2017b, no versioning
                ug = s.Underlying;
                nodeprop = s.NodeProperties;
                edgeprop = s.EdgeProperties;
            else
                % Check if s comes from a future, incompatible version
                if graph.version < s.CompatibilityHelper.minCompatibleVersion
                    warning(message('MATLAB:graphfun:graph:IncompatibleVersion'));
                    g = graph;
                    return;
                end
                
                if isfield(s.CompatibilityHelper, 'SaveMultigraph')
                    mg = s.CompatibilityHelper.SaveMultigraph;
                    ug = mg.Underlying;
                    nodeprop = mg.NodeProperties;
                    edgeprop = mg.EdgeProperties;
                else
                    ug = s.Underlying;
                    nodeprop = s.NodeProperties;
                    edgeprop = s.EdgeProperties;
                end
            end
            
            % Minimize representation of nodeprop and edgeprop if possible
            nodeprop = graph.minimizeNodeProperties(nodeprop);
            edgeprop = graph.minimizeEdgeProperties(edgeprop);
            
            if numnodes(ug) == 0 && (size(nodeprop, 1) ~= 0 || size(edgeprop, 1) ~= 0)
                % Case of corrupted Underlying, reload the default object.
                nodeprop = [];
                edgeprop = [];
            end

            g = graph(ug, edgeprop, nodeprop);
        end
    end
end

function me = bldUndefErr(fname)
m = message('MATLAB:UndefinedFunctionTextInputArgumentsType', fname, 'graph');
me = MException('MATLAB:UndefinedFunction', getString(m));
end

function [checksym, omitLoops] = validateFlag(fl, checksym, omitLoops)
if ~graph.isvalidoption(fl)
    error(message('MATLAB:graphfun:graph:InvalidFlagAdjacency'));
end
opt = graph.partialMatch(fl, ["upper" "lower" "omitselfloops"]);
if ~any(opt)
    error(message('MATLAB:graphfun:graph:InvalidFlagAdjacency'));
end
if opt(3)
    if omitLoops
        error(message('MATLAB:graphfun:graph:DuplicateOmitSelfLoops'));
    end
    omitLoops = true;
else
    if checksym ~= 0
        error(message('MATLAB:graphfun:graph:DuplicateUpperLower'));
    end
    if opt(1)
        checksym = 1;
    else
        checksym = -1;
    end
end
end
