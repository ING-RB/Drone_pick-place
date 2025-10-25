function outAdap = computeReducedSize(outAdap, origAdap, reductionDim, canLeaveEmpty)
% Update size information for the output of a reduction given the input
% adaptor and reduction dimension.
%
% canLeaveEmpty specifies whether a zero dimension should be left empty
% (true) or set to 1 (false). For example, MIN, MAX, set this true, SUM,
% PROD set it false.

% Copyright 2016-2018 The MathWorks, Inc.

% For safety, assume the output size is unknown until we can prove otherwise
outAdap = resetSizeInformation(outAdap);

if isempty(reductionDim) || ~matlab.bigdata.internal.util.isValidReductionDimension(reductionDim)
    % Can't do much if we don't know what was reduced! If the dimension is
    % invalid we leave it to the operation to throw the right error.
    return
end

% If dim is specified as "all" or the dimension vector includes all
% dimensions, then the result is a scalar unless empties are preserved.
if ~canLeaveEmpty && iReducingAllDims(origAdap, reductionDim)
    outAdap = outAdap.setKnownSize([1 1]);
    return;
end

% First deal with the tall dimension
if matlab.bigdata.internal.util.isAllFlag(reductionDim) || any(reductionDim==1)
    if canLeaveEmpty
        if origAdap.isTallSizeGuaranteedNonZero()
            outAdap = setSizeInDim(outAdap, 1, 1);
        else
            % New tall size is unknown
        end
    else
        outAdap = setSizeInDim(outAdap, 1, 1);
    end
else
    % Not reducing tall size, so copy the tall size from the input
     outAdap = copyTallSize(outAdap, origAdap);
end

% Now loop over small sizes. If they aren't known, we're done.
if ~isSmallSizeKnown(origAdap)
    return;
end

% Small sizes are known, so we can reduce them
smallSizes = origAdap.SmallSizes;
if matlab.bigdata.internal.util.isAllFlag(reductionDim)
    smallIdx = 1:numel(smallSizes);
else
    % Numeric dimensions
    reductionDim = unique(reductionDim);
    reductionDim(reductionDim==1 | reductionDim>origAdap.NDims) = [];
    smallIdx = reductionDim-1;
end

if canLeaveEmpty
    smallSizes(smallIdx) = min(smallSizes(smallIdx), 1);
else
    smallSizes(smallIdx) = 1;
end
outAdap = setSmallSizes(outAdap, smallSizes);

end

function tf = iReducingAllDims(adap, reductionDims)
% Helper to detect if we know we are reducing all dimensions. i.e. if the
% reduction dimension is the string "all" or we know the number of
% dimensions and they are all included.
tf = matlab.bigdata.internal.util.isAllFlag(reductionDims) ...
    || (isvector(reductionDims) && ~isnan(adap.NDims) && isempty(setdiff(1:adap.NDims, reductionDims)));
end
