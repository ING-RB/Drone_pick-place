function N = vecnorm(ta, varargin)
%VECNORM   Vector norm.
%   N = VECNORM(A)
%   N = VECNORM(A,p)
%   N = VECNORM(A,p,DIM)
%
%   Example:
%
%       % Find the 2-norm along the columns and rows of a matrix
%       A = tall([0 1 2; 3 4 5])
%       c = vecnorm(A)
%       r = vecnorm(A,2,2)
%
%   See also VECNORM, TALL.

%   Copyright 2018-2024 The MathWorks, Inc.

%% Argument checks
narginchk(1,3);

% First argument must be tall. Others must not.
if nargin > 1
    tall.checkNotTall(upper(mfilename), 1, varargin{:});
end

% Grab arguments or set default values
dim = [];
dimSupplied = false;
switch nargin
    case 1
        p = 2;
    case 2
        p = varargin{1};
    case 3
        p = varargin{1};
        dim = varargin{2};
        dimSupplied = true;
end

if dimSupplied
    [ta, p, dim] = iCheckInputs(ta, p, dim);
else
    [ta, p] = iCheckInputs(ta, p);
    % Try to deduce dimension (will be left empty if we can't)
    dim = matlab.bigdata.internal.util.deduceReductionDimension(ta.Adaptor);
end

if isempty(dim) % Dimension not supplied and not deducable
    dimArg = {};
else
    dimArg = {dim};
end

%% Computations
if isinf(p)
    % Infinity norm is the maximum absolute element. However we need to be
    % careful about empties.
    N = max(abs(ta), [], dimArg{:}, 'includenan');
    % We may need to fix up the result if the tall size was 0 - we need
    % to expand it to 1.
    Nadap = N.Adaptor;
    N = clientfun(@iHandleEmptyTallDim, N, size(ta), dimArg{:});
    if isempty(dim)
        % Here we don't even know which dimension was changed.
        N.Adaptor = resetSizeInformation(Nadap);
    else
        N.Adaptor = setSizeInDim(Nadap, dim, 1);
    end
else
    % All other norms can be done using sum
    N = sum(abs(ta).^(p), dimArg{:}).^(1/p);
end

end % vecnorm


function [ta, p, dim] = iCheckInputs(ta, p, dim)
% Check that the inputs are all supported types and sizes, throwing
% appropriate errors if not.

try
    % Data must be floating point
    ta = tall.validateTypeWithError(ta, "vecnorm", 1, "float", "MATLAB:vecnorm:inputType");

    % P must be a positive scalar or "inf"
    if isempty(p) % Avoid empty arguments
        error(message("MATLAB:vecnorm:unknownNorm"));
    end
    if matlab.internal.datatypes.isScalarText(p)
        if strncmpi(p, "inf", strlength(p))
            p = Inf;
        else
            error(message("MATLAB:vecnorm:unknownNorm"));
        end
    elseif ~isnumeric(p) || ~isscalar(p) || ~isreal(p) || (p <= 0) || isnan(p) % p must be a positive real value or Inf
        error(message("MATLAB:vecnorm:unknownNorm"));
    end
    if ~isfloat(p)
        p = double(p);
    end
    if nargin>2
        dim = matlab.internal.math.getdimarg(dim);
    end
    
catch err
    throwAsCaller(err)
end

end


function A = iHandleEmptyTallDim(A, globalSzA, dim)
% Make sure the size in the reduction dimension is 1, not 0
if nargin<3
    % Strangely:
    %    vecnorm([], inf, 1) is 1x0, but
    %    vecnorm([], inf) is 1x1
    if isequal(globalSzA, [0 0])
        A = zeros(like=A);
        return;
    end
    % All other cases, work out which dim was reduced
    dim = find(globalSzA~=1, 1, 'first');
    if isempty(dim)
        dim = 1;
    end
end

if dim<=numel(globalSzA) && globalSzA(dim)==0
    globalSzA(dim) = 1;
    A = zeros(globalSzA, like=A);
end
end
