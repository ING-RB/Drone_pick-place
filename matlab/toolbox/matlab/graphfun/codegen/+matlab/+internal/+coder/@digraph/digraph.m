classdef (Sealed) digraph < matlab.internal.coder.graphBase
    %DIGRAPH Directed Graph

    %   Copyright 2021-2022 The MathWorks, Inc.
    %#codegen

    properties (Hidden, Access = protected) % TODO: Constant g2415408
        errTag = 'digraph';
    end

    methods
        function G = digraph(varargin)
            if nargin == 0
                G.Underlying = matlab.internal.coder.MLDigraph;
                G.EdgeProperties = matlab.internal.coder.graphPropertyContainer('edge','digraph',[],0);
                G.NodeProperties = matlab.internal.coder.graphPropertyContainer('node','digraph',[],0);
                return;
            end

            if (isnumeric(varargin{1}) || islogical(varargin{1})) ...
                    && ((nargin == 1) || ~isnumeric(varargin{2}))
                % Adjacency matrix Constructor.
                A = varargin{1};
                % Validation on A.
                coder.internal.assert(size(A,1) == size(A,2), 'MATLAB:graphfun:digraph:SquareAdjacency');
                coder.internal.assert(isfloat(A) || islogical(A), 'MATLAB:graphfun:digraph:InvalidAdjacencyType');
                coder.internal.assert(nargin <= 4, 'MATLAB:maxrhs');
                % Set up defaults for flags.
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
                        coder.internal.assert(size(nnames,1) == size(A,1),'MATLAB:graphfun:digraph:InvalidNodeNames');
                        G.NodeProperties = matlab.internal.coder.graphPropertyContainer('node','digraph',nnames,[]);
                        nodePropsSet = true;
                    else
                        % Look for 'omitselfloops'.
                        omitLoops = validateFlag(nnames, omitLoops);
                    end
                end
                if nargin > 2
                    omitLoops = validateFlag(varargin{3}, omitLoops);
                end
                useWeights = ~islogical(A);
                if omitLoops
                    n = size(A,1);
                    A(1:n+1:end) = 0;
                end
                G.Underlying = matlab.internal.coder.MLDigraph(A);
                if useWeights
                    G.EdgeProperties = matlab.internal.coder.graphPropertyContainer('edge','digraph',nonzeros(A.'),[]);
                else
                    G.EdgeProperties =  matlab.internal.coder.graphPropertyContainer('edge','digraph',[],G.Underlying.numedges());
                end
                if ~nodePropsSet
                    G.NodeProperties =  matlab.internal.coder.graphPropertyContainer('node','digraph',[],G.Underlying.numnodes());
                end
                return;
            end
            if istable(varargin{1})
                % Table based Constructor.
                [G.Underlying, G.EdgeProperties, G.NodeProperties] = ...
                    matlab.internal.coder.constructFromTable(...
                    @matlab.internal.coder.MLDigraph, 'digraph', ...
                    varargin{:});
                return;
            end
            % Finally, assume Edge List Constructor.
            coder.internal.assert(nargin ~= 1, 'MATLAB:graphfun:digraph:EdgesNeedTwoInputs');
            [G.Underlying, G.EdgeProperties, G.NodeProperties] = ...
                matlab.internal.coder.constructFromEdgeList( ...
                @matlab.internal.coder.MLDigraph, 'digraph', ...
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
        d = indegree(G, nodeids);
        d = outdegree(G, nodeids);

        % Algorithms
        [bins, binSize] = conncomp(G, varargin);
        preid = predecessors(G, nodeid);
        sucid = successors(G, nodeid);

    end

    methods (Hidden)
        % Functions of graph that are not defined for digraph.
        function varargout = bctree(varargin) %#ok<STOUT>
            coder.internal.assert(false,'MATLAB:graphfun:digraph:OnlyGraphSupported');
        end
        function varargout = biconncomp(varargin) %#ok<STOUT>
            coder.internal.assert(false,'MATLAB:graphfun:digraph:OnlyGraphSupported');
        end
        function varargout = degree(varargin) %#ok<STOUT>
            coder.internal.assert(false,'MATLAB:graphfun:digraph:NoDegreeDir');
        end
        function varargout = laplacian(varargin) %#ok<STOUT>
            coder.internal.assert(false,'MATLAB:graphfun:digraph:OnlyGraphSupported');
        end
        function varargout = minspantree(varargin) %#ok<STOUT>
            coder.internal.assert(false,'MATLAB:graphfun:digraph:OnlyGraphSupported');
        end
        function varargout = neighbors(varargin) %#ok<STOUT>
            coder.internal.assert(false,'MATLAB:graphfun:digraph:NoNeighborsDir');
        end
        % Hidden helper to construct MLDigraph from digraph
        function mlg = MLDigraph(g)
            mlg = g.Underlying;
        end
        % Methods not supported by codegen
        function C = condensation(G) %#ok<STOUT,MANU>
            coder.internal.assert(false,'MATLAB:graphfun:codegen:MethodNotSupported');
        end
        function H = flipedge(G, s, t) %#ok<STOUT,INUSD>
            coder.internal.assert(false,'MATLAB:graphfun:codegen:MethodNotSupported');
        end
        function [isd, order] = isdag(g, varargin) %#ok<STOUT,INUSD>
            coder.internal.assert(false,'MATLAB:graphfun:codegen:MethodNotSupported');
        end
        function [H, order] = toposort(g, varargin) %#ok<STOUT,INUSD>
            coder.internal.assert(false,'MATLAB:graphfun:codegen:MethodNotSupported');
        end
        function H = transreduction(G) %#ok<STOUT,MANU>
            coder.internal.assert(false,'MATLAB:graphfun:codegen:MethodNotSupported');
        end
        function H = transclosure(G) %#ok<STOUT,MANU>
            coder.internal.assert(false,'MATLAB:graphfun:codegen:MethodNotSupported');
        end
    end

    methods (Access = protected)
        function out = underlyingConstructor(~,varargin)
            out = matlab.internal.coder.MLDigraph(varargin{:});
        end

        function out = underlyingConstructorTransp(~,varargin)
            out = matlab.internal.coder.MLDigraph(varargin{:},'transp');
        end

        function out = adjacencyTransp(G,varargin)
            out = G.Underlying.adjacency(varargin{:},'transp');
        end
        
        function out = edgeIndFromAdjacency(~,N)
            out = nonzeros(N);
        end
    end

    methods(Hidden, Static)
        function  b = matlabCodegenToRedirected(a)
            b = matlab.internal.coder.digraph(a.Edges,a.Nodes);
        end

        function name = matlabCodegenUserReadableName
            % Make this look like a graph (not the redirected graph) in the codegen report
            name = 'digraph';
        end

        function b = matlabCodegenFromRedirected(a)
            b = digraph(a.Edges,a.Nodes);
        end

        function result = matlabCodegenNontunableProperties(~)
            result = {'errTag'};
        end
    end
end

function omitLoops = validateFlag(fl, omitLoops)
coder.internal.assert(matlab.internal.coder.digraph.isvalidoption(fl), 'MATLAB:graphfun:digraph:InvalidFlag');
opt = matlab.internal.coder.digraph.partialMatch(fl, "omitselfloops");
coder.internal.assert(opt,'MATLAB:graphfun:digraph:InvalidFlag');
coder.internal.assert(~omitLoops,'MATLAB:graphfun:digraph:DuplicateOmitSelfLoops');
omitLoops = true;
end
