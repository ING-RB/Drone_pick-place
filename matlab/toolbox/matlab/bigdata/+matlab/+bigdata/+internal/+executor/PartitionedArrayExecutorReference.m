%PartitionedArrayExecutorReference
% An implementation of PartitionedArrayExecutor that wraps around a weak
% reference to another PartitionedArrayExecutor.
%
% This exists so that PartitionedArrays objects can hold a reference to an
% instance of PartitionedArrayExecutor without preventing the execution
% environment being destroyed if the mapreducer is explicitly changed. It
% contains the means to recreate an executor if it is safe to do this.
%

%   Copyright 2016-2024 The MathWorks, Inc.

classdef (Sealed) PartitionedArrayExecutorReference < matlab.bigdata.internal.executor.PartitionedArrayExecutor
    properties (WeakHandle, SetAccess = private)
        % The underlying weak reference to the executor.
        ExecutorWeakRef (1, 1) matlab.bigdata.internal.executor.PartitionedArrayExecutor ...
            = matlab.lang.invalidHandle("matlab.bigdata.internal.executor.PartitionedArrayExecutorReference")
    end
        
    properties (SetAccess = immutable)
        % A memento struct that can recreate the underlying mapreducer
        % object when this object requires to recreate an execution
        % environment
        MapReducerMemento;
    end
    
    methods
        function obj = PartitionedArrayExecutorReference(executor, memento)
            if nargin >= 1
                obj.ExecutorWeakRef = executor;
            end
            
            if nargin >= 2
                obj.MapReducerMemento = memento;
            end
        end
        
        %EXECUTEWITHHANDLER Execute the provided graph of tasks redirecting
        %  all output to the given output handler.
        function readFailureSummary = executeWithHandler(obj, taskGraph, outputHandler)
            executor = obj.getOrCreate();
            readFailureSummary = executor.executeWithHandler(taskGraph, outputHandler);
        end
        
        %COUNTNUMPASSES Count the number of passes required to execute the provided graph of tasks.
        function numPasses = countNumPasses(obj, taskGraph)
            executor = obj.getOrCreate();
            numPasses = executor.countNumPasses(taskGraph);
        end
        
        %NUMPARTITIONS Retrieve the number of partitions for the given
        %  partition strategy.
        function n = numPartitions(obj, partitionStrategy)
            executor = obj.getOrCreate();
            n = executor.numPartitions(partitionStrategy);
        end
    end
    
    methods
        % Check whether this executor can still be used for execution.
        function tf = isUsable(obj)
            tf = isvalid(obj);
            if ~tf
                return;
            end
            executor = obj.ExecutorWeakRef;
            tf = isvalid(executor) && executor.isUsable();
        end
        
        %CHECKDATASTORESUPPORT Check whether the provided datastore is supported.
        % The default is to do nothing. Implementations will are allowed to
        % issue errors from here if the datastore is not supported.
        function checkDatastoreSupport(obj, ds)
            executor = obj.getOrCreate();
            executor.checkDatastoreSupport(ds);
        end
        
        %CHECKSAMEEXECUTOR Check whether the two executor objects represent
        % the same underlying execution environment.
        function tf = checkSameExecutor(obj1, obj2)
            tf = (obj1.ExecutorWeakRef == obj2.ExecutorWeakRef);
            if ~tf && strcmp(class(obj1), class(obj2))
                try
                    tf = checkSameExecutor(obj1.getOrCreate(), obj2.getOrCreate());
                catch
                    tf = false;
                end
            end
        end
        
        %KEEPALIVE Notify to the executor that operations have just been
        %performed and it should reset any idle timeouts.
        function keepAlive(obj)
            executor = obj.getOrCreate();
            executor.keepAlive();
        end
        
        %REQUIRESSEQUENCEFILEFORMAT A flag that specifies if tall/write
        %should always generate sequence files.
        function tf = requiresSequenceFileFormat(obj)
            executor = obj.getOrCreate();
            tf = executor.requiresSequenceFileFormat();
        end
        
        %SUPPORTSSINGLEPARTITION A flag that specifies if the executor
        %supports the single partition optimization.
        function tf = supportsSinglePartition(obj)
            executor = obj.getOrCreate();
            tf = executor.supportsSinglePartition();
        end
    end
    
    methods (Access = private)
        % Get or create the underlying executor.
        function executor = getOrCreate(obj)
            executor = obj.ExecutorWeakRef;
            if isUsable(executor)
                return;
            end
            
            if isempty(obj.MapReducerMemento)
                matlab.bigdata.internal.throw(message('MATLAB:bigdata:array:InvalidTall'));
            end
            
            mapReducerManager = matlab.mapreduce.internal.MapReducerManager.getCurrentManager();
            mr = mapReducerManager.getDefault();
            if isempty(mr)
                mr = matlab.mapreduce.MapReducer.createFromMemento(obj.MapReducerMemento);
                result = false;
                if ~isempty(mr)
                    result = mapReducerManager.setDefault(mr);
                end
                if ~result
                    matlab.bigdata.internal.throw(message('MATLAB:bigdata:array:InvalidTall'));
                end
            else
                if ~mr.checkMemento(obj.MapReducerMemento)
                    matlab.bigdata.internal.throw(message('MATLAB:bigdata:array:InvalidTall'));
                end
            end
            executor = mr.getPartitionedArrayExecutor();
            if isa(executor, 'matlab.bigdata.internal.executor.PartitionedArrayExecutorReference')
                executor = executor.getOrCreate();
            end
            obj.ExecutorWeakRef = executor;
        end
    end
end
