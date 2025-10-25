function [tc, nCount, numEl] = computeCov(cellIn, normFlag, NaNFlag)
% Private function for tall/cov and access to nCount and numEl for
% tall/corrcoef

%   Copyright 2017-2023 The MathWorks, Inc.

if length(cellIn) == 2
    aggregateFunc = @(x,y)covWithTwoDataInput(x, y, NaNFlag);
    reduceFcn = @(x) reduceCovCell(x, 1);
    tmpCell = aggregatefun(aggregateFunc,reduceFcn,cellIn{:});
else
    aggregateFcn = @(x, dim) covWithOneDataInput(x, dim, NaNFlag);
    reduceFcn = @(x, dim) reduceCovCell(x, dim);
    tmpCell = tall(reduceInDefaultDim({aggregateFcn, reduceFcn}, cellIn{:}));
end
[tc, nCount, numEl] = clientfun(@(x)getCovCell(x,normFlag), tmpCell);
end

% -------------------------------------------------------------------------
function outCell = covWithOneDataInput(x, dim, NaNFlag)
% Wrapper needed to call reduceInDefaultDim with one data input.
if dim == 2
    x = x(:);  
end
[nCovCell,nCount,nMean,nNumel] = chunkCov(x, NaNFlag);
outCell = {nCovCell,nCount,nMean,nNumel};
end

% -------------------------------------------------------------------------
function outCell = covWithTwoDataInput(x, y, NaNFlag)
% Handling the two data inputs.
[nCovCell,nCount,nMean,nNumel] = chunkCov([x(:), y(:)], NaNFlag);
outCell = {nCovCell,nCount,nMean,nNumel};
end

% -------------------------------------------------------------------------
function [nCovCell,nCount,nMean,nNumel] = chunkCov(data, NaNFlag)
% Compute covariant matrix of a partition.
nNumel = numel(data);
h = ~any(isnan(data),2);
nCount = sum(h);   % count without rows with NaNs
if ismember(NaNFlag,["includenan", "includemissing"]) || nCount == size(data,1) %no NaNs
    nCount = size(data,1); %data has NaN
else
    assert(strcmp(NaNFlag,"omitrows"))
    data = data(h,:);
end
nMean = sum(data,1)./max(nCount,1);  % mean
data = data - nMean;
nCovCell = {data'*data};  % Cov times n
end

% -------------------------------------------------------------------------
function outCell = reduceCovCell(inCell, dim)
% Combine the covariance matrix from each partition.
if size(inCell,1) == 1
    outCell = inCell;
else
    assert(dim == 1);
    nCovCell = cat(1, inCell{:,1});
    nCount = cat(1, inCell{:,2});
    nMean = cat(1, inCell{:,3});
    nNumel = cat(1, inCell{:,4});
    if length(nCovCell) >= 2
        nNumel = sum(nNumel,1);
        n = nCount;
        nCount = sum(n,1);
        me = nMean;
        nMean  = (n' * me)./max(nCount,1);
        d = me - nMean;
        t = d'*(d.*n);
        t = (t+t')/2;  % Ensure symmetry.
        nCovCell = {t + nCovCell{1} + nCovCell{2}};
    end
    outCell = {nCovCell,nCount,nMean,nNumel};
end
end

% -------------------------------------------------------------------------
function [X,n,Numel] = getCovCell(inCell,normFlag)
% Extract and update the combined result
X = inCell{1}{1};
n = inCell{2};
Numel= inCell{4};
if normFlag == 0
    X = X./max(n-1,1);
else 
    X = X./max(n,1);
end
if Numel == 0 || n == 0 % handle empty matrix or all rows are omitted.
    X(:) = NaN;
end
if ~isreal(X)
    r = size(X,1); % Renaming to r in order to return n = inCell{2}
    X(1:r+1:end) = real(diag(X)); % handle NaN diagonal
end
end
