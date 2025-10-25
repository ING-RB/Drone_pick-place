classdef MLGraph
    % 
    
    %   Copyright 2021 The MathWorks, Inc.
    %#codegen
    
    properties(Access = private)
        Ir % 1-based, but 0-based in C++
        Jc % matches C++ version, think of these as offset not index
        PosMap % 1-based, but 0-based in C++
        Diag % matches C++ version, think of these as offset not index
        isMultigraph
    end
    
    properties(Dependent)
        Edges
    end
    
    methods
        function mlg = MLGraph(s, t, numNodes)
            % For now, only 0, 1, and 3 inputs are supported
            
            % Force Ir and Jc to be varsize
            coder.varsize('tmp',[inf,1],[1,0]);
            tmp = coder.internal.indexInt(1);
            mlg.Ir = tmp;
            mlg.Jc = tmp;
            
            if nargin == 0
                mlg.Ir = zeros(0, 1, coder.internal.indexIntClass());
                mlg.Jc = zeros(1, coder.internal.indexIntClass());
                mlg.isMultigraph = false;
            elseif nargin == 1 % Adjacency matrix constructor                
                validateattributes(s,{'double','single','logical'},{});
                coder.internal.assert(size(s,1) == size(s,2),'MATLAB:graphfun:graphbuiltin:InvalidAdjacency')
                mlg.isMultigraph = false;   
                if ~issparse(s)
                    [i, j] = find(s);
                    [mlg.Ir, mlg.Jc] = rowColtoIrJc(i, j, size(s, 1));                    
                    [mlg.Ir, mlg.Jc] = duplicateSelfLoops(mlg.Ir, mlg.Jc, size(s, 1));
                    [mlg.PosMap, mlg.Diag] = definePosMapAndDiag(mlg.Ir, mlg.Jc, size(s, 1));
                else
                    if isempty(s)
                        mlg = matlab.internal.coder.MLGraph();
                        mlg.Diag = mlg.Jc;
                        mlg.PosMap = zeros(1, length(mlg.Ir),coder.internal.indexIntClass());
                    elseif nnz(s) == 0
                        % Special handing for an all-zeros, non-empty
                        % sparse matrix
                        mlg = matlab.internal.coder.MLGraph.edgesConstrWithIndex([],[],size(s,1));
                    else
                        % There are situations where a sparse matrix in
                        % codegen can have more elements in rowidx than it
                        % has non-zero elements (probably to avoid
                        % resizing). This throws everything off if you
                        % don't explicitly limit the values of rowidx used
                        mlg.Ir = coder.internal.indexInt(s.rowidx(1:nnz(s)));
                        mlg.Jc = coder.internal.indexInt(s.colidx - 1);
                        [mlg.Ir, mlg.Jc] = duplicateSelfLoops(mlg.Ir, mlg.Jc, size(s, 1));
                        [mlg.PosMap, mlg.Diag] = definePosMapAndDiag(mlg.Ir, mlg.Jc, size(s, 1));
                    end
                end
            else
                mlg = matlab.internal.coder.MLGraph.edgesConstrWithIndex(s, t, numNodes);
            end
        end
        
        function n = numnodes(mlg)
            if isempty(mlg.Jc)
                % This is needed to reassure coder that n is never negative
                n = 0;
            else
                n = length(mlg.Jc)-1;
            end
        end
        
        function n = numedges(mlg)
            n = length(mlg.Ir)/2;
        end
        
        function tf = ismultigraph(mlg)
            tf = mlg.isMultigraph;
        end
        
        function ed = get.Edges(mlg)
            n = numnodes(mlg);
            if n == 0
                ed = zeros(0, 2);
                return
            end
            e = numedges(mlg);
            ir = mlg.Ir;
            jc = mlg.Jc;
            Diag_ = mlg.Diag;
            
            ed = zeros(e, 2);
            pp = 1;
            for s=1:n
                ll = Diag_(s)+1;
                while ll <= jc(s+1)
                    t = ir(ll);
                    ed(pp, 1) = s;
                    ed(pp, 2) = t;
                    pp = pp+1;
                    if s == t
                        ll = ll+2;
                    else
                        ll = ll+1;
                    end
                end
            end
        end
        
        function M = adjacency(mlg,w_in)
            % Not supported for multigraph
            % Note: This is a limitation compared to existing
            % functionality. But we only need to use adjacency internally,
            % and it's only called for simple graphs.

            ONE = coder.internal.indexInt(1);
            if nargin < 2
                w = ones(mlg.numedges,1);
            else
                coder.internal.assert(isa(w_in,'double') || isa(w_in,'single') ...
                    || islogical(w_in), ...
                    'MATLAB:graphfun:graphbuiltin:InvalidWeightAdjacency');
                w = w_in;
            end

            n = mlg.numnodes;
            ir = coder.internal.indexInt(mlg.Ir(:));
            jc = coder.internal.indexInt(mlg.Jc(:));

            % Check specified weights for 0's and check ir & jc for
            % duplicate entries on diagonals

            M = coder.internal.sparse.spallocLike(n,n,numel(ir),w);

            M.colidx(1) = ONE; % JcA is 1-based to match rowidx for coder sparse matrices
            nzA = coder.internal.indexInt(0);

            for ii = ONE:n
                l = jc(ii) + ONE;
                while l <= jc(ii + ONE)
                    currentWeight = w(mlg.PosMap(l));
                    if currentWeight ~= 0
                        nzA = nzA + ONE;
                        M.rowidx(nzA) = coder.internal.indexInt(ir(l));
                        M.d(nzA) = currentWeight;
                    end
                    if ir(l) == ii
                        % Skip duplicate self-loop
                        l = l + ONE;
                    end
                    l = l + ONE;
                end
                M.colidx(ii + ONE) = nzA + ONE;
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
                s = s_in;
                t = t_in;
            end
            % For multigraph, these arrays will grow longer than allocated
            % here.
            coder.varsize('edgeind',[inf 1]);
            coder.varsize('tind',[inf 1]);

            edgeind = zeros(length(s), 1);
            
            ir = mlg.Ir;
            jc = mlg.Jc;
            posMap = mlg.PosMap;
            
            if ~mlg.isMultigraph
                tind = (1:length(s))';
                for ll=1:length(s)
                    sloc = s(ll);
                    tloc = t(ll);
                    for kk=jc(sloc)+1:jc(sloc+1)
                        if ir(kk) == tloc
                            edgeind(ll) = posMap(kk);
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
                                edgeind = vectorParenAssignPastEnd(edgeind, pp, posMap(kk));
                                tind = vectorParenAssignPastEnd(tind, pp, ll);
                                if sloc == tloc
                                    kk = kk+2;
                                else
                                    kk = kk+1;
                                end
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
        
        function [mlg, p] = addedge(mlg, s, t)
            % Core of this method is a translation of graph.cpp/addEdge
            if isempty(s) || isempty(t)
                p = zeros(0, 1);
                return
            end
            
            n = numnodes(mlg);
            numNodesNew = max([n; s(:); t(:)]);
            
            [addG, ind] = matlab.internal.coder.MLGraph.edgesConstrWithIndex(s, t, numNodesNew);
            
            Gjc = zeros(numNodesNew+1, 1, coder.internal.indexIntClass);
            Gjc(1:n+1) = mlg.Jc;
            Gjc(n+2:end) = mlg.Jc(end);
            
            jc = Gjc + addG.Jc;
            ir = zeros(length(mlg.Ir) + length(addG.Ir), 1, ...
                coder.internal.indexIntClass);
            edgeind = zeros(length(ind), 1);
            
            nullind = intmax(coder.internal.indexIntClass);
            ismulti = false;
            
            for j=1:numNodesNew
                l = jc(j)+1;
                lold = Gjc(j)+1;
                if lold == Gjc(j+1)+1
                    tOld = nullind;
                else
                    tOld = mlg.Ir(lold);
                end
                lnew = addG.Jc(j)+1;
                if lnew == addG.Jc(j+1)+1
                    tNew = nullind;
                else
                    tNew = addG.Ir(lnew);
                end
                prevTgt = nullind;
                
                while true
                    if tNew < tOld
                        ir(l) = tNew;
                        edgeind(addG.PosMap(lnew)) = l;
                        lnew = lnew + 1;
                        if tNew == j
                            l = l+1;
                            ir(l) = tNew;
                            lnew = lnew+1;
                        end
                        if lnew == addG.Jc(j+1)+1
                            tNew = nullind;
                        else
                            tNew = addG.Ir(lnew);
                        end
                    elseif tOld ~= nullind
                        ir(l) = tOld;
                        lold = lold+1;
                        if tOld == j
                            l = l+1;
                            ir(l) = tOld;
                            lold = lold+1;
                        end
                        if lold == Gjc(j+1)+1
                            tOld = nullind;
                        else
                            tOld = mlg.Ir(lold);
                        end
                    else
                        break;
                    end
                    if ir(l) == prevTgt
                        ismulti = true;
                    end
                    prevTgt = ir(l);
                    l = l+1;
                end
            end
            
            [posMap, Diag_] = definePosMapAndDiag(ir, jc, numNodesNew);
            
            % Restore to original order in which new edges were given
            p = zeros(length(ind), 1);
            for jj=1:length(p)
                if edgeind(jj) == 0
                    p(ind(jj)) = 0;
                else
                    p(ind(jj)) = posMap(edgeind(jj));
                end
            end
            
            mlg.Ir = ir;
            mlg.Jc = jc;
            mlg.PosMap = posMap;
            mlg.Diag = Diag_;
            mlg.isMultigraph = ismulti;
        end
        
        
        function bins = connectedComponents(mlg)
            % This should be based on connectedComp.cpp/bfsSearchConnComp.
            % It's the simplest of the 3 conncomp-methods.
            ONE = coder.internal.indexInt(1);

            n = numnodes(mlg);
            ir = mlg.Ir;
            jc = mlg.Jc;
            bins = zeros(1, n);
            
            nextbin = 0;
            for start=ONE:n
                % bins(i) starts out as 0 for not discovered
                % bins(i) is -1 for discovered, not finished.
                % bins(i) is >0 for finished assigned to a bin.
                
                if bins(start) == 0
                    % Node start belongs to a new component
                    nextbin = nextbin + 1;
                    
                    % Start a list of all discovered nodes in the
                    % component
                    nodeList = coder.internal.list(start, ...
                    'InitialCapacity',1,'FixedCapacity',false);
                    nodeList = nodeList.pushBack(start);
                    while length(nodeList) > 0 %#ok<ISMT> 
                        [nodeList,s] = nodeList.popFront();
                        for l=jc(s)+1:jc(s+1)
                            t = ir(l);
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

        function [edges,nodes] = outedges(mlg, u)
            % Return a list of all nodes connected to u and the edges that
            % connect them
            
            jc = mlg.Jc;
            ir = mlg.Ir;
            nodesTmp = ir(jc(u)+1:jc(u+1));
            edgesTmp = mlg.PosMap(jc(u)+1:jc(u+1));
            % Check for self-loops (they will be double counted)
            if isempty(nodesTmp)
                nodes = nodesTmp;
                edges = edgesTmp;
            else
                notRepeatedEdge = [true, diff(edgesTmp)~=0];
                nodes = nodesTmp(notRepeatedEdge);
                edges = edgesTmp(notRepeatedEdge);
            end
        end

        function N = neighbors(mlg,nodeid)
            firstInd = mlg.Jc(nodeid)+1;
            lastInd = mlg.Jc(nodeid+1);
            N = double(mlg.Ir(firstInd:lastInd));
        end
        

        function d = degree(mlg, nodeids)
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
            
            if ~isequal(in1.PosMap,in2.PosMap)
                tf = false;
                return
            end
            
            if ~isequal(in1.Diag,in2.Diag)
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
            tf = isequal(in1,in2,varargin); % None of the properties of MLGraph can be NaN
        end
    end
    
    methods (Static)
        function [mlg, ind] = edgesConstrWithIndex(s, t, numNodes)
             coder.internal.assert(all(s == fix(s),'all') && all(t == fix(t),'all') && ...
                 all(s>0,'all') && all(t>0,'all'),'MATLAB:graphfun:graphbuiltin:InvalidSRC');
            
            mlg = matlab.internal.coder.MLGraph;
            if isscalar(s)
                sExpanded = repmat(s, size(t));
                tExpanded = t;
            elseif isscalar(t)
                sExpanded = s;
                tExpanded = repmat(t, size(s));
            else
                sExpanded = s;
                tExpanded = t;
            end
            st = coder.internal.indexInt([sExpanded(:) tExpanded(:)]);
            st = sort(st, 2);
            [st, ind] = sortrows(st);
            
            numEdges = length(ind);
            
            % Force Ir and Jc to be varsize
            coder.varsize('ir',[inf,1],[1,0]);
            coder.varsize('jc',[inf,1],[1,0]);
            
            % The following is based on graph.cpp/acquire(edgeList, numNodes)
            ir = zeros(2*numEdges, 1, coder.internal.indexIntClass);
            jc = zeros(numNodes+1, 1, coder.internal.indexIntClass);
            
            for jj=1:numEdges
                jc(st(jj, 1)+1) = jc(st(jj, 1)+1) + 1;
                jc(st(jj, 2)+1) = jc(st(jj, 2)+1) + 1;
            end
            
            nzBoth = zeros(coder.internal.indexIntClass);
            for i=1:numNodes
                thisRowCount = jc(i+1);
                jc(i+1) = nzBoth;
                nzBoth = nzBoth + thisRowCount;
            end
            
            % Fill in "matrix" up to diagonal (all edges (t, s) with s <= t)
            for jj=1:numEdges
                l = jc(st(jj, 2)+1);
                ir(l+1) = st(jj, 1);
                jc(st(jj, 2)+1) = jc(st(jj, 2)+1) + 1;
            end
            
            % Fill in "matrix" below diagonal (all edges (s, t) with s <= t)
            for jj=1:numEdges
                l = jc(st(jj, 1)+1);
                ir(l+1) = st(jj, 2);
                jc(st(jj, 1)+1) = jc(st(jj, 1)+1) + 1;
            end
            
            ismulti = false;
            if numEdges > 1
                for jj=1:numEdges-1
                    if st(jj, 1) == st(jj+1, 1) && st(jj, 2) == st(jj+1, 2)
                        ismulti = true;
                        break;
                    end
                end
            end
            
            mlg.Ir = ir;
            mlg.Jc = jc;
            mlg.isMultigraph = ismulti;
            
            [mlg.PosMap, mlg.Diag] = definePosMapAndDiag(mlg.Ir, mlg.Jc, numNodes);
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
    Ir = zeros(0, 1, coder.internal.indexIntClass());
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

function [ir_out, jc_out] = duplicateSelfLoops(ir, jc, n)
coder.varsize('listOfSelfLoops',[1 inf],[0 1]);
listOfSelfLoops = zeros(1,0,coder.internal.indexIntClass());
ir_out = ir;
jc_out = jc;
% Maximum number of self loops = number of edges
for s = coder.internal.indexInt(1):n
    nrSelfLoops = coder.internal.indexInt(numel(listOfSelfLoops));
    for ii = jc_out(s)+1:jc_out(s+1)
        t = ir_out(ii);
        if s == t
            listOfSelfLoops = [listOfSelfLoops ii]; %#ok<AGROW> 
        elseif t > s
            break;
        end
    end
    jc_out(s) = jc_out(s) + nrSelfLoops;
end

numSelfLoops = coder.internal.indexInt(numel(listOfSelfLoops));
jc_out(end) = jc_out(end) + numSelfLoops;

irNewIndex = coder.internal.indexInt(1);
irIndex = coder.internal.indexInt(1);
if ~isempty(listOfSelfLoops)
    irNew = zeros(coder.internal.indexInt(length(ir_out))+numSelfLoops, 1, coder.internal.indexIntClass());
    
    for loopCount=1:numel(listOfSelfLoops)
        loop = coder.internal.indexInt(listOfSelfLoops(loopCount));
        irNew(irNewIndex:irNewIndex+(loop-irIndex)) = ir_out(irIndex:loop);
        
        irNewIndex = irNewIndex + loop - irIndex;
        irIndex = loop;
        
        irNew(irNewIndex) = ir_out(loop);
        irNewIndex = irNewIndex+1;
    end
    
    irNew(irNewIndex:end) = ir_out(irIndex:end);
    ir_out = irNew;
end

end

function [posMap, Diag] = definePosMapAndDiag(ir, jc, n)
ONE = coder.internal.indexInt(1);

Diag = jc;
posMap = zeros(1, length(ir),coder.internal.indexIntClass());

ne = ONE;
numSelfLoops = coder.internal.indexInt(0);

for j=1:n
    l = Diag(j)+1;
    coder.internal.assert(~(l <= jc(j+1) && ir(l) < j), ...
        'MATLAB:graphfun:graphbuiltin:SymmetricAdjacency');
    
    while l <= jc(j+1) && ir(l) == j
        numSelfLoops = numSelfLoops + ONE;
        posMap(l) = ne;
        posMap(l+1) = ne;
        l = l+2;
        ne = ne+ONE;
    end
    
    while l <= jc(j+1)
        i = ir(l);
        coder.internal.assert(~(Diag(i) >= jc(i+1) || ir(Diag(i)+1) ~= j), ...
            'MATLAB:graphfun:graphbuiltin:SymmetricAdjacency');
        posMap(l) = ne;
        posMap(Diag(i)+1) = ne;
        Diag(i) = Diag(i)+1;
        l = l+1;
        ne = ne+ONE;
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