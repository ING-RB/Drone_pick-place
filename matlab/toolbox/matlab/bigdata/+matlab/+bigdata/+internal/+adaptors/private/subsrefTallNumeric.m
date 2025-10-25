function paY = subsrefTallNumeric(paX, paIdx)
% Get x(idx,:,:,..) where idx is a numeric index. Input arguments x and idx
% can be either tall or non-tall.
%
% This assumes paIdx is a column vector and is either numeric or logical.

%   Copyright 2017-2019 The MathWorks, Inc.

% There is a chance that paIdx is actually logical. In such cases where
% this needs to continue working, we bypass the communication parts of the
% calculation. This is done by performing the logical indexing, storing the
% result of that in paLogicalY, then making paIdx empty. If paIdx is in
% fact numeric, paLogicalY is empty and everything continues as normal.
wasPartitionIndependent = isPartitionIndependent(paX, paIdx);

attemptLogicalBypass = isCompatible(paX.PartitionMetadata.Strategy, paIdx.PartitionMetadata.Strategy);
if attemptLogicalBypass
    [paLogicalY, paIdx] = iAttemptLogicalIndex(paX, paIdx);
else
    paIdx = iAssertNotLogical(paIdx);
end

% Pass 1. Get the partition sizes of X and form necessary pieces of metadata
% about X. This is needed to map requested indices to the right partition of X.
%
% For the example, we know partition sizes to be [3,3]. I.e. indices 1:3
% refer to partition 1 of X and indices 4:6 refer to partition 2 of X.
xPartitionSizes = matlab.bigdata.internal.lazyeval.getPartitionSizes(paX);
xPartitionBoundaries = iBuildPartitionBoundaries(xPartitionSizes);
xNumel = clientfun(@sum, xPartitionSizes);

% Pass 2-4. Defer to the 3-pass keyindexslices algorithm.
dim = 1;
paIdx = verifyNumericSubscript(paIdx, dim, xNumel);

paY = matlab.bigdata.internal.lazyeval.keyindexslices(...
    paX, matlab.bigdata.internal.lazyeval.getAbsoluteSliceIndices(paX), ...
    paIdx, ...
    'XPartitionBoundaries', xPartitionBoundaries);

% If a logical bypass worked, all of the output will be in paLogicalY
% instead of paY. Here we combine the two.
if attemptLogicalBypass
    paY = iVertcatPartitions(paY, paLogicalY);
end

% The framework will assume out is partition dependent because it is
% derived from partitionfun/generalpartitionfun. It is not, so we must
% correct this.
if wasPartitionIndependent
    paY = markPartitionIndependent(paY);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Bypass for logical types.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [paLogicalY, paNumericIdx] = iAttemptLogicalIndex(paX, paIdx)
% Attempt logical indexing. If paIdx is logical, this will perform the
% logical indexing. Otherwise it will no-op.
[paLogicalIdx, paNumericIdx] = generalpartitionfun(@iSplitIndexOnType, paIdx, paX);
paLogicalY = filterslices(paLogicalIdx, paX);
end

function [isFinished, unusedInputs, logicalIdx, numericIdx] = iSplitIndexOnType(info, idx, x)
% Direct idx into one of several outputs based on whether idx is logical
% or numeric.
if islogical(idx)
    % As idx is logical, we simply return an empty for the numeric output.
    % This only consumes idx, so we can exit early if idx finishes before
    % x.
    isFinished = info.IsLastChunk(1);
    logicalIdx = idx;
    numericIdx = zeros(0, 1);
else
    % As idx is numeric, we return an a column vector of false compatible
    % with x. The subsequent filter operation will filter out all of paX,
    % leaving paLogicalY empty. This must consume all of both idx and x.
    isFinished = all(info.IsLastChunk);
    logicalIdx = false(size(x, 1), 1);
    numericIdx = idx;
end
unusedInputs = [];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function paY = iVertcatPartitions(paY, paLogicalY)
% Fuse two vertically concatenable arrays assuming at least one is empty.
% This is used to fuse the result of logical indexing with numeric
% indexing. We can make this assumption because the index will either be
% logical or numeric, it can't be both.
paY = generalpartitionfun(@iVertcatPartitionsImpl, paY, paLogicalY);
end

function [isFinished, unusedInputs, y] = iVertcatPartitionsImpl(info, y, logicalY)
% Implementation of iVertcatPartitions. At least one of y or logicalY
% should be empty.
assert(isempty(y) || isempty(logicalY), ...
    'Assertion Failed: Both y and logicalY were non-empty.');
isFinished = all(info.IsLastChunk);
unusedInputs = [];
y = [y; logicalY];
end

function paIdx = iAssertNotLogical(paIdx)
% Assert that idx is a numeric index. If it is not, then we can issue an
% incompatibility error because logical indexing would not have worked
% anyway.
paIdx = elementfun(@iAssertNotLogicalImpl, paIdx);
end

function idx = iAssertNotLogicalImpl(idx)
% Implementation of iAssertNotLogical.
if islogical(idx)
    error(message('MATLAB:bigdata:array:IncompatibleTallIndexing'));
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Common helper functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function partitionBoundaries = iBuildPartitionBoundaries(partitionSizes)
% Convert partition sizes into a row vector of boundaries for use with
% discretize.
partitionBoundaries = clientfun(@iBuildPartitionBoundariesImpl, partitionSizes);
end

function partitionBoundaries = iBuildPartitionBoundariesImpl(partitionSizes)
% Implementation of iBuildPartitionBoundaries.
partitionBoundaries = cumsum(partitionSizes(:));
partitionBoundaries = [1; partitionBoundaries(1 : end - 1) + 1];
end
