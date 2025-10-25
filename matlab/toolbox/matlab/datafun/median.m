function y = median(x,dim,flag,varargin)
%MEDIAN Median value
%   MEDIAN(X) is the median value of the elements in x for vectors.
%   For matrices, MEDIAN(X) is a row vector containing the median value
%   of each column.  For N-D arrays, MEDIAN(X) is the median value of the
%   elements along the first non-singleton dimension of X.
%
%   MEDIAN(X,"all") is the median of all elements of X.
%
%   MEDIAN(X,DIM) takes the median along the dimension DIM of X.
%
%   MEDIAN(X,VECDIM) operates on the dimensions specified in the vector
%   VECDIM. For example, MEDIAN(X,[1 2]) operates on the elements contained
%   in the first and second dimensions of X.
%
%   MEDIAN(...,NANFLAG) specifies how NaN values are treated:
%
%   "includemissing" / "includenan" -
%                  (default) The median of a vector containing NaN values
%                  is also NaN.
%   "omitmissing" / "omitnan"       -
%                  The median of a vector containing NaN values is the
%                  median of all its non-NaN elements. If all elements
%                  are NaN, the result is NaN.
%
%   MEDIAN(...,Weights = W) computes the weighted median by finding the
%   value in X associated with cumulative 50% of the weights specified by W.
%   The elements of W must be nonnegative. The weight argument is not
%   supported with a vector dimension argument or the "all" flag.
%
%   Example:
%       X = [1 2 4 4; 3 4 6 6; 5 6 8 8; 5 6 8 8]
%       median(X,1)
%       median(X,2)
%
%   Class support for input X:
%      float: double, single
%      integer: uint8, int8, uint16, int16, uint32, int32, uint64, int64
%
%   See also MEAN, STD, MIN, MAX, VAR, COV, MODE.

%   Copyright 1984-2024 The MathWorks, Inc.

if isstring(x)
    error(message('MATLAB:median:wrongInput'));
end

omitnan = false;
dimIsAll = false;
isWeighted = false;
if nargin == 1
    dimSet = false;
else
    dimIsAll = matlab.internal.math.checkInputName(dim,'all');

    dimSet = (~ischar(dim) && ~(isstring(dim) && isscalar(dim))) || dimIsAll;

    if ~dimSet
        if nargin == 2
            % median(x,nanflag)
            flag = dim;
        else
            if matlab.internal.math.checkInputName(dim,"Weights")
                varargin = [{dim flag} varargin];
                dim = matlab.internal.math.firstNonSingletonDim(x);
                flag = 'includemissing';
            else
                if nargin == 3
                    error(message('MATLAB:median:unknownOption'));
                end

                varargin = [{flag} varargin];
                flag = dim;
                dim = matlab.internal.math.firstNonSingletonDim(x);
            end
        end
    else
        if nargin > 3 && matlab.internal.math.checkInputName(flag,"Weights")
            varargin = [{flag} varargin];
            flag = 'includemissing';
        end
    end
end

if dimSet
    if isnumeric(dim) || islogical(dim)
        if ~isvector(dim)
            error(message('MATLAB:getdimarg:invalidDim'));
        else
            if ~isreal(dim) || any(floor(dim) ~= ceil(dim)) || any(dim < 1) || ~allfinite(dim)
                error(message('MATLAB:getdimarg:invalidDim'));
            end
            if ~isscalar(dim) && numel(unique(dim)) ~= numel(dim)
                error(message('MATLAB:getdimarg:vecDimsMustBeUniquePositiveIntegers'));
            end
        end
        dim = reshape(dim, 1, []);
    elseif ~dimIsAll
        error(message('MATLAB:getdimarg:invalidDim'));
    end
end

if ((nargin >= 2 && ~dimSet) || (dimSet && nargin >= 3))
    if ~isrow(flag)
        if nargin == 2
            error(message('MATLAB:median:unknownOption'));
        else
            error(message('MATLAB:median:unknownFlag'));
        end
    end

    s = matlab.internal.math.checkInputName(flag, {'omitnan', 'includenan','omitmissing','includemissing'});

    if ~any(s)
        if nargin == 2
            error(message('MATLAB:median:unknownOption'));
        else
            error(message('MATLAB:median:unknownFlag'));
        end
    end

    omitnan = s(1) || s(3);
end

sz = size(x);

if ~isempty(varargin) % nv pairs are specified
    [w,isWeighted] = matlab.internal.math.parseWeights(x,dim,dimSet,omitnan,varargin);
    if ~isequal(size(w),size(x))
        wsz=sz;
        if dim <= numel(wsz)
            wsz(dim) = 1;
        end
        w = repmat(w,wsz);
    end
end

if isempty(x)
    if ~dimSet

        % The output size for [] is a special case when DIM is not given.
        if isequal(x,[])
            if isinteger(x) || islogical(x)
                y = zeros("like",x);
            else
                y = nan("like",x);
            end
            return;
        end
        dim = matlab.internal.math.firstNonSingletonDim(x);
    end

    if dimIsAll
        dim = 1:ndims(x);
    end

    if max(dim)>numel(sz)
        sz(end+1:max(dim)) = 1;
    end
    sz(dim) = 1; % Set size to 1 along dimensions
    if isinteger(x) || islogical(x)
        y = zeros(sz,"like",x);
    else
        y = nan(sz,"like",x);
    end

    return;
end

if dimIsAll
    x = x(:);
    dim = 1;
    sz = size(x);
end

if dimSet && all(dim > numel(sz))
    y = x;
    return;
end

if isvector(x) && (~dimSet || (isscalar(dim) && sz(dim) > 1))
    % If input is a vector, calculate single value of output.
    if isreal(x) && ~issparse(x) && isnumeric(x) && ~isobject(x) && ~isWeighted
        % Utilize internal fast median
        if isrow(x)
            x = x.';
        end
        y = matlab.internal.math.columnmedian(x,omitnan);
    else
        if isWeighted
            [x,perm,sizey] = permuteX(x,dim,sz);
            w = permuteW(w,perm,dim,sz,sizey);
            y = weightedmedian(x,omitnan,w);
        else
            x = sort(x);
            nCompare = length(x);
            if isnan(x(nCompare))        % Check last index for NaN
                if omitnan
                    nCompare = find(~isnan(x), 1, 'last');
                    if isempty(nCompare)
                        y = nan("like",x([])); % using x([]) so that y is always real
                        return;
                    end
                else
                    y = nan("like",x([])); % using x([]) so that y is always real
                    return;
                end
            end

            half = floor(nCompare/2);
            y = x(half+1);
            if 2*half == nCompare        % Average if even number of elements
                y = meanof(x(half),y);
            end
        end
    end
else
    if ~dimSet
        dim = matlab.internal.math.firstNonSingletonDim(x);
    elseif issparse(x)
        % permuting beyond second dimension not supported for sparse
        dim(dim > 2) = [];
    else
        dim = min(dim, ndims(x)+1);
        sz(end+1:max(dim)) = 1;
    end

    [x,perm,sizey] = permuteX(x,dim,sz);

    if isreal(x) && ~issparse(x) && isnumeric(x) && ~isobject(x) && ~isWeighted
        % Utilize internal fast median
        y = matlab.internal.math.columnmedian(x,omitnan);
    else
        if isWeighted
            w = permuteW(w,perm,dim,sz,sizey);
            y = weightedmedian(x,omitnan,w);
        else
            % Sort along columns
            x = sort(x, 1);
            if ~omitnan || all(~isnan(x(end, :)))
                % Use vectorized method with column indexing.  Reshape at end to
                % appropriate dimension.
                nCompare = size(x,1);          % Number of elements used to generate a median
                half = floor(nCompare/2);    % Midway point, used for median calculation

                y = x(half+1,:);
                if 2*half == nCompare
                    y = meanof(x(half,:),y);
                end

                if isfloat(x)
                    y(isnan(x(nCompare,:))) = NaN;   % Check last index for NaN
                end
            else
                % Get median of the non-NaN values in each column.
                y = nan(1, size(x, 2), "like", x([])); % using x([]) so that y is always real

                % Number of non-NaN values in each column
                n = sum(~isnan(x), 1);

                % Deal with all columns that have an odd number of valid values
                oddCols = find((n>0) & rem(n,2)==1);
                oddIdxs = sub2ind(size(x), (n(oddCols)+1)/2, oddCols);
                y(oddCols) = x(oddIdxs);

                % Deal with all columns that have an even number of valid values
                evenCols = find((n>0) & rem(n,2)==0);
                evenIdxs = sub2ind(size(x), n(evenCols)/2, evenCols);
                y(evenCols) = meanof( x(evenIdxs), x(evenIdxs+1) );
            end
        end
    end
    % Reshape and permute back
    y = reshape(y, sizey);
end
end

%============================

function c = meanof(a,b)
% MEANOF the mean of A and B with B > A
%    MEANOF calculates the mean of A and B. It uses different formula
%    in order to avoid overflow in floating point arithmetic.
if islogical(a)
    c = a | b;
else
    if isinteger(a)
        % Swap integers such that ABS(B) > ABS(A), for correct rounding
        ind = b < 0;
        temp = a(ind);
        a(ind) = b(ind);
        b(ind) = temp;
    end
    c = a + (b-a)/2;
    k = (sign(a) ~= sign(b)) | isinf(a) | isinf(b);
    c(k) = (a(k)+b(k))/2;
end
end

function wM = weightedmedian(x,omitnan,w)
allFiniteNoZeroWeights = allfinite(x) && allfinite(w) && all(w,'all');

% sort the inputs and rearrange the weights
[sX,I] = sort(x,1);
I = I + (0:size(x,2)-1)*size(x,1);
sW = w(I);

if ~allFiniteNoZeroWeights
    % handle edge cases where the weights contain NaN, Inf and 0's
    % Over write the weighted medium with NaNs
    % if 1) the weights are a combination of 0's or NaNs,equivalent to all(zeroW | isnan(sW),1)
    %    2) the weights contain Infs
    %    3) x contains any NaN，regardless of the associated weights
    overWriteWithNaN = ~any(sW,1) | any(isinf(sW), 1);
    if ~omitnan
        anyNaNx = isnan(sX(end,:));
        overWriteWithNaN = overWriteWithNaN | anyNaNx;
    end

    if all(overWriteWithNaN)
        wM = NaN([1 size(sW,2)],"like",x);
        return
    end
end

% scale weights to avoid overflow
% using nextpow2 to avoid losing nice numbers when scaling
sW = sW./2.^(nextpow2(max(sW,[],1))-1);

if omitnan
    csw = cumsum(sW,1,"omitmissing");
    cswr = cumsum(sW,1,"reverse","omitmissing");
else
    % sW has no NaNs in this branch 
    % because weights with NaN errors with default nanflag
    csw = cumsum(sW,1);
    cswr = cumsum(sW,1,"reverse");
end

% find the linear indices of entries ≥ 0.5 in each column, 
% proceeding from the top-down or bottom-up.
% by using the differences between sums and 0.5,
% instead of using find in a for-loop.

% top-down
d = csw >= 0.5*csw(end,:);
[~,y] = max(d,[],1,"linear");

% bottom-up
dr = cswr >= 0.5*csw(end,:);
[~,yr] = max(flip(dr),[],1);

% flip yr back and shift it to get the linear indices
yr = (size(sX,1) - yr + 1) + ((0:(size(sX,2)-1))*size(sX,1));

sameMedians = y == yr;

if all(sameMedians)
    % no ties among columns / rows
    wM = sX(y);
else
    % columns / rows contain ties
    wM = sX(y);
    tiedM = meanof(sX(y(~sameMedians)),sX(yr(~sameMedians)));
    wM(~sameMedians) = tiedM;
end

if ~allFiniteNoZeroWeights
    wM(overWriteWithNaN) = NaN;
end
end


function [x,perm,sizey] = permuteX(x,dim,sz)
% Reshape and permute x into a matrix of size prod(sz(dim)) x (numel(x) / prod(sz(dim)))
sizey = sz;
sizey(dim) = 1;

tf = false(size(sizey));
tf(dim) = true;
perm = [find(tf), find(~tf)];
x = permute(x, perm);
x = reshape(x, [prod(sz(dim)), prod(sizey)]);
end

function w = permuteW(w,perm,dim,sz,sizey)
% Reshape and permute w into a matrix of size prod(sz(dim)) x (numel(x) / prod(sz(dim)))

w = permute(w, perm);
w = reshape(w, [prod(sz(dim)), prod(sizey)]);
end