function paX = sortSlices(paX, sortFcn, partitionFcn, varargin)
%SORTSLICES Communicating sort of slices in a partitioned array.
%
% Syntax:
%   paY = sortSlices(paX,sortFcn,partitionFcn,...) reorders paX, using
%   sortFcn to provide the new ordering. If communication is required,
%   partitionFcn will be used to map slice to target partitions.
%
%   paY = sortSlices(...,name1,value1,...) specifies one or more options:
%
%   IsSorted: A lazy logical scalar, is the input already sorted? This
%   allows the caller to provide an way to skip the sort if at evaluation
%   time we know sort is not needed.
%
%   OtherPartitionFcnInputs: Other lazy inputs to be passed to partitionFcn.
%   These must be scalars or broadcasts.
%

%   Copyright 2018-2019 The MathWorks, Inc.

pnames = {'IsSorted', 'OtherPartitionFcnInputs'};
dflts =  {        [],                        []};
[isSorted, otherPartitionFcnInputs, supplied] ...
    = matlab.internal.datatypes.parseArgs(pnames, dflts, varargin{:});
assert(supplied.IsSorted, ...
    'Assertion Failed: IsSorted lazy input argument must be provided.');
assert(supplied.OtherPartitionFcnInputs, ...
    'Assertion Failed: OtherPartitionFcnInputs input argument must be provided.');

wasPartitionIndependent = isPartitionIndependent(paX);
[paSortedX, paX] = iSwitch(isSorted, paX);

% When partitioning is not guaranteed to be 1 partition, we must schedule
% communication. Note, if IsNumPartitionsFixed is false, then
% DesiredNumPartitions can change (E.G. save/load into a different
% execution environment).
partitionStrategy = paX.PartitionMetadata.Strategy;
communicationRequired = ~partitionStrategy.isKnownSinglePartition;
if communicationRequired
    fh = @(info, varargin) iPartitionFcn(info, partitionFcn, varargin{:});
    targetPartitionIdx = partitionfun(fh, paX, otherPartitionFcnInputs{:});
    paX = repartition(paX.PartitionMetadata, targetPartitionIdx, paX);
end

% External sort as a single partition might be
% out-of-memory.
fh = matlab.bigdata.internal.io.ExternalSortFunction(sortFcn);
fh = matlab.bigdata.internal.FunctionHandle(fh);
paX = partitionfun(fh, paX);

paX = iUndoSwitch(paSortedX, paX);
if wasPartitionIndependent
    paX = markPartitionIndependent(paX);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [isFinished, idx] = iPartitionFcn(info, fcn, varargin)
% Wrapper around partitionfcn that passes in the number of partitions of
% the target partitioning.
isFinished = info.IsLastChunk;
idx = fcn(info.NumPartitions, varargin{:});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [paOutIfTrue, paOutIfFalse] = iSwitch(flag, paIn)
% Redirect all input to one of two outputs dependent on a lazy logical
% scalar. The other output will be empty, of the correct size.
negFlag = elementfun(@not, flag);
paOutIfTrue = partitionfun(@iFilterAll, flag, paIn);
paOutIfFalse = partitionfun(@iFilterAll, negFlag, paIn);
if isPartitionIndependent(flag, paIn)
    [paOutIfTrue, paOutIfFalse] = markPartitionIndependent(paOutIfTrue, paOutIfFalse);
end
end

function [isFinished, x] = iFilterAll(info, flag, x)
% Partitionfun function that filters entire partitions if provided flag is
% false.
isFinished = info.IsLastChunk;
if ~flag
    isFinished = true;
    x = matlab.bigdata.internal.util.indexSlices(x, []);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function paOut = iUndoSwitch(paIn1, paIn2)
% Rejoin two arrays that was previously split into two via iSwitch.
% The underlying operation with generalpartitionfun is vertcat, it must
% directly handle TaggedArrays such as UnknownEmptyArray.
opts = matlab.bigdata.internal.PartitionedArrayOptions;
opts.PassTaggedInputs = true;
paOut = generalpartitionfun(opts, @iUndoSwitchImpl, paIn1, paIn2);
end

function [isFinished, unusedInputs, out] = iUndoSwitchImpl(info, in1, in2)
isFinished = all(info.IsLastChunk);
unusedInputs = [];
out = [in1; in2];
end
