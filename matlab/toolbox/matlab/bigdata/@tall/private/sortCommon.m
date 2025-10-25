function [tY,varargout] = sortCommon(sortFunctionHandle, tX, varargin)
%SORTCOMMON Shared sort/sortrows implementation
%
% This algorithm requires at most three passes:
%  1. A pass to estimate the distribution of the data so that it can be
%  partitioned correctly.
%  2. A pass to read the data and distribute it correctly.
%  3. A pass to sort the data after communication.
% If the number of partitions is one, passes 1 and 2 are skipped.
%
% This is shared because tall/sort only supports column vectors, where it
% overlaps with the implementation of sortrows.
%
% This also accepts two name-value pairs:
%  "PartitionWrtColumn": ensures that the elements of tY are partitioned
%                        only according to certain columns. Value can be a
%                        tall or non-tall double vector.
%  "AllInOnePartition": ensures all elements of tY end up in the same
%                       partition. Value can be a tall or non-tall logical.
%                       This option should only be used for when the output
%                       is expected to fit in memory
%
% This has syntaxes:
%  tY = sortCommon(sortFunctionHandle, tX)
%  tY = sortCommon(sortFunctionHandle, tX, "PartitionWrtColumn", value1)
%  tY = sortCommon(sortFunctionHandle, tX, "AllInOnePartition", value2)
%  tY = sortCommon(sortFunctionHandle, tX, "PartitionWrtColumn", value1, "AllInOnePartition", value2)
%  [tY,tOutIdx] = sortCommon(sortFunctionHandle, tX, tIdx, ...)
%
% Where sortFunctionHandle performs a sort of a local chunk of data in
% dimension 1.

%   Copyright 2016-2023 The MathWorks, Inc.

import matlab.bigdata.internal.FunctionHandle;
import matlab.bigdata.internal.io.ExternalSortFunction;
import matlab.bigdata.internal.broadcast;
import matlab.bigdata.internal.PartitionMetadata;

narginchk(2,7);
nargoutchk(0,2);
% Return an error when sorted indices are requested but the index input has
% not been provided.
assert(nargout ~= 2 || mod(nargin, 2) == 1,  ...
    'Error. Cannot provide sorted indices if the original set of indices is not provided.');

% This algorithm uses partitioned array instead of tall so that the adaptor
% information isn't needed for update till the very end.
tXInputAdaptor = tX.Adaptor;
if nargout > 1    
    % Create a table with tuples of <tX, tIdx> to sort all the values in tX
    % with their corresponding indices.
    tIdx = varargin{1};
    tX = table(tX,tIdx);
    commonSortFunctionHandle = @(tX) applySortWithIndices(tX, sortFunctionHandle);
else
    % When indices are not provided, use tX and sortFunctionHandle.
    commonSortFunctionHandle = sortFunctionHandle;
end

paX = hGetValueImpl(tX);

% Get number of partitions.
numPartitions = numpartitions(paX);

if numPartitions ~= 1
    % Parse varargin inputs.
    mode = {'', ''};
    if nargin > 3
        [mode, isInOnePartition, isPartitionWrtCol, partitionCols] = iParseVararginInputs(varargin{:});
    end
    
    if ismember("PartitionWrtColumn", mode) || ismember("AllInOnePartition", mode)
        % Set all unimportant columns in paX to ones so that new partition
        % boundaries are calculated only with respect to the desired
        % columns of paX. If no columns are specified, then the elements
        % will all end up in the same partition.
        prevPaX = paX;
        numArgsOut = nargout;
        paX = slicefun(@(paX, isRowVectors) iChangeColValuesToOnes(paX, partitionCols, isPartitionWrtCol, isRowVectors, numArgsOut), ...
            paX, matlab.bigdata.internal.broadcast(isInOnePartition));
    end
    
    % Need to estimate how to distribute the data among workers evenly.
    paNewPartitionBoundaries = iEstimateQuantiles(paX, commonSortFunctionHandle, numPartitions - 1);
    if nargout > 1
        % Need to ensure indices are zero for the boundaries to avoid
        % creating a different partitioning compared to when indices aren't
        % attached to the data.
        paNewPartitionBoundaries = slicefun(@iFlattenBoundaryIndices, paNewPartitionBoundaries);
    end
    paNewPartitionBoundaries = broadcast(paNewPartitionBoundaries);
    
    fh = @(varargin) matlab.bigdata.internal.util.discretizerows(varargin{:}, commonSortFunctionHandle) + 1;
    paRedistributeKeys = slicefun(fh, paX, paNewPartitionBoundaries);
    
    if  ismember("PartitionWrtColumn", mode) || ismember("AllInOnePartition", mode)
        % The partition boundaries calculated for paX are applied to
        % the original data held in prevPax instead.
        paX = repartition(PartitionMetadata(numPartitions), paRedistributeKeys, prevPaX);
    else
        paX = repartition(PartitionMetadata(numPartitions), paRedistributeKeys, paX);
    end
end

paY = partitionfun(FunctionHandle(ExternalSortFunction(commonSortFunctionHandle)), paX);

if nargout > 1
    % Extract sorted data.
    tTblY = tall(paY, tX.Adaptor);
    tY = subsref(tTblY, substruct('.','tX'));
    tY.Adaptor = tXInputAdaptor;
    % Extract indices.
    tOutIdx = subsref(tTblY, substruct('.','tIdx'));
    tOutIdx.Adaptor = tIdx.Adaptor;
    % The framework will assume out is partition dependent because it is
    % derived from partitionfun. It is not, so we must correct this.
    tOutIdx = copyPartitionIndependence(tOutIdx, tIdx);
    varargout{1} = tOutIdx;
else
    tY = tall(paY, tXInputAdaptor);
end

% The framework will assume out is partition dependent because it is
% derived from partitionfun. It is not, so we must correct this.
tY = copyPartitionIndependence(tY, tX);
end

% Estimate the N-quantiles of the given partitioned array input.
%
% TODO(g1473256): This is the generic version and a crude algorithm. If we
% can map this to the space of real numbers with a reasonable distance
% metric, we can use algorithms such as t-digest to get a much more
% accurate quantile estimation.
function paBoundaries = iEstimateQuantiles(paX, commonSortFunctionHandle, numQuantiles)
import matlab.bigdata.internal.util.StatefulFunction;
import matlab.bigdata.internal.FunctionHandle;

% We over-sample the quantiles to improve the accuracy of the estimate.
oversampledNumQuantiles = 3 * numQuantiles + 2;

fh = StatefulFunction(@(quantiles, info, x) iEstimateQuantilesPerPartition(quantiles, info, x, commonSortFunctionHandle, oversampledNumQuantiles));
paBoundaries = partitionfun(FunctionHandle(fh), paX);
paBoundaries = clientfun(@(x) iLocalQuantiles(x, commonSortFunctionHandle, numQuantiles), paBoundaries);
end

% A partitionfun function that estimates the N-quantiles of a partition.
function [quantiles, isFinished, out] = iEstimateQuantilesPerPartition(quantiles, info, x, commonSortFunctionHandle, numQuantiles)
isFinished = info.IsLastChunk;

if isempty(quantiles)
    quantiles = matlab.bigdata.internal.util.indexSlices(x, []);
end
if ~isempty(x)
    quantiles = [quantiles; iLocalQuantiles(x, commonSortFunctionHandle, numQuantiles)];
    quantiles = iLocalQuantiles(quantiles, commonSortFunctionHandle, numQuantiles);
end

if isFinished
    out = quantiles;
    quantiles = [];
else
    out = matlab.bigdata.internal.util.indexSlices(x, []);
end
end

% Calculate the quantiles for a local array.
function q = iLocalQuantiles(x, commonSortFunctionHandle, numQuantiles)

x = feval(commonSortFunctionHandle, x);

tallSize = size(x, 1);
if tallSize == 0
    q = matlab.bigdata.internal.util.indexSlices(x, []);
else
    idx = ceil(tallSize * (1 : numQuantiles) / (numQuantiles + 1));
    q = matlab.bigdata.internal.util.indexSlices(x, idx);
end
end

% Apply sortFunctionHandle to data + indices per chunk.
function [tblY,localIdx] = applySortWithIndices(tblX, sortFunctionHandle)

x = tblX.tX;

% Sort the indices of this chunk to later provide sorted data and indices
% for duplicated values and NaNs.
[sortedIdx,locSortedIdx] = sort(tblX.tIdx);

% Apply sort/sortrows as indicated by sortFunctionHandle.
[x,localIdx] = sortFunctionHandle(x(locSortedIdx,:));

% Compute global indices for this chunk.
idx = sortedIdx(localIdx);

% Compute local indices for this chunk.
localIdx = locSortedIdx(localIdx);

% Build the table up with dot subscripted assignment because the vars might
% be char row vectors which the table constructor doesn't support.
tblY = table(); tblY.tX = x; tblY.tIdx = idx;
end

function [mode, isInOnePartition, isPartitionWrtCol, partitionCols] = iParseVararginInputs(varargin)
% Parse Varargin inputs.

% Return an error if the provided indices are not the first input of
% varargin.
assert(tall.getClass(varargin{1}) ~= "char" || mod(nargin, 2) == 0,  ...
    'Error. Provided indices must be the first input of varargin.');

mode = {'', ''};
modeIdx = 1;
isInOnePartition = false;
isPartitionWrtCol = false;
partitionCols = 0;
for ii = 1:numel(varargin)
    if tall.getClass(varargin{ii}) == "char"
        mode{modeIdx} = varargin{ii};
        modeIdx = modeIdx + 1;
        if varargin{ii} == "PartitionWrtColumn"
            partitionCols = varargin{ii+1};
            isPartitionWrtCol = true;
        elseif varargin{ii} == "AllInOnePartition"
            isInOnePartition = varargin{ii+1};
        end
    end
end
end

function tXOut = iChangeColValuesToOnes(tXIn, keepCols, isPartitionWrtCol, isInOnePartition, numArgsOut)
% Change the contents of all the columns that we do not want to have an
% effect on the partitioning of the tall array to ones.
% Input is assumed to always be tabular.
if isInOnePartition && isPartitionWrtCol
    keepCols = 0;
end
if isInOnePartition || isPartitionWrtCol
    if numArgsOut == 2
        tX = subsref(tXIn, substruct('.','tX'));
    else
        tX = tXIn;
    end
    for ii = 1:size(tX, 2)
        if ii ~= keepCols
            if ((istable(tX) || istimetable(tX)) && class(tX(:, ii).Variables) == "categorical") ...
                    || class(tX) == "categorical"
                tX(:, ii) = {categorical(1)};
            elseif ((istable(tX) || istimetable(tX)) && class(tX(:, ii).Variables) == "cell") ...
                    || class(tX) == "cell"
                tX(:, ii) = {{1}};
            else
                tX(:, ii) = {1};
            end
        end
    end
    if numArgsOut == 2
        tXIn.tX = tX;
        tXOut = tXIn;
    else
        tXOut = tX;
    end
else
    tXOut = tXIn;
end
end

function partitionBoundaries = iFlattenBoundaryIndices(partitionBoundaries)
% Flatten attached indices on partition boundaries. This avoids the
% attached indices affecting the partitioning of the output.
if height(partitionBoundaries) > 0
    partitionBoundaries.tIdx(:) = 0;
end
end
