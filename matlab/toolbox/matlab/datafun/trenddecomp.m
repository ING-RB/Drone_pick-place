function [LT,ST,R] = trenddecomp(A,varargin)
%TRENDDECOMP Find trends in data.
%   T = TRENDDECOMP(A) finds trends in A using an additive decomposition.
%   That is, A is the sum of the returned long-term trend, seasonal or
%   oscillatory trend, and remainder (A = T + ST + R). A must be a vector,
%   table, or timetable. If A is a table or timetable, TRENDDECOMP operates
%   on each table variable separately. The trends are identified using
%   singular spectrum analysis (SSA).
%
%   When A is a vector, T is a vector the same size as A and contains the
%   long-term trend.
%
%   When A is a table or timetable, T is a table or timetable with
%   variables containing the long-term trend, seasonal trends, and the
%   remainder. If multiple seasonal trends are found, they are returned as
%   a matrix in the same table variable.
%
%   T = TRENDDECOMP(A,'ssa',LAG) finds trends in A using the SSA algorithm,
%   which is an additive decomposition. LAG determines the size of the
%   matrix on which the SVD is performed. LAG must be a scalar between 3
%   and N/2 where N is the number of elements in A. This method is useful
%   when the periods of the seasonal trends are unknown. If the period is
%   known, then LAG should be a multiple of the period. Larger values of
%   LAG typically provide better separation of the trends.
%
%   T = TRENDDECOMP(A,'stl',PERIOD) finds trends in A using the STL
%   algorithm, which is an additive decomposition based on a
%   locally-weighted regression. PERIOD is a scalar or vector containing
%   the periods of the seasonal trends. When A is a timetable, PERIOD can
%   be a duration.
%
%   T = TRENDDECOMP(A,'NumSeasonal',N) or T =
%   TRENDDECOMP(A,'ssa',LAG,'NumSeasonal',N) specifies the number of
%   seasonal trends. N must be a scalar.
%
%   [T,ST,R] = TRENDDECOMP(A,...) also returns the seasonal trends and the
%   remainder of A using any of the previous syntaxes when A is a vector.
%   ST is a matrix with the number of columns equal to the number of
%   seasonal trends.
%
%   EXAMPLE: Create data
%       t = (1:200)';
%       trend = 0.001*(t-100).^2;
%       p1 = 20;
%       p2 = 30;
%       periodic1 = 2*sin(2*pi*t/p1);
%       periodic2 = 0.75*sin(2*pi*t/p2);
%       noise = 2*(rand(200,1) - 0.5);
%       F = trend + periodic1 + periodic2 + noise;
%       FTable = table(F);
%
%   Use SSA to find trends:
%       [T,ST,R] = trenddecomp(F);
%       plot([F T ST R]);
%       legend("Data","Long-term","Seasonal1","Seasonal2","Remainder");
%
%   Use STL to find trends:
%       T = trenddecomp(FTable,'stl',[20 30]);
%       T = addvars(T,F,'Before',1,'NewVariableNames','F_Original');
%       stackedplot(T);
%
%   See also DETREND, SMOOTHDATA.

%   Copyright 2021-2024 The MathWorks, Inc.

if istabular(A)
    % Error if asking for more than 1 output for table
    nargoutchk(0,1);
else
    if ~isvector(A)
        error(message('MATLAB:trenddecomp:InvalidFirstInput'));
    end
    A = A(:);
end

[method,methodType,numST,AisTabular] = parseInputs(A,varargin{:});

if AisTabular
    if istimetable(A)
        LT = timetable(A.Properties.RowTimes);
    else
        LT = A([],[]);
    end
    varNames = A.Properties.VariableNames;
    for vj = 1:width(A)
        namevj = varNames{vj};
        if ~iscolumn(A.(namevj))
            error(message('MATLAB:trenddecomp:NonVectorTableVariable'));
        end
        [lTemp,sTemp,rTemp] = findtrendsVector(A.(namevj),method,methodType,numST);
        lsrnames = {[namevj '_LongTerm'],[namevj '_Seasonal'],[namevj '_Remainder']};
        uniqueLabel = matlab.lang.makeUniqueStrings(lsrnames,LT.Properties.VariableNames,namelengthmax);
        LT.(uniqueLabel{1}) = lTemp;
        LT.(uniqueLabel{2}) = sTemp;
        LT.(uniqueLabel{3}) = rTemp;
    end
else
    [LT,ST,R] = findtrendsVector(A,method,methodType,numST);
end
end

%--------------------------------------------------------------------------

function [LT,ST,R] = findtrendsVector(A,method,methodType,numST)
if ~isfloat(A) || ~isreal(A)
    error(message('MATLAB:trenddecomp:InvalidFirstInput'));
end
if method == "ssa"
    [LT,ST,R] = ssa(A,methodType,numST);
else % 'stl'
    [LT,ST,R] = stl(A,methodType);
end
end

%--------------------------------------------------------------------------

function [LT,ST,R] = ssa(y, L, numST)
% Time series decomposition using Singular-Spectrum Analysis
% L = window length for trajectory matrix
% numST = number of seasonal components, if supplied

% Citation:
% Golyandina, N., and A. Zhigljavsky. Singular Spectrum Analysis for Time
% Series. Springer-Verlag Berlin Heidelberg, 2013.

if any(isinf(y))
    error(message('MATLAB:trenddecomp:InputDataInf'));
end

N = numel(y);

nanFlag = false;
if anynan(y)
    nanFlag = true;
    nanLoc = isnan(y);
    % Fill in NaN with mean
    meanY = mean(y,'omitnan');
    if isnan(meanY)
        % For all NaN input, return the NaNs in the remainder
        y(nanLoc) = 0;
    else
        y(nanLoc) = meanY;
    end
end

% Step 1: Embedding
% Form trajectory matrix X
K = N - L + 1;
X = hankel(y(1:L), y(L:(L+K-1)));

% Step 2: SVD
% Direct approach
[U,ss,V] = svdsketch(X);
ss = diag(ss);

if numel(ss) < 3
    [U,ss,V] = svd(full(X),"vector");
end

% Step 3: Eigentriple grouping
% Find singular values that contribute the most
relContrib = ((ss.^2)./sum(ss.^2));
% Using 0.01 as the cutoff for dominant singular values
h = 0.01;
M = nnz(relContrib >= h);
% Since we always return at least 3 trends, we need to make sure we have enough
% singular values to do that, so adjust M accordingly
if M < 3 && isempty(numST)
    numST = 1;
    M = 3;
end

if ~isempty(numST)
    % Again adjust M to make sure we have enough singular values to make
    % the number of seasonal trends requested
    M = min(numel(ss),max(M, 2*numST + 1));
end

% Calculate weighted correlation matrix
elemTS = elemXToTimeSeries(ss, U, V, M);
weights = [1:L,L*ones(1,K-L-1),N:-1:K];
normElemTS = zeros(1,M,"like",y);
for k = 1:M
    normElemTS(k) = dot(weights,elemTS(:,k).^2);
end
normElemTS = sqrt(normElemTS);

weightsElemTSElemTS = sum(weights(:) .* elemTS .* reshape(elemTS, N, 1, M), 1);

weightsElemTSElemTS = reshape(weightsElemTSElemTS, M, M);

Wcorr = 1 - abs(weightsElemTSElemTS) ./ (normElemTS .* normElemTS');

% Only use a flat vector containing the lower triangle of this symmetric matrix.
Wcorr = Wcorr(tril(true(M), -1));

% Do the grouping
idx = groupSingularValues(Wcorr, 0.7);

% Standardize the index
idx = standardizeIndex(idx);

if isempty(numST)
    numST = max(idx) - 1;
end

% Figure out which group has the low-frequency data and that will be the
% long-term trend
F = abs(fft(U(:,1:M)));
F = F(1:floor(size(U,1)/2),:);
[~,freqIdx] = max(F,[],1);
[~,minFreqIdx] = min(freqIdx);
grpLT = idx(minFreqIdx);

% Step 4: Diagonal averaging - this was done in elemXToTimeSeries, so we
% just combine the appropriate time series here

% Combine time series for grpLT
cols = idx == grpLT;
LT = zeros(N,1,"like",y);
LT(:,1) = sum(elemTS(:,cols),2);

% Adjust ST indices according to grpLT
grpST = 1:numST;
grpAdjust = grpST >= grpLT;
grpST(grpAdjust) = grpST(grpAdjust) + 1;

% If numST > max(idx) the last columns will just be exactly 0
ST = zeros(N,numST,"like",y);
for j = 1:numST
    cols = idx == grpST(j);
    ST(:,j) = sum(elemTS(:,cols),2);
end

if nanFlag
    y(nanLoc) = NaN;
end

R = y - sum(ST,2) - LT;

end

%--------------------------------------------------------------------------

function elemTS = elemXToTimeSeries(s,U,V,M)
% Convert the elementary matrices to timeseries by diagonal averaging since
% the elementary matrices won't be exactly hankel
L = size(U,1);
K = size(V,1);
N = K + L - 1;
elemTS = zeros(N,M,"like",U);
numAntiDiag = K + min(1-K:L-1,0) + min(L-1:-1:1-K,0);
for j = 1:M
    elemTS(:,j) = s(j) * conv(U(:,j), V(:,j)) ./ numAntiDiag.';
end
end

%--------------------------------------------------------------------------

function idx = standardizeIndex(idx)
nextID = 1;
reorderIdx = zeros(max(idx), 1);
for ii=1:length(idx)
    if reorderIdx(idx(ii)) == 0
        reorderIdx(idx(ii)) = nextID;
        nextID = nextID+1;
    end
end
idx = reorderIdx(idx);
end

%--------------------------------------------------------------------------

function [LT,ST,R] = stl(y, np)
% Time series decomposition using STL algorithm
% np = Number of observations in each period, or cycle, of the seasonal
% components

% Citation for algorithm and some of the magic numbers below:
% Cleveland, R.B., W.S. Cleveland, J.E. McRae, and I. Terpenning. "STL: A
% Seasonal-Trend Decomposition Procedure Based on Loess." Journal of
% Official Statistics. Vol. 6, 1990, pp. 3--73.

sparseInput = issparse(y);
if sparseInput
    y = full(y);
end

% Sort periods
[np, periodIdx] = sort(np);

% Error when there are Infs in data
if any(isinf(y))
    error(message('MATLAB:trenddecomp:InputDataInf'));
end

% Determine if robustness iterations are needed
% numOuter - Number of robustness iterations, needed for outliers
% numInner - Number of inner iterations, usually converges quickly
% Whether to use robust estimation or not is based on knowledge of the
% series and diagnostic methods.  If robustness is needed, use numInner = 1
% and numOuter = 5 or 10.
robust = false;
% Robustness weights - reflect how extreme R is
weights = [];
if any(isoutlier(y,'movmedian',np(end)))
    robust = true;
end
if robust
    numOuter = 10;
    numInner = 1;
else
    numOuter = 1;
    numInner = 2;
end

% Initialize LT and ST
LT = zeros(size(y),"like",y);
ST = zeros(size(y,1),numel(np),"like",y);

dim = 1;
degree2 = 2;
numPeriods = numel(np);

for outer = 1:numOuter
    for inner = 1:numInner
        [LT,ST] = innerLoop(y, LT, ST, weights, np);
    end

    for k = 1:numPeriods
        % Post-smoothing of the seasonal components to smooth local roughness
        winsz4 = matlab.internal.math.chooseWindowSize(ST(:,k), dim, [], 0.1, []);
        ST(:,k) = localRegressionForSTL(ST(:,k), winsz4, degree2); % Always use degree 2 here
    end

    R = y - sum(ST,2);

    % Post-smoothing of the trend
    winsz5 = matlab.internal.math.chooseWindowSize(R, dim, [], 0.1, []);
    if winsz5 > 1
        LT = localRegressionForSTL(R, winsz5, degree2); % Always use degree 2 here
    end

    % Find remainder
    R = R - LT;

    if robust
        % Update weights
        h = 6*median(abs(R));
        weights = zeros(size(y));
        u = abs(R)/h;
        u2 = ((1 - u).*(1 + u)).^2;
        weights(u < 1) = u2(u < 1);
    end
end
% Make sure the columns of ST match the order of the periods
ST = ST(:,periodIdx);

if sparseInput
    LT = sparse(LT);
    ST = sparse(ST);
    R = sparse(R);
end
end

%--------------------------------------------------------------------------
function [LT,ST] = innerLoop(y, LT, ST, weights, np)

dim = 1;
degree1 = 1;
degree2 = 2;
numPeriods = numel(np);
n = numel(y);

% Step 1: Detrending
dt = y - LT;

% Loop over all the seasonal components
for k = 1:numPeriods
    period = np(k);
    numSubseries = ceil(n/period);

    % Step 2: Cycle-subseries smoothing
    % allocate vector to hold cycle-subseries smoothing
    C = zeros(n + 2*period,1);
    for j = 1:period
        subseries = dt(j:period:end);
        subseries = subseries([1 1:numel(subseries) numel(subseries)]);
        % Determine window size
        winsz = matlab.internal.math.chooseWindowSize(subseries, dim, [], 0.1, []);
        if winsz == 1
            winsz = numSubseries;
        end
        if isempty(weights)
            C([j:period:n+period, n+period+j]) = localRegressionForSTL(subseries, winsz, degree2);
        else
            subseriesWgts = weights(j:period:end);
            C([j:period:n+period, n+period+j]) = localRegressionForSTL(subseries, winsz, degree2, [1;subseriesWgts;1]);
        end
    end

    % Step 3: Low-pass filter of smoothed cycle-subseries
    % The following is equivalent to 2 movmeans length period and
    % one movmean length 3
    h = 3*(0:period)';
    h([1;end]) = h([1;end]) + [1;-2];
    h = [h; h(end-1:-1:1)] / (period^2*3);
    f = conv(C, h, 'valid');
    % loess smoothing with degree 1 and winsz = least odd integer >= period
    winsz2 = 2*floor(period/2)+1;
    L = localRegressionForSTL(f, winsz2, degree1);

    % Step 4: Detrending of smoothed cycle-subseries
    ST(:,k) = C(period+1:n+period) - L;
    dt = dt - ST(:,k);
end

% Step 5: Deseasonalizing
ds = y - sum(ST,2);

% Step 6: Trend smoothing
% winsz is smallest odd integer >= (1.5*np)/(1 - 1.5*winsz^-1)
winsz3 = 2*floor(((1.5*np(end))/(1 - 1.5/winsz))/2)+1;
if isempty(weights)
    LT = localRegressionForSTL(ds, winsz3, degree1);
else
    LT = localRegressionForSTL(ds, winsz3, degree1, weights);
end
end

%--------------------------------------------------------------------------
function y = localRegressionForSTL(y,winsz,degree,weights)
% Local regression helper that does the local regression calls needed for
% STL
dim = 1;
if nargin < 4 % No weights supplied
    y = matlab.internal.math.localRegression(y, winsz, dim, ...
        "omitnan", degree, "loess", []);
else
    sp = 1:numel(y);
    y = matlab.internal.math.localRegression_impl(y, dim, sp, winsz, ...
        degree, 'omitnan', true, weights);
end
end

%--------------------------------------------------------------------------

function [method,methodType,numST,AisTabular] = parseInputs(A,varargin)
% Parse TRENDDECOMP inputs

AisTabular = istabular(A);
N = size(A,1);

% Set defaults
method = "ssa";
methodType = min(floor(N/2),5000);
numST = [];
methodProvided = false;

if istimetable(A)
    [isReg, step] = isregular(A);
    % Check to make sure timetable has uniform sample points
    if ~isReg
        error(message("MATLAB:trenddecomp:SamplePointsNonUniform"));
    end
end

if nargin > 2
    indStart = 1;
    validMethods = ["ssa","stl"];
    if checkCharString(varargin{indStart})
        indMethod = startsWith(validMethods, varargin{indStart}, 'IgnoreCase', true);
        if nnz(indMethod) == 1
            methodProvided = true;
            method = validMethods(indMethod);
            methodType = varargin{indStart+1};
            indStart = indStart + 2;
            if method == "ssa"
                if N < 6
                    % Need at least 6 data points for SSA
                    error(message('MATLAB:trenddecomp:NotEnoughDataSSA'));
                end
                if ~isnumeric(methodType) || ~isscalar(methodType) || ~isreal(methodType) || ...
                        ~isfinite(methodType) || ~mod(methodType,1) == 0 || methodType < 3 || methodType > size(A,1)/2
                    error(message('MATLAB:trenddecomp:InvalidLag'));
                end
            else % "stl"
                if N < 4
                    % Need at least 4 data points for STL
                    error(message('MATLAB:trenddecomp:NotEnoughDataSTL'));
                end
                if ~(isnumeric(methodType) || isduration(methodType)) || ...
                        ~isvector(methodType) || isempty(methodType) || ...
                        ~allfinite(methodType) || numel(methodType) ~= numel(unique(methodType))
                    error(message('MATLAB:trenddecomp:InvalidPeriod'));
                end
                if isnumeric(methodType)
                    if (~isreal(methodType) || any(methodType < 2) ||...
                            any(size(A,1) < 2*methodType)) || any(mod(methodType,1) ~= 0)
                        error(message('MATLAB:trenddecomp:InvalidNumericPeriod'));
                    end
                    methodType = double(methodType);
                else
                    if ~istimetable(A)
                        error(message('MATLAB:trenddecomp:InvalidDurationPeriodNoTimetable'));
                    end
                    % Convert to number of samples between cycles
                    t = A.Properties.RowTimes;
                    temp = zeros(numel(methodType),1);
                    for j = 1:numel(methodType)
                        temp(j) = floor(N/((t(end) - t(1))/methodType(j)));
                        if mod(methodType(j),step) ~= 0 || temp(j) < 2 || size(A,1) < 2*temp(j)
                            error(message('MATLAB:trenddecomp:InvalidDurationPeriod',char(step)));
                        end
                    end
                    methodType = temp;
                end
            end
        end

        % Parse name-value pairs
        if rem(nargin-indStart,2) == 0
            for j = indStart:2:length(varargin)
                name = varargin{j};
                if ~checkCharString(name)
                    error(message('MATLAB:trenddecomp:ParseFlags'));
                elseif startsWith("NumSeasonal", name, 'IgnoreCase', true)
                    if method == "stl"
                        error(message('MATLAB:trenddecomp:NumSeasonalWithSTL'));
                    end
                    numST = varargin{j+1};
                    if ~isnumeric(numST) || ~isscalar(numST) || ~isreal(numST) || ...
                            mod(numST,1) ~= 0 || numST <= 0 || numST > methodType - 2
                        error(message('MATLAB:trenddecomp:InvalidNumSeasonal'));
                    end
                else
                    if methodProvided
                        error(message('MATLAB:trenddecomp:ParseFlags'));
                    else
                        error(message('MATLAB:trenddecomp:InvalidMethod'));
                    end
                end
            end
        else
            error(message('MATLAB:trenddecomp:IncorrectNumInputs'));
        end
    else
        error(message('MATLAB:trenddecomp:InvalidMethod'));
    end
elseif nargin == 2
    error(message('MATLAB:trenddecomp:IncorrectNumInputs'));
elseif N < 6
    % Need at least 6 data points for SSA
    if (~AisTabular && ~(isfloat(A) && isreal(A))) || ...
            (AisTabular && any(varfun(@(x) ~(isfloat(x) && isreal(x)),A,'OutputFormat','uniform')))
        error(message('MATLAB:trenddecomp:InvalidFirstInput'))
    else
        error(message('MATLAB:trenddecomp:NotEnoughDataSSA'));
    end
end

end

%--------------------------------------------------------------------------

function flag = checkCharString(inputName)
flag = (ischar(inputName) && isrow(inputName)) || (isstring(inputName) && isscalar(inputName) ...
    && strlength(inputName) ~= 0);
end