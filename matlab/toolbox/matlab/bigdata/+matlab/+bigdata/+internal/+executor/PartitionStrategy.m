%PartitionStrategy
% The interface for classes that represent a partitioning strategy.
%
% A partitioning strategy tells the execution environment how a particular
% piece of execution or output should be partitioned. The different
% strategies modify how much control the execution environment has over the
% partitioning and with what information about the partition should be
% given to the data processor factory from ExecutionTask.
%
% Abstract Properties:
%
%  MinNumPartitions:
%    Minimum number of partitions supported by this strategy. This
%    must be a positive scalar integer in the range
%    1 <= MinNumPartitions < inf with MinNumPartitions <= MaxNumPartitions
%
%  MaxNumPartitions
%    Maximum number of partitions supported by this strategy. This
%    must be a positive scalar integer in the range
%    1 <= MaxNumPartitions < inf with MinNumPartitions <= MaxNumPartitions
%
%  IsDatastorePartitioning
%    A flag that indicates whether the partitioning is based on an
%    underlying datastore.
%
%  IsBroadcast
%    A flag that indicates whether the data will be explicitly
%    broadcasted to every partition.
%
%  MaxNumReadFailures
%    The maximum number of read failures allowed during this partition
%    strategy.
%
% Abstract Methods:
%
%  partition = createPartition(obj, partitionIndex, numPartitions) creates a
%  datastore based on numPartitions. The numPartitions input
%  argument must be within the range [MinNumPartitions, maxNumPartitions]
%
%  partition = createPartition(obj, partitionIndex, numPartitions, hadoopSplit)
%  creates a datastore based on the provided datastore Hadoop split.
%  The partitionIndex must match corresponding partition index of
%  the Hadoop split. This argument is only supported if
%  IsDatastorePartitioning is true.
%
%  obj = fixNumPartitions(obj, numPartitions) returns a
%  PartitionStrategy object equivalent to the input but where the
%  number of partitions is now fixed at numPartitions. This will be
%  used by backends to provide strategy objects that are aware of
%  the partitioning chosen by the backend.
%
% Methods:
%
%  obj = resolve(obj, defaultNumPartitionsHint, maxNumPartitionsHint, isPartitioningFirst)
%  resolves a partition strategy to the actual strategy and number of
%  partitions to be used by an environment. defaultNumPartitionsHint is a
%  suggested hint if the strategy doesn't have a good default.
%  maxNumPartitionsHint hints at a desired upper-limit. Both hints can be
%  used or ignored as required by the strategy.
%
%  N = numpartitions(obj, suggestedNumPartitions) gets the default number
%  of partitions to use for partitioned operations.
%
%  N = numpartitions(obj) returns the default number of partitions in
%  absence of any other information.
%
%  tf = isKnownSinglePartition(obj) returns true if and only if this
%  strategy knows it has exactly one partition.
%
%  tf = allowsSinglePartition(obj) returns true if and only if this strategy
%  allows for single partition evaluation.
%
%  tf = isResolved(obj) returns true if and only if this strategy is fully
%  resolved; I.E. the strategy will not change with any further
%  information from the backend.
%
%  n = getMinNumPartitions(obj) return property MinNumPartitions. This
%  exists to support cellfun on a cell array of strategies.
%
%  n = getMaxNumPartitions(obj) return property MaxNumPartitions. This
%  exists to support cellfun on a cell array of strategies.
%
%  tf = isCompatible(obj, other) checks if two strategies are compatible.
%  Two strategies are compatible if and only if the two strategies are
%  interchangeable for the purposes of partitioning.
%
%  options = getSerializedLocationOptions(~) builds the options struct to
%  pass to getSerializedLocation. This allows the partition structure to
%  tell Hadoop additional information such as force fullfile. By default,
%  we do not.
%
% Static Methods:
%
%  strategy = PartitionStrategy.create(N)  creates a fixed strategy with
%  exactly N partitions.
%
%  strategy = PartitionStrategy.create(ds) creates a strategy that decides
%  the partitioning based on the datastore ds.
%
%  strategy = PartitionStrategy.align(varargin) aligns several strategies
%  to form one that will work for all inputs. If an aligned strategy does
%  not exist, this will throw an appropriate end-user visible error.
%
%  strategy = PartitionStrategy.vertcatPartitionMetadata(varargin) builds a
%  strategy that represents the vertical concatenation of all partitions
%  across all input partition strategies.

%   Copyright 2015-2022 The MathWorks, Inc.
