function varargout = locateOutliers(A, varargin)
% LOCATEOUTLIERS Detect (and fill) outliers in tall arrays and tall tables.

% Copyright 2017-2023 The MathWorks, Inc.

if nargout < 5
    fname = 'isoutlier'; % [TF,LB,UB,C] = tall/isoutlier(A,...)
else
    fname = 'filloutliers'; % [B,TF,LB,UB,C] = tall/filloutliers(A,...)
end

% Parse inputs and error out as early as possible.
% The first input and 'OutlierLocations' must be tall. The other inputs
% must not be tall (will be checked later on when we parse them).
tall.checkIsTall(upper(fname),1,A);
typesA = {'double','single','table','timetable'};
A = tall.validateType(A,fname,typesA,1);
opts = parseLocateOutlierInputs(A,fname,varargin{:});

% Match in-memory error message for complex data.
if ~opts.IsTabular
    A = lazyValidate(A,{@(a)iValidateattributesPred(a,typesA,fname)});
end

if istall(opts.Method) % Fill outliers according to 'OutlierLocations'
    if opts.IsTabular
        [varargout{1:nargout}] = iTabularWrapper(A,fname,opts,@iFillLocations);
    else
        [varargout{1:nargout}] = iFillLocations(A,opts);
    end
elseif startsWith(opts.Method, {'me', 'movme'})
    % 'median' (default), 'mean', 'movmedian', 'movmean'
    if opts.IsTabular
        [varargout{1:nargout}] = iTabularWrapper(A,fname,opts,@iOutliersMedianMean);
    else
        [varargout{1:nargout}] = iOutliersMedianMean(A,opts);
    end
else
    % 'quartiles'
    if opts.IsTabular
        [varargout{1:nargout}] = iTabularWrapper(A,fname,opts,@iOutliersQuartiles);
    else
        [varargout{1:nargout}] = iOutliersQuartiles(A,opts);
    end
end

% ISOUTLIER might want the output as a table
if opts.OutputFormat == "tabular"
    if ismember(A.Adaptor.Class, ["table","timetable"])
        % For OutputFormat - tabular, only keep the selected variables.
        if numel(opts.DataVars) < numel(opts.AllVars)
            varargout{1} = subselectTabularVars(varargout{1},ismember(opts.AllVars,opts.DataVars));
        end
        % Keep format (table/timetable) and all properties of the input A
        % except for VariableUnits and VariableContinuity.
        if A.Adaptor.Class == "table"
            tabularOutput = array2table(varargout{1},"VariableNames",opts.DataVars,...
                "DimensionNames",getDimensionNames(A.Adaptor));
        else %timetable
            rt = subsref(A,substruct('.','Properties','.','RowTimes'));
            tabularOutput = array2timetable(varargout{1},"DimensionNames",getDimensionNames(A.Adaptor),...
                "VariableNames",opts.DataVars,"RowTimes",rt);
        end
        tabularOutput = matlab.bigdata.internal.adaptors.TabularAdaptor.copyOtherTabularProperties(...
            tabularOutput,A);
        tabularOutput = subsasgn(tabularOutput,substruct('.','Properties','.','VariableUnits'),{});
        tabularOutput = subsasgn(tabularOutput,substruct('.','Properties','.','VariableContinuity'),{});
        varargout{1} = tabularOutput;
    else
        varargout{1} = array2table(varargout{1});
    end

% FILLOUTLIERS might want the new results appended instead of over-written
elseif ~opts.ReplaceValues
    % We need to prepend a logical array with all values false (the columns
    % corresponding to the orginal data were not filled).
    TF2 = subsasgn(varargout{1},substruct('()',{':',':'}), false);
    varargout{1} = horzcat(TF2,varargout{1});
    % If not replacing, create a new table using only the modified
    % variables and then append to the input.
    if nargout>4
        B = subselectTabularVars(varargout{5},ismember(opts.AllVars,opts.DataVars));
        varargout{5} = matlab.internal.math.appendDataVariables(A,B,"filled");
    end
end


%--------------------------------------------------------------------------
function [TF,lowerbound,upperbound,center,B] = iOutliersMedianMean(A,opts)
% Outlier detection: 'median', 'mean', 'movmedian', 'movmean'.
% 'median', 'mean', 'movmedian', and 'movmean' only need (mov)median,
% (mov)mean, (mov)std, abs, and erfcinv. Therefore, we can directly use
% the tall implementations of these functions.

if strcmpi(opts.Method,'median')
    % tall/median errors with a median-specific message if DIM cannot be
    % deduced. We avoid this and error ourselves if:
    %   (1) The DIM cannot be deduced
    %   (2) AND the first input was not a tall column vector.
    % If the first input was a tall column vector, we do compute outliers.
    [A,opts.Dim] = iDeduceFirstNonSingletonDimOrError(A,opts.Dim);
    dimAndNaN = {opts.Dim 'omitnan'};
else
    % We let the tall implementations of movmedian, (mov)mean, (mov)std
    % properly handle DIM, which we had parsed and set to [] if unknown.
    dimAndNaN(~isempty(opts.Dim)) = {opts.Dim};
    dimAndNaN = [dimAndNaN,{'omitnan'}]; % {'omitnan'} or {dim 'omitnan'}
end

switch opts.Method
    case 'median'
        center = median(A,dimAndNaN{:});
        k = -1/(sqrt(2)*erfcinv(3/2)); % ~ 1.4826
        thresh = k .* median(abs(A-center),dimAndNaN{:});
    case 'mean'
        center = mean(A,dimAndNaN{:});
        thresh = std(A,0,dimAndNaN{:});
    case 'movmedian'
        center = movmedian(A,opts.Window,dimAndNaN{:});
        k = -1/(sqrt(2)*erfcinv(3/2)); % ~ 1.4826
        thresh = k .* movmad(A,opts.Window,dimAndNaN{:});
    otherwise % 'movmean'
        center = movmean(A,opts.Window,dimAndNaN{:});
        thresh = movstd(A,opts.Window,0,dimAndNaN{:});
end

% Apply the outlier thresholds.
lowerbound = center - opts.ThresholdFactor .* thresh;
upperbound = center + opts.ThresholdFactor .* thresh;
TF = A < lowerbound | upperbound < A;

% Fill outliers if called by tall/filloutliers.
if nargout > 4
    B = iFillOutliers(A,TF,lowerbound,upperbound,center,opts);
end

%--------------------------------------------------------------------------
function [A,dim] = iDeduceFirstNonSingletonDimOrError(A,dim)
% Deduce the first non-singleton dimension. If we cannot deduce it, error
% for tall arrays that are not column vectors.
if isempty(dim)
    dim = getDefaultReductionDimIfKnown(A.Adaptor);
    if isempty(dim)
        % DIM couldn't be deduced. Error for non-column tall inputs.
        errid = 'MATLAB:bigdata:array:NoDimMustBeColumn';
        A = tall.validateColumn(A,errid);
        % But do compute for a tall column vector.
        dim = 1;
    end
end

%--------------------------------------------------------------------------
function [TF,LB,UB,C,B] = iOutliersQuartiles(A,opts)
% Branch 'quartiles' according to the tall dimension (DIM == 1).

[A,opts.Dim] = iDeduceFirstNonSingletonDimOrError(A,opts.Dim);

if opts.Dim == 1
    % Use the tall algorithm.
    [TF,LB,UB,C] = iQuartilesTallCol(A,opts.ThresholdFactor);
else
    % Use in-memory algorithm on each slice.
    fh = @(x,d)isoutlier(x,'quartiles',d,'Threshold',opts.ThresholdFactor);
    [TF,LB,UB,C] = slicefun(fh,A,opts.Dim);
    TF = iSetFirstOutputAdaptor(A,TF);
end

% Fill outliers if called by tall/filloutliers.
if nargout > 4
    B = iFillOutliers(A,TF,LB,UB,C,opts);
end

%--------------------------------------------------------------------------
function [tf,lowerbound,upperbound,center] = iQuartilesTallCol(a,factor)
% Same formula as non-tall isoutlier, but rephrased in a tall-friendly way.

[iqr,quartile1,quartile3] = datafuniqr(a);

% Apply the quartile thresholds.
center = mean([quartile1 quartile3],2);
lowerbound = quartile1 - factor .* iqr;
upperbound = quartile3 + factor .* iqr;
tf = a < lowerbound | upperbound < a;

%--------------------------------------------------------------------------
function [TF,LB,UB,C,B] = iTabularWrapper(A,fname,opts,outlierFun)
% Tall array outlier computations for each tall (time)table variable.

opts.MethodIn = opts.Method; % Need to keep track for 'OutlierLocations'.

av = opts.AllVars;
dv = opts.DataVars;
numav = numel(av);
numdv = numel(dv);

% Validate table variables upfront, just like in tall/fillmissing.
adaptorA = A.Adaptor;
A = elementfun(@(T)iCheckTableVarType(T,fname,dv),A);
A.Adaptor = adaptorA;

if nargout > 4
    B = A; % First output from filloutliers.
end
% Use cells to hold individual tall table variable results.
dataTF = cell(1,numav); % TF has the same size as the table.
dataLB = cell(1,numdv);
dataUB = cell(1,numdv);
dataC = cell(1,numdv);

% Apply tall array computation with DIM = 1 to each (time)table variable.
for jj = 1:numdv
    % Get and validate the table variable.
    vj = subsref(A,substruct('.',dv{jj}));
    % Compute.
    if nargout > 4
        % tall/filloutliers
        if istall(opts.MethodIn)
            % Select appropriate column of 'OutlierLocations' logical mask.
            mj = ismember(av,dv{jj});
            opts.Method = subselectTabularVars(opts.MethodIn,mj);
        end
        [dataTF{jj},dataLB{jj},dataUB{jj},dataC{jj},vjf] = outlierFun(vj,opts);
        % Assign back to jth (time)table variable.
        B = subsasgn(B,substruct('.',dv{jj}),vjf);
    else
        % tall/isoutlier
        [dataTF{jj},dataLB{jj},dataUB{jj},dataC{jj}] = outlierFun(vj,opts);
    end
    % Match in-memory behavior for non-column table variables.
    dataTF{jj} = any(dataTF{jj},2);
end

% TF has the same size as the table. Reconcile this with DataVariables.
if numdv < numav
    % Map computed results back to the correct columns in TF.
    colsInDataVars = ismember(av,dv);
    dataTF(colsInDataVars) = dataTF(1:numdv);
    % Set the columns that were not included in DataVariables to FALSE.
    v1 = subsref(A,substruct('.',av{1})); % av is never empty here
    falseColumn = slicefun(@(a)false(size(a,1),1),v1);
    falseColumn = setKnownType(falseColumn,'logical');
    dataTF(~colsInDataVars) = {falseColumn};
end

if numav == 0
    % For empty tables A, force TF to have the same number of rows as A.
    TF = elementfun(@(a)false(size(a,1),0),A);
else
    % Convert cells of tall columns into correct tall outputs.
    TF = [dataTF{:}];
end
TF = iSetFirstOutputAdaptor(A,TF);

% Similar approach to tall/varfun for tall (time)table outputs 2, 3, and 4.
if strcmpi(A.Adaptor.Class,'table')
    if isempty(dv)
        % Empty DataVariables or empty tables.
        emptyTable = table.empty(1, 0);
        emptyTable.Properties.DimensionNames = getDimensionNames(A.Adaptor);
        LB = tall.createGathered(emptyTable);
        LB = matlab.bigdata.internal.adaptors.TabularAdaptor.copyOtherTabularProperties(LB,A);
        UB = LB;
        C = LB;
    else
        dn = getDimensionNames(A.Adaptor);
        LB = table(dataLB{:},'VariableNames',dv,'DimensionNames',dn);
        UB = table(dataUB{:},'VariableNames',dv,'DimensionNames',dn);
        C = table(dataC{:},'VariableNames',dv,'DimensionNames',dn);
        % Make sure that we copy across the properties from A.
        LB = matlab.bigdata.internal.adaptors.TabularAdaptor.copyOtherTabularProperties(LB,A);
        UB = matlab.bigdata.internal.adaptors.TabularAdaptor.copyOtherTabularProperties(UB,A);
        C = matlab.bigdata.internal.adaptors.TabularAdaptor.copyOtherTabularProperties(C,A);
    end
else
    dn = getDimensionNames(A.Adaptor);
    rt = subsref(A,substruct('.','Properties','.','RowTimes'));
    % Match in-memory isoutlier and keep the first entry in Time.
    if ~startsWith(opts.Method,'mov')
        rt = head(rt,1);
        % If the timetable A is a 0-by-N empty, the optional outputs LB,
        % UB, C are 1-by-N timetables with NaNs/missing. We need to force
        % the RowTimes property to have height 1 before attempting to
        % create the corresponding timetables for LB, UB, and C.
        rtAdaptor = matlab.bigdata.internal.adaptors.getAdaptor(rt);
        isRTHeightEmpty = size(rt, 1) == 0;
        isRTHeightEmpty = matlab.bigdata.internal.broadcast(isRTHeightEmpty);
        rt = clientfun(@iGenerateRowTimesIfEmpty, rt, isRTHeightEmpty);
        rt.Adaptor = resetTallSize(rtAdaptor);
    end
    LB = makeTallTimetableWithDimensionNames(dn,rt,dv,'',dataLB{:});
    UB = makeTallTimetableWithDimensionNames(dn,rt,dv,'',dataUB{:});
    C = makeTallTimetableWithDimensionNames(dn,rt,dv,'',dataC{:});
    % Make sure that we copy across the properties from A.
    LB = matlab.bigdata.internal.adaptors.TabularAdaptor.copyOtherTabularProperties(LB,A);
    UB = matlab.bigdata.internal.adaptors.TabularAdaptor.copyOtherTabularProperties(UB,A);
    C = matlab.bigdata.internal.adaptors.TabularAdaptor.copyOtherTabularProperties(C,A);
end

%--------------------------------------------------------------------------
function A = iCheckTableVarType(A,functionName,dataVars)
% Match in-memory error messages.
errid1 = ['MATLAB:',functionName,':NonColumnTableVar'];
errid2 = ['MATLAB:',functionName,':NonfloatTableVar'];
errid3 = ['MATLAB:',functionName,':ComplexTableVar'];
for jj = 1:numel(dataVars)
    vj = A.(dataVars{jj});
    if ~(isempty(vj) || iscolumn(vj))
        error(message(errid1));
    end
    if ~isfloat(vj)
        error(message(errid2,dataVars{jj},class(vj)));
    end
    if ~isreal(vj)
        error(message(errid3));
    end
end

%--------------------------------------------------------------------------
function TF = iSetFirstOutputAdaptor(A,TF)
% First output is always logical of the same size as the first input.
outAdaptor = matlab.bigdata.internal.adaptors.getAdaptorForType('logical');
TF.Adaptor = copySizeInformation(outAdaptor,A.Adaptor);

%--------------------------------------------------------------------------
function tf = iValidateattributesPred(A,typesA,fname)
% We need a predicate to return A because validateattributes has no output.
validateattributes(A,typesA,{'real'},fname,'A',1);
tf = true;

%--------------------------------------------------------------------------
function [TF,LB,UB,C,B] = iFillLocations(A,opts)
% Fill outliers according to 'OutlierLocations'.
TF = opts.Method; % 'OutlierLocations' value.

% For consistency with in-memory filloutliers, the bounds and center must
% be reduction results filled with NaNs.
dim(~isempty(opts.Dim)) = {opts.Dim}; % Empty for default dimension.

% Follow tall/sum approach to get reduced results full of NaNs and
% dimension information. Can't use @(x) x+NaN directly because 
% aggregateInDim only supports @sum, @min, @median ...
[LB,opts.Dim] = aggregateInDim(@sum,A,dim,{},{});
LB.Adaptor = A.Adaptor;
LB.Adaptor = computeReducedSize(LB.Adaptor,A.Adaptor,opts.Dim,false);
LB = elementfun(@(x) x+NaN,LB); % Fill with NaNs of correct type.
UB = LB;
C = LB;

B = iFillOutliers(A,TF,LB,UB,C,opts);

%--------------------------------------------------------------------------
function B = iFillOutliers(A,TF,lowerbound,upperbound,center,opts)
% Fill outliers
B = A;
if isnumeric(opts.Fill)
    B = elementfun(@iReplaceUsingLogicalMask,B,TF,opts.Fill);
elseif strcmpi(opts.Fill,'center')
    if startsWith(opts.Method,'mov')
        % B(TF) = center(TF)
        B = elementfun(@iReplaceUsingLogicalMask,B,TF,center);
    else
        % center is a reduced array containing a single center along the
        % operating dimension, but we need to fill multiple outliers along
        % this dimension with this center value.
        % This is done in in-memory filloutliers with:
        % B(TF) = center(ceil(find(TF)/size(A,DIM)))
        B = TF.*center;
        B = elementfun(@iReplaceUsingLogicalMask,B,~TF,A);
    end
elseif strcmpi(opts.Fill,'clip')
    % Same call as in-memory filloutliers.
    B = min(max(B,lowerbound,'includenan'),upperbound,'includenan');
else
    % NaNs are ignored by isoutlier and filloutliers, so we can use
    % tall/fillmissing by changing outliers to NaN: B(TF) = NaN.
    B = elementfun(@iReplaceUsingLogicalMask,B,TF,NaN);
    dim(~isempty(opts.Dim)) = {opts.Dim}; % Empty for default dimension.
    B = fillmissing(B,opts.Fill,dim{:});
    % But do not fill the original NaNs in the data: B(isnan(A)) = NaN.
    B = elementfun(@iReplaceUsingLogicalMask,B,isnan(A),NaN);
end
B.Adaptor = A.Adaptor;

%--------------------------------------------------------------------------
function b = iReplaceUsingLogicalMask(b,tf,r)
if isscalar(r)
    b(tf) = r;
else % r has the same size as b.
    b(tf) = r(tf); % r is the array of centers from 'movmedian'/'movmean'.
end

%--------------------------------------------------------------------------
function rowtimes = iGenerateRowTimesIfEmpty(rowtimes, isRTHeightEmpty)
% Generate a "missing" value for rowTimes when it is entirely empty.
if isRTHeightEmpty
    rowtimes(1) = missing;
end
