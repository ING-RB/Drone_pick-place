function y = mean(x,dim,varargin)
%MEAN   Average or mean value
%   S = MEAN(X) is the mean value of the elements in X if X is a vector.
%   For matrices, S is a row vector containing the mean value of each
%   column.
%   For N-D arrays, S is the mean value of the elements along the first
%   array dimension whose size does not equal 1.
%
%   MEAN(X,"all") is the mean of all elements in X.
%
%   MEAN(X,DIM) takes the mean along the dimension DIM of X.
%
%   MEAN(X,VECDIM) operates on the dimensions specified in the vector
%   VECDIM. For example, MEAN(X,[1 2]) operates on the elements contained
%   in the first and second dimensions of X.
%
%   S = MEAN(...,OUTTYPE) specifies the type in which the mean is performed,
%   and the type of S. Available options are:
%
%   "double"    -  S has class double for any input X
%   "native"    -  S has the same class as X
%   "default"   -  If X is floating point, that is double or single,
%                  S has the same class as X. If X is not floating point,
%                  S has class double.
%
%   S = MEAN(...,NANFLAG) specifies how NaN values are treated:
%
%   "includemissing" / "includenan" -
%                  (default) The mean of a vector containing NaN values is NaN.
%   "omitmissing" / "omitnan"       -
%                  The mean of a vector containing NaN values is the mean
%                  of all its non-NaN elements. If all elements are NaN,
%                  the result is NaN.
%
%   S = MEAN(...,Weights = W) computes the weighted mean. The elements
%   of W must be nonnegative. The weight argument is not supported with a
%   vector dimension argument or the "all" flag.
%
%   Example:
%       X = [1 2 3; 3 3 6; 4 6 8; 4 7 7]
%       mean(X,1)
%       mean(X,2)
%
%   Class support for input X:
%      float: double, single
%      integer: uint8, int8, uint16, int16, uint32,
%               int32, uint64, int64
%
%   See also MEDIAN, STD, MIN, MAX, VAR, COV, MODE.

%   Copyright 1984-2024 The MathWorks, Inc.

isDimSet = nargin > 1 && ((~ischar(dim) && ~(isstring(dim) && isscalar(dim))) || ...
     matlab.internal.math.checkInputName(dim,'all'));

isWeighted = false;
% Optimize syntax with no flag, dim and 1 flag
if nargin == 1 || (nargin == 2 && isDimSet)
    flag = 'default';
    omitnan = false;
elseif nargin == 2
    flag = dim;
    [flag, omitnan] = parseFlag(flag);
elseif nargin == 3 && isDimSet
    flag = varargin{1};
    [flag, omitnan] = parseFlag(flag);
else
    [flag, omitnan,w,isWeighted] = parseInputs(x,dim,isDimSet,isWeighted,varargin{:});
end

if ~isDimSet
    % preserve backward compatibility with 0x0 empty
    if isequal(x,[])
        y = sum(x,flag)./0;
        return
    end
    dim = matlab.internal.math.firstNonSingletonDim(x);
else
    if isempty(dim) && ~isvector(dim)
        error(message('MATLAB:mean:nonNumericSecondInput'));
    end
end

if isinteger(x)
    % accumulation flag may still be partial
    isnative = matlab.internal.math.checkInputName(flag, 'native');
    if intmin(underlyingType(x)) == 0  % unsigned integers
        y = sum(x,dim,flag);

        precisionPreserved = (isnative && all(y(:) < intmax(underlyingType(x)))) || ...
            (~isnative && all(y(:) <= flintmax));

        if precisionPreserved
            y = y./mysize(x,dim);
        else  % throw away and recompute
            y = intmean(x,dim,isnative);
        end
    else  % signed integers
        ypos = sum(max(x,0),dim,flag);
        yneg = sum(min(x,0),dim,flag);

        if (isnative && all(ypos(:) < intmax(underlyingType(x))) && ...
                all(yneg(:) > intmin(underlyingType(x)))) || ...
                (~isnative && all(ypos(:) <= flintmax) && ...
                all(yneg(:) >= -flintmax))
            % no precision lost, can use the sum result
            y = (ypos+yneg)./mysize(x,dim);
        else  % throw away and recompute
            y = intmean(x,dim,isnative);
        end
    end
else

    if ~isWeighted
        if omitnan
            % Compute sum and number of NaNs
            m = sum(x, dim, flag, 'omitnan');
            nr_nonnan = mysize(x, dim) - matlab.internal.math.countnan(x, dim);
            % Divide by the number of non-NaNs.
            y = m ./ nr_nonnan;
        else
            y = sum(x, dim, flag) ./ mysize(x,dim);
        end
    else
        if matlab.internal.math.checkInputName(flag, 'double',2)
            x = double(x);
            w = double(w);
        elseif matlab.internal.math.checkInputName(flag,'native')
            error(message('MATLAB:mean:invalidOuttype'));
        end

        xw = x.*w;
        if omitnan
            m = sum(xw, dim, flag, 'omitnan');
            y = m./ sum(w,dim,flag,'omitnan');

            % Don't omit NaNs caused by computation (not missing data)
            ind = any(isnan(xw) & ~isnan(w), dim);
            y(ind) = NaN;
        else
            m = sum(xw, dim, flag);
            y = m./ sum(w,dim,flag);
        end
    end
end

end


function y = intmean(x, dim, isnative)
% compute the mean of integer vector

ysiz = size(x);
if ischar(dim) || isstring(dim)
    x = x(:);
else
    dim = reshape(dim, 1, []);
    dim = min(dim, ndims(x)+1);
    if max(dim)>length(ysiz)
        ysiz(end+1:max(dim)) = 1;
    end
    tf = false(size(ysiz));
    tf(dim) = true;
    r = find(~tf);
    perm = [find(tf), r];
    x = permute(x, perm);
    x = reshape(x,[prod(ysiz(dim)), prod(ysiz(r))]);
    ysiz(dim) = 1;
end

xUnderlyingType = underlyingType(x);
if ~isnative
    outPrototype = double(x([]));
else
    outPrototype = x([]);
end

if intmin(xUnderlyingType) == 0
    accumPrototype = uint64(x([]));
else
    accumPrototype = int64(x([]));
end
xsiz = size(x);
xlen = cast(xsiz(1), "like", accumPrototype);

y = zeros([1 xsiz(2:end)], "like", outPrototype);
ncolumns = prod(xsiz(2:end));
int64input = isUnderlyingType(x,'uint64') || isUnderlyingType(x,'int64');

for iter = 1:ncolumns
    xcol = cast(x(:,iter), "like", accumPrototype);
    if int64input
        xr = rem(xcol,xlen);
        ya = sum((xcol-xr)./xlen,1,'native');
        xcol = xr;
    else
        ya = zeros("like", accumPrototype);
    end
    xcs = cumsum(xcol);
    ind = find(xcs == intmax("like", accumPrototype) | (xcs == intmin("like", accumPrototype) & (xcs < 0)) , 1);

    while (~isempty(ind))
        remain = rem(xcs(ind-1),xlen);
        ya = ya + (xcs(ind-1) - remain)./xlen;
        xcol = [remain; xcol(ind:end)];
        xcs = cumsum(xcol);
        ind = find(xcs == intmax("like", accumPrototype) | (xcs == intmin("like", accumPrototype) & (xcs < 0)), 1);
    end

    if ~isnative
        remain = rem(xcs(end),xlen);
        ya = ya + (xcs(end) - remain)./xlen;
        % The latter two conversions to double never lose precision as
        % values are less than FLINTMAX. The first conversion may lose
        % precision.
        y(iter) = double(ya) + double(remain)./double(xlen);
    else
        y(iter) = cast(ya + xcs(end) ./ xlen, "like", outPrototype);
    end
end
if ~isscalar(y)
    y = reshape(y,ysiz);
end

end

function [flag, omitnan] = parseFlag(flag)

    if isInvalidText(flag)
        error(message('MATLAB:mean:invalidFlags'));
    end

    s = matlab.internal.math.checkInputName(flag, {'omitnan', 'includenan','omitmissing','includemissing'});

    omitnan = s(1) || s(3);
    if any(s)
        % flag can be nanflag or outtype. If nanflag is set, then flag is
        % outtype and it's set to default
        flag = 'default';
    end
end


function [flag, omitnan,w,isWeighted] = parseInputs(x,dim,isDimSet,isWeighted,varargin)
if ~isDimSet
    varargin = [{dim} varargin];
end

omitnan = false;
w = [];
flag = 'default';
isNanFlagSet = false;
isOuttypeSet = false;

narg = numel(varargin);

for ii =1:narg
    input = varargin{ii};

    s = matlab.internal.math.checkInputName(input,{'omitnan', 'includenan','omitmissing','includemissing'});

    if any(s) && isNanFlagSet
        % For cases like mean(x,'omitnan','omitnan')
        error(message('MATLAB:mean:invalidFlags'));
    end

    isWeighted = matlab.internal.math.checkInputName(input,'Weights');

    if any(s)
        omitnan = s(1) || s(3);
        isNanFlagSet = true;
    elseif isWeighted
        nvp = varargin(ii:end);
        break
    else
        if ~isempty(flag) && isOuttypeSet
            % For cases like mean(x,'double','native')
            error(message('MATLAB:mean:invalidFlags'));
        end
        % Otherwise, rely on sum to parse the outtype flag
        flag = input;
        isOuttypeSet = true;
    end

end

if isWeighted
    if ~isDimSet
        dim = matlab.internal.math.firstNonSingletonDim(x);
    end
    [w, isWeighted] = matlab.internal.math.parseWeights(x,dim,isDimSet,omitnan, nvp);
end

end

function tf = isInvalidText(str)
tf = (ischar(str) && ~isrow(str)) || ...
    (isstring(str) && ~(isscalar(str) && (strlength(str) > 0)));
end

function s = mysize(x, dim)
if isnumeric(dim) || islogical(dim)
    if isscalar(dim)
        s = size(x,dim);
    else
        s = 1;
        for i = 1:length(dim)
            s = s * size(x,dim(i));
        end
    end
else
    s = numel(x);
end

end
