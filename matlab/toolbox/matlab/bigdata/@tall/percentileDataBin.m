function [prctileDataBins, locationInPrctileDataBins] = percentileDataBin(tX, percentiles)
% percentileDataBin Find data bin(s) containing percentile(s)
%
% Compute the entry of tX which coincides with the percentile, or compute a
% data bin formed from two consecutive entries of tX (the data bin which
% contains the percentile). For example, set the percentile input to 50 for median,
% or to [25, 75] for the first and third quartiles.
%
% Output is a pair of cell arrays specifying the bin and location in the
% bin for each of the requested percentiles.

% Copyright 2017-2019 The MathWorks, Inc.

assert( isnumeric(percentiles) && isvector(percentiles) ...
    && all((percentiles>=0 & percentiles<=100) | isnan(percentiles)) );

numPrcts = numel(percentiles);
prctileDataBins = cell(size(percentiles));
locationInPrctileDataBins = cell(size(percentiles));

% Bin the data to avoid sorting the entire array.
[n, ~, bins] = histcounts(tX);

% We need to take extreme care over +inf, -inf and NaN. We want NaN
% and +inf to be at the end of the bins list and -inf to be at the
% beginning (should already be the case).
toGoAtBeginning = isinf(tX) & (tX < 0);
bins = elementfun( @iReplaceInf, bins, tX, numel(n) + 1 );
% Prepend a bin for -inf, offsetting the bin counts (n)
n = [nnz(toGoAtBeginning), n];
bins = bins + 1;
nCumulative = cumsum(n, 2);

% Make sure we don't defer calculations on numel if size is already known.
if tX.Adaptor.isSizeKnown
    numelX = prod(tX.Adaptor.Size);
else
    numelX = numel(tX);
end

% Although this looks awful, the calculations will all be fused.
for ii=1:numPrcts
    [prctileDataBins{ii}, locationInPrctileDataBins{ii}] = iPercentile(tX, percentiles(ii), numelX, nCumulative, bins);
end

%--------------------------------------------------------------------------
function [prctileDataBin, locationInPrctileDataBin] = ...
    iPercentile(tX, percentile, numelX, nCumulative, bins)

% numelX might be tall or in-memory. If tall, optimize the calculation
% using one deferred call (all inputs are scalar).
if istall(numelX)
    [p,pf,pc] = elementfun(@iGetElementIdxs, numelX, percentile);
    outAdap = matlab.bigdata.internal.adaptors.getAdaptor(percentile);
    p.Adaptor = outAdap;
    pf.Adaptor = outAdap;
    pc.Adaptor = outAdap;
else
    [p,pf,pc] = iGetElementIdxs(percentile, numelX);
end

% Percentile can be in one bin or the interpolation between values in two
% separate bins. Note that these indices are zero-based.
[lowerBin,upperBin] = iGetBinIdx(nCumulative, pf, pc);

% Reduced set of data where we know the percentile is. Note that we offset
% by -1 to make the bin indices 1-based.
binsToKeep = iIsOneOf(bins, lowerBin, upperBin, -1);
reducedX = filterslices(binsToKeep, tX);

% Sort only the reduced set of data.
reducedX = sort(reducedX,1);

% Form the vector 1:size(reducedX,1).
import matlab.bigdata.internal.lazyeval.getAbsoluteSliceIndices
absoluteIndices = tall(getAbsoluteSliceIndices(hGetValueImpl(reducedX)));

% Extract the data bin containing the percentile.
nPrevious = nnz(bins <= lowerBin);
binToKeep = iIsOneOf(absoluteIndices, pc, pf, nPrevious);
prctileDataBin = filterslices(binToKeep, reducedX);

if nargout > 1
    % tall/isoutlier 'quartiles'
    % Location in bin is between [0,1), unless the tall array is empty or
    % scalar, then the location is NaN.
    if istall(p)
        locationInPrctileDataBin = elementfun(@iGetLocationInBin, p, pf, numelX);
        locationInPrctileDataBin.Adaptor = p.Adaptor;
    else
        % All sizes were in-memory so we can immediately evaluate.
        locationInPrctileDataBin = tall.createGathered( ...
            iGetLocationInBin(p, pf, numelX), getExecutor(tX));  
    end
end

%--------------------------------------------------------------------------
function bins = iReplaceInf(bins, vals, newIdx)
bins(isnan(vals) | (isinf(vals) & vals > 0)) = newIdx;

%--------------------------------------------------------------------------
function [p,pf,pc] = iGetElementIdxs(numelX, percentile)
% Helper to calculate the specific element index we want for one percentile
% plus floor/ceil versions of the same.
p = (percentile./100) .* numelX + 0.5;
pf = floor(p);
pc = ceil(p);

%--------------------------------------------------------------------------
function [bin1,bin2] = iGetBinIdx(nCumulative, pf, pc)
% Combine the calculation of the bin above and below. Bin indices returned
% are zero-based.
[bin1,bin2] = aggregatefun(@countLessThan, @sum2, nCumulative, pf, pc);
bin1.Adaptor = matlab.bigdata.internal.adaptors.getScalarDoubleAdaptor();
bin2.Adaptor = matlab.bigdata.internal.adaptors.getScalarDoubleAdaptor();

function [xa,xb] = countLessThan(x, a, b)
xa = nnz(x < a);
xb = nnz(x < b);

function [a,b] = sum2(a, b)
a = sum(a,1);
b = sum(b,1);

%--------------------------------------------------------------------------
function out = iIsOneOf(in, val1, val2, offset)
% Return a tall logical vector indicating elements of IN that are VAL1 or
% VAL2.
out = elementfun( @(x,a,b,o) x==(a-o) | x==(b-o), in, val1, val2, offset );
out.Adaptor = copySizeInformation(matlab.bigdata.internal.adaptors.getAdaptorForType("logical"), in.Adaptor);

%--------------------------------------------------------------------------
function p = iGetLocationInBin(p, pf, numelX)
% Return distance in bin or NaN if original input was empty or scalar.
if numelX<2
    % Empty or scalar
    p = NaN("like", p);
else
    p = p - pf;
end