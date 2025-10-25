%MapReducerStackNode
% Helper class that represents a stack position in the list of weak
% references to MapReducers

%   Copyright 2014-2024 The MathWorks, Inc.

classdef (Sealed) MapReducerStackNode < handle
    properties (WeakHandle, SetAccess = private)
        % The next node in this doubly-linked list. This is a weak
        % reference as this MapReducerStackNode lifetime is tied to the
        % MapReducer/MapReducerManager that owns it.
        Next (1, 1) matlab.mapreduce.internal.MapReducerStackNode ...
            = matlab.lang.invalidHandle("matlab.mapreduce.internal.MapReducerStackNode")

        % The previous node in this doubly-linked list. This is a weak
        % reference as this MapReducerStackNode lifetime is tied to the
        % MapReducer/MapReducerManager that owns it.
        Prev (1, 1) matlab.mapreduce.internal.MapReducerStackNode ...
            = matlab.lang.invalidHandle("matlab.mapreduce.internal.MapReducerStackNode")

        % The MapReducer corresponding with this node. This is a weak
        % handle to avoid the cyclic references between this node and this
        % MapReducer who is its owner as far as lifecycle is concerned.
        MapReducer (1, 1) matlab.mapreduce.MapReducer ...
            = matlab.mapreduce.internal.makeInvalidMapReducer();
    end

    properties (Constant)
        % An invalid node for setting Next and Prev back to unset.
        InvalidNode = matlab.lang.invalidHandle("matlab.mapreduce.internal.MapReducerStackNode")
    end
    
    methods
        % Insert this node after the given node in the list.
        function insertAfter(obj, node)
            validateattributes(node, {'matlab.mapreduce.internal.MapReducerStackNode'}, {'scalar'});
            obj.removeFromList();
            
            obj.Next = node.Next;
            if isvalid(obj.Next)
                obj.Next.Prev = obj;
            end
            
            node.Next = obj;
            obj.Prev = node;
        end
        
        % Remove this node from the list of all MapReducer stack nodes.
        function removeFromList(obj)
            next = obj.Next;
            prev = obj.Prev;
            
            obj.Next = obj.InvalidNode;
            obj.Prev = obj.InvalidNode;
            if isvalid(next)
                next.Prev = prev;
            end
            if isvalid(prev)
                prev.Next = next;
            end            
        end
        
        function delete(obj)
            removeFromList(obj);
        end
    end
    
    methods (Access = {?matlab.mapreduce.MapReducer, ?matlab.mapreduce.internal.MapReducerManager})
        % Private constructor for MapReducer and MapReducerManager to
        % construct node instances as necessary.
        function obj = MapReducerStackNode(mapReducer)
            if nargin >= 1
                obj.MapReducer = mapReducer;
            end
        end
    end
end
