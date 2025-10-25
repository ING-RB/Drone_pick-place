function [r,p,rlo,rup] = corrcoef(x,varargin)
%   Syntax:
%      R = corrcoef(A)
%      R = corrcoef(A,B)
%      [R,P] = corrcoef(___)
%      [R,P,RL,RU] = corrcoef(___)
%      [___] = corrcoef(___,Name,Value)
%
%   For more information, see documentation

%   Copyright 1984-2024 The MathWorks, Inc.

if ~isempty(varargin) && isnumeric(varargin{1})
    y = varargin{1};
    varargin(1) = [];

    % Convert two inputs to equivalent single input.
    if numel(x)~=numel(y)
        error(message('MATLAB:corrcoef:XYmismatch'));
    end
    x = [x(:) y(:)];
elseif ~ismatrix(x)
    error(message('MATLAB:corrcoef:InputDim'));
end

% Quickly dispose of most common case.
if nargout<=1 && isempty(varargin)
    r = correl(x);
    return;
end

if ~isreal(x) && nargout>1
    error(message('MATLAB:corrcoef:ComplexInputs'));
end

% Deal with empty inputs
[n,m] = size(x);
if isempty(x)
    if n <= 1
        % Zero observations with m variables results in an m x m NaN,
        % unless m == 0 where we return a scalar NaN by convention.
        % Note, an empty row vector is treated as zero observations with
        % one variable, consistent with treatment of non-empty row vectors.
        r = NaN(max(m,1), class(x));
    else
        % n > 1 observations with no variables returns an empty matrix of
        % correlations.
        r = ones(0, class(x));
    end
    p = r; rlo = r; rup = r;
    return;
end

% Treat all vectors like column vectors.
if isvector(x)
    x = x(:);
    [~, m] = size(x);
end

% Process parameter name/value inputs.
[alpha,userows] = getparams(varargin{:});

% Compute correlations.
t = isnan(x);
removemissing = any(t(:));
if (userows == "all") || ~removemissing
    [r, n] = correl(x);
elseif userows == "complete"
    % Remove observations with missing values.
    x = x(~any(t,2),:);
    if isrow(x)
        % x is now a row vector, but wasn't a row vector on input.
        r = NaN(size(x, 2), "like", x([]));
        n = 1;
    else
        [r, n] = correl(x);
    end
else
    % Compute correlation for each pair.
    [r, n] = correlpairwise(x);
end

% Compute p-value if requested.
if nargout>=2
    % Operate on half of symmetric matrix.
    lowerhalf = (tril(ones(m),-1)>0);
    rv = r(lowerhalf);
    if ~isempty(n) && ~isscalar(n)
        nv = n(lowerhalf);
    else
        nv = n;
    end

    % Tstat = +/-Inf and p = 0 if abs(r) == 1, NaN if r == NaN.
    Tstat = rv .* sqrt((nv-2) ./ (1 - rv.^2));
    p = zeros(m,class(x));
    p(lowerhalf) = 2*tpvalue(-abs(Tstat),nv-2);
    p = p + p' + diag(diag(r)); % Preserve NaNs on diag.

    % Compute confidence bound if requested.
    if nargout>=3
        % Confidence bounds are degenerate if abs(r) = 1, NaN if r = NaN.
        z = 0.5 * log((1+rv)./(1-rv));
        zalpha = NaN(size(nv),class(x));
        if any(nv>3)
            zalpha(nv>3) = (-erfinv(alpha - 1)) .* sqrt(2) ./ sqrt(nv(nv>3)-3);
        end
        rlo = zeros(m,class(x));
        rlo(lowerhalf) = tanh(z-zalpha);
        rlo = rlo + rlo' + diag(diag(r)); % Preserve NaNs on diag.
        rup = zeros(m,class(x));
        rup(lowerhalf) = tanh(z+zalpha);
        rup = rup + rup' + diag(diag(r)); % Preserve NaNs on diag.
    end
end


% ------------------------------------------------
function [r,n] = correl(x)
%CORREL Compute correlation matrix without error checking.

[n,m] = size(x);
r = cov(x);
d = sqrt(diag(r)); % sqrt first to avoid under/overflow
r = r ./ d ./ d'; % r = r ./ d*d';
% Fix up possible round-off problems, while preserving NaN: put exact 1 on the
% diagonal, and limit off-diag to [-1,1].
r = (r+r')/2;
t = abs(r) > 1;
r(t) = sign(r(t));
r(1:m+1:end) = sign(diag(r));


% ------------------------------------------------
function [c, nrNotNaN] = correlpairwise(x)
% apply corrcoef pairwise to columns of x, ignoring NaN entries

n = size(x, 2);

c = zeros(n, "like", x([])); % using x([]) so that c is always real
nrNotNaN = zeros(n, "like", x([]));

% First fill in the diagonal:
% Fix up possible round-off problems, while preserving NaN: put exact 1 on the
% diagonal, unless computation results in NaN.
c(1:n+1:end) = sign(localcorrcoef_elementwise(x, x));

% Now compute off-diagonal entries
for j = 2:n
    x1 = repmat(x(:, j), 1, j-1);
    x2 = x(:, 1:j-1);

    % make x1, x2 have the same NaN patterns
    x1(isnan(x2)) = nan;
    x2(isnan(x(:, j)), :) = nan;

    [c(j,1:j-1), nrNotNaN(j,1:j-1)] = localcorrcoef_elementwise(x1, x2);
end
c = c + tril(c,-1)';
nrNotNaN = nrNotNaN + tril(nrNotNaN,-1)';

% Fix up possible round-off problems: limit off-diag to [-1,1].
t = abs(c) > 1;
c(t) = sign(c(t));


% ------------------------------------------------
function [c, nrNotNaN] = localcorrcoef_elementwise(x,y)
%LOCALCORRCOEF Return c(i) = corrcoef of x(:, i) and y(:, i), for all i
% with no error checking and assuming NaNs are removed
% returns 1xn vector c
% x, y must be of the same size, with identical NaN patterns

nrNotNaN = sum(~isnan(x), 1);
xc = x - (sum(x, 1, 'omitnan') ./ nrNotNaN);
yc = y - (sum(y, 1, 'omitnan') ./ nrNotNaN);

denom = nrNotNaN - 1;
denom(nrNotNaN == 1) = 1;
denom(nrNotNaN == 0) = 0;

xy = conj(xc) .* yc;
cxy = sum(xy, 1, 'omitnan') ./ denom;
xx = conj(xc) .* xc;
cxx = sum(xx, 1, 'omitnan') ./ denom;
yy = conj(yc) .* yc;
cyy = sum(yy, 1, 'omitnan') ./ denom;

c = cxy ./ sqrt(cxx) ./ sqrt(cyy);

% Don't omit NaNs caused by computation (not missing data)
ind = any((isnan(xy) | isnan(xx) | isnan(yy)) & ~isnan(x), 1);
c(ind) = nan;


% ------------------------------------------------
function p = tpvalue(x,v)
%TPVALUE Compute p-value for t statistic.

normcutoff = 1e7;
if ~isscalar(x) && isscalar(v)
    v = repmat(v,size(x));
end

% Initialize P.
p = NaN(size(x));
nans = (isnan(x) | ~(0<v)); % v == NaN ==> (0<v) == false

% First compute F(-|x|).
%
% Cauchy distribution.  See Devroye pages 29 and 450.
cauchy = (v == 1);
p(cauchy) = .5 + atan(x(cauchy))/pi;

% Normal Approximation.
normal = (v > normcutoff);
p(normal) = 0.5 * erfc(-x(normal) ./ sqrt(2));

% See Abramowitz and Stegun, formulas 26.5.27 and 26.7.1.
gen = ~(cauchy | normal | nans);
p(gen) = betainc(v(gen) ./ (v(gen) + x(gen).^2), v(gen)/2, 0.5)/2;

% Adjust for x>0.  Right now p<0.5, so this is numerically safe.
reflect = gen & (x > 0);
p(reflect) = 1 - p(reflect);

% Make the result exact for the median.
p(x == 0 & ~nans) = 0.5;


% -----------------------------------------------
function [alpha,userows] = getparams(varargin)
%GETPARAMS Process input parameters for CORRCOEF.
alpha = 0.05;
userows = "all";
if nargin == 0
    return
end

while ~isempty(varargin)
    if isscalar(varargin)
        error(message('MATLAB:corrcoef:unmatchedPVPair'));
    end

    pname = varargin{1};
    if ischar(pname) || (isstring(pname) && isscalar(pname))
        ind = strncmpi(pname, ["alpha" "rows"], max(strlength(pname),1));
    else
        ind = [];
    end
    if ~any(ind)
        error(message('MATLAB:corrcoef:invalidArgName'));
    end

    pval = varargin{2};
    if ind(1)
        alpha = pval;
    else
        userows = pval;
    end
    varargin(1:2) = [];
end

% Check for valid inputs.
if ~isnumeric(alpha) || ~isscalar(alpha) || ~isreal(alpha) ...
        || ~(0 < alpha && alpha < 1)
    error(message('MATLAB:corrcoef:invalidAlpha'));
end

oktypes = ["all" "complete" "pairwise"];
if ischar(userows) || (isstring(userows) && isscalar(userows))
    k = strncmpi(userows, oktypes, max(strlength(userows),1));
else
    k = [];
end
if ~any(k)
    error(message('MATLAB:corrcoef:invalidRowChoice'));
end
userows = oktypes(k);
