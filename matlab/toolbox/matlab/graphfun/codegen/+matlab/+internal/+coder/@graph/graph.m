classdef (Sealed) graph < matlab.internal.coder.graphBase
    %GRAPH Undirected Graph

    %   Copyright 2021-2022 The MathWorks, Inc.
    %#codegen

    properties (Hidden, Access = protected)
        errTag = 'graph';
    end

    methods
        function G = graph(varargin)
            if nargin == 0
                G.Underlying = matlab.internal.coder.MLGraph;
                G.EdgeProperties = matlab.internal.coder.graphPropertyContainer('edge','graph',[],0);
                G.NodeProperties = matlab.internal.coder.graphPropertyContainer('node','graph',[],0);
                return;
            end

            if (isnumeric(varargin{1}) || islogical(varargin{1})) ...
                    && ((nargin == 1) || ~isnumeric(varargin{2}))
                % Adjacency matrix Constructor.
                A = varargin{1};
                % Validation on A.
                coder.internal.assert(size(A,1) == size(A,2), 'MATLAB:graphfun:graph:SquareAdjacency');
                coder.internal.assert(isfloat(A) || islogical(A), 'MATLAB:graphfun:graph:InvalidAdjacencyType');
                coder.internal.assert(nargin <= 4, 'MATLAB:maxrhs');
                % Set up defaults for flags.
                checksym = 0;
                omitLoops = false;
                nodePropsSet = false;
                % Second arg can be Cell Str of node names, Nodes table(?)
                % or one of trailing flags.
                if nargin > 1
                    nnames = varargin{2};
                    coder.internal.assert(~(iscellstr(nnames) || (isstring(nnames) && ...
                        (~isscalar(nnames) || ...
                        (size(A,1) == 1 && ~any(strcmpi(nnames, ...
                        {'omitselfloops', 'upper', 'lower'})))))), ...
                        'MATLAB:graphfun:codegen:NodeNamesNotSupported');
                    if istable(nnames)
                        coder.internal.assert(size(nnames,1) == size(A,1),'MATLAB:graphfun:graph:InvalidNodeNames');
                        G.NodeProperties = matlab.internal.coder.graphPropertyContainer('node','graph',nnames,[]);
                        nodePropsSet = true;
                    else
                        % Look for 'upper', 'lower', 'omitselfloops'.
                        [checksym, omitLoops] = validateFlag(nnames, checksym, omitLoops);
                    end
                end
                if nargin > 2
                    [checksym, omitLoops] = validateFlag(varargin{3}, checksym, omitLoops);
                end
                if nargin > 3
                    [checksym, omitLoops] = validateFlag(varargin{4}, checksym, omitLoops);
                end
                useWeights = ~islogical(A);
                if checksym == 1
                    A = triu(A) + triu(A,1).';
                elseif checksym == -1
                    A = tril(A) + tril(A,-1).';
                elseif issparse(A)
                    ONE = coder.internal.indexInt(1);
                    isSym = true;
                    for jj = ONE:size(A,2)
                        for ii = ONE:jj
                            isSym = isSym && A(ii,jj) == A(jj,ii);
                        end
                    end
                    coder.internal.assert(isSym, 'MATLAB:graphfun:graph:SymmetricAdjacency');
                else
                    coder.internal.assert(~isnumeric(A) || issymmetric(A), 'MATLAB:graphfun:graph:SymmetricAdjacency');
                end
                if omitLoops
                    n = size(A,1);
                    A(1:n+1:end) = 0;
                end
                G.Underlying = matlab.internal.coder.MLGraph(A);
                if useWeights
                    G.EdgeProperties = matlab.internal.coder.graphPropertyContainer('edge','graph',nonzeros(tril(A)),[]);
                else
                    G.EdgeProperties =  matlab.internal.coder.graphPropertyContainer('edge','graph',[],G.Underlying.numedges());
                end
                if ~nodePropsSet
                    G.NodeProperties =  matlab.internal.coder.graphPropertyContainer('node','graph',[],G.Underlying.numnodes());
                end

                return;
            end
            if istable(varargin{1})
                % Table based Constructor.
                [G.Underlying, G.EdgeProperties, G.NodeProperties] = ...
                    matlab.internal.coder.constructFromTable(...
                    @matlab.internal.coder.MLGraph, 'graph', ...
                    varargin{:});
                return;
            end
            % Finally, assume Edge List Constructor.
            coder.internal.assert(nargin ~= 1, 'MATLAB:graphfun:graph:EdgesNeedTwoInputs');
            [G.Underlying, G.EdgeProperties, G.NodeProperties] = ...
                matlab.internal.coder.constructFromEdgeList(...
                @matlab.internal.coder.MLGraph, 'graph', ...
                varargin{:});
            % Make the property object the correct size
            EndNodes = G.Underlying.Edges;
            if isempty(G.EdgeProperties)
                G.EdgeProperties = G.EdgeProperties.append([],size(EndNodes,1));
            end
            if isempty(G.NodeProperties)
                if isempty(EndNodes)
                    numNodes = 0;
                else
                    numNodes = max(EndNodes,[],'all');
                end
                G.NodeProperties = G.NodeProperties.append([],numNodes);
            end
        end

        % Manipulate nodes.
        d = degree(G, nodeids)
        n = neighbors(G, nodeid);
        % Algorithms
        [bins, binSize] = conncomp(G, varargin);
    end

    methods (Hidden)
        % Functions of digraph that are not defined for graph.
        function varargout = condensation(varargin) %#ok<STOUT>
            coder.internal.assert(false,'MATLAB:graphfun:graph:OnlyDigraphSupported');
        end
        function varargout = flipedge(varargin) %#ok<STOUT>
            coder.internal.assert(false,'MATLAB:graphfun:graph:OnlyDigraphSupported');
        end
        function varargout = indegree(varargin) %#ok<STOUT>
            coder.internal.assert(false,'MATLAB:graphfun:graph:NoInDegreeUndir');
        end
        function varargout = inedges(varargin) %#ok<STOUT>
            coder.internal.assert(false,'MATLAB:graphfun:graph:NoInEdgesUndir');
        end
        function varargout = isdag(varargin) %#ok<STOUT>
            coder.internal.assert(false,'MATLAB:graphfun:graph:OnlyDigraphSupported');
        end
        function varargout = outdegree(varargin) %#ok<STOUT>
            coder.internal.assert(false,'MATLAB:graphfun:graph:NoOutDegreeUndir');
        end
        function varargout = predecessors(varargin) %#ok<STOUT>
            coder.internal.assert(false,'MATLAB:graphfun:graph:NoPredecessorsUndir');
        end
        function varargout = successors(varargin) %#ok<STOUT>
            coder.internal.assert(false,'MATLAB:graphfun:graph:NoSuccessorsUndir');
        end
        function varargout = toposort(varargin) %#ok<STOUT>
            coder.internal.assert(false,'MATLAB:graphfun:graph:OnlyDigraphSupported');
        end
        function varargout = transclosure(varargin) %#ok<STOUT>
            coder.internal.assert(false,'MATLAB:graphfun:graph:OnlyDigraphSupported');
        end
        function varargout = transreduction(varargin) %#ok<STOUT>
            coder.internal.assert(false,'MATLAB:graphfun:graph:OnlyDigraphSupported');
        end
        % Hidden helper to construct MLGraph from graph
        function mlg = MLGraph(g)
            mlg = g.Underlying;
        end
        % Methods not supported by codegen
        function varargout = biconncomp(varargin) %#ok<STOUT>
            coder.internal.assert(false,'MATLAB:graphfun:codegen:MethodNotSupported');
        end
        function varargout = cyclebasis(varargin) %#ok<STOUT>
            coder.internal.assert(false,'MATLAB:graphfun:codegen:MethodNotSupported');
        end
        function varargout = laplacian(varargin) %#ok<STOUT>
            coder.internal.assert(false,'MATLAB:graphfun:codegen:MethodNotSupported');
        end
        function varargout = bctree(varargin) %#ok<STOUT>
            coder.internal.assert(false,'MATLAB:graphfun:codegen:MethodNotSupported');
        end
        function varargout = minspantree(varargin) %#ok<STOUT>
            coder.internal.assert(false,'MATLAB:graphfun:codegen:MethodNotSupported');
        end
    end
    methods (Access = protected)
        function out = underlyingConstructor(~, varargin)
            out = matlab.internal.coder.MLGraph(varargin{:});
        end

        function out = underlyingConstructorTransp(~,varargin)
            out = matlab.internal.coder.MLGraph(varargin{:});
        end

        function out = adjacencyTransp(G,varargin)
            out = G.Underlying.adjacency(varargin{:});
        end
        
        function out = edgeIndFromAdjacency(~,N)
            out = nonzeros(tril(N));
        end
    end

    methods(Hidden, Static)
        function  b = matlabCodegenToRedirected(a)
            b = matlab.internal.coder.graph(a.Edges,a.Nodes);
        end

        function name = matlabCodegenUserReadableName
            % Make this look like a graph (not the redirected graph) in the codegen report
            name = 'graph';
        end

        function b = matlabCodegenFromRedirected(a)
            b = graph(a.Edges,a.Nodes);
        end

        function result = matlabCodegenNontunableProperties(~)
            result = {'errTag'};
        end
    end
end

function [checksym, omitLoops] = validateFlag(fl, checksym, omitLoops)
coder.internal.assert(matlab.internal.coder.graph.isvalidoption(fl), ...
    'MATLAB:graphfun:graph:InvalidFlagAdjacency');
opt = matlab.internal.coder.graph.partialMatch(fl, {'upper' 'lower' 'omitselfloops'});
coder.internal.assert(any(opt),'MATLAB:graphfun:graph:InvalidFlagAdjacency');
if opt(3)
    coder.internal.assert(~omitLoops,'MATLAB:graphfun:graph:DuplicateOmitSelfLoops');
    omitLoops = true;
else
    coder.internal.assert(checksym == 0, 'MATLAB:graphfun:graph:DuplicateUpperLower')
    if opt(1)
        checksym = 1;
    else
        checksym = -1;
    end
end
end