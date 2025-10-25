function y = prctile(x,p,varargin)
%PRCTILE Percentiles of a sample.
%   Supported syntaxes for tall arrays:
%
%   Y = PRCTILE(X,P)
%   Y = PRCTILE(X,P,'all') 
%   Y = PRCTILE(X,P,DIM)
%   Y = PRCTILE(X,P,VECDIM)
%   Y = PRCTILE(...,'PARAM1',val1,'PARAM2',val2,...)
%
%   Supported parameter name/value pairs:
%       'Method' 
%
%   Usage notes and limitations:
%   * Y = prctile(X,p) returns the exact percentiles only if X is a tall
%     numeric column vector.
%   * Y = prctile(X,p,dim) returns the exact percentiles only when one of
%     these conditions exists:
%      - X is a tall numeric column vector.
%      - X is a tall numeric array and dim is not 1.
%     If X is a tall numeric array and dim is 1, then you must specify
%     'Method','approximate' to use an approximation algorithm based on
%     T-Digest for computing the percentiles.
%   * Y = prctile(X,p,vecdim) returns the exact percentiles only when one
%     of these conditions exists: 
%      - X is a tall numeric column vector.
%      - X is a tall numeric array and vecdim does not include 1.
%      - X is a tall numeric array and vecdim includes 1 and all the nonsingleton
%        dimensions of X.
%     If X is a tall numeric array and vecdim includes 1 but does not include all
%     the nonsingleton dimensions of X, then you must specify
%     'Method','approximate' to use the approximation algorithm.
%
%   See also IQR, MEDIAN, NANMEDIAN, QUANTILE.

%   Copyright 2018-2024 The MathWorks, Inc.

tall.checkNotTall(upper(mfilename), 1, p);
tall.checkNotTall(upper(mfilename), 2, varargin{:});

par = inputParser();
par.addRequired('x');
par.addRequired('p');
par.addOptional('dim',1, @validateDim);
par.addParameter('Method', 'exact');
par.addParameter('Delta',1e3);
par.addParameter('RandStream',[]);
par.parse(x,p,varargin{:});

tx = par.Results.x;
p = par.Results.p;
dim = convertStringsToChars(par.Results.dim);
isDefaultDim = ismember('dim', par.UsingDefaults);
method = par.Results.Method;
delta = par.Results.Delta;
rs = par.Results.RandStream;

validateattributes(p,{'numeric'},...
    {'nonempty','nonnegative','real','vector'},...
    ['tall/',mfilename],'p',2);
validateattributes(p(~isnan(p)),{'numeric'},{'<=',100},...
    ['tall/',mfilename],'p',2);
validatestring(method,["exact", "approximate"]);

tx = tall.validateType(tx, mfilename, {'numeric'},1);

isPermuted = false;
if (length(dim)>=2 && ismember(1,dim)) || strcmpi(dim,'all')
    isPermuted = true;
    sizeOriginal = size(tx);
    vecDim = dim;    
    
    tx = vectorDimPermuteReshape(tx, dim);
    dim = 1;
end

isExact = strcmpi(method,'exact');
if isExact
    if dim == 1
        % Exact solution on tall dimension is expensive to compute as it
        % calculates a full histogram and sorts the bins.
        tx = tall.validateColumn(tx, 'MATLAB:prctile:MustBeColumn');
        tx = filterslices(~ismissing(tx),tx);
        [y1,l1] = percentileDataBin(tx,p);
        if isDefaultDim && isrow(p)
            outDim = 2;
        else
            outDim = 1;
        end
        % Result should be a tall row/column vector with numel(p) entries.
        y = iCombineResults(y1, l1, outDim, tx.Adaptor);
    
    else
        y = slicefun(@(x)prctile(x,p,dim),tx);
        y = clientfun(@adjustSize,y, size(tx), size(p), isDefaultDim);
    end
else
    % Exact solution can be computed. Error and suggest it
    if dim~=1
        error(message('MATLAB:prctile:NoApproximateTall'));
    end
    
    sz = size(tx);
    txmin = min(tx,[],1);
    txmax = max(tx,[],1);
    
    td = TDigest(tx,delta, rs);
    
    y = clientfun(@matlab.internal.math.tdigestICDF,td,p, txmin,txmax);
    y = clientfun(@adjustSize,y, sz, size(p),true); 
end

if isPermuted
    y = clientfun(@reshapeVecDim, y, sizeOriginal, vecDim);
end

% In approximate case, the digest is automatically a double regardless of
% input class. We need to cast it to the expected output type.
cls = tall.getClass(tx);
if ~isExact && cls ~= "double"
    txSample = head(tx, 0);
    y = clientfun(@cast, y, like=txSample);
    if ~isempty(cls)
        y = setKnownType(y, cls);
    end
end

function y = adjustSize(y, xSize, pSize, isDefaultDim)
isvec = length(xSize)==2 && ((xSize(2)==1));
if  isDefaultDim && isvec
    y = reshape(y,pSize);
end

function q = iQuartileFormula(a,xq)
% Convert the bin values and ratio into the scalar result.
if isnan(xq)
    % Empties and scalars
    if isempty(a)
        q = nan;
    else
        q = a;
    end
elseif numel(a) <= 1
    % The quartile coincides with an actual entry of the tall column A.
    q = a;
else
    % The quartile is between two consecutive entries in the tall column A.
    q = interp1(a,xq+1);
end

function y = iCombineResults(y1, l1, dim, inAdap)
% Combine the results for multiple percentile calculations into one vector
for ii=1:numel(y1)
    % Extract the result. It will have the same type as the input (inAdap),
    % but is guaranteed scalar.
    tmp = clientfun(@iQuartileFormula, y1{ii}, l1{ii});
    tmp.Adaptor = resetSizeInformation(inAdap);
    tmp.Adaptor = setKnownSize(tmp.Adaptor, [1 1]);
    y1{ii} = tmp;
end
% If several percentiles were requested we need to combine into a
% vector.
if isscalar(y1)
    y = y1{1};
else
    y = cat(dim, y1{:});
end
        
function y = reshapeVecDim(y, xSize, vecDim)
if strcmpi(vecDim, 'all')
    y = y(:);
else
    xSize(vecDim) = 1;
    y = reshape(y,[size(y,1),xSize(2:end)]);
end


function validateDim(dim)
if isnumeric(dim)
    validateattributes(dim,{'numeric'},{'positive','vector','integer'},['tall/',mfilename],'dim',3);
    if numel(dim)~= numel(unique(dim))
        error(message('MATLAB:getdimarg:vecDimsMustBeUniquePositiveIntegers'));
    end
else
    validatestring(dim,{'all'});
end

function y = vectorDimPermuteReshape(tx, vecdim)
%vectorDimPermuteReshape Utility to handle dimension operations on tall arrays.

y = chunkfun(@(x)iPermuteReshape(x, vecdim), tx);



function xx = iPermuteReshape(x,vecDimIndex)

allDimIndex = 1:ndims(x);
diffDimIndex = setdiff(allDimIndex, vecDimIndex);

if strcmpi(vecDimIndex,'all') || isempty(diffDimIndex)
    xx = x(:);
else  
    reorderDimIndex = [vecDimIndex, diffDimIndex];
    
    xx = permute(x, reorderDimIndex);
    
    sizeX = size(x);
    xx = reshape(xx, [prod(sizeX(vecDimIndex)), sizeX(diffDimIndex)]);

end

