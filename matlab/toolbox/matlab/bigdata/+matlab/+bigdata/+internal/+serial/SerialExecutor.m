%SerialExecutor
% Serial implementation of the PartitionArrayExecutor interface.
%
% This currently operates by building a CompositeDataProcessor per
% partition per "stage", where stage is defined to be a collection of
% tasks that can be run simultaneously. A pass is necessarily a stage, but
% a stage is not necessarily a pass as the client side of operations denote
% a stage that isn't over any particular datastore. Each CompositeDataProcessor
% includes processors that perform pieces of the communication, such as
% reading/writing to intermediate store as well as reading/writing to
% cache.
%

%   Copyright 2015-2023 The MathWorks, Inc.

classdef SerialExecutor < matlab.bigdata.internal.executor.PartitionedArrayExecutor
    
    properties (SetAccess = immutable)
        % The object that manages the cache on disk.
        CacheManager;
        
        % A flag that specifies whether this executor will use a single
        % partition whenever it is possible to do so.
        UseSinglePartition = false;

        % A flag that indicates whether this executor will contribute to
        % the total number of passes for an algorithm.
        CountPasses = true;
    end
    
    methods
        % The main constructor.
        function obj = SerialExecutor(varargin)
            import matlab.bigdata.internal.serial.CacheManager;
            import matlab.bigdata.internal.util.TempFolder;
            obj.CacheManager = CacheManager();
            
            p = inputParser;
            p.addParameter('UseSinglePartition', false);
            p.addParameter('CountPasses', true);
            p.parse(varargin{:});
            validateattributes(p.Results.UseSinglePartition, {'logical'}, {'scalar'});
            obj.UseSinglePartition = p.Results.UseSinglePartition;
            validateattributes(p.Results.CountPasses, {'logical'}, {'scalar'});
            obj.CountPasses = p.Results.CountPasses;
        end
    end
    
    % Methods overridden in the PartitionedArrayExecutor interface.
    methods
        %EXECUTEWITHHANDLER Execute the provided graph of tasks redirecting
        %  all output to the given output handler.
        function readFailureSummary = executeWithHandler(obj, taskGraph, outputHandlers)
            import matlab.bigdata.internal.util.TempFolder;
            import matlab.bigdata.internal.executor.ProgressReporter;
            import matlab.bigdata.internal.executor.ReadFailureAccumulator;
            
            pr = ProgressReporter.getCurrent();
            
            readFailureAccumulator = ReadFailureAccumulator();
            
            allowEdtCallbacks = any([outputHandlers.IsStreamingHandler]);
            
            intermediateStoreFolder = TempFolder();
            [stageTasks, broadcastMap] = obj.buildStageTasks(taskGraph, outputHandlers, intermediateStoreFolder.Path);
            
            % We want to ensure that all memory cache entries are cleaned
            % up at the end of execution to avoid conflicting with memory
            % usage of non-tall MATLAB arrays.
            cacheCleanup = onCleanup(@()obj.CacheManager.dumpMemoryToDisk());
            
            executorName = getString(message('MATLAB:bigdata:executor:SerialExecutorName'));
            numTasks = numel(stageTasks) - obj.countNumBroadcastStages(stageTasks);
            numPasses = obj.countNumPassStages(stageTasks);
            
            pr.startOfExecution(executorName, numTasks, numPasses);
            for ii = 1:numel(stageTasks)
                isBroadcastStage = stageTasks(ii).ExecutionPartitionStrategy.IsBroadcast;
                if isBroadcastStage
                    obj.executeTask(stageTasks(ii), stageTasks(ii).CacheEntryKeys, broadcastMap, allowEdtCallbacks);
                else
                    isFullPass = stageTasks(ii).IsPass;
                    pr.startOfNextTask(isFullPass);
                    taskReadFailureSummary = obj.executeTask(stageTasks(ii), stageTasks(ii).CacheEntryKeys, broadcastMap, allowEdtCallbacks, pr);
                    readFailureAccumulator.append(taskReadFailureSummary);
                    pr.endOfTask();
                    if isFullPass && obj.CountPasses
                        obj.incrementTotalNumPasses();
                    end
                end
                
                % If this stage task generated broadcast output to be sent
                % to the client, we can perform that action now.
                outputBroadcasts = stageTasks(ii).OutputBroadcasts;
                outputBroadcasts = outputBroadcasts(ismember(outputBroadcasts, taskGraph.OutputTasks));
                for outputBroadcast = outputBroadcasts(:)'
                    outputHandlers.handleBroadcastOutput(...
                        outputBroadcast.Id, broadcastMap.get(outputBroadcast.Id));
                end
            end
            pr.endOfExecution();
            readFailureSummary = readFailureAccumulator.Summary;
        end
        
        function numPasses = countNumPasses(obj, taskGraph)
            import matlab.bigdata.internal.util.TempFolder;
            import matlab.bigdata.internal.executor.OutputHandler;
            
            intermediateStoreFolder = TempFolder();
            stageTasks = obj.buildStageTasks(taskGraph, ...
                OutputHandler.empty(), intermediateStoreFolder.Path);
            
            numPasses = obj.countNumPassStages(stageTasks);
        end
        
        %NUMPARTITIONS Retrieve the number of partitions for the given
        %  partition strategy.
        function n = numPartitions(obj, partitionStrategy)
            partitionStrategy = obj.resolvePartitionStrategy(partitionStrategy);
            n = numpartitions(partitionStrategy);
        end
        
        %SUPPORTSSINGLEPARTITION A flag that specifies if the executor
        %supports the single partition optimization.
        function tf = supportsSinglePartition(obj)
            tf = true && ~obj.UseSinglePartition;
        end
    end
    
    methods (Access = private)
        function partitionStrategy = resolvePartitionStrategy(obj, partitionStrategy, ignoreSinglePartition)
            % Resolve a partition strategy to a version that knows the
            % exact number of partitions.
            
            % We use a single partition where possible because this is
            % more optimal. Early exit is faster since less intermediate
            % data is written to disk with a single partition.
            if nargin < 3
                ignoreSinglePartition = false;
            end
            useSinglePartition = obj.UseSinglePartition && ~ignoreSinglePartition;
            if useSinglePartition && partitionStrategy.allowsSinglePartition()
                partitionStrategy = fixNumPartitions(partitionStrategy, 1);
                return;
            end
            
            % This balances backwards compatibility with performance:-
            %  * A small number of partitions is more performant.
            %  * But, avoid 1 partition where practical, as this allows
            %    serial to expose user error for cases related to
            %    incompatible tall arrays.
            %  * Except after Any-to-Any communication, which has always
            %    resulted in 1 partition.
            tallSettings = matlab.bigdata.internal.TallSettings.get();
            defaultNumPartitionsHint = 1;
            maxNumPartitionsHint = tallSettings.SerialMaxNumPartitions;
            doPartitioningFirst = false;
            partitionStrategy = resolve(partitionStrategy, ...
                defaultNumPartitionsHint, maxNumPartitionsHint, doPartitioningFirst);
        end
        
        % Count the number of stages that have execution across the full
        % data.
        function numStages = countNumPassStages(obj, stageTasks) %#ok<INUSL>
            numStages = sum([stageTasks.IsPass]);
        end
        
        % Count the number of stages that have execution in broadcast mode.
        function numStages = countNumBroadcastStages(obj, stageTasks) %#ok<INUSL>
            numStages = 0;
            for ii = 1:numel(stageTasks)
                numStages = numStages + stageTasks(ii).ExecutionPartitionStrategy.IsBroadcast;
            end
        end
        
        % Execute the provided independent stage task
        function readFailureSummary = executeTask(obj, task, cacheEntryKeys, broadcastMap, allowEdtCallbacks, progressReporter)
            import matlab.bigdata.internal.executor.ReadFailureAccumulator;
            partitionStrategy = task.ExecutionPartitionStrategy;
            partitionStrategy = obj.resolvePartitionStrategy(partitionStrategy, ~isempty(task.CacheEntryKeys));
            numExecutorPartitions = numpartitions(partitionStrategy);
            
            tallSettings = matlab.bigdata.internal.TallSettings.get();
            timePerProgressUpdate = tallSettings.TimePerProgressUpdate;
            
            % This must be called once per execution task so that cache
            % entries generated from this execution task can override
            % previous cache entries.
            obj.CacheManager.setupForExecution(cacheEntryKeys);
            
            lastTic = tic;
            readFailureAccumulator = ReadFailureAccumulator(partitionStrategy.MaxNumReadFailures);
            for partitionIndex = 1:numExecutorPartitions
                partition = partitionStrategy.createPartition(partitionIndex, numExecutorPartitions);
                partitionContext = matlab.bigdata.internal.executor.PartitionContext(partition, broadcastMap);
                
                dataProcessor = feval(task.DataProcessorFactory, partitionContext);
                
                while ~dataProcessor.IsFinished
                    process(dataProcessor, false(0));
                    if allowEdtCallbacks
                        drawnow;
                    end
                    
                    if nargin >= 6 && toc(lastTic) > timePerProgressUpdate
                        partitionProg = progress(dataProcessor, []);
                        progressReporter.progress((partitionIndex - 1 + partitionProg) / numExecutorPartitions);
                        lastTic = tic;
                    end
                end
                
                readFailureAccumulator.append(partitionContext.getReadFailureSummary());
            end
            readFailureSummary = readFailureAccumulator.Summary;
        end
        
        % Convert the input task graph into an array of independent tasks
        % that can be executed one by one.
        %
        function [stageTasks, broadcastMap] = buildStageTasks(obj, taskGraph, outputHandlers, intermediateFolderPath)
            import matlab.bigdata.internal.executor.BroadcastMap;
            broadcastMap = BroadcastMap();
            stageTasks = matlab.bigdata.internal.executor.convertToIndependentTasks(taskGraph, ...
                'CreateShuffleStorageFunction', @(task)obj.createShuffleStorage(task, intermediateFolderPath), ...
                'CreateStreamFactoryFunction', @(task)obj.createStreamFactory(task, outputHandlers), ...
                'GetCacheStoreFunction', @obj.getCacheStore, ...
                'ResolvePartitionStrategyFunction', @obj.resolvePartitionStrategy);
        end
        
        % Create a shuffle point where data is stored to an intermediate
        % storage, then read in a "shuffled" order by the next task.
        function [writerFactory, readerFactory] = createShuffleStorage(obj, task, intermediateFolderPath) %#ok<INUSL>
            import matlab.bigdata.internal.executor.OutputCommunicationType;
            import matlab.bigdata.internal.serial.KeyValueStoreReader;
            import matlab.bigdata.internal.serial.KeyValueStoreWriter;
            import matlab.bigdata.internal.serial.SerialExecutor;
            
            intermediateStoreFilename = iGetShuffleStoreName(task, intermediateFolderPath);
            
            outputCommunicationType = task.OutputCommunicationType;
            writerFactory = ...
                @(partition) KeyValueStoreWriter(intermediateStoreFilename, iGetDefaultKey(partition, outputCommunicationType));
            
            if task.OutputPartitionStrategy.IsBroadcast
                % When a given piece of intermediate data is in broadcast
                % state, it has only 1 partition. Every data processor that
                % requires this data must read from partition 1.
                broadcastPartitionIndex = 1;
                readerFactory = @(partition) KeyValueStoreReader(intermediateStoreFilename, broadcastPartitionIndex);
            else
                readerFactory = @(partition) KeyValueStoreReader(intermediateStoreFilename, partition.PartitionIndex);
            end
        end
        
        % Create a factory of Writer objects that redirect the output of
        % the given task to the output handlers.
        function streamWriterFactory = createStreamFactory(obj, task, outputHandlers) %#ok<INUSL>
            import matlab.bigdata.internal.serial.OutputHandlerAdaptorWriter;
            taskId = task.Id;
            
            streamWriterFactory = @(partition) OutputHandlerAdaptorWriter(taskId, ...
                partition.PartitionIndex, partition.NumPartitions, outputHandlers);
        end
        
        % Get the CacheManager instance.
        %
        % This exists for the purposes of convertToIndependentTasks.
        function cacheStore = getCacheStore(obj, task) %#ok<INUSD>
            cacheStore = obj.CacheManager.CacheStore;
        end
    end
end

% For the provided partition and output communication type, get the default
% key that should be written to the intermediate data store.
function defaultKey = iGetDefaultKey(partition, outputCommunicationType)
import matlab.bigdata.internal.executor.OutputCommunicationType;
import matlab.bigdata.internal.serial.SerialExecutor;
switch outputCommunicationType
    case OutputCommunicationType.Simple
        defaultKey = partition.PartitionIndex;
    case OutputCommunicationType.Broadcast
        defaultKey = 1;
    case OutputCommunicationType.AllToOne
        defaultKey = 1;
    case OutputCommunicationType.AnyToAny
        % In AnyToAny communication, the partition indices should be
        % specified by the data processor implementation underlying the
        % task.
        defaultKey = [];
end
end

% Get the filename for the intermediate data associated with the provided
% task.
function path = iGetShuffleStoreName(task, intermediateStoreFolder)
path = fullfile(intermediateStoreFolder, [task.Id, '.db']);
end
