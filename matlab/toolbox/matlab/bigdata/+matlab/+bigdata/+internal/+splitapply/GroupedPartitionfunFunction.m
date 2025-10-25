%GroupedPartitionfunFunction
% An object that obeys the feval contract and performs the grouped version
% of the partitionfun call.
%
% This is the implementation of partitionfun on grouped data. This applies
% the partitionfun contract per group:
%
%  1. For each group chunk, this invokes the partitionfun function with
%  info specific to that group. For example, relative index from the start
%  of the partition, counted in slices of that one group.
%
%  2. This will continue to invoke the partitionfun function for a given
%  group until that group returns isFinished true.
%
% Note, not every group will see every partition. If any given group has no
% data in a given partition, this will not invoke the partitionfun function
% for that combination of group and partition.
%
% This works by holding state per group. Each state is used and updated
% every time we see a group corresponding with it. If a group is not
% finished by the end, we use the state to derive empty input and continue
% until that group is done.
%


%   Copyright 2016-2024 The MathWorks, Inc.

classdef (Sealed) GroupedPartitionfunFunction < handle & matlab.mixin.Copyable
    properties (SetAccess = immutable)
        % The underlying FunctionHandle object to be called per group per
        % collection of chunks in partition. This is held separate from the
        % ones actually used because we need to make copies of it in
        % initial state.
        UnderlyingFunction;
    end
    
    properties (Access = private, Transient)
        % The set of currently known keys.
        Keys = zeros(0, 1);
        
        % A vector of relative indices into the partition for each group.
        RelativeIndices;
        
        % A cell array of copies of the underlying function handle, one per
        % group, allowed to hold state relevant to that one group.
        GroupFunctions = {}
        
        % A NumKeys x NumInputs cell array of empty input blocks. This
        % exists to allow continued evaluation of partitionfun function
        % after there is no more input until isFinished returns true.
        GroupEmptyInputPlaceholder = {};
        
        % A vector of logicals that specifies whether each group is
        % finished.
        IsGroupFinished;
    end
    
    properties (Access = private, Transient)
        % The underlying GroupedFunction object that applies the actual
        % grouped invocation behavior. This invokes obj/fevalOneGroup once
        % per group with all of the input for that group. This is
        % intialized lazily to avoid complications when this object is
        % copied.
        ImplFunction;
    end
    
    methods (Static)
        % Construct a FunctionHandle containing a
        % GroupedPartitionfunFunction from a FunctionHandle. This requires
        % to be given a logical vector of whether each input is expected to
        % have broadcast partitioning.
        function fcn = create(fcnHandle)
            import matlab.bigdata.internal.FunctionHandle;
            import matlab.bigdata.internal.splitapply.GroupedPartitionfunFunction;
            obj = GroupedPartitionfunFunction(fcnHandle);
            fcn = FunctionHandle(obj);
        end
    end
    methods
        %FEVAL Call the function handle. This is expected to be called by a
        %partitionfun that has no knowledge of the fact that groups exist.
        function [isFinished, keys, counts, varargout] = feval(obj, info, keys, counts, varargin)
            if info.IsLastChunk && isempty(keys)
                [isFinished, keys, counts, varargout{1 : nargout - 3}] = fevalEmptyBlock(obj, info, keys, counts, varargin{:});
            else
                [isFinished, keys, counts, varargout{1 : nargout - 3}] = fevalNormalBlock(obj, info, keys, counts, varargin{:});
            end
        end
    end
    
    methods (Access = private)
        % Private constructor for the create method.
        function obj = GroupedPartitionfunFunction(fcnHandle)
            assert(isa(fcnHandle, 'matlab.bigdata.internal.FunctionHandle'), ...
                'Assertion failed: GroupedPartitionfunFunction was given something not a function handle');
            obj.UnderlyingFunction = fcnHandle;
        end
        
        % Implementation of feval when there exists more data.
        function [isFinished, keys, counts, varargout] = fevalNormalBlock(obj, info, keys, counts, varargin)
            import matlab.bigdata.internal.BroadcastArray;
            import matlab.bigdata.internal.util.indexSlices;
            % We need to initialize state per group for each group that
            % we've not seen before. In addition, we need to be able to map
            % keys back to input offset to derive the empty placeholders.
            newKeys = keys;
            if isa(newKeys, 'matlab.bigdata.internal.splitapply.GroupedBroadcast')
                newKeys = keys.Keys;
            end
            [newKeys, keyToIdxMap] = unique(newKeys);
            if isempty(obj.Keys)
                % All groups in the first chunk are new.
                obj.Keys = newKeys;
            else
                % Otherwise append new keys onto existing ones. We have to
                % filter non-new keys from the map.
                [obj.Keys, ~, newIdx] = union(obj.Keys, newKeys, 'rows', 'stable');
                keyToIdxMap = keyToIdxMap(newIdx);
            end
            if ~isempty(keyToIdxMap)
                % Initialize state for newly seen groups.
                numKeys = numel(obj.Keys);
                obj.IsGroupFinished(end + 1 : numKeys) = false;
                obj.RelativeIndices(end + 1 : numKeys) = 1;
                obj.GroupFunctions(end + 1 : numKeys) = {[]};
                obj.GroupEmptyInputPlaceholder(end + 1 : numKeys, :) = {[]};
                numNewKeys = numel(keyToIdxMap);
                newKeyBase = numKeys - numNewKeys;
                gropedInputIndices = find(cellfun(@iscell, varargin));
                for newKeyIdx = 1 : numNewKeys
                    fcnCopy = copy(obj.UnderlyingFunction);
                    obj.GroupFunctions{newKeyBase + newKeyIdx} = fcnCopy.Handle;
                    for inputIdx = gropedInputIndices
                        if iscell(varargin{inputIdx})
                            obj.GroupEmptyInputPlaceholder{newKeyBase + newKeyIdx, inputIdx} ...
                                = indexSlices(varargin{inputIdx}{keyToIdxMap(newKeyIdx)}, []);
                        end
                    end
                end
            end
            
            if isempty(obj.ImplFunction)
                obj.initializeImplFunction();
            end
            
            % For each key, also pass the index into obj.Keys alongside.
            % This is used later to retrieve partition-wide metadata about
            % the corresponding group.
            % If keys is a GroupedBroadcast, keyIndices must be a
            % GroupedBroadcast as well.
            if isa(keys, 'matlab.bigdata.internal.splitapply.GroupedBroadcast')
                [~, keyIndices] = ismember(keys.Keys, obj.Keys);
                keyIndices = num2cell(keyIndices);
                keyIndices = matlab.bigdata.internal.splitapply.GroupedBroadcast(keys.Keys, keyIndices);
            else
                [~, keyIndices] = ismember(keys, obj.Keys);
                keyIndices = num2cell(keyIndices);
            end
            % obj is passed in a cell because function_handle is inferior
            % to this class.
            [keys, counts, varargout{1 : nargout - 3}] = feval(...
                obj.ImplFunction, keys, counts,...
                keyIndices,...
                BroadcastArray(info), ...
                varargin{:});
            
            isFinished = info.IsLastChunk && all(obj.IsGroupFinished);
        end
        
        % Implementation of feval when there does not exist any more data.
        % This invokes the partitionfun function on all groups that have
        % not yet finished. This is necessary in-case a given group has not
        % yet had the opportunity to emit it's output.
        function [isFinished, keys, counts, varargout] = fevalEmptyBlock(obj, outerInfo, ~, ~, varargin)
            
            isGroupFinished = obj.IsGroupFinished;
            keys = obj.Keys(~isGroupFinished, :);
            counts = zeros(size(keys));
            if any(~isGroupFinished)
                isChunkedInput = cellfun(@iscell, varargin);
                empties = obj.GroupEmptyInputPlaceholder(~isGroupFinished, isChunkedInput);
                varargin(isChunkedInput) = num2cell(empties, 1);
            end
            [isFinished, keys, counts, varargout{1:nargout-3}] = fevalNormalBlock(obj, outerInfo, keys, counts, varargin{:});
        end
        
        % Invoke the underlying function for one specific group. This is
        % invoked by ImplFunction with the following inputs:
        %  - keyIndex: The index into obj.Keys that represents the current
        %              groups key.
        %  - outerInfo: The info struct passed to GroupedPartitionfunFunction
        %               by LazyPartitionedArray/partitionfun.
        %  - varargin: The input data associated with the current group.
        %              All group related concepts will be unwraped.
        function varargout = fevalOneGroup(obj, keyIndex, outerInfo, varargin)
            import matlab.bigdata.internal.lazyeval.determineNumSlices;
            numSlices = determineNumSlices(varargin{:});
            outerInfo = outerInfo.Value;
            info = obj.createInfoStruct(keyIndex, outerInfo);
            [obj.IsGroupFinished(keyIndex), varargout{1:nargout}] = feval(obj.GroupFunctions{keyIndex}, info, varargin{:});
            obj.RelativeIndices(keyIndex) = obj.RelativeIndices(keyIndex) + numSlices;
        end
        
        % Initialize the ImplFunction property.
        function initializeImplFunction(obj)
            import matlab.bigdata.internal.splitapply.GroupedFunction;
            % We use a weak reference as this function handle references
            % back to this object. As this function handle is owned soley
            % by this object (I.E. cannot outlive it), we can safely assume
            % weakObj.Handle is always valid here.
            weakObj = matlab.lang.WeakReference(obj);
            fcnHandle = @(varargin) fevalOneGroup(weakObj.Handle, varargin{:});
            fcnHandle = obj.UnderlyingFunction.copyWithNewHandle(fcnHandle);
            fcnHandle = GroupedFunction.wrap(fcnHandle);
            obj.ImplFunction = fcnHandle.Handle;
        end
        
        % Helper function that creates the info struct for one group.
        function info = createInfoStruct(obj, keyIndex, outerInfo)
            info = struct(...
                'PartitionId', outerInfo.PartitionId, ...
                'NumPartitions', outerInfo.NumPartitions, ...
                'RelativeIndexInPartition', obj.RelativeIndices(keyIndex), ...
                'IsLastChunk', outerInfo.IsLastChunk);
        end
    end
    
    methods (Access = protected)
        function obj = copyElement(obj)
            % Perform a deep copy of this object and everything underlying
            % it.
            import matlab.bigdata.internal.splitapply.GroupedPartitionfunFunction
            obj = GroupedPartitionfunFunction(copy(obj.UnderlyingFunction));
        end
    end
end
