function [tr,varargout] = corrcoef(tx,varargin)
%CORRCOEF Correlation coefficients.
%   R = CORRCOEF(X)
%   R = CORRCOEF(X,Y)
%   [R,P] = CORRCOEF(X)
%   [R,P] = CORRCOEF(X,Y)
%   [R,P,RLO,RUP] = CORRCOEF(...)
%   [...] = CORRCOEF(...,'alpha',alpha)
%   [...] = CORRCOEF(...,'rows',option) - option can be 'all' or 'complete'
%
%   Limitations:
%   1) X and Y must be tall arrays of the same size, even if both are vectors.
%   2) X and Y cannot be scalars for CORRCOEF(X,Y).
%   3) Y must be 2-D.
%   4) Option 'pairwise' is not supported.
%
%   See also: CORRCOEF.

%   Copyright 2017-2023 The MathWorks, Inc.

nargoutchk(0,4);
% Validate first input
tall.checkIsTall(mfilename, 1, tx);
tx = tall.validateType(tx, mfilename, {'numeric'}, 1);
tx = tall.validateMatrix(tx, 'MATLAB:corrcoef:InputDim');

% Check second input if it is tall.
% If it is tall, assume it is CORRCOEF(X,Y,...)
offset = 2;
if ~isempty(varargin)
    if istall(varargin{1})
        ty = varargin{1};
        varargin = varargin(2:end);
        ty = tall.validateType(ty, mfilename, {'numeric'}, offset);
        ty = tall.validateMatrix(ty, 'MATLAB:corrcoef:InputDim');
        [tx, ty] = validateSameTallSize(tx, ty);
        [tx, ty] = lazyValidate(tx, ty, {@(x,y)size(x)==size(y), ...
            'MATLAB:corrcoef:XYmismatch'});
        tx = tall.validateNotScalar(tx, ...
            'MATLAB:bigdata:array:CorrcoefTwoScalarInputsNotSupported');
        offset = 3;
    end
    % Rest of inputs must not be tall
    tall.checkNotTall(upper(mfilename), offset, varargin{:});
end

% Process parameter name/value inputs as in
% /toolbox/matlab/datafun/corrcoef.m but returning cov() NaNFlag
isTwoInputSyntax = (offset == 3);
[alpha, NaNFlag] = getparams(isTwoInputSyntax, varargin{:});

if strcmp(NaNFlag,'partialrows') % corrcoef - 'pairwise'
    error(message('MATLAB:bigdata:array:CorrcoefPairwiseNotSupported'));
end

% P, RLO and RUP cannot be computed if x or y are complex
if nargout>1
    tx = lazyValidate(tx, {@(x)(~isnumeric(x) || isreal(x)), ...
        'MATLAB:corrcoef:ComplexInputs'});
    if isTwoInputSyntax
        ty = lazyValidate(ty, {@(x)(~isnumeric(x) || isreal(x)), ... 
            'MATLAB:corrcoef:ComplexInputs'});
    end
end

[~, m] = size(tx);
typeX = classUnderlying(tx);

% Compute the covariance and get the number of rows without NaNs for
% 'complete' corrcoef option
if ~isTwoInputSyntax % corrcoef(tX)
    [tc, n, numEl] = computeCov({tx}, 0, NaNFlag);
else % corrcoef(tX,tY)
    [tc, n, numEl] = computeCov({tx, ty}, 0, NaNFlag);
    m = 2; % For two variables, tc and tr are 2-by-2 matrices
end

% To perform with clientfun:
% (1) Handle empty inputs with numEl and n and return R, P, RLO and RUP
% (2) Compute R with correl
% (3) If requested, compute P, RLO, and RUP from: R, nCount, m, alpha,
% class(tx)

[tr,varargout{1:max(0,nargout-1)}] = clientfun(@computeCorrcoefOutputs, ...
    tc, n, m, numEl, typeX, alpha, nargout);
end


% -------------------------------------------------------------------------
% Based on /toolbox/matlab/datafun/corrcoef.m
function [tr,varargout] = computeCorrcoefOutputs(tc,n,m,numEl,typeX,alpha,numOutputs)

if (m == numEl) && (n <= numEl)
    m = 1; % Row vector 
end

% (1) Handle empty inputs as in /toolbox/matlab/datafun/corrcoef.m
if numEl == 0
    if n <= 1
        % Zero observations with m variables results in an m x m NaN,
        % unless m == 0 where we return a scalar NaN by convention.
        % Note, an empty row vector is treated as zero observations with
        % one variable, consistent with treatment of non-empty row vectors.
        tr = NaN(max(m,1), typeX);
    else
        % n > 1 observations with no variables returns an empty matrix of
        % correlations.
        tr = ones(0, typeX);
    end
    tp = tr; trlo = tr; trup = tr;
    varargout{1} = tp;
    varargout{2} = trlo;
    varargout{3} = trup;
    return;
end

% (2) Compute R
tr = correl(tc, m);

% (3) If requested, compute P-values and confidence bounds RLO and RUP
if numOutputs >= 2
    % Based on /toolbox/matlab/datafun/corrcoef.m
    % Operate on half of symmetric matrix.
    lowerhalf = (tril(ones(m),-1)>0);
    rv = tr(lowerhalf);
    nv = n;
    
    % Tstat = +/-Inf and p = 0 if abs(r) == 1, NaN if r == NaN.
    Tstat = rv .* sqrt((nv-2) ./ (1 - rv.^2));
    tp = zeros(m,typeX);
    tp(lowerhalf) = 2*tpvalue(-abs(Tstat),nv-2);
    tp = tp + tp' + diag(diag(tr)); % Preserve NaNs on diag.
    varargout{1} = tp;
    
    % Compute confidence bound if requested.
    if numOutputs >= 3
        % Confidence bounds are degenerate if abs(r) = 1, NaN if r = NaN.
        z = 0.5 * log((1+rv)./(1-rv));
        zalpha = NaN(size(nv),typeX);
        if any(nv>3)
            zalpha(nv>3) = (-erfinv(alpha - 1)) .* sqrt(2) ./ sqrt(nv(nv>3)-3);
        end
        trlo = zeros(m,typeX);
        trlo(lowerhalf) = tanh(z-zalpha);
        trlo = trlo + trlo' + diag(diag(tr)); % Preserve NaNs on diag.
        varargout{2} = trlo;
        trup = zeros(m,typeX);
        trup(lowerhalf) = tanh(z+zalpha);
        trup = trup + trup' + diag(diag(tr)); % Preserve NaNs on diag.
        varargout{3} = trup;
    end
end
end

% -------------------------------------------------------------------------
% Based on /toolbox/matlab/datafun/corrcoef.m ([r,n] = correl(x))
function tr = correl(tc, m)

d = sqrt(diag(tc)); % sqrt first to avoid under/overflow
tr = tc ./ d ./ d'; % r = r ./ d*d';
% Fix up possible round-off problems, while preserving NaN: put exact 1 on 
% the diagonal, and limit off-diag to [-1,1].
tr = (tr+tr')/2;
t = abs(tr) > 1;
tr(t) = sign(tr(t));
tr(1:m+1:end) = sign(diag(tr));
end

% -------------------------------------------------------------------------
% Based on /toolbox/matlab/datafun/corrcoef.m
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
end

% -------------------------------------------------------------------------
% Process parameter name/value inputs as in
% /toolbox/matlab/datafun/corrcoef.m
function [alpha,userows] = getparams(isTwoInputSyntax, varargin)
%GETPARAMS Process input parameters for CORRCOEF.
alpha = 0.05;
userows = "all";

% Y cannot be a non-tall data for syntax corrcoef(X,Y)
if ~isTwoInputSyntax && isscalar(varargin) && isnumeric(varargin{1})
    error(message('MATLAB:bigdata:array:CorrcoefCovSecondArgMustBeTall'));
end

while ~isempty(varargin)
   if isscalar(varargin)
      error(message('MATLAB:corrcoef:unmatchedPVPair'));
   end
   pname = varargin{1};
   if ~ischar(pname) && ~(isstring(pname) && isscalar(pname))
      error(message('MATLAB:corrcoef:invalidArgName'));
   end
   pval = varargin{2};
   if ~(ischar(pname) || (isstring(pname) && isscalar(pname))) ...
           || (strlength(pname) < 1)
       j = false(1, 2);
   else
       j = strncmpi(pname, ["alpha" "rows"], strlength(pname));
   end
   if ~any(j)
      error(message('MATLAB:corrcoef:invalidArgName'));
   end
   if j(1)
      alpha = pval;
   else
      userows = pval;
   end
   varargin(1:2) = [];
end

% Check for valid inputs.
if ~isnumeric(alpha) || ~isscalar(alpha) || alpha<=0 || alpha>=1
   error(message('MATLAB:corrcoef:invalidAlpha'));
end
oktypes = ["all" "complete" "pairwise"];
if (ischar(userows) || (isstring(userows) && isscalar(userows))) ...
        && (strlength(userows) > 0)
   i = strncmpi(userows, oktypes, strlength(userows));
else
   i = [];
end
if ~any(i) 
   error(message('MATLAB:corrcoef:invalidRowChoice'));
end

% Map oktypes with covoktypes
covoktypes = {'includenan', 'omitrows', 'partialrows'};
userows = covoktypes{i};
end
