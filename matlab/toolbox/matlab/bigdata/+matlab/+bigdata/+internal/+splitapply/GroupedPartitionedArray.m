%GroupedPartitionedArray
% An implementation of the PartitionedArray API that represents an
% collection of partitioned groups. Every method of this class
% applies its logic per group.
%
% In the absence of reduced values, all pure
% chunkwise / slicewise / elementwise operations are the same. The funfun
% methods that are supported but differ from LazyPartitionedArray:
%  - reducefun is applied to each group separately
%  - aggregatefun is applied to each group separately
%  - partitionfun is applied to each group separately, with an info struct per group
%
% The following funfun methods are not supported:
%  - gather
%  - reducebykeyfun
%  - aggregatebykeyfun
%
% In the presence of reduced values, such as mean(x - mean(x)), all funfun
% methods map the reduced scalar back to the group. This means that the
% output per group of reducefun/aggregatefun is passed per group if passed
% as an input to other funfun methods.
%
% This uses a modified format of how data is stored. The tall data is
% stored as tuples of the form: <KEY, COUNT, VALUE>, where:
%  * KEY is the identity of the group. It is an integer in the range 0 : N
%  * COUNT is the number of slices inside of VALUE.
%  * VALUE is a cell of slices of the actual data belonging to the group.
% This storage is used for efficiency, it means we can avoid having to
% split the data on each and every operation.

%   Copyright 2016-2023 The MathWorks, Inc.

classdef (InferiorClasses = { ...
        ?matlab.bigdata.internal.BroadcastArray, ...
        ?matlab.bigdata.internal.FunctionHandle, ...
        ?matlab.bigdata.internal.LocalArray, ...
        ?matlab.bigdata.internal.PartitionedArray, ...
        ?matlab.bigdata.internal.PartitionMetadata, ...
        ?matlab.bigdata.internal.PartitionedArrayOptions, ...
        ?matlab.bigdata.internal.lazyeval.LazyPartitionedArray}) ...
        GroupedPartitionedArray < matlab.bigdata.internal.PartitionedArray
    
    properties (GetAccess = private, SetAccess = immutable)
        % A LazyPartitionedArray of group keys. This defines the identity
        % of each group.
        Keys;
        
        % A LazyPartitionedArray of group counts. This defines the number 
        % slice in each group. This is held so we can explicitly check for
        % incompatible heights of tall grouped arrays.
        Counts;
        
        % A LazyPartitionedArray of grouped data. Each element is a cell
        % containing a number of slices belonging to a single group.
        Values;
        
        % A logical scalar that is true if this array is guaranteed to
        % consist of a single partition that is small enough to be
        % equivalent to a single chunk.
        %
        % If this property is true and there exists exactly one slice per
        % group in the underlying data, the underlying data will be held as
        % a scalar GroupedBroadcast. This is to allow singleton expansion
        % per group.
        IsGuaranteedSingleChunk;
        
        % Logical scalar that is true if this array has been sorted by key.
        IsSortedByGroupKey;
    end
    
    properties (SetAccess = immutable)
        % The GroupedPartitionedArraySession object that specifies when
        % this array is valid.
        Session;
    end
    
    properties (SetAccess = private, Dependent)
        % A logical scalar that specifies whether this array is still
        % valid.
        IsValid;
        
        % The underlying object that controls how this array is
        % partitioned.
        PartitionMetadata;
        
        % The underlying execution environment backing this partitioned
        % array.
        Executor;
    end
    
    methods (Hidden)
        % We cannot currently store metadata in a grouped array. The
        % metadata is normally attached to the underlying op tree, which
        % doesn't know about the fact the data is actually grouped in cell
        % arrays. When we want metadata for grouped data, we should look at
        % creating a GroupedMetadata decorator to wrap the object passed
        % into this method.
        function hSetMetadata(~, ~)
        end
        function metadata = hGetMetadata(~)
            metadata = [];
        end
    end

    methods (Static)
        % Create an array of GroupedPartitionedArray that share the same
        % session and <keys, counts> pairs..
        function varargout = create(keys, session, varargin)
            import matlab.bigdata.internal.splitapply.GroupedPartitionedArray;
            assert(nargout == numel(varargin), ...
                'Assertion failed; Nargout must match number of input data partitioned arrays.');
            opts = matlab.bigdata.internal.PartitionedArrayOptions;
            opts.PassTaggedInputs = true;
            [keys, counts, varargout{1:nargout}] = chunkfun(opts, @iSplitChunk, keys, varargin{:});
            for ii = 1:numel(varargout)
                % We cannot guarantee the input contains only a single chunk.
                % Due to this, singleton expansion will not apply to this
                % array if it is actually one slice per group. That is
                % fine, as for splitapply, all inputs must have the same
                % length, groups and partitioning.
                isGuaranteedSingleChunk = false;
                isSortedByGroup = false;
                varargout{ii} = GroupedPartitionedArray(keys, counts, ...
                    varargout{ii}, session, isGuaranteedSingleChunk, isSortedByGroup);
            end
        end
    end
    
    methods
        function out = getKeys(obj)
            % Get the keys underlying a GroupedPartitionedArray as another
            % GroupedPartitionedArray. This will contain one key per group
            % per block.
            [values, counts] = elementfun(@iGetKeys, obj.Keys);
            out = matlab.bigdata.internal.splitapply.GroupedPartitionedArray(...
                obj.Keys, counts, values, obj.Session,obj.IsGuaranteedSingleChunk, obj.IsSortedByGroupKey);
        end
        
        function obj = sortGroups(obj)
            % Sorts the underlying array of groups by group key. This is
            % an all-to-all communication. For each group, all data
            % belonging to that group is guaranteed to exist in a single
            % partition.
            
            if obj.IsSortedByGroupKey
                return;
            end
            
            tuples = chunkfun(@(k,c,v) table(k,c,v,'VariableNames',{'Key','Count','Value'}), obj.Keys, obj.Counts, obj.Values);
            
            if obj.IsGuaranteedSingleChunk
                % If everything is already in a single chunk/block, we
                % don't require sort between blocks.
                tuples = clientfun(@iSortTupleByGroup, tuples);
            else
                % Otherwise we do need sort between blocks.
                tuples = matlab.bigdata.internal.lazyeval.sortSlices(tuples, ...
                    @iSortTupleByGroup, @iPartitionTupleByGroupKey, ...
                    'IsSorted', iAreGroupsSorted(obj.Keys), ...
                    'OtherPartitionFcnInputs', {obj.Session.NumGroups});
            end
            
            [keys, counts, values] = chunkfun(@(t) deal(t.(1), t.(2), t.(3)), tuples);
            isSortedByGroup = true;
            obj = matlab.bigdata.internal.splitapply.GroupedPartitionedArray(...
                    keys, counts, values, obj.Session, obj.IsGuaranteedSingleChunk, isSortedByGroup);
        end
        
        function [keys, values] = ungroup(obj, empty, varargin)
            % Unwrap a GroupedPartitionedArray into a pair of underlying
            % PartitionedArray objects. These contain a flat array of keys
            % and a flat array of slices.
            %
            % This must provide an empty that is used for partitions
            % containing zero groups. That empty is allowed to be
            % UnknownEmptyArray if type/size is not known.
            
            keepGroupedBroadcasts = false;
            if nargin > 2
                p = inputParser;
                p.addParameter('KeepGroupedBroadcasts', false);
                p.parse(varargin{:});
                keepGroupedBroadcasts = p.Results.KeepGroupedBroadcasts;
            end
            
            assert(~isa(empty, 'matlab.bigdata.internal.PartitionedArray'), ...
                'Assertion Failed: Input argument empty must be an in-memory array.');
            fh = matlab.bigdata.internal.util.StatefulFunction(@iJoinGroups, empty);
            fh = matlab.bigdata.internal.FunctionHandle(fh);
            [keys, values] = chunkfun(fh, obj.Keys, obj.Counts, obj.Values, keepGroupedBroadcasts);
        end
    end
    
    methods (Access = private)
        % A private constructor for the static create method.
        function obj = GroupedPartitionedArray(keys, counts, values, ...
                session, isGuaranteedSingleChunk, isSortedByGroup)
            obj.Keys = keys;
            obj.Counts = counts;
            obj.Values = values;
            obj.Session = session;
            obj.IsGuaranteedSingleChunk = isGuaranteedSingleChunk;
            obj.IsSortedByGroupKey = isSortedByGroup;
        end
    end
    
    % Overrides of the PartitionedArray interface.
    methods
        %GATHER Return the underlying data for one or more PartitionedArray instances.
        function varargout = gather(varargin) %#ok<STOUT>
            [~, ~, ~, session, ~] = iParseInputs(varargin{:});
            funStr = func2str(session.FunctionHandle);
            matlab.bigdata.internal.throw(message('MATLAB:bigdata:array:SplitApplyOperationNotSupported', funStr));
        end
        
        %CLIENTFOREACH Stream data back to the client MATLAB Context and
        % perform an action per chunk inside the client MATLAB Context.
        function varargout = clientforeach(~, ~, varargin) %#ok<STOUT>
            [~, ~, ~, session, ~] = iParseInputs(varargin{:});
            funStr = func2str(session.FunctionHandle);
            matlab.bigdata.internal.throw(message('MATLAB:bigdata:array:SplitApplyOperationNotSupported', funStr));
        end
        
        %ELEMENTFUN Apply an element-wise function handle that preserves size in all dimensions to the underlying data.
        function varargout = elementfun(options, functionHandle, varargin)
            [options, functionHandle, inputs] = ...
                matlab.bigdata.internal.util.stripOptions(options, functionHandle, varargin{:});
            [options, passTaggedInputs] = iParseOptions(options);
            [inputs, keys, counts, session, isSingleChunk, isSortedByGroup] = iParseInputs(inputs{:});
            [keys, counts] = iSlicewiseMergeKeys(keys, counts);
            functionHandle = iCreateKeyedFunctionHandle(functionHandle, passTaggedInputs);
            [~, ~, varargout{1:nargout}] = chunkfun(options, functionHandle, keys, counts, inputs{:});
            varargout = iWrapOutput(varargout, keys, counts, session, isSingleChunk, isSortedByGroup);
        end

        %ASSERTADAPTORCORRECT Acts like elementfun and checks each element with the metadata in the adaptor.
        function varargout = assertAdaptorCorrect(options, functionHandle, varargin)
            [options, functionHandle, inputs] = ...
                matlab.bigdata.internal.util.stripOptions(options, functionHandle, varargin{:});
            [options, passTaggedInputs] = iParseOptions(options);
            [inputs, keys, counts, session, isSingleChunk, isSortedByGroup] = iParseInputs(inputs{:});
            [keys, counts] = iSlicewiseMergeKeys(keys, counts);
            functionHandle = iCreateKeyedFunctionHandle(functionHandle, passTaggedInputs);
            [~, ~, varargout{1:nargout}] = assertAdaptorCorrect(options, functionHandle, keys, counts, inputs{:});
            varargout = iWrapOutput(varargout, keys, counts, session, isSingleChunk, isSortedByGroup);
        end

        %SMALLTALLCOMPARISON Apply an element-wise comparator with an in-memory scalar operand.
        function varargout = smallTallComparison(options, functionHandle, smallOperand, isTallFirst, varargin)
            % Defined for tabular row-indexing optimization from read.
            [options, functionHandle, smallOperand, isTallFirst, inputs] = ...
                matlab.bigdata.internal.util.stripOptions(options, functionHandle, smallOperand, isTallFirst, varargin{:});
            [options, passTaggedInputs] = iParseOptions(options);
            [inputs, keys, counts, session, isSingleChunk, isSortedByGroup] = iParseInputs(inputs{:});
            [keys, counts] = iSlicewiseMergeKeys(keys, counts);
            functionHandle = iCreateKeyedFunctionHandle(functionHandle, passTaggedInputs);
            [~, ~, varargout{1:nargout}] = smallTallComparison(options, functionHandle, smallOperand, isTallFirst, keys, counts, inputs{:});
            varargout = iWrapOutput(varargout, keys, counts, session, isSingleChunk, isSortedByGroup);
        end

        %LOGICALELEMENTFUN Apply an element-wise logical operator that behaves as elementfun.
        function varargout = logicalElementfun(options, functionHandle, varargin)
            % Defined for tabular row-indexing optimization from read.
            [options, functionHandle, inputs] = ...
                matlab.bigdata.internal.util.stripOptions(options, functionHandle, varargin{:});
            [options, passTaggedInputs] = iParseOptions(options);
            [inputs, keys, counts, session, isSingleChunk, isSortedByGroup] = iParseInputs(inputs{:});
            [keys, counts] = iSlicewiseMergeKeys(keys, counts);
            functionHandle = iCreateKeyedFunctionHandle(functionHandle, passTaggedInputs);
            [~, ~, varargout{1:nargout}] = logicalElementfun(options, functionHandle, keys, counts, inputs{:});
            varargout = iWrapOutput(varargout, keys, counts, session, isSingleChunk, isSortedByGroup);
        end
        
        %SLICEFUN Apply a given slice-wise function handle that preserves size in the tall dimension to the underlying data.
        function varargout = slicefun(options, functionHandle, varargin)
            [options, functionHandle, inputs] = ...
                matlab.bigdata.internal.util.stripOptions(options, functionHandle, varargin{:});
            [options, passTaggedInputs] = iParseOptions(options);
            [inputs, keys, counts, session, isSingleChunk, isSortedByGroup] = iParseInputs(inputs{:});
            [keys, counts] = iSlicewiseMergeKeys(keys, counts);
            functionHandle = iCreateKeyedFunctionHandle(functionHandle, passTaggedInputs);
            [~, ~, varargout{1:nargout}] = chunkfun(options, functionHandle, keys, counts, inputs{:});
            varargout = iWrapOutput(varargout, keys, counts, session, isSingleChunk, isSortedByGroup);
        end
        
        % SUBSREFTABULARVAR Extract given table variables from a PartitionedArray
        function varargout = subsrefTabularVar(subsrefType, subs, ~, varargin)
            [inputs, keys, counts, session, isSingleChunk, isSortedByGroup] = iParseInputs(varargin{:});
            [keys, counts] = iSlicewiseMergeKeys(keys, counts);
            [~, ~, varargout{1:nargout}] = subsrefTabularVar(subsrefType, subs, true, keys, counts, inputs{:});
            varargout = iWrapOutput(varargout, keys, counts, session, isSingleChunk, isSortedByGroup);
        end
        
        %FILTERSLICES Remove slices from one or more PartitionedArray using a PartitionedArray column vector of logical values.
        function varargout = filterslices(varargin)
            [varargout{1 : nargout}] = chunkfun(@iFilter, varargin{:});
        end

        %LOGICALROWSUBSREF Remove slices from one or more PartitionedArray using a PartitionedArray column vector of logical values.
        function varargout = logicalRowSubsref(varargin)
            % Special primitive for row-indexing optimization from Read on
            % PartitionedArrays. A GroupedPartitionedArray can't be
            % directly created from a datastore, so this optimization won't
            % be available. We use the same operation as filterslices
            % because it's already optimized for splitapply-based
            % workflows.
            [varargout{1 : nargout}] = chunkfun(@iFilter, varargin{:});
        end
        
        %VERTCATPARTITIONS Vertically concatenate the list of partitions for each input.
        function out = vertcatpartitions(varargin) %#ok<STOUT>
            [~, ~, ~, session, ~] = iParseInputs(varargin{:});
            funStr = func2str(session.FunctionHandle);
            matlab.bigdata.internal.throw(message('MATLAB:bigdata:array:SplitApplyOperationNotSupported', funStr));
        end
        
        %REDUCEFUN Perform a reduction of the underlying data.
        function varargout = reducefun(options, functionHandle, varargin)
            [options, functionHandle, inputs] = ...
                matlab.bigdata.internal.util.stripOptions(options, functionHandle, varargin{:});
            [varargout{1:nargout}] = aggregatefun(options, functionHandle, functionHandle, inputs{:});
        end
        
        %AGGREGATEFUN Perform a reduction of the underlying data that includes an initial transformation step.
        function varargout = aggregatefun(options, initialFunctionHandle, reduceFunctionHandle, varargin)
            [options, initialFunctionHandle, reduceFunctionHandle, inputs] = ...
                matlab.bigdata.internal.util.stripOptions(options, initialFunctionHandle, reduceFunctionHandle, varargin{:});
            [options, passTaggedInputs] = iParseOptions(options);
            [inputs, keys, counts, session] = iParseInputs(inputs{:});
            [keys, counts] = iSlicewiseMergeKeys(keys, counts);
            initialFunctionHandle = iCreateKeyedFunctionHandle(initialFunctionHandle, passTaggedInputs);
            reduceFunctionHandle = iCreateKeyedFunctionHandle(reduceFunctionHandle, passTaggedInputs);
            [keys, counts, varargout{1:nargout}] = aggregatefun(options, initialFunctionHandle, reduceFunctionHandle, keys, counts, inputs{:});
            [keys, counts, varargout{:}] = clientfun(@iGroupBroadcastIfSingletonPerGroup, keys, counts, varargout{:});
            isSingleChunk = true;
            isSortedByGroup = true;
            varargout = iWrapOutput(varargout, keys, counts, session, isSingleChunk, isSortedByGroup);
        end
        
        %REDUCEBYKEYFUN For each unique key, perform a reducefun reduction of all of the data associated with that key.
        function [keys, counts, varargout] = reducebykeyfun(options, functionHandle, keys, counts, varargin) %#ok<STOUT>
            [~, ~, keys, counts, inputs] = ...
                matlab.bigdata.internal.util.stripOptions(options, functionHandle, keys, counts, varargin{:});
            [~, ~, ~, session, ~] = iParseInputs(keys, counts, inputs{:});
            funStr = func2str(session.FunctionHandle);
            matlab.bigdata.internal.throw(message('MATLAB:bigdata:array:SplitApplyOperationNotSupported', funStr));
        end
        
        %AGGREGATEBYKEYFUN For each unique key, perform a aggregatefun reduction of all of the data associated with that key.
        function [keys, counts, varargout] = aggregatebykeyfun(options, initialFunctionHandle, reduceFunctionHandle, keys, counts, varargin) %#ok<STOUT>
            [~, ~, ~, keys, counts, inputs] = ...
                matlab.bigdata.internal.util.stripOptions(options, initialFunctionHandle, reduceFunctionHandle, keys, counts, varargin{:});
            [~, ~, ~, session, ~] = iParseInputs(keys, counts, inputs{:});
            funStr = func2str(session.FunctionHandle);
            matlab.bigdata.internal.throw(message('MATLAB:bigdata:array:SplitApplyOperationNotSupported', funStr));
        end
        
        %JOINBYKEY Perform an inner join of two sets of PartitionedArray instances using keys, counts common to both.
        function [keys, counts, varargout] = joinbykey(xKeys, x, yKeys, y) %#ok<STOUT,INUSD>
            assert(false, 'The method PartitionedArray/joinbykey is currently not supported.');
        end
        
        %TERNARYFUN Select between one of two input arrays based on a deferred scalar logical input.
        function  out = ternaryfun(condition, ifTrue, ifFalse)
            out = chunkfun(@iTernary, condition, ifTrue, ifFalse);
        end
        
        %RESIZECHUNKS Resize chunks so they are bigger than a minimum size
        % of 1 MB.
        function  varargout = resizechunks(varargin) %#ok<STOUT>
            [~, ~, ~, session, ~] = iParseInputs(varargin{:});
            funStr = func2str(session.FunctionHandle);
            matlab.bigdata.internal.throw(message('MATLAB:bigdata:array:SplitApplyOperationNotSupported', funStr));
        end
        
        %CHUNKFUN Apply a given chunk-wise function handle to the underlying data.
        function varargout = chunkfun(options, functionHandle, varargin)
            [options, functionHandle, inputs] = ...
                matlab.bigdata.internal.util.stripOptions(options, functionHandle, varargin{:});
            [options, passTaggedInputs] = iParseOptions(options);
            [inputs, keys, counts, session, isSingleChunk, isSortedByGroup] = iParseInputs(inputs{:});
            [keys, counts] = iSlicewiseMergeKeys(keys, counts);
            functionHandle = iCreateKeyedFunctionHandle(functionHandle, passTaggedInputs, isSingleChunk);
            [keys, counts, varargout{1:nargout}] = chunkfun(options, functionHandle, keys, counts, inputs{:});
            varargout = iWrapOutput(varargout, keys, counts, session, isSingleChunk, isSortedByGroup);
        end
        
        % FIXEDCHUNKFUN Perform a chunkfun operation that ensures all
        % chunks of a partition except the last are of a required size.
        function varargout = fixedchunkfun(options, numSlicesPerChunk, functionHandle, varargin)
            [options, functionHandle, inputs] = ...
                matlab.bigdata.internal.util.stripOptions(options, functionHandle, varargin{:});
            [options, passTaggedInputs] = iParseOptions(options);
            [inputs, keys, counts, session, ~, isSortedByGroup] = iParseInputs(inputs{:});
            [keys, counts] = iSlicewiseMergeKeys(keys, counts);
            functionHandle = iCreateKeyedFunctionHandle(functionHandle, passTaggedInputs);
            [keys, counts, varargout{1:nargout}] = fixedchunkfun(options, numSlicesPerChunk, functionHandle, keys, counts, inputs{:});
            isSingleChunk = false;
            varargout = iWrapOutput(varargout, keys, counts, session, isSingleChunk, isSortedByGroup);
        end
        
        %PARTITIONFUN For each partition, apply a function handle to all of the underlying data for the partition.
        function varargout = partitionfun(options, functionHandle, varargin)
            [options, functionHandle, inputs] = ...
                matlab.bigdata.internal.util.stripOptions(options, functionHandle, varargin{:});
            [options, passTaggedInputs] = iParseOptions(options);
            [inputs, keys, counts, session] = iParseInputs(inputs{:});
            [keys, counts] = iSlicewiseMergeKeys(keys, counts);
            functionHandle = iCreateKeyedPartitionfunFunction(functionHandle, passTaggedInputs);
            [keys, counts, varargout{1:nargout}] = partitionfun(options, functionHandle, keys, counts, inputs{:});
            isAllGuaranteedSingleChunk = false;
            varargout = iWrapOutput(varargout, keys, counts, session, isAllGuaranteedSingleChunk);
        end
        
        %GENERALPARTITIONFUN For each partition, apply a function handle to
        % all of the underlying data for the partition with no assumption
        % of size of input.
        function varargout = generalpartitionfun(opts, fcn, varargin) %#ok<STOUT>
            [~, ~, inputs] = ...
                matlab.bigdata.internal.util.stripOptions(opts, fcn, varargin{:});
            [~, ~, ~, session, ~] = iParseInputs(partitionIndices, inputs{:});
            funStr = func2str(session.FunctionHandle);
            matlab.bigdata.internal.throw(message('MATLAB:bigdata:array:SplitApplyOperationNotSupported', funStr));
        end

        %ISPARTITIONINDEPENDENT Returns true if all underlying data is
        % independent of the partitioning of the array.
        function tf = isPartitionIndependent(varargin)
            tf = true;
            for ii = 1 : nargin
                tf = tf && isPartitionIndependent(varargin{ii}.Keys, varargin{ii}.Counts, varargin{ii}.Values);
            end
        end
        
        %MARKPARTITIONINDEPENDENT Mark that the data underlying a PartitionedArray
        % is independent of the partitioning of the PartitionedArray.
        function varargout = markPartitionIndependent(varargin)
            import matlab.bigdata.internal.splitapply.GroupedPartitionedArray;
            varargout = cell(size(varargin));
            for ii = 1:numel(varargin)
                [keys, counts, values] = markPartitionIndependent(...
                    varargin{ii}.Keys, varargin{ii}.Counts, varargin{ii}.Values);
                varargout{ii} = GroupedPartitionedArray(keys, counts, values, ...
                    varargin{ii}.Session, varargin{ii}.IsGuaranteedSingleChunk, varargin{ii}.IsSortedByGroupKey);
            end
            varargout = varargin;
        end
        
        %MARKFORREUSE Inform the Lazy Evaluation Framework that the given PartitionedArray will be reused multiple times.
        function markforreuse(varargin)
            for ii = 1:numel(varargin)
                if isa(varargin{ii}, 'matlab.bigdata.internal.splitapply.GroupedPartitionedArray')
                    markforreuse(varargin{ii}.Keys, varargin{ii}.Counts, varargin{ii}.Values);
                end
            end
        end
        
        %UPDATEFORREUSE Inform the Lazy Evaluation Framework that a
        % PartitionedArray should replace all cache entries of another.
        function updateforreuse(paOld, paNew)
            [~, ~, ~, session, ~] = iParseInputs(paOld, paNew);
            funStr = func2str(session.FunctionHandle);
            matlab.bigdata.internal.throw(message('MATLAB:bigdata:array:SplitApplyOperationNotSupported', funStr));
        end
        
        %ALIGNPARTITIONS Align the partitioning of one or more GroupedPartitionedArray instances.
        function [ref, varargout] = alignpartitions(ref, varargin) %#ok<STOUT>
            [~, ~, ~, session, ~] = iParseInputs(partitionIndices, varargin{:});
            funStr = func2str(session.FunctionHandle);
            matlab.bigdata.internal.throw(message('MATLAB:bigdata:array:SplitApplyOperationNotSupported', funStr));
        end
        
         %REPARTITION Repartition one or more GroupedPartitionedArray instances to a new partition strategy.
        function varargout = repartition(partitionMetadata, partitionIndices, varargin) %#ok<INUSL,STOUT>
            [~, ~, ~, session, ~] = iParseInputs(partitionIndices, varargin{:});
            funStr = func2str(session.FunctionHandle);
            matlab.bigdata.internal.throw(message('MATLAB:bigdata:array:SplitApplyOperationNotSupported', funStr));
        end
        
        %CLIENTFUN Apply a given function handle to the entirety underlying data in one call.
        function varargout = clientfun(options, functionHandle, varargin)
            import matlab.bigdata.internal.broadcast;
            [options, functionHandle, inputs] = ...
                matlab.bigdata.internal.util.stripOptions(options, functionHandle, varargin{:});
            [options, passTaggedInputs] = iParseOptions(options);
            for ii = 1:numel(inputs)
                inputs{ii} = broadcast(inputs{ii});
            end
            [inputs, keys, counts, session] = iParseInputs(inputs{:});
            % AdvancedGroupedFunction requires all input arguments to be
            % triplets of <keys,counts,values>.
            inputs = [keys(:)'; counts(:)'; inputs(:)'];
            isSingleChunk = true;
            isSortedByGroup = true;
            functionHandle = iCreateAdvancedKeyedFunctionHandle(functionHandle, passTaggedInputs, isSingleChunk);
            [out{1:3*nargout}] = clientfun(options, functionHandle, inputs{:});
            % AdvancedGroupedFunction emits all output as triplets of
            % <keys,counts,values>. We need to reroute each correctly.
            varargout = cell(1,nargout);
            for ii = 1 : nargout
                baseIdx = ii * 3 - 2;
                keys = out{baseIdx};
                counts = out{baseIdx + 1};
                values = out{baseIdx + 2};
                varargout(ii) = iWrapOutput({values}, keys, counts, session, isSingleChunk, isSortedByGroup);
            end
        end
        
        %INMEMORYFUN Apply a given function handle to all of the underlying
        % data per group
        %
        % TODO(g1814116): This is an alternative implementation of the
        % clientfun contract that distributes all data for a single group
        % to a worker, instead of the client. Both implementations exist as
        % broadcast from clientfun without loss of performance is complicated.
        % In the short term, the more advanced inmemoryfun is only used
        % if the output of splitapply can be as large as the input. For
        % example "splitapply(@(x) {x},..)".
        function varargout = inmemoryfun(options, functionHandle, varargin)
            [options, functionHandle, inputs] = ...
                matlab.bigdata.internal.util.stripOptions(options, functionHandle, varargin{:});
            [options, passTaggedInputs] = iParseOptions(options);
            for ii = 1:numel(inputs)
                if isa(inputs{ii}, 'matlab.bigdata.internal.splitapply.GroupedPartitionedArray')
                    inputs{ii} = sortAndMergeGroups(inputs{ii});
                end
            end
            [inputs, keys, counts, session, isSingleChunk] = iParseInputs(inputs{:});
            % Non-grouped Broadcasts have [] as keys/counts. We apply the
            % following workaround as chunkfun requires all inputs to be
            % same height or scalar. Any of these broadcasted empties are
            % ignored by the advanced keyed function implementation.
            keys(cellfun(@isempty, keys)) = {matlab.bigdata.internal.broadcast([])};
            counts(cellfun(@isempty, counts)) = {matlab.bigdata.internal.broadcast([])};
            % AdvancedGroupedFunction requires all input arguments to be
            % triplets of <keys,counts,values>.
            inputs = [keys(:)'; counts(:)'; inputs(:)'];
            functionHandle = iCreateAdvancedKeyedFunctionHandle(functionHandle, passTaggedInputs, isSingleChunk);
            [out{1:3*nargout}] = chunkfun(options, functionHandle, inputs{:});
            % AdvancedGroupedFunction emits all output as triplets of
            % <keys,counts,values>. We need to reroute each correctly.
            varargout = cell(1,nargout);
            for ii = 1 : nargout
                baseIdx = ii * 3 - 2;
                keys = out{baseIdx};
                counts = out{baseIdx + 1};
                values = out{baseIdx + 2};
                isSortedByGroup = true;
                varargout(ii) = iWrapOutput({values}, keys, counts, session, isSingleChunk, isSortedByGroup);
            end
        end
        
        % PARTITIONHEADFUN Apply a partition-wise function handle that only
        % requires the first few slices of each partition to generate the
        % complete output.
        %
        % The function handle must obey the same rules as for partitionfun.
        % On top of this, the framework will assume that full evaluation of
        % this operation is fast enough for preview.
        function varargout = partitionheadfun(functionHandle, varargin)
            [varargout{1:nargout}] = partitionfun(functionHandle, varargin{:});
        end
        
        % STRICTSLICEFUN Perform a slicefun operation that does not support
        % singleton expansion.
        function varargout = strictslicefun(options, functionHandle, varargin)
            [options, functionHandle, inputs] = ...
                matlab.bigdata.internal.util.stripOptions(options, functionHandle, varargin{:});
            [options, passTaggedInputs] = iParseOptions(options);
            [inputs, keys, counts, session, isSingleChunk, isSortedByGroup] = iParseInputs(inputs{:});
            [keys, counts] = iSlicewiseMergeKeys(keys, counts);
            functionHandle = iCreateKeyedFunctionHandle(functionHandle, passTaggedInputs);
            [keys, counts, varargout{1:nargout}] = strictslicefun(options, functionHandle, keys, counts, inputs{:});
            if isSingleChunk
                [keys, counts, varargout{:}] = clientfun(@iGroupBroadcastIfSingletonPerGroup, keys, counts, varargout{:});
            end
            varargout = iWrapOutput(varargout, keys, counts, session, isSingleChunk, isSortedByGroup);
        end
        
        %NUMPARTITIONS Get the number of partitions that will be used to
        %evaluate this partitioned array given no other restraints.
        function n = numpartitions(obj)
            n = numpartitions(obj.Values);
        end
        
        %GETEXECUTOR Get the underlying executor.
        function executor = getExecutor(obj)
            executor = getExecutor(obj.Values);
        end
        
        function tf = get.IsValid(obj)
            tf = obj.Session.IsValid;
        end
        
        function partitionMetadata = get.PartitionMetadata(obj)
            partitionMetadata = obj.Keys.PartitionMetadata;
        end
        
        function executor = get.Executor(obj)
            executor = obj.Keys.Executor;
        end
    end
    
    methods (Access = private)
        function obj = sortAndMergeGroups(obj)
            % Sort a grouped partitioned array by group, merging groups
            % across block boundaries so that the data for each group is
            % all together.
            obj = sortGroups(obj);
            opts = matlab.bigdata.internal.PartitionedArrayOptions;
            opts.PassTaggedInputs = true;
            fh = matlab.bigdata.internal.util.StatefulFunction(@iMergeSortedGroups);
            fh = matlab.bigdata.internal.FunctionHandle(fh);
            [keys, counts, values] = partitionfun(opts, fh, obj.Keys, obj.Counts, obj.Values);
            wasPartitionIndependent = isPartitionIndependent(obj);
            obj = matlab.bigdata.internal.splitapply.GroupedPartitionedArray(keys, counts, values, ...
                obj.Session, obj.IsGuaranteedSingleChunk, obj.IsSortedByGroupKey);
            if wasPartitionIndependent
                obj = markPartitionIndependent(obj);
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Helper function that ensures all received function handles are instances
% of the matlab.bigdata.internal.FunctionHandle class.
function functionHandle = iParseFunctionHandle(functionHandle, passTaggedInputs)
import matlab.bigdata.internal.FunctionHandle;
import matlab.bigdata.internal.lazyeval.TaggedArrayFunction;
if ~isa(functionHandle, 'matlab.bigdata.internal.FunctionHandle')
    assert (isa(functionHandle, 'function_handle'), ...
        'Assertion failed: Grouped Function handle must be a function_handle or a matlab.bigdata.internal.FunctionHandle.');
    functionHandle = FunctionHandle(functionHandle);
end
if ~passTaggedInputs
    functionHandle = TaggedArrayFunction.wrap(functionHandle);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Parse the given PartitionedArrayOptions object. This is done explicitly
% because GroupedPartitionedArray requires unwrapping of tagged types to be
% done after the data has been split into groups.
function [options, passTaggedInputs] = iParseOptions(options)
import matlab.bigdata.internal.PartitionedArrayOptions;
if isempty(options)
    options = PartitionedArrayOptions();
end
passTaggedInputs = options.PassTaggedInputs;
options.PassTaggedInputs = true;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Helper function that wraps function handles with the logic necessary to
% do per key function calls.
function fcn = iCreateKeyedFunctionHandle(fcn, passTaggedInputs, isInputGuaranteedBroadcast)
if nargin < 3
    isInputGuaranteedBroadcast = false;
end
fcn = iParseFunctionHandle(fcn, passTaggedInputs);
fcn = matlab.bigdata.internal.splitapply.GroupedFunction.wrap(fcn, ...
    'IsInputGuaranteedBroadcast', isInputGuaranteedBroadcast);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Helper function that wraps function handles with the logic necessary to
% do per key function calls, assuming that all inputs are separate.
function fcn = iCreateAdvancedKeyedFunctionHandle(fcn, passTaggedInputs, isInputGuaranteedBroadcast)
if nargin < 3
    isInputGuaranteedBroadcast = false;
end
fcn = iParseFunctionHandle(fcn, passTaggedInputs);
fcn = matlab.bigdata.internal.splitapply.AdvancedGroupedFunction.wrap(fcn, ...
    'IsInputGuaranteedBroadcast', isInputGuaranteedBroadcast);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Helper function that wraps function handles with the logic necessary to
% do per key function calls using the advanced partitionfun API.
function fcn = iCreateKeyedPartitionfunFunction(fcn, passTaggedInputs)
import matlab.bigdata.internal.splitapply.GroupedPartitionfunFunction;
fcn = iParseFunctionHandle(fcn, passTaggedInputs);
fcn = GroupedPartitionfunFunction.create(fcn);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Parse the input GroupedPartitionedArray data inputs. This checks to ensure
% all common data is the same for all inputs.
function [inputs, keys, counts, session, isAllGuaranteedSingleChunk, isAllSortedByGroup] = iParseInputs(varargin)
inputs = varargin;

session = [];
keys = cell(size(varargin));
counts = cell(size(varargin));
isAllGuaranteedSingleChunk = true;
isAllSortedByGroup = true;
for ii = 1:nargin
    if isa(varargin{ii}, 'matlab.bigdata.internal.splitapply.GroupedPartitionedArray')
        keys{ii} = varargin{ii}.Keys;
        counts{ii} = varargin{ii}.Counts;
        inputs{ii} = varargin{ii}.Values;
        session = iCheckSession(varargin{ii}.Session, session);
        isAllGuaranteedSingleChunk = isAllGuaranteedSingleChunk & varargin{ii}.IsGuaranteedSingleChunk;
        isAllSortedByGroup = isAllSortedByGroup && varargin{ii}.IsSortedByGroupKey;
    elseif isa(varargin{ii}, 'matlab.bigdata.internal.lazyeval.LazyPartitionedArray')
        if ~varargin{ii}.PartitionMetadata.Strategy.IsBroadcast
            matlab.bigdata.internal.throw(message('MATLAB:bigdata:array:IncompatibleTallIndexing'));
        end
        inputs{ii} = clientfun(@iWrapAsBroadcast, varargin{ii});
    elseif isa(varargin{ii}, 'matlab.bigdata.internal.BroadcastArray')
        value = varargin{ii}.Value;
        if isa(value, 'matlab.bigdata.internal.splitapply.GroupedPartitionedArray')
            [keys{ii}, counts{ii}, inputs{ii}] = clientfun(@iWrapAsGroupedBroadcast, ...
                value.Keys, value.Counts, value.Values);
            session = iCheckSession(value.Session, session);
        elseif  isa(value, 'matlab.bigdata.internal.lazyeval.LazyPartitionedArray')
            inputs{ii} = clientfun(@iWrapAsBroadcast, value);
        else
            inputs{ii} = iWrapAsBroadcast(value);
        end
    else
        inputs{ii} = iWrapAsBroadcast(varargin{ii});
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [keys, counts] = iSlicewiseMergeKeys(keys, counts)
% Merge a set of <key,count> tuples together. This assumes all inputs are
% either broadcast, or have the same grouping and partitioning.
keys(cellfun(@isempty, keys)) = [];
if isscalar(unique(vertcat(keys{:})))
    keys = keys{1};
else
    keys = elementfun(@iAssertKeysEqual, keys{:});
end
counts(cellfun(@isempty, counts)) = [];
if isscalar(unique(vertcat(counts{:})))
    counts = counts{1};
else
    counts = elementfun(@iAssertKeysEqual, counts{:});
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check whether the underlying session is valid.
function session = iCheckSession(newSession, session)
if ~newSession.IsValid || (~isempty(session) && newSession ~= session)
    matlab.bigdata.internal.throw(message('MATLAB:bigdata:array:InvalidTall'));
else
    session = newSession;
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Assert whether the keys vector is the same across all input GroupedPartitionArray.
function keys = iAssertKeysEqual(varargin)
foundKeys = false;
keys = [];
for ii = 1:numel(varargin)
    if ~isa(varargin{ii}, 'matlab.bigdata.internal.splitapply.GroupedBroadcast')
        if ~foundKeys
            keys = varargin{ii};
        elseif ~isequal(keys, varargin{ii})
            matlab.bigdata.internal.throw(message('MATLAB:bigdata:array:IncompatibleTallIndexing'));
        end
        foundKeys = true;
    end
end
if ~foundKeys
    keys = varargin{1};
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Wrap the output in a collection of GroupedPartitionedArray instances.
function outputs = iWrapOutput(outputs, keys, counts, session, requiresBroadcast, isSortedByGroup)
import matlab.bigdata.internal.splitapply.GroupedPartitionedArray
if nargin < 5
    requiresBroadcast = false;
end
if nargin < 6
    isSortedByGroup = false;
end
for ii = 1:numel(outputs)
    outputs{ii} = GroupedPartitionedArray(keys, counts, outputs{ii}, session, requiresBroadcast, isSortedByGroup);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [keys, counts, varargout] = iGroupBroadcastIfSingletonPerGroup(keys, counts, varargin)
% Wrap the given variables each as a GroupedBroadcast object if there
% is exactly one slice per group.
if isnumeric(counts) && all(counts == 1)
    varargout = cell(size(varargin));
    [keys, counts, varargout{:}] = groupBroadcast(keys, counts, varargin{:});
else
    varargout = varargin;
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [keys, counts, values] = iWrapAsGroupedBroadcast(keys, counts, values)
% Wrap grouped data as a GroupedBroadcast if not already done.
[keys, counts, values] = groupBroadcast(keys, counts, values);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function out = iWrapAsBroadcast(in)
% Wrap in one level of BroadcastArray.
out = matlab.bigdata.internal.broadcast(in);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function out = iTernary(condition, ifTrue, ifFalse)
% Crude chunkwise implementation of ternaryfun for grouped data. This will
% be wrapped in a keyed function handle, which will allow condition per
% group behavior.
if ~islogical(condition) || ~isscalar(condition)
    sizeStr = join(string(size(condition)), 'x');
    matlab.bigdata.internal.throw(message('MATLAB:bigdata:array:InvalidTernaryLogical', class(condition), char(sizeStr)));
elseif condition
    out = ifTrue;
else
    out = ifFalse;
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [groupKeys, groupCounts, varargout] = iSplitChunk(groupKeys, varargin)
% Split a single chunk of data into cell array of grouped data. This is
% done on any input to GroupedPartitionedArray/create.

% Check for Tagged Array inputs (i.e Broadcast Arrays)
if isa(groupKeys, 'matlab.bigdata.internal.BroadcastArray')
    groupKeys = getUnderlying(groupKeys);
end
for ii = 1:numel(varargin)
    if isa(varargin{ii}, 'matlab.bigdata.internal.BroadcastArray')
        varargin{ii} = getUnderlying(varargin{ii});
    end
end

% Check for UnknownEmptyArray inputs. In the case of grouped functions, we
% know the type and small sizes of groupKeys, groupCounts and the data is
% wrapped into cell arrays. Return empty outputs based on these criteria.
import matlab.bigdata.internal.UnknownEmptyArray;
if UnknownEmptyArray.isUnknown(groupKeys) ...
        || any(cellfun(@UnknownEmptyArray.isUnknown, varargin))
    groupKeys = zeros(0, 1);
    groupCounts = zeros(0, 1);
    varargout = cell(size(varargin));
    varargout(1:numel(varargin)) = {cell(0, 1)};
    return;
end

import matlab.bigdata.internal.util.splitSlices;
[groupKeys, ~, groupIndices] = unique(groupKeys);
groupCounts = accumarray(groupIndices, 1);

varargout = cell(size(varargin));
for ii = 1 : numel(varargin)
    varargout{ii} = splitSlices(varargin{ii}, groupIndices);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [cachedEmptyOutput, groupKeys, groupValues] ...
    = iJoinGroups(cachedEmptyOutput, groupKeys, groupCounts, groupValues, keepGroupedBroadcasts)
% Join grouped data back into a flat array of underlying data.
import matlab.bigdata.internal.util.indexSlices;
import matlab.bigdata.internal.util.vertcatCellContents;
import matlab.bigdata.internal.UnknownEmptyArray;

if isa(groupKeys, 'matlab.bigdata.internal.splitapply.GroupedBroadcast')
    if keepGroupedBroadcasts
        return;
    end
    groupKeys = groupKeys.Keys;
    groupCounts = groupCounts.Values;
    groupValues = groupValues.Values;
end
groupKeys = repelem(groupKeys, groupCounts, 1);

if isempty(groupValues)
    groupValues = cachedEmptyOutput;
else
    if isa(cachedEmptyOutput, 'matlab.bigdata.internal.UnknownEmptyArray')
        cachedEmptyOutput = indexSlices(groupValues{1}, []);
    end
    groupValues = vertcatCellContents(groupValues);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function varargout = iFilter(indices, varargin)
% Filter a collection of slices based on a logical column vector.
import matlab.bigdata.internal.util.indexSlices;
for ii = 1 : numel(varargin)
    varargin{ii} = indexSlices(varargin{ii}, indices);
end
varargout = varargin;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [tuples, idx] = iSortTupleByGroup(tuples)
% Sort a table of <key,count,value> tuples by keys. This will be applied
% per-block during an external sort algorithm.
[~, idx] = sort(tuples.Key);
tuples = tuples(idx, :);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function partitionIdx = iPartitionTupleByGroupKey(numPartitions, tuples, numGroups)
% Pick partition indices based on group key. This assumes group key is an
% integer in the range 0:numGroups.
partitionIdx = ceil((tuples.(1) + 1) / (numGroups + 1) * numPartitions);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function paOut = iAreGroupsSorted(paKeys)
% Determine if groups are already sorted, with no group spanning a
% partition boundary.
paPartitionIdx = partitionfun(@iGetPartitionIdx, paKeys);
[paReducedKey, ~] = reducefun(@iAreGroupsSortedReducer, paKeys, paPartitionIdx);
paOut = clientfun(@(x) ~any(isnan(x)), paReducedKey);
end

function [isFinished, partitionIdx] = iGetPartitionIdx(info, x)
if isa(x, 'matlab.bigdata.internal.splitapply.GroupedBroadcast')
    x = x.Keys;
end
isFinished = info.IsLastChunk;
partitionIdx = info.PartitionId * ones(size(x, 1), 1);
end

function [keys, partitionIdx] = iAreGroupsSortedReducer(keys, partitionIdx)
% If groups are sorted and do not span partition boundaries, return the min
% and the max. If either of these conditions is broken, return NaN.
%
% This works on the basis that reducefun always invokes with data in order.
% Two blocks being reduced together are guaranteed to be consecutive.
if isa(keys, 'matlab.bigdata.internal.splitapply.GroupedBroadcast')
    keys = keys.Keys;
end
if isempty(keys)
    return;
end
if ~issorted(keys)
    keys = nan;
    partitionIdx = nan;
    return;
end
x = [keys, partitionIdx];
x = unique(x, 'rows');
keys = x(:, 1);
partitionIdx = x(:, 2);
if any(diff(keys) < 1)
    keys = nan;
    partitionIdx = nan;
    return;
end
keys = keys([1; end], :);
partitionIdx = partitionIdx([1; end], :);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [buffer, isFinished, keys, counts, values] ...
    = iMergeSortedGroups(buffer, info, keys, counts, values)
% For each group, merge all data across block boundaries. This assumes the
% group blocks are already sorted by group key. This will carry group data
% forward over block boundaries as necessary via StateFunction buffer
% variable.
isFinished = info.IsLastChunk;
if isa(keys, 'matlab.bigdata.internal.splitapply.GroupedBroadcast')
    return;
end
if matlab.bigdata.internal.UnknownEmptyArray.isUnknown(keys)
    keys = zeros(0, 1);
    counts = zeros(0, 1);
    values(1:numel(values)) = {cell(0, 1)};
    return;
end

if ~isempty(buffer)
    % Have to keep all input in FIFO order, including input buffered from
    % previous blocks.
    keys = [buffer.Keys; keys];
    counts = [buffer.Counts; counts];
    values = [buffer.Values; values];
    buffer = [];
end
if isempty(keys)
    return;
end

if ~isFinished
    % The last key of this block might span into the next block. We need to
    % defer processing the last key until we're sure we have all of it.
    numUsableKeys = find(diff(keys, 1, 1) ~= 0, 1, 'last');
    if isempty(numUsableKeys)
        % In this case, all data in the block is associated with one key.
        % We must defer all of it to the next block.
        numUsableKeys = 0;
    end
    buffer.Keys = keys(numUsableKeys + 1:end, :);
    keys(numUsableKeys + 1:end, :) = [];
    buffer.Counts = counts(numUsableKeys + 1:end, :);
    counts(numUsableKeys + 1:end, :) = [];
    buffer.Values = values(numUsableKeys + 1:end, :);
    values(numUsableKeys + 1:end, :) = [];
end
if isempty(keys)
    return;
end

[keys, counts, values] = canonicalizeGroups(keys, counts, values);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [keys, counts] = iGetKeys(keys)
% Get the keys underlying a GroupedPartitionedArray in a way that can be
% used slicewise with the actual data.
if isa(keys, 'matlab.bigdata.internal.splitapply.GroupedBroadcast')
    counts = num2cell(ones(size(keys.Keys)));
    counts = matlab.bigdata.internal.splitapply.GroupedBroadcast(keys.Keys, counts);
    return;
end
keys = num2cell(keys);
counts = ones(size(keys));
end
