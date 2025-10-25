function y = prctile(x,p,varargin)
% Syntax:
%     P = prctile(A,p)
%     P = prctile(___,vecdim)
%     P = prctile(___,Method=method)
%
% For more information, see documentation

%   Copyright 1993-2024 The MathWorks, Inc.

if ~isreal(x)
    error(message('MATLAB:prctile:InvalidData'));
end
if ~(isreal(p) && (isnumeric(p) || islogical(p)) && isvector(p) && ~isempty(p)) || any(p < 0 | p > 100)
    error(message('MATLAB:prctile:BadPercents'));
end

% Make sure we are working in floating point to avoid rounding errors.
if isfloat(x)
    castOutput = true;
    yproto = dominantTypeHelper(x,p); % prototype output
    calcproto = yproto;               % for internal calculations
elseif isinteger(x)
    % integer types are up-cast to either double or single and the result
    % is down-cast back to the input type
    castOutput = true;
    yproto = dominantTypeHelper(x,p); % prototype output
    if contains(underlyingType(x), ["8" "16"])
        % single precision is enough
        x = single(x);
    else
        % Needs double precision
        x = double(x);
    end
    calcproto = x([]); % prototype needed for calculation
elseif isduration(x)
    castOutput = false;
    calcproto = x([]);
else
    % All other types (e.g. char, logical) are cast to double and the result is
    % double, ignoring the type of p
    castOutput = false;
    try
        x = double(x);
    catch
        % For types without double conversion, just proceed
    end
    calcproto = x([]);
end

% Parse dim
dimArgGiven = false;
if nargin > 2
    dim = varargin{1};
    if matlab.internal.math.checkInputName(dim,'all')
        dim = 1:ndims(x);
        dimArgGiven = true;
    elseif ~ischar(dim) && ~(isstring(dim) && isscalar(dim))
        if ~isvector(dim) || ~isreal(dim) || any(floor(dim) ~= dim) || any(dim < 1) || ~allfinite(dim) || isempty(dim) || ~isnumeric(dim)
            error(message('MATLAB:getdimarg:invalidDim'));
        end
        if ~isscalar(dim) && numel(unique(dim)) ~= numel(dim)
            error(message('MATLAB:getdimarg:vecDimsMustBeUniquePositiveIntegers'));
        end
        dimArgGiven = true;
    elseif nargin == 3
        if matlab.internal.math.checkInputName(dim,'Method')
            error(message('MATLAB:prctile:KeyWithoutValue'));
        else
            error(message('MATLAB:getdimarg:invalidDim'));
        end
    end
end
sz = size(x);
if ~dimArgGiven
    dim = matlab.internal.math.firstNonSingletonDim(x);
end

% Parse name-value arguments
validMethods = ["exact", "approximate", "midpoint", "exclusive", "inclusive"];
indMethod = [true false false false false];
doApproxMethod = false;
delta = 1e3;
rs = [];
deltaRSGiven = false;
indStart = dimArgGiven + 1;
num = numel(varargin);
if rem(num - indStart,2) == 0
    error(message('MATLAB:prctile:KeyWithoutValue'));
end
for j = indStart:2:num
    % Allow undocumented parameters 'Delta' and 'RandStream' for backward compatibility.
    indName = matlab.internal.math.checkInputName(varargin{j},["Method","Delta","RandStream"]);
    if ~any(indName)
        error(message('MATLAB:prctile:ParseNames'));
    end
    if indName(1)
        indMethod = matlab.internal.math.checkInputName(varargin{j+1},validMethods);
        if ~any(indMethod) || (indMethod(1) && indMethod(4))
            error(message('MATLAB:prctile:InvalidMethod'))
        end
        doApproxMethod = indMethod(2);
    elseif indName(2)
        % Delta is undocumented, and TDigest does error checking.
        delta = varargin{j+1};
        deltaRSGiven = true;
    else
        % RandStream is undocumented, and TDigest does error checking.
        rs = varargin{j+1};
        deltaRSGiven = true;
    end
end
if deltaRSGiven && ~doApproxMethod
    % Delta and RandStream only apply to the approximate method.
    error(message('MATLAB:prctile:DeltaRSApproxOnly'));
end
if doApproxMethod
    checkSupportedForApproximateMethod(x);
end

% Permute the array so that the requested dimension is the first dim.
if dimArgGiven
    if all(dim > numel(sz))
        % Avoid unecessary calculations and return quickly.
        np = numel(p);
        r = ones(1,min(dim));
        r(end) = np;
        if castOutput
            y = cast(x, "like", yproto);
        else
            y = x;
        end
        y = repmat(y,r);
        return;
    end
    if ~isequal(dim,1)
        dim = sort(dim);
        if issparse(x) && any(dim > 2)
            % permuting beyond second dimension not supported for sparse
            dim(dim > 2) = [];
        end
        perm = [dim setdiff(1:max(ndims(x),max(dim)),dim)];
        x = permute(x, perm);
        sz = size(x);
    end
end

% Special behavior for vectors needed after percentile computation. Store
% whether x is a vector now before x is reshaped during the computation.
XisVector = isvector(x);

% If X is empty, return all NaNs.
if isempty(x)
    if isequal(size(x),[0 0]) && ~dimArgGiven
        szout = size(p);
    else
        if dimArgGiven
            work_dim = 1:numel(dim);
        else
            work_dim = dim;
        end
        szout = sz; 
        szout(work_dim) = 1;
        szout(work_dim(1)) = numel(p);
    end
    y = createArray(szout,Like=calcproto,FillValue=missing);
else
    % Drop X's leading singleton dims, and combine its trailing dims.  This
    % leaves a matrix, and we can work along columns.
    if dimArgGiven
        work_dim = 1:numel(dim);
    else
        work_dim = dim;
    end
    work_dim = work_dim(work_dim <= numel(sz));
    nrows = prod(sz(work_dim));
    ncols = numel(x) ./ nrows;
    x = reshape(x, nrows, ncols);

    if ~isfloat(p)
        p = double(p);
    end
    
    if doApproxMethod
        if issparse(x)
            numCols = size(x,2);
            y = zeros(numel(p),numCols,"like",calcproto);
            for k = 1:numCols
                v = x(:,k);
                td = matlab.internal.math.TDigestArray(full(v), delta, rs);
                y(:,k) = matlab.internal.math.tdigestICDF(td,p,min(v,[],1),max(v,[],1));
            end
        else
            td = matlab.internal.math.TDigestArray(x, delta, rs);
            y = matlab.internal.math.tdigestICDF(td,p,min(x,[],1),max(x,[],1));
        end
    else
        if isequal(p,50) && ~issparse(x) && isnumeric(x) && ~isobject(x)
            % Utilize internal fast median
            y = matlab.internal.math.columnmedian(x,true);
        else
            x = sort(x,1);
            n = sum(~isnan(x), 1); % Number of non-NaN values in each column
            
            % For columns with no valid data, set n=1 to get nan in the result
            n(n==0) = 1;
            
            % If the number of non-nans in each column is the same, do all cols at once.
            if all(n == n(1))
                n = n(1);
                if isequal(p,50) % make the median fast
                    if rem(n,2) % n is odd
                        y = x((n+1)/2,:);
                    else        % n is even
                        y = (x(n/2,:) + x(n/2+1,:))/2;
                    end
                else
                    y = interpColsSame(x,p,n,indMethod);
                end
                
            else
                % Get percentiles of the non-NaN values in each column.
                y = interpColsDiffer(x,p,n,indMethod);
            end
        end
    end

    % Reshape Y to conform to X's original shape and size.
    szout = sz; 
    szout(work_dim) = 1;
    szout(work_dim(1)) = numel(p);
    y = reshape(y,szout);
end
% undo the DIM permutation
if dimArgGiven && ~isequal(dim,1)
     y = ipermute(y,perm);  
end

% If X is a vector, the shape of Y should follow that of P, unless an
% explicit DIM arg was given.
if ~dimArgGiven && XisVector
    y = reshape(y,size(p)); 
end

if castOutput
    y = cast(y, "like", yproto);
end

% -------------------------------------------------------------------------
function y = interpColsSame(x, p, n, indMethod)
%INTERPCOLSSAME An aternative approach of 1-D linear interpolation which is
%   faster than using INTERP1Q and can deal with invalid data so long as
%   all columns have the same number of valid entries (scalar n).

[r,k,kp1,kIsNaN] = getIndexValues(p, n, indMethod);

% Linear interpolation
y = r.*x(kp1,:)+(1-r).*x(k,:);

% Make sure that values we hit exactly are copied rather than interpolated
copyRow = (r==0);
if any(copyRow)
    y(copyRow,:) = x(k(copyRow),:);
end

% Make sure that identical values are copied rather than interpolated
copyValue = ~kIsNaN & (x(k,:)==x(kp1,:));
if any(copyValue(:))
    x = x(k,:); % expand x
    y(copyValue) = x(copyValue);
end

% -------------------------------------------------------------------------
function y = interpColsDiffer(x, p, n, indMethod)
%INTERPCOLSDIFFER A simple 1-D linear interpolation of columns that can
%deal with columns with differing numbers of valid entries (vector n).

[r,k,kp1,kIsNaN] = getIndexValues(p, n, indMethod);
[nrows, ncols] = size(x);

% Convert K and Kp1 into linear indices
offset = nrows*(0:ncols-1);
k =  k + offset;
kp1 = kp1 + offset;

% Use simple linear interpolation for the valid percentages.
% Note that NaNs in r produce NaN rows.
y = r.*x(kp1)+(1-r).*x(k);

% Make sure that values we hit exactly and that identical values are copied
% rather than interpolated
copyValue = (r==0) | (~kIsNaN & (x(k)==x(kp1)));
if any(copyValue(:))
    x = x(k); % expand x
    y(copyValue) = x(copyValue);
end

% -------------------------------------------------------------------------
function [r,k,kp1,kIsNaN] = getIndexValues(p, n, indMethod)
%GETINDEXVALUES Computes the rank according to the method specified in
% indMethod, and returns the ratio and row indices needed for
% interpolation.
% n is either a scalar or a row vector, and it represents the number of
% non-NaN values in each column.

% Make p a column vector.
if isrow(p)
    p = p';
end

if indMethod(1) || indMethod(3) % exact or midpoint
    r = (p/100)*n + 0.5;
elseif indMethod(4) % exclusive
    r = (p/100)*(n+1);
else % inclusive
    r = (p/100)*(n-1) + 1;
end

k = floor(r);     % K gives the index for the row just before r
kp1 = k + 1;      % K+1 gives the index for the row just after r
r = r - k;        % R is the ratio between the K and K+1 rows
kIsNaN = isnan(k);

% Find indices that are out of the range 1 to n and cap them
kp1 = min( kp1, n );
if indMethod(5) % inclusive
    % All percentages are included within the bounds of the data, so we
    % only need to take care of NaNs
    k(kIsNaN) = 1;
else
    k(k<1 | kIsNaN) = 1;
    if indMethod(4) % exclusive
        k = min( k, n );
    end
end

% -------------------------------------------------------------------------
function proto = dominantTypeHelper(x,p)
% Adapted from internal.stats.dominantType
%DOMINANTTYPE return a prototype of the dominant input type
%   DOMINANTTYPE uses standard arithmetic rules to determine a prototype of
%   the dominant type from the inputs.
%
%   Example:
%   dominantType( single(1), double(2) ) => single
%   dominantType( single(1), gpuArray(2) ) => gpuArray(single)
%
% Get a prototype output to determine the type. Mostly X is in the nature
% of data here, and P is something that determine how we index into X, but
% we're going to treat them both as data for the purposes of determining
% the output type. If someone decided to put P on the GPU we want to
% respect that.

% Add together empty arrays so that the types propagate but no actual
% calculation is required.
x = x([]);
if isa(p,'double')
    proto = x;
else
    try
        proto = x + p([]);
        if issparse(x)
            proto = sparse(proto);
        end
    catch
        % if types will not add, first type encountered wins
        proto = x;
    end
end

function checkSupportedForApproximateMethod(x)
m = [];

if ~isnumeric(x)
    m = message('MATLAB:prctile:NumericRequiredForApprox');
elseif isobject(x)
    m = message('MATLAB:prctile:NoObjectsForApprox');
end
if ~isempty(m)
    throwAsCaller(MException(m.Identifier, '%s', getString(m)));
end
