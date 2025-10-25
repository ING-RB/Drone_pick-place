classdef list
    
    %MATLAB Code Generation Private Class
    %
    %   Homogeneous doubly-linked list class.
    %
    %   The list may be created with a fixed capacity. When this is done,
    %   any return vectors will have full length regardless of how many
    %   elements are in the list. The first length(list) elements are the
    %   ones in use. Also, if the list has a fixed capacity and becomes
    %   full, adding new elements becomes a no-op when error checking is
    %   stripped out on stand-alone targets.
    %
    %   A 'ComparisonMethod' can be supplied for sorting. It should be a
    %   function handle F such that F(A,B) returns true if A is
    %   "less-than-or-equal-to" B, i.e. if A sorts to the left of B. If
    %   elements are added with the insertSorted method, the list will stay
    %   sorted. The default comparison method corresponds to the ordering
    %   of SORT with default options.
    %
    %   Sorted, fixed-capacity lists use "mink" semantics when using the
    %   insertSorted method, i.e. when full capacity is reached, a new
    %   value will displace the largest value if it is smaller, or a new
    %   value will be ignored if it is larger than the largest value.
    %
    %   The sorting algorithm is not stable, i.e. if F(A,B) and F(B,A) both
    %   return true and A and B are different, then the sort ordering might
    %   place A before B or B before A. If sort stability is required, it
    %   can generally be achieved by careful definition of the comparison
    %   function and the data type stored by the list (e.g. including a
    %   sequence number along with the value as part of a structure type).
    %
    %
    %   %------------------------------------------------------------------
    %   % Example 1:
    %
    %   % Define the data type that will be stored in the list.
    %   % dataExample = struct('a',0,'b',0);
    %
    %   % Create the list object.
    %   x = coder.internal.list(dataExample, ...
    %       'InitialCapacity',20,'FixedCapacity',true);
    %
    %   % Add data to the list.
    %   rng('default');
    %   for k = 1:7
    %       x = x.pushBack(struct('a',randi(10),'b',randi(10)));
    %   end
    %
    %   % Sort the list by the sum of 'a' and 'b'
    %   x = x.sort(@(x,y)(x.a + x.b) < (y.a + y.b))
    %
    %   % Delete any existing elements where both x.a and x.b are greater than 7.
    %   % Add new elements after elements where both x.a and x.b are less than 7.
    %   node = x.front;
    %   while node ~= 0
    %       % Since we'll be modifying the list but the next node will not
    %       % change, save the next node at the outset.
    %       nextNode = x.next(node);
    %       r = x.getValue(node);
    %       if max(r.a,r.b) < 7
    %           fprintf(1,'Inserting new element\n');
    %           x = x.insertAfter(node,struct('a',randi(10),'b',randi(10)));
    %       elseif min(r.a,r.b) > 7
    %           fprintf(1,'Deleting element\n');
    %           x = x.erase(node);
    %       end
    %       node = nextNode;
    %   end
    %
    %   % Create a list of just the 'a' members.
    %   y = x.applyFunction(@(r)r.a);
    %
    %   % Sum the y list.
    %   s = 0;
    %   node = y.front;
    %   while node ~= 0
    %       s = s + y.getValue(node);
    %       node = y.next(node);
    %   end
    %   fprintf(1,'Sum of ''a'' members is %g\n',s);
    %
    %   % Convert the list to a vector.
    %   [v,len] = y.vector
    %
    %   %------------------------------------------------------------------
    %   % Example 2:
    %
    %   function B = top5rows(A)
    %   % Find the first 5 rows of sortrows(A).
    %   % Define a data type for the homogeneous list to hold.
    %   s = struct('row',zeros(1,size(A,2),'like',A));
    %   % Define a comparison function that operates on s structs.
    %       function p = LE(s1,s2)
    %           A2 = [s1.row;s2.row];
    %           [~,idx] = sortrows(A2);
    %           p = (idx(1) == 1);
    %       end
    %   x = coder.internal.list(s, ...
    %       'InitialCapacity',5, ...
    %       'FixedCapacity',true, ...
    %       'ComparisonFunction',@LE);
    %   % Add all the rows.
    %   for k = 1:size(A,1)
    %       x = x.insertSorted(struct('row',A(k,:)));
    %   end
    %   % Convert output to matrix form.
    %   nrows = min(5,size(A,1));
    %   B = zeros(nrows,size(A,2),'like',A);
    %   k = 0;
    %   node = x.front;
    %   while k < 5 && node ~= 0
    %       s = x.getValue(node);
    %       k = k + 1;
    %       B(k,:) = s.row;
    %       node = x.next(node);
    %   end
    %   end
    
    %   Copyright 2019 The MathWorks, Inc.
    %#codegen
    
    properties (Access = private)
        nodePool % column vector of NODE structures
        valuePool % column vector of values in the list
        unusedAddr % address of first node in the unused node list
        frontAddr % address of first node in the list
        backAddr % address of last node in the list
        len % length of the list
        fixedcap % logical(size(fixedcap,1)) = constant fixedcap input
        LEfun % "less-than-or-equal" function for sorting.
        sorted % indicates if the list is known to be sorted
    end
    
    methods
        
        function obj = list(scalarEg,varargin)
            coder.internal.allowEnumInputs;
            coder.internal.prefer_const(varargin);
            if nargin < 1
                scalarEg = 0;
            end
            parms = {'InitialCapacity','FixedCapacity','ComparisonFunction'};
            poptions = struct( ...
                'CaseSensitivity',false, ...
                'PartialMatching','unique', ...
                'StructExpand',false, ...
                'IgnoreNulls',true);
            pstruct = coder.internal.parseParameterInputs( ...
                parms,poptions,varargin{:});
            icap = coder.internal.indexInt( ...
                coder.internal.getParameterValue( ...
                pstruct.InitialCapacity,BLOCKSIZE,varargin{:}));
            fixedcap = logical( ...
                coder.internal.getParameterValue( ...
                pstruct.FixedCapacity,false,varargin{:}));
            coder.internal.assert(coder.internal.isConst(fixedcap), ...
                'Coder:toolbox:FixedCapPropertyMustBeConstant');
            coder.internal.assert(~fixedcap || ...
                pstruct.InitialCapacity ~= 0, ...
                'Coder:toolbox:FixedCapListRequiresInitCap');
            if coder.const(fixedcap)
                % Note that icap need not be constant.
                obj.valuePool = repmat(scalarEg,icap,1);
                obj.nodePool = repmat(NODE,icap,1);
                obj.fixedcap = zeros(0,0,'uint8'); % No expansion.
            else
                coder.varsize('vpool');
                coder.varsize('npool');
                vpool = repmat(scalarEg,icap,1);
                npool = repmat(NODE,icap,1);
                obj.valuePool = vpool;
                obj.nodePool = npool;
                obj.fixedcap = zeros(1,0,'uint8');
            end
            obj.LEfun = coder.internal.getParameterValue( ...
                pstruct.ComparisonFunction,[],varargin{:});
            obj = obj.clear;
        end
        
        function p = isNull(obj,nodeAddr)
            % Returns true if nodeAddr is zero or out of range.
            coder.inline('always');
            p = nodeAddr < ONE | nodeAddr > size(obj.valuePool,1);
        end
        
        function [x,len] = vector(obj)
            % Return the data as a column vector. If valuePool is
            % fixed-length, x has the same length. The first len values of
            % the vector are the values in the list.
            if ~coder.target('MATLAB') && ...
                    coder.internal.isConst(size(obj.valuePool))
                x = repmat(coder.internal.scalarEg(obj.valuePool), ...
                    size(obj.valuePool,1),1);
            else
                x = coder.nullcopy(repmat( ...
                    coder.internal.scalarEg(obj.valuePool),obj.len,1));
            end
            idx = obj.frontAddr;
            for k = 1:obj.len
                x(k) = obj.valuePool(obj.nodePool(idx).addr);
                idx = obj.nodePool(idx).next;
            end
            len = obj.len;
        end
        
        function [nav,len] = nodeVector(obj)
            % Return the vector of node addresses. If valuePool is
            % fixed-length, nav has the same length. The first len values
            % of the vector are the node addresses.
            if ~coder.target('MATLAB') && ...
                    coder.internal.isConst(size(obj.valuePool))
                nav = zeros(size(obj.valuePool,1),1, ...
                    coder.internal.indexIntClass);
            else
                nav = coder.nullcopy(zeros(obj.len,1, ...
                    coder.internal.indexIntClass));
            end
            nodeAddr = obj.frontAddr;
            for k = 1:obj.len
                nav(k) = nodeAddr;
                nodeAddr = obj.nodePool(nodeAddr).next;
            end
            len = obj.len;
        end
        
        function disp(obj)
            if obj.len == 0
                fprintf(1,'Empty list\n');
            else
                disp(obj.vector.');
            end
        end
        
        function n = length(obj)
            coder.inline('always');
            n = double(obj.len);
        end
        
        function n = numel(obj)
            coder.inline('always');
            n = double(obj.len);
        end
        
        function obj = clear(obj)
            % Reset the list. All nodes will be moved to the unused list.
            % The valuePool and nodePool are not reduced in length.
            obj.len = ZERO;
            obj.frontAddr = NULL;
            obj.backAddr = NULL;
            % Initialize the address of each cell.
            for k = ONE:size(obj.nodePool,1)
                obj.nodePool(k).addr = k;
                obj.nodePool(k).next = k + 1;
                obj.nodePool(k).prev = k - 1;
            end
            obj.nodePool(size(obj.nodePool,1)).next = NULL;
            obj.unusedAddr = ONE;
            obj.sorted = true;
        end
        
        function LE = getLEfun(obj)
            if isa(obj.LEfun,'function_handle')
                LE = obj.LEfun;
            else
                LE = defaultLE;
            end
        end
        
        function [nodeAddr,value] = nth(obj,n)
            % Return the nth node of the list.
            nodeAddr = obj.nthNodeAddr(n);
            value = obj.getValue(nodeAddr);
        end
        
        function value = getValue(obj,nodeAddr)
            % Given a node of the list, return the corresponding value.
            % Returns scalarEg if the node does not point to a value.
            if obj.isNull(nodeAddr)
                value = coder.internal.scalarEg(obj.valuePool);
            else
                value = obj.valuePool(nodeAddr);
            end
        end
        
        function obj = setValue(obj,nodeAddr,value)
            % Given a node of the list, overwrite the corresponding value.
            % This is a no-op when the nodeAddr is null. Using this method
            % may set the list state to "unsorted".
            if ~obj.isNull(nodeAddr)
                obj.valuePool(nodeAddr) = value;
            end
            obj.sorted = obj.len <= 1;
        end
        
        function obj = pushFront(obj,value)
            % Push a new element on to the front of the list.
            % Using this method may set the list state to "unsorted".
            coder.internal.allowEnumInputs;
            nv = coder.internal.indexInt(numel(value));
            for j = nv:-1:1
                [obj,k] = obj.newNodeAddr;
                if k ~= NULL
                    if obj.frontAddr == NULL
                        obj.frontAddr = k;
                        obj.backAddr = k;
                    else
                        obj.nodePool(k).next = obj.frontAddr;
                        obj.nodePool(obj.frontAddr).prev = k;
                        obj.frontAddr = k;
                    end
                    obj.valuePool(k) = value(j);
                end
            end
            obj.sorted = obj.len <= 1;
        end
        
        function [obj,value] = popFront(obj)
            % Remove the element at the front of the list. If the list is
            % empty, this is a no-op, and value is scalarEg.
            if obj.frontAddr == NULL
                % A value must be returned.
                value = coder.internal.scalarEg(obj.valuePool);
            else
                k = obj.frontAddr;
                value = obj.valuePool(k);
                obj.frontAddr = obj.nodePool(k).next;
                if obj.frontAddr ~= NULL
                    obj.nodePool(obj.frontAddr).prev = NULL;
                else
                    obj.backAddr = NULL;
                end
                obj = obj.freeNode(k);
            end
        end
        
        function obj = pushBack(obj,value)
            % Append a new element to the list. Using this method may set
            % the list state to "unsorted".
            coder.internal.allowEnumInputs;
            nv = coder.internal.indexInt(numel(value));
            for j = 1:nv
                [obj,k] = obj.newNodeAddr;
                if k ~= NULL
                    if obj.frontAddr == NULL
                        obj.frontAddr = k;
                        obj.backAddr = k;
                        obj.nodePool(k).next = NULL;
                    else
                        obj.nodePool(k).prev = obj.backAddr;
                        obj.nodePool(obj.backAddr).next = k;
                        obj.backAddr = k;
                    end
                    obj.valuePool(k) = value(j);
                end
            end
            obj.sorted = obj.len <= 1;
        end
        
        function [obj,value] = popBack(obj)
            % Remove the last element of the list. If the list is empty,
            % value is scalarEg.
            if obj.backAddr == NULL
                % A value must be returned.
                value = coder.internal.scalarEg(obj.valuePool);
            else
                k = obj.backAddr;
                value = obj.valuePool(k);
                obj.backAddr = obj.nodePool(k).prev;
                if obj.backAddr ~= NULL
                    obj.nodePool(obj.backAddr).next = NULL;
                else
                    obj.frontAddr = NULL;
                end
                obj = obj.freeNode(k);
            end
        end
        
        function [nodeAddr,value] = front(obj)
            % Return the address of the first node of the list.
            % If the list is empty, node == 0 and value is scalarEg.
            nodeAddr = obj.frontAddr;
            value = obj.getValue(nodeAddr);
        end
        
        function [nodeAddr,value] = back(obj)
            % Return the last node of the list. If the list is empty,
            % node.addr = 0, and value is scalarEg.
            nodeAddr = obj.backAddr;
            value = obj.getValue(nodeAddr);
        end
        
        function [nodeAddr,value] = next(obj,nodeAddr)
            % Return the next node from the list. If the input node is the
            % end of the list, the return node will have node.addr = 0, and
            % value is scalarEg.
            if obj.isNull(nodeAddr)
                nodeAddr = NULL;
            else
                nodeAddr = obj.nodePool(nodeAddr).next;
            end
            value = obj.getValue(nodeAddr);
        end
        
        function [nodeAddr,value] = previous(obj,nodeAddr)
            % Return the previous node from the list. If the input node is
            % the front of the list, the return node will have node.addr =
            % 0, and value is scalarEg.
            if obj.isNull(nodeAddr)
                nodeAddr = NULL;
            else
                nodeAddr = obj.nodePool(nodeAddr).prev;
            end
            value = obj.getValue(nodeAddr);
        end
        
        function y = applyFunction(obj,fun,nodeAddr)
            % Apply a function to list values. If a node is supplied, fun
            % is applied only to the value associated with that node. If
            % only a function handle is supplied, the function is applied
            % to every value of the list, and a new list object is
            % returned. If obj is a fixed-capacity list, the output list
            % will have the same, fixed capacity. Otherwise, the initial
            % allocation for the return list will be the current size.
            if nargin == 3
                % Apply fun to the data associated with the given node.
                if obj.isNull(nodeAddr)
                    y = fun(coder.internal.scalarEg(obj.valuePool));
                else
                    y = fun(obj.getValue(nodeAddr));
                end
            else
                % Return a list after applying fun to all data.
                eg = coder.internal.scalarEg( ...
                    fun(coder.internal.scalarEg(obj.valuePool)));
                maxlen = coder.internal.indexInt(size(obj.valuePool,1));
                if coder.const(obj.isFixedCapacity)
                    y = coder.internal.list(eg, ...
                        'InitialCapacity',maxlen, ...
                        'FixedCapacity',true);
                else
                    assert(obj.len <= maxlen); %<HINT>
                    y = coder.internal.list(eg, ...
                        'InitialCapacity',obj.len, ...
                        'FixedCapacity',false);
                end
                nodeAddr = obj.front;
                for k = 1:obj.len
                    y = y.pushBack(fun(obj.getValue(nodeAddr)));
                    nodeAddr = obj.next(nodeAddr);
                end
            end
        end
        
        function obj = erase(obj,nodeAddr)
            if ~obj.isNull(nodeAddr)
                node = obj.getNode(nodeAddr);
                if nodeAddr == obj.frontAddr
                    obj.frontAddr = node.next;
                end
                if nodeAddr == obj.backAddr
                    obj.backAddr = node.prev;
                end
                if node.prev ~= NULL
                    obj.nodePool(node.prev).next = node.next;
                end
                if node.next ~= NULL
                    obj.nodePool(node.next).prev = node.prev;
                end
                obj = obj.freeNode(nodeAddr);
            end
        end
        
        function [obj,nodeAddr] = insertAfter(obj,nodeAddr,value)
            % Insert a new value into the list after the given node. If the
            % node is null, the value is is pushed to the front of the
            % list. Using this method may set the list state to "unsorted".
            coder.internal.allowEnumInputs;
            if obj.isNull(nodeAddr)
                obj = obj.pushFront(value);
            elseif nodeAddr == obj.backAddr
                obj = obj.pushBack(value);
            else
                [obj,k] = obj.newNodeAddr;
                if k ~= NULL
                    node = obj.getNode(nodeAddr);
                    obj.valuePool(k) = value;
                    left = nodeAddr;
                    right = node.next;
                    obj.nodePool(k).prev = left;
                    obj.nodePool(k).next = right;
                    obj.nodePool(left).next = k;
                    obj.nodePool(right).prev = k;
                    nodeAddr = k;
                end
            end
            obj.sorted = obj.len <= 1;
        end
        
        function [obj,nodeAddr] = insertBefore(obj,nodeAddr,value)
            % Insert a new value into the list before the given node. If
            % the node is null, the value is appended to the end of the
            % list. Using this method may set the list state to "unsorted".
            coder.internal.allowEnumInputs;
            if obj.isNull(nodeAddr)
                obj = obj.pushBack(value);
            elseif nodeAddr == obj.frontAddr
                obj = obj.pushFront(value);
            else
                [obj,k] = obj.newNodeAddr;
                if k ~= NULL
                    node = obj.getNode(nodeAddr);
                    obj.valuePool(k) = value;
                    left = node.prev;
                    right = node.addr;
                    obj.nodePool(k).prev = left;
                    obj.nodePool(k).next = right;
                    obj.nodePool(left).next = k;
                    obj.nodePool(right).prev = k;
                    nodeAddr = k;
                end
            end
            obj.sorted = obj.len <= 1;
        end
        
        function obj = insertSorted(obj,value)
            % Insert a new element into the list in sorted order. If the
            % array isn't known to be sorted already, it is sorted
            % automatically. If the list is statically-sized and full,
            % insertSorted has "mink" semantics: the new entry will be
            % inserted and the last (largest) value removed if the new
            % value is less-than-or-equal to the last element value. If the
            % new value is larger than the last element value, it is
            % silently ignored.
            coder.internal.allowEnumInputs;
            if ~obj.sorted
                obj = obj.sort;
            end
            LE = obj.getLEfun;
            FIXEDCAP = ~logical(size(obj.fixedcap,1));
            dropLast = FIXEDCAP && obj.unusedAddr == NULL;
            if obj.len == 0 % First value
                obj = obj.pushFront(value);
            elseif LE(value,obj.valuePool(obj.front)) % Goes in front
                if dropLast
                    obj = obj.erase(obj.back);
                end
                obj = obj.pushFront(value);
            elseif LE(obj.getValue(obj.back),value) % Goes in back.
                if ~dropLast
                    obj = obj.pushBack(value);
                end
            else
                % Binary search for insertion spot.
                addr = obj.nodeVector;
                TWO = coder.internal.indexInt(2);
                LEFT = ONE;
                RIGHT = obj.len;
                d = idivide(RIGHT - LEFT,TWO,'floor');
                while d > 0
                    k = LEFT + d;
                    if LE(value,obj.valuePool(addr(k)))
                        RIGHT = k;
                    else
                        LEFT = k;
                    end
                    d = idivide(RIGHT - LEFT,TWO,'floor');
                end
                if dropLast
                    obj = obj.erase(obj.back);
                end
                obj = obj.insertAfter(addr(LEFT),value);
            end
            obj.sorted = true;
        end
        
        function obj = flip(obj)
            % Reverse the list. Using this method may set the list state to
            % "unsorted".
            k = obj.frontAddr;
            for j = ONE:obj.len
                next = obj.nodePool(k).next;
                obj.nodePool(k).next = obj.nodePool(k).prev;
                obj.nodePool(k).prev = next;
                k = next;
            end
            tmp = obj.backAddr;
            obj.backAddr = obj.frontAddr;
            obj.frontAddr = tmp;
            obj.sorted = obj.len <= 1;
        end
        
        function obj = sort(obj,LE)
            % Sort the list.
            if nargin == 1 && obj.sorted
                % Quick return if the list is already known to be sorted.
                return
            end
            if nargin == 2
                % If the array is sorted in any order other than that
                % implied by obj.LEfun, it is "unsorted" for the purposes
                % of obj.sorted.
                refLEfun = obj.getLEfun;
                SORTED = isequal(LE,refLEfun);
            else
                LE = obj.getLEfun;
                SORTED = true;
            end
            v = coder.internal.introsort(obj.vector,ONE,obj.len,LE);
            nv = obj.len;
            obj = obj.clear;
            for k = ONE:nv
                obj = obj.pushBack(v(k));
            end
            obj.sorted = SORTED;
        end
        
        function p = issorted(obj,LE)
            % Determine whether the list is sorted.
            p = true;
            if obj.len > 1 && (nargin == 2 || ~obj.sorted)
                if nargin == 1
                    LE = obj.getLEfun;
                end
                k1 = obj.front;
                k2 = obj.next(k1);
                while k2 ~= NULL
                    if ~LE(obj.valuePool(k1),obj.valuePool(k2))
                        p = false;
                        break
                    end
                    k1 = k2;
                    k2 = obj.next(k1);
                end
            end
        end
        
        function dispFrom(obj,nodeAddr)
            % Debugging function to display list nodes starting at the
            % given node. To display the entire list, use
            % obj.dispFrom(obj.front).
            if nargin == 1
                obj.dispFrom(obj.frontAddr);
            elseif coder.internal.isTextRow(nodeAddr)
                coder.internal.prefer_const(nodeAddr);
                sl = max(ONE,strlength(nodeAddr));
                if strncmpi(nodeAddr,'unused',sl)
                    obj.dispFrom(obj.unusedAddr);
                elseif strncmpi(nodeAddr,'front',sl)
                    obj.dispFrom(obj.frontAddr);
                else
                    disp('Invalid input -- use ''front'' or ''unused''');
                end
            elseif obj.isNull(nodeAddr)
                fprintf(1,'**** EMPTY LIST *****\n');
            else
                k = nodeAddr;
                fprintf(1,'******* FRONT *******\n');
                while k ~= NULL
                    fprintf(1,'---------------------\n');
                    disp(obj.nodePool(k));
                    k = obj.nodePool(k).next;
                end
                fprintf(1,'---------------------\n');
                fprintf(1,'******* BACK ********\n');
            end
        end
        
        function checkListIntegrity(obj)
            % Debugging function.
            n = coder.internal.indexInt(size(obj.valuePool,1));
            v = false(n,1);
            nodeAddr = obj.frontAddr;
            count = ZERO;
            ok = true;
            while ~obj.isNull(nodeAddr)
                if v(nodeAddr)
                    fprintf(1,'Node %d is in the list twice!\n',nodeAddr);
                    % ok = false;
                    return
                end
                count = count + 1;
                v(nodeAddr) = true;
                nodeAddr = obj.next(nodeAddr);
            end
            if count ~= obj.len
                fprintf(1,'List length is saved as %d, but the actual list length is %d.\n',obj.len,count);
                ok = false;
            end
            nodeAddr = obj.unusedAddr;
            while ~obj.isNull(nodeAddr)
                if v(nodeAddr)
                    fprintf(1,'Node %d is in both the list and the unused list!\n',nodeAddr);
                    % ok = false;
                    return
                end
                v(nodeAddr) = true;
                nodeAddr = obj.next(nodeAddr);
            end
            orphans = find(~v);
            for nodeAddr = ONE:length(orphans)
                fprintf(1,'Node %d is orphaned.\n',orphans(nodeAddr));
                ok = false;
            end
            if ok
                fprintf(1,'No issues detected.\n');
            end
        end
        
    end
    
    methods (Access = private)
        
        function node = getNode(obj,nodeAddr)
            coder.inline('always');
            if obj.isNull(nodeAddr)
                node = NODE;
            else
                node = obj.nodePool(nodeAddr);
            end
        end
        
        function obj = expandIfFull(obj)
            % If expansion is not needed, make a quick return.
            if obj.unusedAddr ~= NULL
                return
            end
            % If expansion is not allowed, issue an error and return.
            if coder.const(obj.isFixedCapacity)
                coder.internal.error('Coder:toolbox:ListCannotBeExpanded');
                return
            end
            startlen = coder.internal.indexInt(length(obj.nodePool));
            eg = coder.internal.scalarEg(obj.valuePool);
            obj.valuePool = [obj.valuePool;repmat(eg,BLOCKSIZE,1)];
            obj.nodePool = [obj.nodePool;repmat(NODE,BLOCKSIZE,1)];
            % Would be nice to do the above three lines only when
            % coder.target('MATLAB') is true and to do the following
            % when generating code, but reallocDynamicMatrix doesn't
            % work on struct members.
            % newcap = blocksize + ...
            %     coder.internal.indexInt(length(obj.valuePool));
            % obj.valuePool = coder.internal.reallocDynamicMatrix( ...
            %     obj.valuePool,[newcap,1]);
            % obj.nodePool = coder.internal.reallocDynamicMatrix( ...
            %     obj.nodePool,[newcap,1]);
            %end
            for k = 1:BLOCKSIZE
                obj.nodePool(startlen + k).addr = startlen + k;
                obj.nodePool(startlen + k).next = startlen + k + 1;
                obj.nodePool(startlen + k).prev = startlen + k - 1;
            end
            cap = coder.internal.indexInt(size(obj.nodePool,1));
            obj.unusedAddr = startlen + 1;
            obj.nodePool(obj.unusedAddr).prev = NULL;
            obj.nodePool(cap).next = NULL;
        end
        
        function [obj,k] = newNodeAddr(obj)
            % Pop a node off the list of unuse nodes and increment the
            % list length. The caller must add the new node to the list.
            obj = obj.expandIfFull;
            k = obj.unusedAddr;
            if k ~= NULL
                obj.len = obj.len + 1;
                obj.unusedAddr = obj.nodePool(k).next;
                obj.nodePool(k).next = NULL;
                if obj.unusedAddr ~= NULL
                    obj.nodePool(obj.unusedAddr).prev = NULL;
                end
            end
        end
        
        function obj = freeNode(obj,k)
            % Decrement the list length and put the node with address k in
            % the unused pool.
            if k ~= NULL
                obj.len = obj.len - 1;
                if obj.unusedAddr ~= NULL
                    obj.nodePool(obj.unusedAddr).prev = k;
                end
                obj.nodePool(k).next = obj.unusedAddr;
                obj.nodePool(k).prev = NULL;
                obj.unusedAddr = k;
            end
        end
        
        function k = nthNodeAddr(obj,n)
            count = ZERO;
            k = ZERO;
            if n >= ONE && n <= obj.len
                k = obj.frontAddr;
                while k ~= NULL && count < n
                    count = count + 1;
                    if count == n
                        break
                    end
                    k = obj.nodePool(k).next;
                end
            end
        end
        
        function p = isFixedCapacity(obj)
            p = coder.const(size(obj.fixedcap,1) == 0);
        end
        
    end
end

%--------------------------------------------------------------------------

function n = BLOCKSIZE
% blocksize is the smallest number of elements to allocate when using
% variable-sizing and either initializing or extending the internal arrays.
coder.inline('always');
n = coder.internal.indexInt(8);
end

function j = ZERO
coder.inline('always');
j = coder.internal.indexInt(0);
end

function j = ONE
coder.inline('always');
j = coder.internal.indexInt(1);
end

function j = NULL
coder.inline('always');
j = coder.internal.indexInt(0);
end

function s = NODE(addr,next,prev)
coder.inline('always')
if nargin < 3
    prev = ZERO;
end
if nargin < 2
    next = ZERO;
end
if nargin < 1
    addr = ZERO;
end
s = struct('addr',addr,'next',next,'prev',prev);
end

function p = sortcmp(a,b)
[~,idx] = sort([a,b]);
p = idx(1) == ONE;
end

function f = defaultLE
if coder.target('MATLAB')
    f = @sortcmp;
else
    f = @coder.internal.sortAscendLE;
end
end

%--------------------------------------------------------------------------
