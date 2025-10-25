classdef MLDigraph
    %

    %   Copyright 2021-2022 The MathWorks, Inc.
    %#codegen

    properties(Access = private)
        Ir % 1-based, but 0-based in C++
        Jc % matches C++ version, think of these as offset not index
        isMultigraph
    end

    properties(Dependent)
        Edges
    end

    methods
        function mlg = MLDigraph(s, t, numNodes)
            % Force Ir and Jc to be varsize
            coder.varsize('tmp',[inf,1],[1,0]);
            tmp = coder.internal.indexInt(1);
            mlg.Ir = tmp;
            mlg.Jc = tmp;

            if nargin == 0
                mlg.Ir = zeros(0,1,coder.internal.indexIntClass());
                mlg.Jc = coder.internal.indexInt(0);
                mlg.isMultigraph = false;
            elseif nargin == 1 % Adjacency matrix constructor
                validateattributes(s,{'double','single','logical'},{'square'});
                if ~issparse(s) || coder.target('MATLAB')
                    [i, j] = find(s');
                    [mlg.Ir, mlg.Jc] = rowColtoIrJc(i, j, size(s, 1));
                else
                    if isempty(s)
                        mlg = matlab.internal.coder.MLDigraph();
                    elseif nnz(s) == 0
                        % Special handing for an all-zeros, non-empty
                        % sparse matrix
                        mlg = matlab.internal.coder.MLDigraph.edgesConstrWithIndex([],[],size(s,1));
                    else
                        st = s';
                        mlg.Ir = coder.internal.indexInt(st.rowidx(1:nnz(st)));
                        mlg.Jc = coder.internal.indexInt(st.colidx - 1);
                    end
                end
                mlg.isMultigraph = false;
            elseif nargin == 2
                validateattributes(s,{'double','single','logical'},{'square'});
                if ~issparse(s)
                    [i, j] = find(s);
                    [mlg.Ir, mlg.Jc] = rowColtoIrJc(i, j, size(s, 1));
                else
                    if isempty(s)
                        mlg = matlab.internal.coder.MLDigraph();
                    elseif nnz(s) == 0
                        mlg = matlab.internal.coder.MLDigraph.edgesConstrWithIndex([],[],size(s,1));
                    else
                        mlg.Ir = coder.internal.indexInt(s.rowidx(1:nnz(s)));
                        mlg.Jc = coder.internal.indexInt(s.colidx - 1);
                    end
                end
                mlg.isMultigraph = false;
            else
                mlg = matlab.internal.coder.MLDigraph.edgesConstrWithIndex(s, t, numNodes);
            end
        end

        function n = numnodes(mlg)
            n = length(mlg.Jc)-1;
        end

        function n = numedges(mlg)
            n = length(mlg.Ir);
        end

        function tf = ismultigraph(mlg)
            tf = mlg.isMultigraph;
        end

        function ed = get.Edges(mlg)
            n = length(mlg.Jc)-1;
            if n == 0
                ed = zeros(0,2);
                return
            end
            dJc = coder.internal.indexInt(diff(mlg.Jc));
            % It's not worth the overhead of sum here
            edLength = dJc(1);
            for ii = coder.internal.indexInt(2):numel(dJc)
                edLength = edLength + dJc(ii);
            end
            ed = coder.nullcopy(zeros(edLength,2));
            startIndex = coder.internal.indexInt(1);
            for ii = coder.internal.indexInt(1):n
                ed(startIndex + (0:dJc(ii)-1)) = double(ii);
                startIndex = startIndex + dJc(ii);
            end
            ed(:,2) = mlg.Ir;
        end

        function M = adjacency(mlg, in1, in2)
            nEdges = mlg.numedges;
            transp = true;
            if nargin == 1
                w = ones(nEdges,1);
            elseif nargin == 2
                if ischar(in1)
                    coder.internal.assert(strcmpi(in1,'transp'),'MATLAB:graphfun:graphbuiltin:InvalidTranspFlag');
                    transp = false;
                    w = ones(nEdges,1);
                else
                    w = in1;
                end
            else
                coder.internal.assert(ischar(in2) && strcmpi(in2,'transp'),'MATLAB:graphfun:graphbuiltin:InvalidTranspFlag');
                transp = false;
                w = in1;
            end
            
            n = numnodes(mlg);
            ir = mlg.Ir;
            jc = mlg.Jc;

            ONE = coder.internal.indexInt(1);
            M = coder.internal.sparse.spallocLike(n,n,numel(ir),w);

            M.colidx(1) = ONE; % JcA is 1-based to match rowidx for coder sparse matrices
            nzA = coder.internal.indexInt(0);
            
            % Remove non-structural zeros
            for ii = ONE:n
                for l = jc(ii) + ONE : jc(ii + ONE)
                    currentWeight = w(l);
                    if currentWeight ~= 0
                        nzA = nzA + ONE;
                        M.rowidx(nzA) = coder.internal.indexInt(ir(l));
                        M.d(nzA) = currentWeight;
                    end
                end
                M.colidx(ii + ONE) = nzA + ONE;
            end

            if transp
                M = M';
            end
        end

        function [edgeind, tind] = findedge(mlg, s_in, t_in)
            if isscalar(s_in)
                s = repmat(s_in, size(t_in));
                t = t_in;
            elseif isscalar(t_in)
                t = repmat(t_in, size(s_in));
                s = s_in;
            else
                % Check that s and t have the same number of elements
                coder.internal.assert(numel(s_in) == numel(t_in),'MATLAB:graphfun:graphbuiltin:EqualNumel');
                t = t_in;
                s = s_in;
            end
            % For multigraph, these arrays will grow longer than allocated
            % here.
            coder.varsize('edgeind',[inf 1]);
            coder.varsize('tind',[inf 1]);            

            edgeind = zeros(length(s), 1);

            ir = mlg.Ir;
            jc = mlg.Jc;

            if ~mlg.isMultigraph
                tind = (1:length(s))';
                for ll=1:length(s)
                    sloc = s(ll);
                    tloc = t(ll);
                    for kk=jc(sloc)+1:jc(sloc+1)
                        if ir(kk) == tloc
                            edgeind(ll) = kk;
                            break;
                        end
                    end
                end
            else
                tind = zeros(length(s), 1);
                pp = 1;
                for ll=1:length(s)
                    sloc = s(ll);
                    tloc = t(ll);
                    foundEdge = false;
                    kk = jc(sloc)+1;
                    while kk <= jc(sloc+1)
                        if ir(kk) == tloc
                            foundEdge = true;
                            while kk <= jc(sloc+1) && ir(kk) == tloc
                                edgeind = vectorParenAssignPastEnd(edgeind, pp, kk);
                                tind = vectorParenAssignPastEnd(tind, pp, ll);
                                kk = kk+1;
                                pp = pp+1;
                            end
                            break;
                        end
                        kk = kk+1;
                    end
                    if ~foundEdge
                        edgeind = vectorParenAssignPastEnd(edgeind, pp, 0);
                        tind = vectorParenAssignPastEnd(tind, pp, ll);
                        pp = pp+1;
                    end
                end
            end
        end

        function [G, edgeind] = flipedge(mlg)
            % Flip all edges in the  digraph - note that the option to flip
            % a subset of the edges is not currently implemented

            n = numnodes(mlg);
            ir = mlg.Ir;
            jc = mlg.Jc;

            if nargout == 2
                [irF, jcF, edgeind] = flipDigraph(ir,jc,n);
            else
                [irF, jcF] = flipDigraph(ir,jc,n);
            end

            G = matlab.internal.coder.MLDigraph();
            G.Ir = irF;
            G.Jc = jcF;
            G.isMultigraph = mlg.isMultigraph;
        end

        function [mlg, p] = addedge(mlg, s_in, t_in)
            % Core of this method is a translation of digraph.cpp/addEdge

            if isscalar(s_in)
                t = t_in;
                s = repmat(s_in, size(t));
            elseif isscalar(t_in)
                s = s_in;
                t = repmat(t_in, size(s));
            else
                s = s_in;
                t = t_in;
            end
            
            if isempty(s)
                p = zeros(0, 1);
                return
            end

            n = numnodes(mlg);
            e = numedges(mlg);
            [newEdgesDouble, ind] = sortrows([s(:) t(:)]);
            newEdges = coder.internal.indexInt(newEdgesDouble);
            numNodesNew = max(newEdges(:));

            irnew = zeros(e+size(newEdges, 1), 1, coder.internal.indexIntClass);
            coder.varsize('jcnew',[inf 1],[1 0]);
            jcnew = zeros(numNodesNew+1, 1, coder.internal.indexIntClass);
            p = zeros(length(ind), 1);

            ir = mlg.Ir;
            jc = mlg.Jc;

            nullind = intmax(coder.internal.indexIntClass);
            ismulti = false;
            l = 1;
            lnew = 1;
            for j=1:n
                lold = jc(j)+1;
                if lold == jc(j+1)+1
                    tOld = nullind;
                else
                    tOld = ir(lold);
                end
                if lnew <= size(newEdges, 1) && newEdges(lnew, 1) == j
                    tNew = newEdges(lnew, 2);
                else
                    tNew = nullind;
                end
                prevTgt = nullind;
                while true
                    if tNew < tOld
                        irnew(l) = tNew;
                        p(lnew) = l;
                        lnew = lnew+1;
                        if lnew <= size(newEdges, 1) && newEdges(lnew, 1) == j
                            tNew = newEdges(lnew, 2);
                        else
                            tNew = nullind;
                        end
                    elseif tOld ~= nullind
                        irnew(l) = tOld;
                        lold = lold+1;
                        if lold == jc(j+1)+1
                            tOld = nullind;
                        else
                            tOld = ir(lold);
                        end
                    else
                        break;
                    end
                    if irnew(l) == prevTgt
                        ismulti = true;
                    end
                    prevTgt = irnew(l);
                    l = l+1;
                end
                if j+1 <= numel(jcnew)
                    jcnew(j+1) = l-1;
                else
                    jcnew = [jcnew; zeros(j-numel(jcnew),1,'like',jcnew); l-1]; %#ok<AGROW>
                end
            end

            for j=n+1:numNodesNew
                prevTgt = nullind;
                while lnew<=size(newEdges, 1) && newEdges(lnew, 1) == j
                    irnew(l) = newEdges(lnew, 2);
                    p(lnew) = l;
                    if irnew(l) == prevTgt
                        ismulti = true;
                    end
                    prevTgt = irnew(l);
                    lnew = lnew+1;
                    l = l+1;
                end
                jcnew(j+1) = l-1;
            end

            mlg.Ir = irnew;
            mlg.Jc = jcnew;
            mlg.isMultigraph = ismulti;

            % Restore to original order in which new edges were given
            p(ind) = p;
        end

        function bins = weakConnectedComponents(mlg)
            % NOTE: In our C++ code, this algorithm that uses a boost
            % helper, see connectedComp.cpp/weakConnectedComponents. As an
            % alternative, here I'm computing the flipped
            % version of mlg and then applying the algorithm for the
            % undirected case, bfsSearchConnComp.

            n = numnodes(mlg);
            ir = mlg.Ir;
            jc = mlg.Jc;

            % Compute irF, jcF of mlg where each edge has been flipped in
            % direction.
            [irF, jcF] = flipDigraph(ir, jc, n);

            bins = zeros(1, n);

            nextbin = 0;
            for start=1:n
                % bins(i) starts out as 0 for not discovered
                % bins(i) is -1 for discovered, not finished.
                % bins(i) is >0 for finished assigned to a bin.

                if bins(start) == 0
                    % Node start belongs to a new component
                    nextbin = nextbin + 1;

                    % Start a list of all discovered nodes in the
                    % component
                    nodeList = coder.internal.list(start,'InitialCapacity',n,'FixedCapacity',true);
                    nodeList = nodeList.pushBack(start);
                    while length(nodeList) > 0 %#ok<ISMT> 
                        [nodeList, s] = nodeList.popFront();

                        for l=jc(s)+1:jc(s+1)
                            t = ir(l);
                            if bins(t) == 0
                                bins(t) = -1;
                                nodeList = nodeList.pushBack(t);
                            end
                        end
                        for l=jcF(s)+1:jcF(s+1)
                            t = irF(l);
                            if bins(t) == 0
                                bins(t) = -1;
                                nodeList = nodeList.pushBack(t);
                            end
                        end
                        bins(s) = nextbin;
                    end
                end
            end
        end

        function [bins, nrbins] = connectedComponents(mlg)
            % This is based on connectedComp.cpp/dfsSearchConnComp.

            ZERO = coder.internal.indexInt(0);
            ONE = coder.internal.indexInt(1);
            WHITE = ZERO;
            GRAY = ONE;
            BLACK = coder.internal.indexInt(2);

            n = coder.internal.indexInt(numnodes(mlg));
            ir = mlg.Ir;
            jc = mlg.Jc;
            bins = zeros(1, n);
            currBin = 0;
            currIndex = ZERO;
            color = zeros(1, n, coder.internal.indexIntClass);
            index = intmax(coder.internal.indexIntClass) * ones(1, n, coder.internal.indexIntClass); % This is intmax in C++
            lowlink = index;
            coder.varsize('MirIndex');
            for start=ONE:n
                if color(start) == WHITE
                    vertexOnPath = coder.internal.list(start,'InitialCapacity',1,'FixedCapacity',false);
                    vertexOnPath = vertexOnPath.pushBack(start);
                    stack = coder.internal.list(start,'InitialCapacity',1,'FixedCapacity',false);
                    stack = stack.pushBack(start);

                    MirIndex = jc(start)+1;
                    index(start) = currIndex;
                    lowlink(start) = currIndex;
                    color(start) = GRAY;

                    currIndex = currIndex+ONE;

                    while length(vertexOnPath) ~= 0 %#ok<ISMT>
                        v = vertexOnPath.getValue(vertexOnPath.back);
                        iiMir = MirIndex(end);
                        lastInPath = length(vertexOnPath);

                        last = jc(v+1);
                        while iiMir <= last
                            target_vertex = ir(iiMir);
                            if color(target_vertex) == WHITE
                                vertexOnPath = vertexOnPath.pushBack(target_vertex);
                                MirIndex = [MirIndex, jc(target_vertex)+1]; %#ok<AGROW>
                                index(target_vertex) = currIndex;
                                lowlink(target_vertex) = currIndex;
                                color(target_vertex) = GRAY;
                                stack = stack.pushBack(target_vertex);
                                currIndex = currIndex+1;
                                break;
                            elseif color(target_vertex) == GRAY
                                if lowlink(v) > index(target_vertex)
                                    lowlink(v) = index(target_vertex);
                                end
                            end

                            iiMir = iiMir + 1;
                        end

                        MirIndex(lastInPath) = iiMir;

                        if iiMir == last+1 % finished node v
                            vertexOnPath = vertexOnPath.popBack();
                            MirIndex(end) = [];

                            if lowlink(v) == index(v)
                                currBin = currBin+1;
                                [stack, w] = stack.popBack();
                                while v ~= w
                                    color(w) = BLACK;
                                    bins(w) = currBin;
                                    [stack, w] = stack.popBack();
                                end
                                color(w) = BLACK;
                                bins(w) = currBin;
                            end

                            if length(vertexOnPath) ~= 0 %#ok<ISMT>
                                w = v;
                                oldv = vertexOnPath.getValue(vertexOnPath.back);
                                if lowlink(oldv) > lowlink(w)
                                    lowlink(oldv) = lowlink(w);
                                end
                                MirIndex(end) = MirIndex(end)  + 1;
                            end
                        end
                    end
                end
            end
            nrbins = currBin;
        end
        function [edges, nodes] = outedges(mlg, u)            
            % Return a list of all edges that connect from u to other
            % nodes, and a list of those nodes

            jc = mlg.Jc;
            ir = mlg.Ir;
            nodes = ir(jc(u)+1:jc(u+1));
            edges = jc(u)+1:jc(u+1);
        end

        function [edges, nodes] = inedges(mlg, u)
            % Return a list of all edges with connect other nodes to u, and
            % a list of those nodes

            jc = mlg.Jc;
            ir = mlg.Ir;
            n = coder.internal.indexInt(mlg.numnodes);
            edgesBuffer = coder.nullcopy(zeros(1,n,coder.internal.indexIntClass));
            nodesBuffer = coder.nullcopy(zeros(1,n,coder.internal.indexIntClass));
            count = coder.internal.indexInt(0);
            
            for ii = 1:n
                for jj=jc(ii)+1:jc(ii+1)
                    if ir(jj) == u
                        count = count + 1;
                        edgesBuffer(count) = jj;
                        nodesBuffer(count) = ii;
                    end
                end
            end  

            edges = edgesBuffer(1:count);
            nodes = nodesBuffer(1:count);
        end

        function d = outdegree(mlg, nodeids)
            if nargin == 1
                n = mlg.numnodes;
                nodeids = (1:n)';
            end
            d = zeros(size(nodeids));
            jc = mlg.Jc;
            for ii = 1:numel(nodeids)
                node = nodeids(ii);
                d(ii) = jc(node+1) - jc(node);
            end
        end

        function d = indegree(mlg, nodeids)
            n = mlg.numnodes;
            if nargin == 1
                nodeids = (1:n)';
            end
            jc = mlg.Jc;
            ir = mlg.Ir;
            inDegreeList = zeros(n,1);
            
            % Traverse graph and precompute in degree
            for ii = 1:n
                for jj=jc(ii)+1:jc(ii+1)
                    t = ir(jj);
                    inDegreeList(t) = inDegreeList(t) + 1;
                end
            end
            
            d_tmp = inDegreeList(nodeids(:)); % (:) prevents vector(vector) vs. vector(matrix) issues
            d = reshape(d_tmp,size(nodeids));
        end

        function p = predecessors(mlg, nodeid)
            jc = mlg.Jc;
            ir = mlg.Ir;
            n = mlg.numnodes;
            pBuffer = coder.nullcopy(zeros(n,1,coder.internal.indexIntClass));
            pBufferLastElement = coder.internal.indexInt(0);
            for currentNode = coder.internal.indexInt(1):n
                for ii = jc(currentNode)+1:jc(currentNode+1)
                    if ir(ii) == nodeid
                        pBufferLastElement = pBufferLastElement + coder.internal.indexInt(1);
                        pBuffer(pBufferLastElement) = currentNode;
                        break
                    end
                end
            end
            p = double(pBuffer(1:pBufferLastElement));
        end

        function s = successors(mlg, nodeid)
            s = double(mlg.Ir(mlg.Jc(nodeid)+1:mlg.Jc(nodeid+1)));
        end

        function tf = isequal(in1,in2,varargin)
            if nargin > 2
                % Deal with the (rare) case of more than two inputs by calling
                % this function again with each input separately.
                tf = isequal(in1, in2);
                ii = 1;
                while tf && ii <= nargin-2
                    tf = isequal(in1, varargin{ii});
                    ii = ii+1;
                end
                return
            end

            if in1.isMultigraph ~= in2.isMultigraph
                tf = false;
                return
            end

            if ~isequal(in1.Ir,in2.Ir)
                tf = false;
                return
            end

            tf = isequal(in1.Jc,in2.Jc);
            return
        end

        function tf = isequaln(in1,in2,varargin)
            tf = isequal(in1,in2,varargin);  % None of the properties of MLDigraph can have NaNs
            return
        end
    end

    methods (Static)
        function [mlg, ind] = edgesConstrWithIndex(s, t, numNodes)
            coder.internal.assert(all(s == fix(s),'all') && all(t == fix(t),'all') && ...
                all(s>0,'all') && all(t>0,'all'),'MATLAB:graphfun:graphbuiltin:InvalidSRC');

            mlg = matlab.internal.coder.MLDigraph;
            if isscalar(s)
                s1 = repmat(s, size(t));
                t1 = t;
            elseif isscalar(t)
                t1 = repmat(t, size(s));
                s1 = s;
            else
                s1 = s;
                t1 = t;
            end
            [st, ind] = sortrows([s1(:) t1(:)]);

            isMulti = false;
            for ii=1:size(st, 1)-1
                if st(ii, 1) == st(ii+1, 1) && st(ii, 2) == st(ii+1, 2)
                    isMulti = true;
                    break;
                end
            end
            mlg.isMultigraph = isMulti;

            [mlg.Ir, mlg.Jc] = rowColtoIrJc(st(:, 2), st(:, 1), numNodes);
        end
    end
end

function [Ir, Jc] = rowColtoIrJc(i, j, n)
% This is basically like SPARSE, except we expect i, j to be sorted
% already, there are no values and we allow repeated pairs of values.

e = coder.internal.indexInt(length(i));

% Force Ir and Jc to be varsize
coder.varsize('Ir',[inf,1],[1,0]);
coder.varsize('Jc',[inf,1],[1,0]);
            
Jc = zeros(n+1, 1, coder.internal.indexIntClass());
if isempty(i)
    Ir = zeros(0, 1, coder.internal.indexIntClass);
else
    Ir = coder.internal.indexInt(reshape(i, [], 1));
end

ll = coder.internal.indexInt(0);
for ii=2:n+1
    while ll < e && j(ll+1) < ii
        ll = ll+1;
    end
    Jc(ii) = ll;
end
end

function [irF, jcF, edgeind] = flipDigraph(ir, jc, n)
% code used in flipedge, included here as a helper for
% weakConnectedComponents. In C++, digraph.cpp/transposeStructure.
ONE = coder.internal.indexInt(1);

e = coder.internal.indexInt(length(ir));
irF = zeros(e, 1, coder.internal.indexIntClass());
jcF = zeros(n+1, 1, coder.internal.indexIntClass());
edgeind = zeros(e, 1);

for k = ONE:e
    jcF(ir(k) + ONE) = jcF(ir(k) + ONE) + ONE;
end

nz = coder.internal.indexInt(0);
for i = ONE:n
    thisRowCount = jcF(i + ONE);
    jcF(i + ONE) = nz;
    nz = nz + thisRowCount;
end

count = 1;
for j = ONE:n
    for k=jc(j) + ONE:jc(j + ONE)
        indIr = jcF(ir(k) + ONE) + ONE;
        irF(indIr) = j;
        jcF(ir(k) + ONE) = indIr;
        if nargout == 3
            edgeind(indIr) = count;
            count = count + 1;
        end
    end
end
end

function in = vectorParenAssignPastEnd(in,index,value_in)
% Only works for numeric vectors
% Expands codegen parenAssign to allow you to assign outside the current
% range of in by padding the end of in with zeros

coder.inline('always');
value = cast(value_in,'like',in);
numelIn = numel(in);
if index <= numelIn
    in(index) = value;
elseif iscolumn(in)
    pad = zeros(index - numelIn - 1, 1, 'like', in);
    in = [in; pad; value];
else
    pad = zeros(1, index - numelIn - 1, 'like', in);
    in = [in, pad, value];
end
end

%{
% Helpers: Go through each edge (s, t) in the graph
% Nodes are listed in the same order they have in the edges table.
for s=1:n
    for l=jc(s)+1:jc(s+1)
        t = ir(l);          % Target node of the current edge
        edgeID = l;         % Row of the Edges table that this edge is
                            % located, relevant mostly for multigraph

        %%% Do stuff with edge edgeID from node s to node t. %%%
    end
end

% Helpers: Go through every successor of node s
% t is listed in non-monotonically increasing order.
for l=jc(s)+1:jc(s+1)
    t = ir(l);          % Target node of the current edge
    edgeID = l;         % Row of the Edges table that this edge is
                        % located, relevant mostly for multigraph

    %%% Do stuff with edge edgeID from nodes s to node t. %%%
end
%}