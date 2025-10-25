classdef accessWrapper
    % Class that implements sort functionality for polyshape

    %   Copyright 2022 The MathWorks, Inc.
    %#codegen

    properties(Access=private)
        accessOrder
        issorted
        dir
        cri
        refPt
        nb
    end

    methods
        function obj = accessWrapper()
            % use the static in boundary2d to create a var size
            obj.accessOrder = coder.internal.polyshapeHelper.boundary2D.createVarSize( ...
                zeros(1,0,coder.internal.indexIntClass()));
            obj.issorted = false;
            obj.dir = 'a';
            obj.cri = 'a';
            obj.nb = coder.internal.indexInt(0);
            obj.refPt = [0 0];
        end

        function obj = clear(obj)
            obj.accessOrder = coder.internal.polyshapeHelper.boundary2D.createVarSize( ...
                zeros(1,0,coder.internal.indexIntClass()));
            obj.issorted = false;
            obj.dir = 'a';
            obj.cri = 'a';
            obj.nb = coder.internal.indexInt(0);
            obj.refPt = [0 0];
        end

        function mappedIdx = getMappedIndex(obj, idx)
            % Return the mappedIndex
            mappedIdx = obj.accessOrder(idx);
        end

        function obj = updateAccessOnAdd(obj, nb)
            % update the access order with the boundaries added.
            obj.nb = obj.nb + nb;
            obj.accessOrder = horzcat(obj.accessOrder, zeros(1,nb));
            for i = 0:nb-1
                obj.accessOrder(obj.nb-i) = obj.nb - i;
            end
            % no longer sorted
            obj.issorted = false;
        end

        function obj = updateAccessOnRemove(obj, idx, nb)
            % removing 1 by 1 is expensive, treat the input idx as a vector
            % and remove those indices.

            % remove the boundaries specified by the index
            obj.nb = obj.nb - coder.internal.indexInt(nb);
            obj.accessOrder(idx) = [];

            % get the sorted index for the remaining elements
            remainIdx = coder.internal.sortIdx(obj.accessOrder, 'a');
            assert(numel(remainIdx) == obj.nb)

            for i = 1:obj.nb
                % Assign the new mapping
                obj.accessOrder(remainIdx(i)) = i;
            end
        end

        % function obj = updateAccessOnRemove(obj, idx, nb)
        %     % removing 1 by 1 is expensive, treat the input idx as a vector
        %     % and remove those indices.
        % 
        %     % remove the boundaries specified by the index
        %     obj.nb = obj.nb - coder.internal.indexInt(nb);
        %     tempAccessOrder = coder.nullcopy(zeros(1, obj.nb, coder.internal.indexIntClass));
        % 
        %     j = coder.internal.indexInt(1);
        %     k = coder.internal.indexInt(1);
        %     for i = 1:numel(obj.accessOrder)
        %         if idx(k) == i
        %             k = k + 1;
        %         else
        %             tempAccessOrder(j) = obj.accessOrder(i);
        %             j = j + 1;
        %         end
        %     end
        %     obj.accessOrder = tempAccessOrder;
        % 
        %     % get the sorted index for the remaining elements
        %     remainIdx = coder.internal.sortIdx(obj.accessOrder, 'a');
        %     assert(numel(remainIdx) == obj.nb)
        % 
        %     for i = 1:obj.nb
        %         % Assign the new mapping
        %         obj.accessOrder(remainIdx(i)) = i;
        %     end
        % end


        function [issorted, cri, dir, refPt] = getProps(obj)
            issorted = obj.issorted;
            cri = obj.cri;
            dir = obj.dir;
            refPt = obj.refPt;
        end

        function obj = resortAfterRmsliver(obj, bndObj)
            obj = sortBoundaries(obj, bndObj, obj.dir, obj.criterion, obj.refPt);
        end

        acObj = sortBoundaries(acObj, bndObj, dir, criterion, refPoint)
    end
end