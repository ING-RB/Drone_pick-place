classdef (AllowedSubclasses = {?matlab.internal.coder.graph, ...
        ?matlab.internal.coder.digraph}) graphBase
    %GRAPHBASE base class for codegen graph and digraph

    %   Copyright 2021-2024 The MathWorks, Inc.
    %#codegen

    properties (Dependent)
        Edges
        Nodes
    end

    properties (Hidden, Access = protected, Abstract)
        errTag
    end

    properties (Access = protected)
        Underlying
        EdgeProperties
        NodeProperties
    end
    methods
        function E = get.Edges(G)
            EndNodes = G.Underlying.Edges;
            E = G.EdgeProperties.makeTable({EndNodes},'EndNodes');
        end

        function N = get.Nodes(G)
            N = G.NodeProperties.makeTable();
        end

        function G = set.Edges(G, T)
            % Checking size first is necessary for codegen but might cause
            % different errors to be thrown
            coder.internal.assert(size(T.EndNodes,2) == 2, 'MATLAB:table:RowDimensionMismatch');

            % Check for changes to EndNodes
            coder.internal.assert(size(T,1) == size(G.Edges,1), ['MATLAB:graphfun:' G.errTag ':SetEdges']);
            tf = true;
            for ii = coder.internal.indexInt(1):numel(G.Edges.EndNodes)
                tf = tf && G.Edges.EndNodes(ii) == T.EndNodes(ii);
            end
            coder.internal.assert(tf, ['MATLAB:graphfun:' G.errTag ':SetEdges']);

            if size(T,2) > 1
                G.EdgeProperties = G.EdgeProperties.setProperties(T(:,2:end));
            end % else do nothing since there are no properties to set
        end

        function G = set.Nodes(G,T)
            coder.internal.assert(size(T, 1)  == numnodes(G), ['MATLAB:graphfun:' G.errTag ':SetNodes']);
            G.NodeProperties = G.NodeProperties.setProperties(T);
        end

        function nn = numnodes(G)
            %NUMNODES Number of nodes in a graph
            %   n = NUMNODES(G) returns the number of nodes in the graph.
            %
            %   Example:
            %       % Create a graph, and then determine the number of
            %       nodes.edit
            %       G = graph(bucky)
            %       n = numnodes(G)
            %
            %   See also GRAPH, NUMEDGES, ADDNODE, RMNODE
            nn = numnodes(G.Underlying);
        end
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

        function tf = ismultigraph(G)
            tf = ismultigraph(G.Underlying);
        end
    end

    methods
        % Manipulate nodes
        ind = findnode(G, N);
        H = addnode(G, N);
        H = rmnode(G, N);
        % Manipulate edges
        A = adjacency(G, w);
        [t, h] = findedge(G, s, t);
        H = addedge(G, t, h, w);
        H = rmedge(G, t, h);

        % Algorithms
        H = subgraph(G, ind);
        C = edgecount(G,s,t);
        [path, d, edgepath] = shortestpath(G, s, t, varargin);
        [nodeids, d] = nearest(G, s, d, varargin);
    end


    methods(Hidden)
        % isequal/isequaln
        tf = isequal(g1, g2, varargin)
        tf = isequaln(g1, g2, varargin)

        % Methods not supported by codegen
        % Manipulate edges
        function varargout = incidence(varargin)
            coder.internal.assert(false,'MATLAB:graphfun:codegen:MethodNotSupported');
        end
        % Plots
        function varargout = plot(varargin)
            coder.internal.assert(false,'MATLAB:graphfun:codegen:MethodNotSupported');
        end
        function varargout = layoutcoords(varargin)
            coder.internal.assert(false,'MATLAB:graphfun:codegen:MethodNotSupported');
        end
        % Algorithms
        function varargout = allcycles(varargin)
            coder.internal.assert(false,'MATLAB:graphfun:codegen:MethodNotSupported');
        end

        function varargout = allpaths(varargin)
            coder.internal.assert(false,'MATLAB:graphfun:codegen:MethodNotSupported');
        end

        function varargout = hascycles(varargin)
            coder.internal.assert(false,'MATLAB:graphfun:codegen:MethodNotSupported');
        end

        function varargout = shortestpathtree(varargin)
            coder.internal.assert(false,'MATLAB:graphfun:codegen:MethodNotSupported');
        end

        function varargout = distances(varargin)
            coder.internal.assert(false,'MATLAB:graphfun:codegen:MethodNotSupported');
        end

        function varargout = bfsearch(varargin)
            coder.internal.assert(false,'MATLAB:graphfun:codegen:MethodNotSupported');
        end

        function varargout = dfsearch(varargin)
            coder.internal.assert(false,'MATLAB:graphfun:codegen:MethodNotSupported');
        end

        function varargout = maxflow(varargin)
            coder.internal.assert(false,'MATLAB:graphfun:codegen:MethodNotSupported');
        end

        function varargout = centrality(varargin)
            coder.internal.assert(false,'MATLAB:graphfun:codegen:MethodNotSupported');
        end

        function varargout = isomorphism(varargin)
            coder.internal.assert(false,'MATLAB:graphfun:codegen:MethodNotSupported');
        end

        function varargout = isisomorphic(varargin)
            coder.internal.assert(false,'MATLAB:graphfun:codegen:MethodNotSupported');
        end

        function varargout = simplify(varargin)
            coder.internal.assert(false,'MATLAB:graphfun:codegen:MethodNotSupported');
        end

        function varargout = reordernodes(varargin)
            coder.internal.assert(false,'MATLAB:graphfun:codegen:MethodNotSupported');
        end
    end

    methods (Hidden)
        % Functions that we need to disable.
        function G = ctranspose(G, varargin) %#ok<*STOUT>
            coder.internal.assert(false,bldUndefErr(G,'ctranspose'));
        end
        function n = length(G, varargin)
            coder.internal.assert(false,bldUndefErr(G,'length'));
        end
        function G = permute(G, varargin)
            coder.internal.assert(false,bldUndefErr(G,'permute'));
        end
        function G = reshape(G, varargin)
            coder.internal.assert(false,bldUndefErr(G,'reshape'));
        end
        function G = transpose(G, varargin)
            coder.internal.assert(false,bldUndefErr(G,'transpose'));
        end
    end

    methods (Access = protected)
        % Internal-only helpers

        function [names, hasNodeNames] = getNodeNames(G) %#ok<MANU>
            % Node names are not supported in codegen
            names = {};
            hasNodeNames = false;
        end

        function tf = hasNodeProperties(G)
            coder.inline('always');
            tf = G.NodeProperties.hasProperties();
        end

        function [w, hasEdgeWeights] = getEdgeWeights(G)
            coder.inline('always');
            [w,hasEdgeWeights] = G.EdgeProperties.getByName('Weight');
        end

        function tf = hasEdgeProperties(G)
            coder.inline('always');
            tf = G.EdgeProperties.hasProperties();
        end

        function edgeProps = getEdgePropertiesTable(G)
            coder.inline('always');
            edgeProps = G.EdgeProperties.makeTable();
        end

        function me = bldUndefErr(G,fname)
            me = sprintf('Undefined function ''%s'' for input arguments of type ''%s''.',fname,G.errTag);
        end

        [nodeProperties, newnodes] = addToNodeProperties(G, N);

        src = validateNodeID(G, s);

        [dist, pred, edgepred] = dijkstraShortestPathImpl(G, weight, start, subsetAllNodes, inTargetSubset, maxNrNodes, nearestRadius);
    end

    methods (Static, Access = protected)
        function tf = isvalidoption(name)
            % Check for options and Name-Value pairs used in graph methods
            tf = (ischar(name) && isrow(name)) || (isstring(name) && isscalar(name));
        end

        function ind = partialMatch(name, candidates)
            len = max(strlength(name), 1);
            ind = strncmpi(name, candidates, len);
        end
    end

    methods (Access = protected, Abstract)
        out = underlyingConstructor(G, varargin);
        out = underlyingConstructorTransp(G, varargin);
        out = adjacencyTransp(G, varargin);
        out = edgeIndFromAdjacency(G, N);
    end

    methods (Static, Hidden)
        function methodNames = matlabCodegenUnsupportedMethods(~)
            sharedMethods = {'allcycles','allpaths','hascycles','incidence', ...
                'plot','layoutcoords','shortestpathtree',...
                'distances','bfsearch','dfsearch','maxflow','centrality', ...
                'isomorphism','isisomorphic','simplify','reordernodes'};
            digraphMethods = {'condensation','flipedge','isdag','toposort', ...
                'transreduction', 'transclosure'};
            graphMethods = {'biconncomp','cyclebasis','laplacian', ...
                'bctree','minspantree'};
            methodNames = [sharedMethods,digraphMethods,graphMethods];
        end
    end
end