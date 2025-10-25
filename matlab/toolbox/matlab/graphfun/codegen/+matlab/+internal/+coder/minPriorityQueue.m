classdef minPriorityQueue
    % This heap is based on a complete binary tree (see below for an example).
    % This is an indirect heap, meaning that we store the indices u, but
    % sort the heap with respect to dist(u).
    % VERY IMPORTANT: dist(u) for node u in the heap may only ever be
    % decreased. When this happens, update must be called.
    %
    %                                 1
    %                       2                   3
    %                 4           5       6           7
    %               8   9      10

    %   Copyright 2021-2022 The MathWorks, Inc.
    %#codegen

    properties(Access=private)
        heap        % heap(1:len) contains the indices of all nodes that are in the heap
        indexToHeap % indexToHeap(i) gives the location of node i in the heap.
        len         % number of nodes currently in the heap
        % The heap is sorted such that the node i which minimizes dist(i) is at the top of
        % the heap. The comparison is stabilized, if dist(i) == dist(j), the smaller node
        % (i < j) is used.
    end
    methods
        function obj = minPriorityQueue(n)
            obj.heap = coder.nullcopy(zeros(n, 1, coder.internal.indexIntClass()));
            obj.indexToHeap = coder.nullcopy(zeros(n, 1, coder.internal.indexIntClass()));
            obj.len = ZERO;
        end

        function obj = clear(obj)
            % Reset the list.
            obj.len = ZERO;
        end

        function tf = isempty(obj)
            tf = obj.len == ZERO;
        end

        function obj = push(obj, u, dist)
            % Push new node u into the heap. Its position is determined based on
            % dist(u), compared to dist(v) of nodes v that are currently in the heap.
            obj.len = obj.len + ONE;
            obj.heap(obj.len) = u;
            obj.indexToHeap(u) = obj.len;
            obj = obj.percUp(obj.len, dist);
        end

        function [obj, value] = pop(obj, dist)
            % Remove smallest element of the heap (u with minimal dist(u)).
            % Note that we do not check for empty heaps
            value = obj.heap(ONE);
            obj.heap(ONE) = obj.heap(obj.len);
            obj.indexToHeap(obj.heap(ONE)) = ONE;
            obj.len = obj.len - ONE;
            obj = obj.percDown(ONE, dist);
        end

        function value = top(obj)
            % Return the index of the node at the top of the heap (the node that had the
            % smallest distance the last time the heap was modified or updated)
            value = obj.heap(ONE);
        end

        function obj = update(obj,u,dist)
            % The value of dist(u) has been decreased. Update u's position in the heap
            % based on this change.
            ind = obj.indexToHeap(u);
            obj = obj.percUp(ind, dist);
        end

        function n = numel(obj)
            n = obj.len;
        end

        function v = getValue(obj,n)
            % Return the index of the n-th node in the heap
            v = obj.heap(n);
        end

    end

    methods (Access = private)
        function obj = percUp(obj, i, dist)
            iparent = coder.internal.indexDivide(i, 2);
            while iparent > 0 && obj.LE(i, iparent, dist)
                obj.heap([i iparent]) = obj.heap([iparent i]);
                obj.indexToHeap(obj.heap([i iparent])) = obj.indexToHeap(obj.heap([iparent i]));
                i = iparent;
                iparent = coder.internal.indexDivide(i, 2);
            end
        end

        function obj = percDown(obj, i, dist)
            sz = obj.len;
            while 2*i <= sz
                lc = 2*i;
                rc = 2*i+1;
                if rc > sz || obj.LE(lc, rc, dist)
                    ichild = lc;
                else
                    ichild = rc;
                end

                if ~obj.LE(i, ichild, dist)
                    obj.heap([i ichild]) = obj.heap([ichild i]);
                    obj.indexToHeap(obj.heap([i ichild])) = obj.indexToHeap(obj.heap([ichild i]));
                else
                    break
                end
                i = ichild;
            end
        end

        function tf = LE(obj, index1, index2, dist)
            i = obj.heap(index1);
            j = obj.heap(index2);
            tf = dist(i) < dist(j) || ( dist(i) == dist(j) && i <= j );
        end
    end
end

function out = ONE()
out = coder.internal.indexInt(1);
end

function out = ZERO()
out = coder.internal.indexInt(0);
end