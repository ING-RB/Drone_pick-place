function z = cumtrapz(x,y,dim)
%   Syntax:
%      Q = cumtrapz(Y)
%      Q = cumtrapz(X,Y)
%      Q = cumtrapz(___,dim)
%
%   For more information, see documentation

%   Copyright 1984-2024 The MathWorks, Inc.

%   Make sure x and y are column vectors, or y is a matrix.

perm = [];
nshifts = 0;
if nargin == 3 % cumtrapz(x,y,dim)
    % Preserve existing errors for non-integer dim.
    dim = min(ndims(y)+1, getDimArg(dim));
    perm = [dim:max(ndims(y),dim) 1:dim-1];
    y = permute(y,perm);
    [m,n] = size(y);
elseif nargin == 2 && isscalar(y) % cumtrapz(y,dim)
    dim = y;
    y = x;
    x = 1;
    % Preserve existing errors for non-integer dim.
    dim = min(ndims(y)+1, getDimArg(dim));
    perm = [dim:max(ndims(y),dim) 1:dim-1];
    y = permute(y,perm);
    [m,n] = size(y);
else % cumtrapz(y) and cumtrapz(x, y)
    if nargin < 2
        y = x;
        x = 1;
    end
    [y,nshifts] = shiftdim(y);
    [m,n] = size(y);
end
if ~isvector(x)
    error(message('MATLAB:cumtrapz:xNotVector'));
end
% Make sure we have a column vector.
x = x(:);
if ~isscalar(x) && numel(x) ~= m
    error(message('MATLAB:cumtrapz:LengthXMismatchY'));
end

if isempty(y)
    z = y;
elseif isscalar(x)
    z = [zeros(1,n,class(y)); x * cumsum((y(1:end-1,:) + y(2:end,:)),1)]/2;
else
    dt = diff(x,1,1)/2;
    z = [zeros(1,n,class(y)); cumsum(dt .* (y(1:end-1,:) + y(2:end,:)),1)];
end

siz = size(y);
z = reshape(z,[ones(1,nshifts),siz]);
if ~isempty(perm)
    z = ipermute(z,perm);
end
end

% local function
function dim = getDimArg(dim)
if isnumeric(dim) || islogical(dim)
    dim = cast(dim, "like", 1);
end
dim = matlab.internal.math.getdimarg(dim);
end

