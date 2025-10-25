function y = tdigestICDF(tdigestArray, prct, txMin,txMax)
% tdigestICDF computes percentile approximation from an array of TDigest.

%   Copyright 2018-2021 The MathWorks, Inc.

numPrct = length(prct);
sz = size(tdigestArray);
tdigestArray = reshape(tdigestArray, 1,[]);
numCol = prod(sz(2:end));
y = zeros(numPrct, numCol);

if all(sz ==0)
    y = nan(size(prct));
    return;
end

if sz(1) == 0
    y = nan([numPrct,sz(2:end)]);
    return;
end

if any(sz(2:end)==0)
    y = zeros([numPrct,sz(2:end)]);
    return;
end

for i = 1:numCol
    n = double(tdigestArray(i).NumDataPoints);
    y(:,i) = tdigestArray(i).icdf(prct/100);
    if ~isempty(txMin)
        y(prct < 50/n,i) = txMin(i);
    end
    if ~isempty(txMax)
        y(prct > 100*(n-0.5)/n,i) = txMax(i);
    end
end
y = reshape(y,[numPrct, sz(2:end)]);