function [B,FB] = fillmissing(A,fillMethod,varargin)
%FILLMISSING   Fill missing entries
%   First argument must be numeric, datetime, duration, calendarDuration,
%   string, categorical, character array, cell array of character vectors,
%   a table, or a timetable.
%   Standard missing data is defined as:
%      NaN                  - for double and single floating-point arrays
%      NaN                  - for duration and calendarDuration arrays
%      NaT                  - for datetime arrays
%      <missing>            - for string arrays
%      <undefined>          - for categorical arrays
%      empty character {''} - for cell arrays of character vectors
%
%   B = FILLMISSING(A,'constant',C) fills missing entries in A with the
%   constant scalar value C. You can also use a vector C to specify
%   different fill constants for each column (or table variable) in A: C(i)
%   represents the fill constant used for the i-th column of A. For tables
%   A, C can also be a cell containing fill constants of different types.
%
%   B = FILLMISSING(A,INTERP) fills standard missing entries using the
%   interpolation method specified by INTERP, which must be:
%      'previous'  - Previous non-missing entry.
%      'next'      - Next non-missing entry.
%      'nearest'   - Nearest non-missing entry.
%      'linear'    - Linear interpolation of non-missing entries.
%      'spline'    - Piecewise cubic spline interpolation.
%      'pchip'     - Shape-preserving piecewise cubic spline interpolation.
%      'makima'    - modified Akima cubic interpolation.
%
%   B = FILLMISSING(A,MOV,K) fills standard missing entries using a
%   centered moving window formed from neighboring non-missing entries.
%   K specifies the window length and must be a positive integer scalar.
%   MOV specifies the moving window method, which must be:
%      'movmean'   - Moving average of neighboring non-missing entries.
%      'movmedian' - Moving median of neighboring non-missing entries.
%   
%   B = FILLMISSING(A,MOV,[NB NF]) uses a moving window defined by the
%   previous NB elements, the current element, and the next NF elements.
%
%   B = FILLMISSING(A,'knn') fills standard missing entries with the
%   corresponding element from the nearest neighbor row, calculated based
%   on the Euclidean distance between rows.
%
%   B = FILLMISSING(A,'knn',k) fills standard missing entries with the
%   mean of the corresponding entries in the k-nearest neighbor rows, 
%   calculated based on the Euclidean distance between rows.
% 
%   B = FILLMISSING(A,fillfun,K) fills standard missing entries using the
%   function handle fillfun and a centered fixed window formed from
%   neighboring non-missing entries. K specifies the window length and must
%   be a positive scalar. The function handle fillfun requires
%   three input arguments, (xs, ts, tq), which are vectors containing the
%   sample data xs of length K, the sample data locations ts of length K,
%   and the missing data locations tq. The vectors ts and tq are subsets of
%   the 'SamplePoints' vector. The output of fillfun must be either a
%   scalar or a vector with the same length as tq.
% 
%   B = FILLMISSING(A,fillfun,[NB NF]) uses a fixed window defined by the
%   NB elements before a gap of missing values and the NF elements after
%   the gap when specifying a function handle fillfun.
% 
%   Optional arguments:
%
%   B = FILLMISSING(A,METHOD,...,'MissingLocations',M) specifies the
%   missing data locations. Elements of M that are true indicate missing
%   data in the corresponding elements of A.
%
%   B = FILLMISSING(A,METHOD,...,'EndValues',E) also specifies how to
%   extrapolate leading and trailing missing values. E must be:
%      'extrap'    - (default) Use METHOD to also extrapolate missing data.
%      'previous'  - Previous non-missing entry.
%      'next'      - Next non-missing entry.
%      'nearest'   - Nearest non-missing entry.
%      'none'      - No extrapolation of missing values.
%      VALUE       - Use an extrapolation constant. VALUE must be a scalar
%                    or a vector of type numeric, duration, or datetime.
% 'EndValues' is not supported for the 'knn' method.
%
%   B = FILLMISSING(A,METHOD,...,'SamplePoints',X) also specifies the
%   sample points X used by the fill method. X must be a floating-point,
%   duration, or datetime vector. If the first input A is a table, X can
%   also specify a table variable in A. X must be sorted and contain unique
%   points. You can use X to specify time stamps for the data. By default,
%   FILLMISSING uses data sampled uniformly at points X = [1 2 3 ... ]. Not
%   supported for the 'knn' method.
%   
%   B = FILLMISSING(A,...,'MaxGap',G) specifies a maximum gap size to fill.
%   Gaps larger than G will not be filled. A gap is a set of consecutive
%   missing data points whose size is the distance between the known values
%   at the ends of the gap. Here, distance is relative to the Sample
%   Points. Not supported for the 'knn' method.
%
%   B = FILLMISSING(A,'knn',...,'Distance',D) specifies the distance metric
%   used to calculate the nearest neighbors. D must be:
%      'euclidean'     - (default) Euclidean distance
%      'seuclidean'    - Scaled Euclidean distance 
%      function handle - A distance function
%   A distance function must accept two inputs: a 2xn matrix, table, or
%   timetable containing two vectors to be compared, and a 2xn logical
%   matrix indicating the locations of missing values in the vectors. It
%   must return the distance as a real, scalar double.
%
%   B = FILLMISSING(A,METHOD,DIM,...) also specifies a dimension DIM to
%   operate along. A must be an array.
%
%   [B,FB] = FILLMISSING(A,...) also returns a logical array FB indicating
%   the filled entries in B that were previously missing. FB has the same
%   size as B.
%
%   Arguments supported only for table inputs:
%
%   B = FILLMISSING(A,...,'DataVariables',DV) fills missing data only in
%   the table variables specified by DV. The default is all table variables
%   in A. DV must be a table variable name, a cell array of table variable
%   names, a vector of table variable indices, a logical vector, a function
%   handle that returns a logical scalar (such as @isnumeric), or a table 
%   vartype subscript. Output table B has the same size as input table A.
%
%   B = FILLMISSING(...,'ReplaceValues',TF) specifies how the filled data
%   is returned. TF must be one of the following:
%        true   - (default) replace table variables with the filled data 
%        false  - append the filled data as additional table variables
%
%   Examples:
%
%     % Linear interpolation of NaN entries
%       a = [NaN 1 2 NaN 4 NaN]
%       b = fillmissing(a,'linear')
%
%     % Quadratic fitting using a custom function handle
%       t = linspace(0,1,10);
%       a = sin(2*pi*t); a(a > 0.7 | a < -0.7) = NaN
%       fn = @(xs, ts, tq) polyval(polyfit(ts, xs, 2), tq)
%       b = fillmissing(a, fn, [2 2])
%
%     % Fill leading and trailing NaN entries with their nearest neighbors
%       a = [NaN 1 2 NaN 4 NaN]
%       b = fillmissing(a,'linear','EndValues','nearest')
%
%     % Fill NaN entries with their previous neighbors (zero-order-hold)
%       A = [1000 1 -10; NaN 1 NaN; NaN 1 NaN; -1 77 5; NaN(1,3)]
%       B = fillmissing(A,'previous')
%
%     % Fill NaN entries with the mean of each column
%       A = [NaN(1,3); 13 1 -20; NaN(4,1) (1:4)' NaN(4,1); -1 7 -10; NaN(1,3)]
%       C = mean(A,'omitnan');
%       B = fillmissing(A,'constant',C)
%
%     % Linear interpolation of NaN entries for non-uniformly spaced data
%       x = [linspace(-3,1,120) linspace(1.1,7,30)];
%       a = exp(-0.1*x).*sin(2*x); a(a > -0.2 & a < 0.2) = NaN;
%       [b,id] = fillmissing(a,'linear','SamplePoints',x);
%       plot(x,a,'.', x(id),b(id),'o')
%       title('''linear'' fill')
%       xlabel('Sample points x');
%       legend('original data','filled missing data')
%
%     % Fill missing entries in tables with their previous neighbors
%       temperature = [21.1 21.5 NaN 23.1 25.7 24.1 25.3 NaN 24.1 25.5]';
%       windSpeed = [12.9 13.3 12.1 13.5 10.9 NaN NaN 12.2 10.8 17.1]';
%       windDirection = categorical({'W' 'SW' 'SW' '' 'SW' 'S' ...
%                           'S' 'SW' 'SW' 'SW'})';
%       conditions = {'PTCLDY' '' '' 'PTCLDY' 'FAIR' 'CLEAR' ...
%                           'CLEAR' 'FAIR' 'PTCLDY' 'MOSUNNY'}';
%       T = table(temperature,windSpeed,windDirection,conditions)
%       U = fillmissing(T,'previous')
%
%     % Fill NaN entries with the corresponding entry from the most similar
%     % row (based on the Euclidean distance between rows):
%       A = [1 NaN 3 2; 7 2 3 2; NaN 1 3 2; 1 3 2 2]
%       B = fillmissing(A,'knn')
%
%     % Fill NaN entries with the corresponding entry from the most similar
%     % row (based on the city block distance, ignoring all NaNs):
%       A = [1 NaN 3 2; 7 2 3 2; NaN 1 3 2; 1 3 2 2]
%       cityBlockDist = @(x,~) sum(abs(diff(x)),'omitmissing');
%       B = fillmissing(A,'knn','Distance',cityBlockDist)
%
%     % Fill only the entries specified by the logical mask
%       a = [1 NaN 3 4 5]
%       mask = [false false false true false]
%       fillmissing(a,'constant',10,'MissingLocations',mask)
%
%     % Fill missing entries only in gaps less than or equal to 3
%       a = [20 NaN NaN NaN NaN 10 8 NaN NaN 2]
%       b = fillmissing(a,'linear','MaxGap',3)
%
%   See also ISMISSING, STANDARDIZEMISSING, RMMISSING, ISNAN, ISNAT
%            ISOUTLIER, FILLMISSING2, FILLOUTLIERS, RMOUTLIERS, SMOOTHDATA

%   Copyright 2015-2024 The MathWorks, Inc.

[A,AisTable,intM,intConstOrWindowSizeOrK,extM,x,dim,dataVars,ma,maxgap,replace,distance] = parseInputs(A,fillMethod,varargin{:});

if strcmp(intM,'knn')
    [B,FB] = knnFill(A,AisTable,intConstOrWindowSizeOrK,dataVars,ma,distance,dim,replace);
    return
end

if ~AisTable
    [intConstOrWindowSizeOrK,extM] = checkArrayType(A,intM,intConstOrWindowSizeOrK,extM,x,false,ma);
    if nargout < 2
        B = fillArray(A,intM,intConstOrWindowSizeOrK,extM,x,dim,false,ma,maxgap); 
    else
        [B,FB] = fillArray(A,intM,intConstOrWindowSizeOrK,extM,x,dim,false,ma,maxgap); 
    end
else
    if nargout < 2
        B = fillTable(A,intM,intConstOrWindowSizeOrK,extM,x,dataVars,ma,maxgap,replace);
    else
        [B,FB] = fillTable(A,intM,intConstOrWindowSizeOrK,extM,x,dataVars,ma,maxgap,replace);
    end
end
end
%--------------------------------------------------------------------------
function [B,FA] = fillTable(A,intMethod,intConst,extMethod,x,dataVars,ma,maxgap,replace) 
% Fill table according to DataVariables
if replace
    B = A;
    if istabular(ma)
        tnames = string(A.Properties.VariableNames);
    end
else
    B = A(:,dataVars);
    dataVars = 1:width(B);
    if istabular(ma)
        tnames = string(ma.Properties.VariableNames);
    end
end
if nargout > 1
    FA = false(size(B));
end
useJthFillConstant = strcmp(intMethod,'constant') && ~isscalar(intConst) && ~ischar(intConst);
useJthExtrapConstant = ~ischar(extMethod) && ~isscalar(extMethod);
indVj = 1;

for vj = dataVars
    if isempty(ma)
        mavj = ma; % Need to call ismissing
    else % 'MissingLocations' provided
        if istabular(ma)
            name = tnames(vj);
            mavj = ma.(name);
        else
            mavj = ma(:,vj); 
        end
    end
    if nargout < 2
        B.(vj) = fillTableVar(indVj,B.(vj),intMethod,intConst,extMethod,x,useJthFillConstant,useJthExtrapConstant,mavj,maxgap,B,vj); 
    else
        [B.(vj),FA(:,vj)] = fillTableVar(indVj,B.(vj),intMethod,intConst,extMethod,x,useJthFillConstant,useJthExtrapConstant,mavj,maxgap,B,vj);
    end
    indVj = indVj+1;
end
if ~replace
    % alternate FA output:
    % FA = array2table(FA);
    % FA.Properties.VariableNames = B.Properties.VariableNames;
    B = matlab.internal.math.appendDataVariables(A,B,"filled");
    if nargout > 1
        FA = [false(size(A)) FA];
    end
end
end % fillTable
%--------------------------------------------------------------------------
function [Bvj,FAvj] = fillTableVar(indVj,Avj,intMethod,intConst,extMethod,x,useJthFillConstant,useJthExtrapConstant,ma,maxgap,A,vj)
% Fill each table variable
intConstVj = intConst;
extMethodVj = extMethod;
if useJthFillConstant
    intConstVj = intConst(indVj);
end
if iscell(intConstVj)
    intConstVj = checkConstantsSize(Avj,false,true,intConstVj{1},1,[],'');
end
if useJthExtrapConstant
    extMethodVj = extMethod(indVj);
end
% Validate types of array and fill constants
[intConstVj,extMethodVj] = checkArrayType(Avj,intMethod,intConstVj,extMethodVj,x,true,ma,A,vj);
% Treat row in a char table variable as a string
AisCharTableVar = ischar(Avj);
if AisCharTableVar
    AvjCharInit = Avj;
    Avj = matlab.internal.math.charRows2string(Avj);
    if strcmp(intMethod,'constant')
        intConstVj = matlab.internal.math.charRows2string(intConstVj,true);
    end
end
% Fill
if nargout < 2
    Bvj = fillArray(Avj,intMethod,intConstVj,extMethodVj,x,1,true,ma,maxgap); 
else
    [Bvj,FAvj] = fillArray(Avj,intMethod,intConstVj,extMethodVj,x,1,true,ma,maxgap); 
end
% Convert back to char table variable
if AisCharTableVar
    if all(ismissing(Avj(:)))
        % For completely blank char table variables, force B to equal A
        Bvj = AvjCharInit;
    else
        Bvj = matlab.internal.math.string2charRows(Bvj);
    end
end
end % fillTableVar
%--------------------------------------------------------------------------
function [B,FA] = fillArray(A,intMethod,intConstOrWindowSizeOrK,extMethod,x,dim,AisTableVar,ma,maxgap)
% Perform FILLMISSING of standard missing entries in an array A
B = A;
didIsmissing = isempty(ma);
if didIsmissing
    FA = ismissing(A);
else
    % 'MissingLocations' provided
    if AisTableVar
        FA = repmat(ma,1,prod(size(A,2:ndims(A))));
    else
        FA = ma;
    end
end
ndimsBin = ndims(B);

% Quick return
if ~AisTableVar && dim > ndimsBin && ~isa(intMethod,'function_handle')
    if isnumeric(B) && ~isreal(B)
        B(true(size(B))) = B;
    end
    if ~isfinite(maxgap)
        if nargout < 2
            B = extrapolateWithConstant(B,intMethod,intConstOrWindowSizeOrK,extMethod,FA,FA);
        else
            [B,FA] = extrapolateWithConstant(B,intMethod,intConstOrWindowSizeOrK,extMethod,FA,FA);
        end
    end
    % else consider the gap too large, don't fill
    return
end
% Permute and reshape into a matrix
permNeeded = dim ~= 1 || ndimsBin > 2;
if permNeeded
    dim = min(ndimsBin + 1, dim); % all dim > ndimsBin behave the same way, this avoids errors for arbitrarily large dim
    perm = [dim, 1:(dim-1), (dim+1):ndimsBin];
    sizeBperm = size(B, perm);
    ncolsB = prod(sizeBperm(2:end));
    nrowsB = sizeBperm(1);
    B = reshape(permute(B, perm),[nrowsB, ncolsB]); % permute errors expectedly for ND sparse matrix
    FA = reshape(permute(FA, perm),[nrowsB, ncolsB]);
else
    ncolsB = size(B,2);
end
% Fill each column
if didIsmissing || nargout < 2
    % For ismissing, compute the filled mask at the very end. This ensures
    % that tall/fillmissing takes 2 passes instead of 3 for two outputs.
    for jj = 1:ncolsB
        B(:,jj) = fillArrayColumn(jj,B(:,jj),FA(:,jj),intMethod,intConstOrWindowSizeOrK,extMethod,x,maxgap,didIsmissing);
    end
else
    % For 'MissingLocations', also compute the filled mask
    for jj = 1:ncolsB
        [B(:,jj),FA(:,jj)] = fillArrayColumn(jj,B(:,jj),FA(:,jj),intMethod,intConstOrWindowSizeOrK,extMethod,x,maxgap,didIsmissing);
    end
end
% Reshape and permute back to original size
if AisTableVar && nargout > 1
    FA = any(FA,2);
    if didIsmissing
        FA = xor(FA,any(ismissing(B),2)); % Compute the filled mask
    end
end
if permNeeded
    B = ipermute(reshape(B,sizeBperm), perm);
end
if ~AisTableVar && nargout > 1
    if permNeeded
        FA = ipermute(reshape(FA,sizeBperm), perm);
    end
    if didIsmissing
        FA(FA) = xor(FA(FA),ismissing(B(FA))); % Compute the filled mask
    end
end
end % fillArray
%--------------------------------------------------------------------------
function [b,ma] = fillArrayColumn(jj,a,ma,intMethod,intConstOrWindowSizeOrK,extMethod,x,maxgap,didIsmissing)
% Fill one column. Do not error if we cannot fill all missing entries.
% jj = j-th column numeric index. Used to select the j-th fill constant.
% a  = the j-th column itself. Can be numeric, logical, duration, datetime,
%      calendarDuration, char, string, cellstr, or categorical.
% ma = logical mask of missing entries found in a.
% intMethod = interpolation method.
% intConstOrWindowSizeOrK = interpolation constant for 'constant' or window size
%      for 'movmean'. [] if intMethod is not 'constant'/'mov*'.
% extMethod = extrap method. If not a char, it holds the extrap constant.
% x = the abscissa ('SamplePoints'). Can be float, duration, or datetime.
b = a;
% Quick return
nma = ~ma;
numNonMissing = nnz(nma);

useDefaultX = isempty(x);
spFlag = ~useDefaultX; % whether sample points are used

% Default sample points only need to be generated when MaxGap is used, the
% input data is non-numeric, or the method is a function handle or an 
% interpolation method that uses sample points. Note that "knn" also needs 
% default sample points, but does not use this function.
if useDefaultX && (~isnumeric(a) || isfinite(maxgap) || ...
    isa(intMethod,'function_handle') || ...
    ~matches(intMethod,["constant","next","previous","movmean","movmedian"]))
    x = (1:size(a,1)).';
end

if numNonMissing == 0
    % Column is full of missing data:
    if ~isfinite(maxgap)
        % Fill with constant
        if nargout > 1
            if isa(intMethod,'function_handle') && strcmp(extMethod,'extrap')
                b = handlefill(b,ma,intMethod,intConstOrWindowSizeOrK,spFlag,x);
                ma = ~ismissing(b);
            else
                [b,ma] = extrapolateWithConstant(b,intMethod,intConstOrWindowSizeOrK,extMethod,ma,jj);
            end
        else
            if isa(intMethod,'function_handle') && strcmp(extMethod,'extrap') 
                b = handlefill(b,ma,intMethod,intConstOrWindowSizeOrK,spFlag,x);
            else
                b = extrapolateWithConstant(b,intMethod,intConstOrWindowSizeOrK,extMethod,ma,jj);
            end
        end
    end
    % else, column is a "large gap": do not fill
    return
end
% Ignore gaps of missing data bigger than maxgap
ma = removeLargeGaps(ma,maxgap,x);
maBeforeInterp = ma;
% (1) Interpolate
if issparse(b)
    b = full(b);
end
if strcmp(intMethod,'constant')
    b = assignConstant(b,intConstOrWindowSizeOrK,ma,jj);
elseif strcmp(intMethod,'movmean')
    if didIsmissing
        if useDefaultX
            newb = movmean(b,intConstOrWindowSizeOrK,'omitnan');
        else
            newb = movmean(b,intConstOrWindowSizeOrK,'omitnan','SamplePoints',x);
        end
        b(ma) = newb(ma);
    else % 'MissingLocations' case
        b(ma) = missing;
        if useDefaultX
            newb = movmean(b,intConstOrWindowSizeOrK,'omitnan');
        else
            newb = movmean(b,intConstOrWindowSizeOrK,'omitnan','SamplePoints',x);
        end
        b(ma) = newb(ma);
        ma(ma) = xor(ma(ma),ismissing(b(ma)));
    end
elseif strcmp(intMethod,'movmedian')
    if didIsmissing
        if useDefaultX
            newb = movmedian(b,intConstOrWindowSizeOrK,'omitnan');
        else
            newb = movmedian(b,intConstOrWindowSizeOrK,'omitnan','SamplePoints',x);
        end
        b(ma) = newb(ma);
    else % 'MissingLocations' case
        b(ma) = missing;
        if useDefaultX
            newb = movmedian(b,intConstOrWindowSizeOrK,'omitnan');
        else
            newb = movmedian(b,intConstOrWindowSizeOrK,'omitnan','SamplePoints',x);
        end
        b(ma) = newb(ma);
        ma(ma) = xor(ma(ma),ismissing(b(ma)));
    end
elseif isnumeric(b) && strcmp(intMethod,'next')
    if numNonMissing > 1
        b = fillWithNext(b,ma);
    end
elseif isnumeric(b) && strcmp(intMethod,'previous')
    if numNonMissing > 1
        b = fillWithPrevious(b,ma);
    end
elseif strcmp(intMethod,'linear') && isfloat(x) && isfloat(b) ...
        && nnz(ma)<3000 % For many missing values, the built-ins are faster
    if numNonMissing > 1 && any(ma)
        b = matlab.internal.math.linearInterpExtrap(x,b,ma,nma,spFlag);
    end
elseif ~isa(intMethod,'function_handle') % function handle case handled below
    % griddedInterpolant/interp1 require at least 2 grid points.
    % Do not error if we cannot fill. Instead, return the original array.
    % For example, fillmissing([NaN 1 NaN],'linear') returns [NaN 1 NaN].
    if numNonMissing > 1
        isfloatb = isfloat(b);
        if isfloatb && isfloat(x)
            G = griddedInterpolant(x(nma),b(nma),intMethod);
            b(ma) = G(x(ma)); % faster than interp1
        elseif isfloatb || isduration(b) || isdatetime(b)
            b(ma) = interp1(x(nma),b(nma),x(ma),intMethod,'extrap');
        else
            % calendarDuration, char, string, cellstr, or categorical:
            % No griddedInterpolant because x may be datetime/duration
            vq = interp1(x(nma),find(nma),x(ma),intMethod,'extrap');
            indvq = ~isnan(vq); % vq may have leading or trailing NaN
            iatmp = find(ma);
            b(iatmp(indvq)) = b(vq(indvq)); % copy non-missing to missing
        end
    end
end
% (2) Correct for EndValues, including the logical mask of what got filled
% use ma to find non-missing for correct maxgap behavior
% ma has at least one false, all-missing case was quick returned
if maBeforeInterp(1)
    indBeg = find(~maBeforeInterp,1);
else
    indBeg = 1;
end

if maBeforeInterp(end)
    indEnd = find(~maBeforeInterp,1,'last');
else
    indEnd = numel(a);
end

if indBeg > 1 || indEnd < numel(a)
    if ischar(extMethod) || (isstring(extMethod) && isscalar(extMethod))
        if strcmp(extMethod,'none')
            b(1:indBeg-1)   = a(1:indBeg-1);
            b(indEnd+1:end) = a(indEnd+1:end);
            if nargout > 1 % 'MissingLocations' case
                ma(1:indBeg-1) = false;
                ma(indEnd+1:end) = false;
            end
        elseif strcmp(extMethod,'nearest') || (strcmp(extMethod,'extrap') && strcmp(intMethod,'nearest'))
            b(1:indBeg-1)   = a(indBeg);
            b(indEnd+1:end) = a(indEnd);
            if nargout > 1 % 'MissingLocations' case
                ma(1:indBeg-1) = true;
                ma(indEnd+1:end) = true;
            end
        elseif strcmp(extMethod,'previous') || (strcmp(extMethod,'extrap') && strcmp(intMethod,'previous'))
            b(1:indBeg-1)   = a(1:indBeg-1);
            b(indEnd+1:end) = a(indEnd);
            if nargout > 1 % 'MissingLocations' case
                ma(1:indBeg-1) = false;
                ma(indEnd+1:end) = true;
            end
        elseif strcmp(extMethod,'next') || (strcmp(extMethod,'extrap') && strcmp(intMethod,'next'))
            b(1:indBeg-1)   = a(indBeg);
            b(indEnd+1:end) = a(indEnd+1:end);
            if nargout > 1 % 'MissingLocations' case
                ma(1:indBeg-1) = true;
                ma(indEnd+1:end) = false;
            end
        end
    else
        % Extrapolate with given value(s)
        if isscalar(extMethod)
            b([1:indBeg-1, indEnd+1:end]) = extMethod;
        elseif ~isa(intMethod,'function_handle') % function handle has separate implementation (directly below)
            b([1:indBeg-1, indEnd+1:end]) = extMethod(jj);
        end
        if nargout > 1
            ma([1:indBeg-1, indEnd+1:end]) = true;
        end
    end
end
if isa(intMethod,'function_handle')
    isExtrap = strcmp(extMethod,'extrap');
    if ~isExtrap
        ma([1:indBeg-1, indEnd+1:end]) = false;
    end

    if nargout < 2 % one output case
        newb = handlefill(b,ma,intMethod,intConstOrWindowSizeOrK,spFlag,x);
        b(ma) = newb(ma);
    else % two output case
        b(ma) = missing;
        newb = handlefill(b,ma,intMethod,intConstOrWindowSizeOrK,spFlag,x);
        b(ma) = newb(ma);
        ma(ma) = xor(ma(ma),ismissing(b(ma)));
        if ~isExtrap
            ma([1:indBeg-1, indEnd+1:end]) = true;
        end
    end
end
end % fillArrayColumn
%--------------------------------------------------------------------------
function MItoBeFilled = removeLargeGaps(MI,maxgap,x)
% set elements in the given missing indicator within large gaps to false
% MI is a vector, maxgap is either numeric or duration scalar
MItoBeFilled = MI;
% x has at least 1 element, empties are already special cased
if ~isfinite(maxgap)
    % no gaps will be too large to fill, don't change MI
    return
end
% find all segments in the missing indicator vector
segmentLengths = diff([0; find(diff(MI(:))); numel(MI)]);
% gaps span x_j to x_k
k = cumsum(segmentLengths);
j = k - segmentLengths + 1;
% The gap size is defined as x_(k+1)-x_(j-1)
% If the segment is at the end of a vector, we use the nearest sample point
x = [x(1); x(:); x(end)];
% for this x, the size of a gap is x_(k+2)-x_(j)
for idx =1:numel(segmentLengths)
    % only act on segments of missing data
    if MI(j(idx))
        % check to see if the segment is small enough to fill
        doFill = x(j(idx)) + maxgap >= x(k(idx)+2);
        if ~doFill
            % if it is too large, don't fill, i.e. treat as nonmissing
            MItoBeFilled(j(idx):k(idx)) = false;
        end
    end
end
end % removeLargeGaps
%--------------------------------------------------------------------------
function [B,FA] = extrapolateWithConstant(B,intMethod,intConst,extMethod,lhsIndex,rhsIndex)
% Fill all missings with a constant. Used if B is full of missing data, or
% for array B with dim > ndims(B). rhsIndex may be logical or numeric.
% Fill only when we have specified an extrapolation constant:
if nargout > 1
    FA = lhsIndex;
end
if ~ischar(extMethod) && ~(isstring(extMethod) && isscalar(extMethod))
    % Either through EndValues:
    % fillmissing(A,METHOD,'EndValues',ConstVals)
    B = assignConstant(B,extMethod,lhsIndex,rhsIndex);
elseif strcmp(intMethod,'constant') && strcmp(extMethod,'extrap')
    % Or through the 'constant' fill method:
    % fillmissing(A,'constant',ConstVals)
    % fillmissing(A,'constant',ConstVals,'EndValues','extrap')
    B = assignConstant(B,intConst,lhsIndex,rhsIndex);
elseif nargout > 1
    FA(:) = false;
end
end % extrapolateWithConstant
%--------------------------------------------------------------------------
function B = assignConstant(B,ConstVals,lhsIndex,rhsIndex)
if isscalar(ConstVals)
    B(lhsIndex) = ConstVals;
else
    B(lhsIndex) = ConstVals(rhsIndex);
end
end
%--------------------------------------------------------------------------
function [A,AisTable,intMethod,intConstOrWindowSizeOrK,extMethod,x,dim,dataVars,ma,maxgap,replace,distance] = ... 
    parseInputs(A,fillMethod,varargin)
% Parse FILLMISSING inputs
AisTable = istabular(A);
if ~AisTable && ~isSupportedArray(A)
    error(message('MATLAB:fillmissing:FirstInputInvalid'));
end
% Parse fill method. Empty '' or [] fill method is not allowed.
validIntMethods = {'constant','previous','next','nearest','linear',...
                   'spline','pchip','movmean','movmedian','makima','knn'};
if ischar(fillMethod) || isstring(fillMethod)
   indIntMethod = matlab.internal.math.checkInputName(fillMethod,validIntMethods);
   if sum(indIntMethod) ~= 1
       % Also catch ambiguities for fillmissing(A,'ne') and fillmissing(A,'p')
       error(message('MATLAB:fillmissing:MethodInvalid'));
   end
   intMethod = validIntMethods{indIntMethod};
   indIntMethod = find(indIntMethod);

   if indIntMethod == 11 && ~ismatrix(A) % tables and timetables return TRUE for ismatrix
       error(message('MATLAB:fillmissing:knnMustBeMatrixTableOrTimetable'))
   end

   intConstOrWindowSizeOrK = [];
   % Parse fillmissing(A,'constant',c) and fillmissing(A,MOVFUN,windowSize)
   intConstOffset = 0;
   if any(indIntMethod == [1 8 9])
       if nargin > 2
           intConstOrWindowSizeOrK = varargin{1};
       else
           error(message(['MATLAB:fillmissing:',intMethod,'Input']));
       end
       intConstOffset = 1;
   elseif indIntMethod == 11
       if nargin > 2 && isnumeric(varargin{1})
           intConstOrWindowSizeOrK = varargin{1};
           intConstOffset = 1;
       else
           intConstOrWindowSizeOrK = 1;
       end
   end
elseif isa(fillMethod,'function_handle')
    if nargin(fillMethod) < 3
        error(message('MATLAB:fillmissing:FunctionHandleNumberOfArguments'));
    end
    intMethod = fillMethod;
    intConstOffset = 1;
    indIntMethod = [];
    if nargin < 3
        error(message('MATLAB:fillmissing:FunctionHandleInput'));
    end
    intConstOrWindowSizeOrK = varargin{1};
else
    error(message('MATLAB:fillmissing:MethodInvalid'));
end
% Parse optional inputs
extMethod = 'extrap';
x = [];
ma = []; 
maxgap = [];
dataVarsProvided = false;
missingLocationProvided = false;
replace = true;
distance = 'euclidean';

if ~AisTable
    dim = matlab.internal.math.firstNonSingletonDim(A);
    dataVars = []; % not supported for arrays
else
    dim = 1; % Fill each table variable separately
    dataVars = 1:width(A);
end
if nargin > 2+intConstOffset
    % Third input can be a constant, a window size, the dimension, or an
    % argument Name from a Name-Value pair:
    %   fillmissing(A,'constant',C,...) and C may be a char itself
    %   fillmissing(A,'movmean',K,...) with K numeric, numel(K) == 1 or 2
    %   fillmissing(A,'linear',DIM,...)
    %   fillmissing(A,'linear','EndValues',...)
    firstOptionalInput = varargin{1+intConstOffset};
    % The dimension
    dimOffset = 0;
    if isnumeric(firstOptionalInput) || islogical(firstOptionalInput)
        if AisTable
            error(message('MATLAB:fillmissing:DimensionTable'));
        end
        dimOffset = 1;
        dim = firstOptionalInput;
        if ~isscalar(dim) || ~isreal(dim) || fix(dim) ~= dim || dim < 1 || ~isfinite(dim)
            error(message('MATLAB:fillmissing:DimensionInvalid'));
        end
    end
    % Trailing N-V pairs
    indNV = (1+intConstOffset+dimOffset):numel(varargin);
    if rem(length(indNV),2) ~= 0
        error(message('MATLAB:fillmissing:NameValuePairs'));
    end
    spvar = [];
    for i = indNV(1:2:end)
        if matlab.internal.math.checkInputName(varargin{i},'EndValues')
            if indIntMethod == 11
                error(message('MATLAB:fillmissing:unsupportedNVPair','EndValues','''knn'''))
            end
            extMethod = varargin{i+1};
            if ischar(extMethod) || (isstring(extMethod) && isscalar(extMethod))
                validExtMethods = {'extrap','previous','next','nearest','none'};
                indExtMethod = matlab.internal.math.checkInputName(extMethod,validExtMethods);
                if sum(indExtMethod) ~= 1 
                    % Also catch ambiguities between nearest and next
                    error(message('MATLAB:fillmissing:EndValuesInvalidMethod'));
                end
                extMethod = validExtMethods{indExtMethod};
            end
        elseif matlab.internal.math.checkInputName(varargin{i},'DataVariables')
            if AisTable
                dataVars = matlab.internal.math.checkDataVariables(A,varargin{i+1},'fillmissing');
                dataVarsProvided = true;
            else
                error(message('MATLAB:fillmissing:DataVariablesArray'));
            end
        elseif matlab.internal.math.checkInputName(varargin{i},'ReplaceValues')
            if AisTable
                replace = matlab.internal.datatypes.validateLogical(varargin{i+1},'ReplaceValues');
            else
                error(message('MATLAB:fillmissing:ReplaceValuesArray'));
            end
        elseif matlab.internal.math.checkInputName(varargin{i},'SamplePoints')
            if indIntMethod == 11
                error(message('MATLAB:fillmissing:unsupportedNVPair','SamplePoints','''knn'''));
            end
            if istimetable(A)
                error(message('MATLAB:samplePoints:SamplePointsTimeTable'));
            end
            [x,spvar] = matlab.internal.math.checkSamplePoints(varargin{i+1},A,AisTable,false,dim);
        elseif matlab.internal.math.checkInputName(varargin{i},'MissingLocations',2)
            ma = varargin{i+1};
            missingLocationProvided = true;
        elseif matlab.internal.math.checkInputName(varargin{i},'MaxGap',2)
             if indIntMethod == 11
                error(message('MATLAB:fillmissing:unsupportedNVPair','MaxGap','knn'))
            end
            maxgap = varargin{i+1};
            if ~isscalar(maxgap) || ~(isnumeric(maxgap) || isduration(maxgap) || iscalendarduration(maxgap)) ||...
                    ~isreal(maxgap) || isnan(maxgap) || (~iscalendarduration(maxgap) && maxgap <= 0)
                error(message('MATLAB:fillmissing:MaxGapInvalid'))
            end
        elseif matlab.internal.math.checkInputName(varargin{i},'Distance')
            if indIntMethod ~= 11
                error(message('MATLAB:fillmissing:DistanceNonKNNMethod'))
            end
            distance = varargin{i+1};
            if ischar(distance) || (isstring(distance) && isscalar(distance))
                validDistanceMetrics = {'euclidean','seuclidean'};
                distMask = matlab.internal.math.checkInputName(distance,validDistanceMetrics);
                if ~any(distMask)
                    error(message('MATLAB:fillmissing:InvalidDistance'));
                end
                distance = validDistanceMetrics{distMask};
            elseif ~isa(distance,'function_handle')
                error(message('MATLAB:fillmissing:InvalidDistance'))
            end
        else
            error(message('MATLAB:fillmissing:NameValueNames'));
        end
    end

    if ~isempty(spvar)
        dataVars(dataVars == spvar) = []; % remove sample points var from data vars
    end

    if missingLocationProvided
        if AisTable && istabular(ma)
            dataVars = validateTabularMissingLocations(A,ma,dataVars,dataVarsProvided);
        elseif AisTable && isvector(ma) && isscalar(dataVars)
            if ~islogical(ma) || ~isequal(height(A),height(ma))
                error(message('MATLAB:fillmissing:MissingLocationsInvalid'));
            end
        else
            if ~islogical(ma) || ~isequal(size(A),size(ma))
                error(message('MATLAB:fillmissing:MissingLocationsInvalid'));
            end
        end
    end

    % Ensure not both MaxGap and MissingLocations specified
    if ~isempty(ma) && ~isempty(maxgap)
        error(message('MATLAB:fillmissing:MaxGapMissingLocations'))
    end
end
% Validate fill constants size
if indIntMethod == 1 % 'constant' fill method
    intConstOrWindowSizeOrK = checkConstantsSize(A,AisTable,false,intConstOrWindowSizeOrK,dim,dataVars,'');
elseif indIntMethod == 11 % Validate number of nearest neighbors
    if ~isnumeric(intConstOrWindowSizeOrK) || ~isscalar(intConstOrWindowSizeOrK) || ...
            fix(intConstOrWindowSizeOrK) ~= intConstOrWindowSizeOrK || ...
            intConstOrWindowSizeOrK < 1 || ~isreal(intConstOrWindowSizeOrK)
        error(message('MATLAB:fillmissing:InvalidK'));
    end
end
if ~ischar(extMethod) && ~(isstring(extMethod) && isscalar(extMethod))
    extMethod = checkConstantsSize(A,AisTable,false,extMethod,dim,dataVars,'Extrap');
end
% Default abscissa
if isempty(x) && istimetable(A)
    x = matlab.internal.math.checkSamplePoints(A.Properties.RowTimes,A,false,true,dim);
end
% Default Sample Points
if isa(intMethod,'function_handle')
    if isempty(x)
        checkHandleWindow(A,intConstOrWindowSizeOrK,false,1:numel(A));
    else
        checkHandleWindow(A,intConstOrWindowSizeOrK,true,x);
    end
end
% Default maxgap/check datatype against abscissa
if isempty(maxgap)
    maxgap = inf;
elseif (isnumeric(x) && ~isnumeric(maxgap)) || (~isnumeric(x) && isnumeric(maxgap)) ||...
        (isduration(x) && iscalendarduration(maxgap))
    error(message('MATLAB:fillmissing:MaxGapDurationInvalid'))
end
end % parseInputs
%--------------------------------------------------------------------------
function tf = isSupportedArray(A)
% Check if array type is supported
tf = isnumeric(A) || islogical(A) || ...
     isstring(A) || iscategorical(A) || iscellstr(A) || ischar(A) || ...
     isdatetime(A) || isduration(A) || iscalendarduration(A);
end % isSupportedArray
%--------------------------------------------------------------------------
function C = checkConstantsSize(A,AisTable,AisTableVar,C,dim,dataVars,eid)
% Validate the size of the fill constant. We can fill all columns with the
% same scalar, or use a different scalar for each column.
if ischar(C) && (~ischar(A) || AisTableVar)
    % A char fill constant is treated as a scalar for string, categorical
    % and cellstr (arrays or table variables), and char table variables
    if ~isrow(C) && ~isempty(C) % '' is not a row
        error(message('MATLAB:fillmissing:CharRowVector'));
    end
elseif ~isscalar(C)
    sizeA = size(A);
    if AisTable
        % numel(constant) must equal numel 'DataVariables' value
        sizeA(2) = length(dataVars);
    end
    if dim <= ndims(A)
        sizeA(dim) = [];
        nVects = prod(sizeA);
    else
        % fillmissing(A,'constant',c) supported
        % fillmissing(A,METHOD,'EndValues',constant_value) supported
        nVects = numel(A);
    end
    if (numel(C) ~= nVects)
        if nVects <= 1
            error(message(['MATLAB:fillmissing:SizeConstantScalar',eid]));
        else
            error(message(['MATLAB:fillmissing:SizeConstant',eid],nVects));
        end
    end
	C = C(:);
end
end % checkConstantsSize
%--------------------------------------------------------------------------
function [intConst,extMethod] = checkArrayType(A,intMethod,intConst,extMethod,x,AisTableVar,ma,T,vj)
% Check if array types match
if AisTableVar && ~isSupportedArray(A)
    error(message('MATLAB:fillmissing:UnsupportedTableVariable',class(A)));
end

if ~(isnumeric(A) || islogical(A) || isduration(A) || isdatetime(A)) && ...
        ~any(strcmp(intMethod,{'nearest','next','previous','constant'})) && ...
        ~isa(intMethod,'function_handle')
    if AisTableVar
        error(message('MATLAB:fillmissing:InterpolationInvalidTableVariable',intMethod));
    else
        error(message('MATLAB:fillmissing:InterpolationInvalidArray',intMethod,class(A)));
    end
end
% 'MissingLocations' doesn't work with all methods for integer and logical
if ~isempty(ma) && (isinteger(A) || islogical(A)) && ...
        ~(any(strcmp(intMethod,{'nearest','next','previous','constant','knn'})) || ...
        isa(intMethod,'function_handle'))
    error(message('MATLAB:fillmissing:MissingLocationsInteger'));
end
try
    if strcmp(intMethod,'constant')
        intConst = checkConstantType(A,intConst,'');
    end
    if ~ischar(extMethod) && ~(isstring(extMethod) && isscalar(extMethod))
        extMethod = checkConstantType(A,extMethod,'Extrap');
    end
catch ME
    if AisTableVar && matlab.internal.math.checkInputName('MATLAB:fillmissing:Constant',ME.identifier)
        % Generic error message for tables
        varNames = T.Properties.VariableNames;
        error(message('MATLAB:fillmissing:ConstantInvalidTypeForTableVariable',varNames{vj}));
    else
        % Specific error message for arrays
        throw(ME);
    end
end
if isa(x,'single') && (isduration(A) || isdatetime(A))
    error(message('MATLAB:samplePoints:SamplePointsSingle'));
end
end % checkArrayType
%--------------------------------------------------------------------------
function C = checkConstantType(A,C,eid)
% Check if constant type matches the array type
if ~isempty(eid) && ~isnumeric(C) && ~islogical(C) && ...
        ~isdatetime(C) && ~isduration(C) && ~iscalendarduration(C)
    error(message('MATLAB:fillmissing:ConstantInvalidTypeExtrap'));
end
if isnumeric(A) && ~isnumeric(C) && ~islogical(C)
    error(message(['MATLAB:fillmissing:ConstantNumeric',eid]));
elseif isdatetime(A) && ~isdatetime(C)
    error(message(['MATLAB:fillmissing:ConstantDatetime',eid]));
elseif isduration(A) && ~isduration(C)
    error(message(['MATLAB:fillmissing:ConstantDuration',eid]));
elseif iscalendarduration(A) && ~iscalendarduration(C)
    error(message(['MATLAB:fillmissing:ConstantCalendarDuration',eid]));
elseif iscategorical(A)
    if ischar(C)
        C = string(C); % make char a scalar string
    elseif iscategorical(C) && (isordinal(A) ~= isordinal(C))
        error(message('MATLAB:fillmissing:ConstantCategoricalOrdMismatch'));
    elseif iscategorical(C) && isordinal(C) && ~isequal(categories(C),categories(A))
        error(message('MATLAB:fillmissing:ConstantCategoricalCatMismatch'));
    elseif (~iscellstr(C) && ~isstring(C) && ~iscategorical(C))
        error(message(['MATLAB:fillmissing:ConstantCategorical',eid]));
    end
elseif ischar(A) && ~ischar(C)
    error(message(['MATLAB:fillmissing:ConstantChar',eid]));
elseif iscellstr(A)
    if ischar(C)
        C = {C}; % make char a scalar cellstr
    elseif ~iscellstr(C) %#ok<ISCLSTR>
        % string constants not supported
        error(message(['MATLAB:fillmissing:ConstantCellstr',eid]));
    end
elseif isstring(A) && ~isstring(C)
    % char and cellstr constants not supported
    error(message(['MATLAB:fillmissing:ConstantString',eid]));
end
end % checkConstantType

function datavariables = validateTabularMissingLocations(a,loc,datavariables,dataVarsProvided)
vnames = loc.Properties.VariableNames;
tnames = a.Properties.VariableNames;
if dataVarsProvided
    if ~all(ismember(tnames(datavariables),vnames))
        % DataVariable names must be present in loc table
        error(message('MATLAB:fillmissing:InvalidLocationsWithDataVars'));
    end
else
    try
        datavariables = matlab.internal.math.checkDataVariables(a, vnames, 'fillmissing');
    catch
        error(message('MATLAB:fillmissing:InvalidTabularLocationsFirstInput'));
    end
end

vnames = string(vnames);
for ii=vnames
    if ~islogical(loc.(ii)) || ~isequal(size(a.(ii)),size(loc.(ii)))
        error(message('MATLAB:fillmissing:LogicalVarsRequired'));
    end
end
end
%--------------------------------------------------------------------------
function checkHandleWindow(A,intConstOrWindowSizeOrK,spFlag,t)
needDuration = (~spFlag && istimetable(A)) || ...
            (spFlag && (isduration(t) || isdatetime(t)));
if (isduration(intConstOrWindowSizeOrK) || isnumeric(intConstOrWindowSizeOrK)) && ...
        isreal(intConstOrWindowSizeOrK) && any(numel(intConstOrWindowSizeOrK) == [1 2]) && ...
        allfinite(intConstOrWindowSizeOrK) && any(intConstOrWindowSizeOrK > 0) && ...
        all(intConstOrWindowSizeOrK >= 0)
    if needDuration && ~isduration(intConstOrWindowSizeOrK)
        error(message('MATLAB:fillmissing:FunctionHandleInvalidWindowDuration'));
    elseif ~needDuration && isduration(intConstOrWindowSizeOrK)
        error(message('MATLAB:fillmissing:FunctionHandleInvalidWindow'));
    end
else
    error(message('MATLAB:fillmissing:FunctionHandleInvalidWindow'));
end
end % checkHandleWindow
%--------------------------------------------------------------------------
function ide = getMissingIntervals(MI)
% get the 2-column array of first and last indices of each gap
segmentLengths = diff([0; find(diff(MI(:))); numel(MI)]); % This assumes MI is not empty, which cannot happen when this is called
k = cumsum(segmentLengths); % last index of each interval
alt = MI(k); % which intervals are missing vs non-missing
ide = zeros(sum(alt),2); 
if alt(1) % if the first interval is missing 
    ide(:,2) = k(1:2:end);
    ide(:,1) = k(1:2:end) - segmentLengths(1:2:end) + 1;
elseif numel(alt) >= 2 && alt(2) % if the second interval is missing
    ide(:,2) = k(2:2:end);
    ide(:,1) = k(2:2:end) - segmentLengths(2:2:end) + 1;
end
end % getMissingIntervals
%--------------------------------------------------------------------------
function Y = handlefill(A,MI,fillfun,intConstOrWindowSizeOrK,spFlag,t)
A = A(:);
t = t(:);
tidx = 1:numel(t);
% Initialize the output
Y = A;
% Quick return
if isempty(MI)
    return
end

ide = getMissingIntervals(MI); % array of first and last indices of each gap
% Split into left and right window values
if numel(intConstOrWindowSizeOrK) == 2
    a = intConstOrWindowSizeOrK(1);
    b = intConstOrWindowSizeOrK(2);
elseif ~spFlag
    a = floor(intConstOrWindowSizeOrK/2);
    b = a;
else
    a = intConstOrWindowSizeOrK/2;
    b = a;
end
% Call fillfun on each interval of missing data skip filling gaps when xin
% is empty 
nide = size(ide,1);
for i = 1:nide
    if spFlag
        ind = find(((t <= t(ide(i+nide)) + b) & (t > t(ide(i+nide)))) | ...
            ((t >= t(ide(i)) - a) & (t < t(ide(i)))));
    else
        ind = [max(1, ceil(ide(i) - a)):ide(i)-1, ide(i+nide)+1:min(numel(A), floor(ide(i+nide) + b))];
    end
    xin = A(ind);
    tin = t(ind);
    toutidx = tidx(ide(i,1):ide(i,2));
    tout = t(toutidx);
    try
        ytmp = fillfun(xin, tin, tout);
    catch ME
        if isempty(xin)
            m = message('MATLAB:fillmissing:FunctionHandleEmptyInput');
            throw(addCause(MException(m.Identifier,'%s',getString(m)),ME));
        else
            throw(ME);
        end
    end

    if isscalar(ytmp) || (isvector(ytmp) && isequal(numel(ytmp),numel(toutidx)))
        Y(toutidx) = ytmp;
    else % Bad output size
        error(message('MATLAB:fillmissing:FunctionHandleInvalidOutputSize'));
    end
end
end % handlefill
%--------------------------------------------------------------------------
function [B,FB] = knnFill(A,AisTable,k,dataVars,ma,distance,dim,replace)
if isempty(ma)
    ma = ismissing(A);
end

% Quick return when no filling is needed
if isempty(A) || ~any(ma,'all') || dim > 2
    if replace
        B = A;
    else
        B = matlab.internal.math.appendDataVariables(A,A(:,dataVars),"filled");
    end
    FB = false(size(B));
    return
end

if isa(distance,'function_handle')
    [B,FB] = knnFillCustomDistances(A,AisTable,k,dataVars,ma,distance,dim,replace);
else
    [B,FB] = knnFillBuiltInDistances(A,AisTable,k,dataVars,ma,distance,dim,replace);
end
end % knnFill
%--------------------------------------------------------------------------
function [B,FB] = knnFillBuiltInDistances(A,AisTable,k,dataVars,ma,distance,dim,replace)
if istimetable(A)
    error(message('MATLAB:fillmissing:DistanceTimetableNotSupported'));
end
% matlab.internal.math.fillmissingKNN fills using the k-nearest rows, so
% A is transposed unless dim == 1
transposeData = dim == 2;
if AisTable
    AT = checkAndExtractTableVars(A,dataVars);
    ma = ma(:,dataVars);
elseif transposeData
    AT = A.';
    ma = ma.';
else % dim == 1
    AT = A;
end

if ~isfloat(AT)
    error(message('MATLAB:fillmissing:DistanceNonFloatsNotSupported'));
end

if strcmp(distance,'seuclidean')
    scalingVector = double(std(AT,0,1,'omitnan'));
    [BOutTmp,FBTmp] = matlab.internal.math.fillmissingKNN(full(AT),full(ma),uint64(k),full(scalingVector));
else
    [BOutTmp,FBTmp] = matlab.internal.math.fillmissingKNN(full(AT),full(ma),uint64(k));
end
if issparse(A)
    BOutTmp = sparse(BOutTmp);
    FBTmp = sparse(FBTmp);
end

if AisTable
    if replace
        B = A;
        BDataVars = dataVars;
    else
        B = A(:,dataVars);
        BDataVars = 1:width(B);
    end

    FB = false(size(B));
    if ~any(FBTmp,'all')
        return
    end
    varsToReplace = find(any(FBTmp,1));
    for ii = varsToReplace
        B.(BDataVars(ii)) = cast(BOutTmp(:,ii),class(B.(ii)));
    end
    
    if replace
        FB(:,dataVars) = FBTmp;
    else
        B = matlab.internal.math.appendDataVariables(A,B,"filled");
        FB = [false(size(A)),FBTmp];
    end
else
    if transposeData
        B = BOutTmp';
        FB = FBTmp';
    else
        B = BOutTmp;
        FB = FBTmp;
    end
end
end % knnFillBuiltInDistances
%--------------------------------------------------------------------------
function [B,FB] = knnFillCustomDistances(A,AisTable,k,dataVars,ma,distance,dim,replace)
if dim == 2
    A = A.';
    ma = ma';
end

if AisTable
    ADataVars = A(:,dataVars);
    ma = ma(:,dataVars);
else
    ADataVars = A;
    dataVars = 1:size(A,2);
end

if replace
    B = A;
    BDataVars = dataVars;
else % can only be hit for tables and timetables
    B = A(:,dataVars);
    BDataVars = 1:width(B);
end

if issparse(A)
    FB = logical(sparse(size(B,1),size(B,2)));
else
    FB = false(size(B));
end

numOfVectors = size(A,1);
vectorDistances = zeros(numOfVectors,1);
% Walk through the rows (vectors) of BIn, calculating nearest neighbors as needed 
for ii = 1:numOfVectors
    maCurrentVector = ma(ii,:);
    if any(maCurrentVector) && ~all(maCurrentVector) % all-missing vectors cannot be filled
        % Calculate nearest neighbors
        for jj = 1:numOfVectors
            if ii ~= jj
                try
                    vectorDistances(jj) = double(distance(ADataVars([ii,jj],:),ma([ii,jj],:)));
                catch ME
                    if strcmp(ME.identifier,'MATLAB:invalidConversion')
                        baseException = MException(message('MATLAB:fillmissing:InvalidCustomDistance'));
                    else
                        baseException = MException(message('MATLAB:fillmissing:DistanceCalculationFailed'));
                    end
                    baseException = addCause(baseException, ME);
                    throw(baseException);
                end
            else
                vectorDistances(jj) = NaN;
            end
        end

        if ~isreal(vectorDistances)
            error(message('MATLAB:fillmissing:InvalidCustomDistance'));
        end

        % vectorDistances is sorted before NaNs are removed to preserve indices
        [sortedDistances,sortedIndices] = sort(vectorDistances);
        sortedIndices = sortedIndices(~isnan(sortedDistances)); % Don't use NaN distances
        if ~isempty(sortedIndices) % Only fill if there are non-NaN values to fill with
            for jj = find(maCurrentVector)
                kIndices = sortedIndices(~ma(sortedIndices,jj)); % Don't try to fill with a missing value
                if ~isempty(kIndices)
                    kIndices = kIndices(1:min(numel(kIndices),k)); % Keep the k lowest distances (the k nearest neighbors)
                    % Note that if n > k vectors are the same distance from the
                    % current vector, the k vectors with the smallest index are
                    % used.
                    if isscalar(kIndices)
                        fillValue = ADataVars(kIndices,jj);
                        B(ii,BDataVars(jj)) = fillValue;
                    else
                        if AisTable
                            try
                                fillValue = mean(ADataVars{kIndices,jj},1,'native');
                            catch ME
                                baseException = MException(message('MATLAB:fillmissing:AggregationFailed'));
                                baseException = addCause(baseException, ME);
                                throw(baseException);
                            end
                            B{ii,BDataVars(jj)} = fillValue;
                        else
                            try
                                fillValue = mean(ADataVars(kIndices,jj),1,'native');
                            catch ME
                                baseException = MException(message('MATLAB:fillmissing:AggregationFailed'));
                                baseException = addCause(baseException, ME);
                                throw(baseException);
                            end
                            B(ii,jj) = fillValue; % dataVars are unnecessary for the non-tabular case
                        end
                    end
                    FB(ii,BDataVars(jj)) = true;
                end
            end
        end
    end
end
if ~replace
    B = matlab.internal.math.appendDataVariables(A,B,"filled");
    FB = [false(size(A)),FB];
end
if dim == 2
    B = B.';
    FB = FB.';
end
end % knnFillCustomDistances
%--------------------------------------------------------------------------
function AMatrixT = checkAndExtractTableVars(ATable,dataVars)
AMatrixT = zeros(height(ATable),numel(dataVars)); % This will hold the transpose of the data in ATable
for ii = 1:numel(dataVars)
    tmp = ATable.(dataVars(ii));
    if ~isfloat(tmp)
        error(message('MATLAB:fillmissing:DistanceNonFloatsNotSupported'));
    end
    if size(tmp,2) ~= 1
        error(message('MATLAB:fillmissing:DistanceMultiColumnTableVars'))
    end
    AMatrixT(:,ii) = tmp;
end
end % checkAndExtractTableVars
%--------------------------------------------------------------------------
function b = fillWithNext(b,ma)
maInds = flip(find(ma));
if ma(end) % Last value is missing
    firstFillableElement = 2;
    % Walk through maInds to find the first non-consecutive element
    % This will correspond to the last missing value that is followed by a
    % non-missing value
    while(firstFillableElement <= numel(maInds) && ...
            maInds(firstFillableElement) + 1 == maInds(firstFillableElement - 1))
        firstFillableElement = firstFillableElement + 1;
    end
    maInds = maInds(firstFillableElement:end);
end
for ii = maInds.'
    b(ii) = b(ii + 1);
end
end % fillWithNext
%--------------------------------------------------------------------------
function b = fillWithPrevious(b,ma)
maInds = find(ma);
if ma(1) % First value is missing
    firstFillableElement = 2;
    % Walk through maInds to find the first non-consecutive element
    % This will correspond to the first missing value that is preceded by a
    % non-missing value
    while(firstFillableElement <= numel(maInds) && ...
            maInds(firstFillableElement) - 1 == maInds(firstFillableElement - 1))
        firstFillableElement = firstFillableElement + 1;
    end
    maInds = maInds(firstFillableElement:end);
end
for ii = maInds.'
    b(ii) = b(ii - 1);
end
end % Fill with previous
