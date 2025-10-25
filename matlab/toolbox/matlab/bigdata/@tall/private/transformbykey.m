function data = transformbykey(data, groups, fcn, fcnErrHandler)
% Transform grouped data

% Copyright 2019-2020 The MathWorks, Inc.


% Hide this function and everything below it when erroring to the user.
frame = matlab.bigdata.internal.InternalStackFrame(); %#ok<NASGU>

session = matlab.bigdata.internal.splitapply.SplitapplySession(fcn, hGetValueImpl(data));
tX = data;
tX = iWrapTallAsGroupedTall(tX, groups, session);
tX = fcn(tX);
% Resolve non-tall outputs
if istall(tX)
    tX = iUnwrapGroupedTall(tX, groups, session);
    tX = iInjectCorrectEmpty(tX, data, session, fcnErrHandler);
    data = tX;
else
    tX = iReplicateNonTall(tX,groups);
    data = tX;
end
end

%--------------------------------------------------------------------------

function tX = iInjectCorrectEmpty(tX, data, session, fcnErrHandler)
% Inject an empty of the correct size/type if the output is empty without
% known size/type.

import matlab.bigdata.internal.adaptors.getAdaptor
dataAdaptor = getAdaptor(data);
% Ignore the case where the data is guaranteed non-empty. Non-empty tall
% arrays are guaranteed to have correct size-type already.
if dataAdaptor.isTallSizeGuaranteedNonZero()
    return;
end

outAdaptor = getAdaptor(tX);
% Ignore the case where the adaptor reports size/type as known. The output
% will already have a correct sized output. This converts blocks tagged as
% "UnknownEmptyArray" into an empty generated directly from the inputs.

if outAdaptor.isNestedTypeKnown() && outAdaptor.isNestedSmallSizeKnown()
    % If the adaptor is certain, then any empty tX will have the correct
    % size/type.
    return;
end

% We need to use the original input to calculate the right size/type if it
% was empty. We reduce to an empty just in-case the original input was
% truly tall (we don't know it's height, could be empty, could be big).
import matlab.bigdata.internal.util.indexSlices
origHeight = size(data, 1);
emptyInput = reducefun(@(x) indexSlices(x, []), data);
emptyInput.Adaptor = resetTallSize(dataAdaptor);


% Finally, modify tX to remove UnknownEmptyArray blocks.
import matlab.bigdata.internal.broadcast
fcn = session.FunctionHandle;
% This is needed to differentiate UnknownEmptyArray blocks from other
% blocks.
tX = chunkfun(@(x, e, h) iApplyInjectCorrectEmpty(fcn, fcnErrHandler, x, e, h), ...
    tX, broadcast(emptyInput), origHeight);
tX.Adaptor = outAdaptor;
end

%--------------------------------------------------------------------------

function x = iApplyInjectCorrectEmpty(fcn, fcnErrHandler, x, emptyInput, origHeight)
% Apply the contract of iInjectCorrectEmpty per block of underlying data.

% If the tall has height zero, I.E. zero groups, x will be an estimated
% empty because splitapply internals cannot propagate type/size. We need to
% replace the estimated empty with the actual one. This might error, for
% example for user function @(x) x - x(1), which is why we only do this
% step if the entire tall array has height zero instead of just the block.
if (origHeight == 0)
    try
        x = fcn(emptyInput);
        x = matlab.bigdata.internal.util.indexSlices(x, []);
    catch
        fcnErrHandler();
    end
end
end

%--------------------------------------------------------------------------

function tY = iWrapTallAsGroupedTall(tX, tInKeys, session)
% Convert a tall array and column vector of 1:N keys into a special grouped
% equivalent
import matlab.bigdata.internal.splitapply.GroupedPartitionedArray;
tInKeys = hGetValueImpl(tInKeys);
paX = hGetValueImpl(tX);
gpaY = GroupedPartitionedArray.create(tInKeys, session, paX);
tY = tall(gpaY);
tY.Adaptor = resetTallSize(tX.Adaptor);
end

%--------------------------------------------------------------------------

function tX = iUnwrapGroupedTall(tY, tOutKeys, ~)
% Convert a special grouped tall array back into a normal one
gpaY = hGetValueImpl(tY);
emptyY = buildUnknownEmpty(tY.Adaptor);
[paXKeys, paX] = ungroup(gpaY, emptyY, 'KeepGroupedBroadcasts', true);
paX = generalpartitionfun(@iMatchOrderImpl, paX, paXKeys, hGetValueImpl(tOutKeys), ...
    matlab.bigdata.internal.broadcast(emptyY));
tX = tall(paX);
tX.Adaptor =  resetTallSize(tY.Adaptor);
tX = copyPartitionIndependence(tX, tY);
end

%--------------------------------------------------------------------------

function [isFinished, unusedInputs, out] = iMatchOrderImpl(info, x, xKeys, outKeys, emptyOut)
% Apply the order of outKeys to x using xKeys. This assumes x/xKeys are
% equivalently partitioned.
%
% This is required because splitapply internals change the order of
% x/xKeys, yet grouptransform need the output to match order of input.

import matlab.bigdata.internal.util.indexSlices;
numXKeys = size(xKeys, 1);

assert(numXKeys == size(x, 1), ...
    'Assertion Failed: x and xKeys do not match.');

% If the input is a GroupedBroadcast, then the output per group is a
% reduction to a single row per group. Each row needs to be expanded to the
% full group.
if isa(x, 'matlab.bigdata.internal.splitapply.GroupedBroadcast')
    if isempty(x.Keys)
        % Zero groups is hit if the input contained zeros rows of data. We
        % use the adaptor information to infer the size and type of the
        % output.
        out = emptyOut;
    else
        [~, idx] = ismember(outKeys, x.Keys);
        xValues = matlab.bigdata.internal.util.vertcatCellContents(x.Values);
        out = indexSlices(xValues, idx);
    end
    unusedInputs = {x, xKeys, zeros(0,1)};
    isFinished = all(info.IsLastChunk);
    return;
end

maxOutKey = max(outKeys);
xToOutIdx = zeros(size(xKeys, 1), 1);
for key = 0:maxOutKey
    xIdx = find(xKeys == key);
    outIdx = find(outKeys == key);
    numKeys = min(numel(xIdx), numel(outIdx));
    xToOutIdx(outIdx(1:numKeys)) = xIdx(1:numKeys);
end

% The chunks might not completely align, so we have to account for cases
% where xKeys doesn't have everything to fill outKeys.
missingIdx = find(xToOutIdx == 0, 1, 'first');

if ~isempty(missingIdx)
    xToOutIdx(missingIdx : end) = [];
end

out = indexSlices(x, xToOutIdx);

% Things to carry to next block
subs = repmat({':'}, 1, ndims(x)-1);
x(xToOutIdx, subs{:}) = [];
xKeys(xToOutIdx, :) = [];
outKeys(1:numel(xToOutIdx), :) = [];
unusedInputs = {x, xKeys, outKeys};

% And finally, when do we finish? When do we give up?
isFinished = all(info.IsLastChunk);
if isFinished && (~isempty(xKeys) || ~isempty(outKeys))
    error(message('MATLAB:grouptransform:MethodOutputInvalidSize'));
end
end

%--------------------------------------------------------------------------

function tX = iReplicateNonTall(tX, groups)
% Handle cases where the output of the user's function handle is not a
% grouped tall array.
adaptor = matlab.bigdata.internal.adaptors.getAdaptor(tX);
tX = slicefun(@iReplicateNonTallImpl, tX, groups);
tX.Adaptor = resetTallSize(adaptor);
end

function x = iReplicateNonTallImpl(x, groups)
x = matlab.bigdata.internal.util.indexSlices(x, ones(size(groups, 1), 1));
end
