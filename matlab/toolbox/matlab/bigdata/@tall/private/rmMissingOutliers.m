function [B,indrm,indoutlier,lthresh,uthresh,center] = rmMissingOutliers(funName,A,varargin)
% rmMissingOutliers Helper function for rmmissing and rmoutliers
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%
%   B - A after removing rows or columns
%   I - Colum(row) logical vector indicating removed (rows)columns
%

%   Copyright 2017-2024 The MathWorks, Inc.

narginchk(2,Inf);
nargoutchk(0,6);
tall.checkIsTall(upper(funName), 1, A);

if isequal(funName,'rmoutliers')
    typesA = {'double','single','table','timetable'};
    A = tall.validateType(A, funName, typesA, 1);
else
    % RMMISSING can accept any type but returns the input unmodified if the
    % type does not have a definition of "missing".
end

[dim, opts] = iParseInputs(funName, A, varargin{:});

if isequal(funName,'rmoutliers') && opts.locsProvided
    % Mimic in-memory that relies on parsing for isoutlier when
    % 'OutlierLocations' is provided.
    if opts.AisTable
        dataVars = opts.dataVars;
        A = lazyValidate(A,{@(a)iValidateTabularVars(a, dataVars)});
    else
        A = lazyValidate(A,{@(a)iValidateattributesPred(a, typesA, 'isoutlier')});
    end
end

if A.Adaptor.NDims > 2
    issueError(funName,'NDArrays');
end

if opts.AisTable
    for ii = 1 : width(A)
        S = substruct('.', ii);
        A = subsasgn(A, S, tall.validateMatrix(subsref(A, S), ['MATLAB:', funName, ':NDArrays']));
    end
else
    A = tall.validateMatrix(A, ['MATLAB:', funName, ':NDArrays']);
end

% First find where the missing values are
if opts.AisTable
    if isequal(funName,'rmmissing')
        dataVars = opts.dataVars;
        indrm = slicefun(@(t)ismissing(t(:, dataVars)), A);
    else
        if opts.locsProvided
            % Don't call isoutlier and create "undefined" thresholds and
            % center. These will have the same tabular properties as A and
            % will contain a single row of missing values,
            % depending on the datatypes of each variable. We take a single
            % row of the tabular input A to generate them.
            indrm = opts.outlierLocs;
            indoutlier = indrm;
            if opts.dataVarsProvided
                indrm = subselectTabularVars(indrm, opts.dataVars);
            end
            if nargout > 3
                headA = head(A, 1);
                if opts.dataVarsProvided
                    headA = subselectTabularVars(headA, opts.dataVars);
                end
                [lthresh, uthresh, center] = clientfun(@iGenerateExtraOutputs, headA);
                [lthresh, uthresh, center] = iSetExtraOutputAdaptors(headA, lthresh, uthresh, center);
            end
        else
            opts.isoutlierArgs = {opts.isoutlierArgs{:} 'DataVariables' opts.dataVars}; %#ok<CCAT>
            if nargout > 3
                [indrm, lthresh, uthresh, center] = isoutlier(A,opts.isoutlierArgs{:});
            else
                indrm = isoutlier(A,opts.isoutlierArgs{:});
            end
            indoutlier = indrm;
        end
    end
else
    if isequal(funName,'rmmissing')
        indrm = ismissing(A);
    else
        if opts.locsProvided
            % Don't call isoutlier and create "undefined" thresholds and
            % center. These will be a row/slice of the same type as input A
            % with NaNs. We take a row/slice of input A to generate them.
            indrm = opts.outlierLocs;
            indoutlier = indrm;
            if nargout > 3
                headA = head(A, 1);
                [lthresh, uthresh, center] = clientfun(@iGenerateExtraOutputs, headA);
                [lthresh, uthresh, center] = iSetExtraOutputAdaptors(headA, lthresh, uthresh, center);
            end
        else
            if nargout > 3
                [indrm, lthresh, uthresh, center] = isoutlier(A,opts.isoutlierArgs{:});
            else
                indrm = isoutlier(A,opts.isoutlierArgs{:});
            end
            indoutlier = indrm;
        end
    end
end

% Create filters for removing either missing rows or missing columns.
% Row filter is a slice-wise operation to create a tall logical column
% vector with the same tall size as the input
minNum = opts.minNum;
Irows = slicefun(@(tf) sum(tf, 2) >= minNum, indrm);

if isequal(funName,'rmmissing') && strcmpi(A.Adaptor.Class, 'timetable')
    % For timetables, also need to remove any missing row times
    rmMissingRowTimes = @(t, ism) ism | ismissing(t.Properties.RowTimes);
    Irows = slicefun(rmMissingRowTimes, A, Irows);
end

Irows.Adaptor = setKnownSize(Irows.Adaptor, [NaN 1]);
Irows.Adaptor = copyTallSize(Irows.Adaptor, A.Adaptor);

% Column filter is a reduction down to a logical row vector that has the
% same length as A is wide
minNum = opts.minNum;
Icols = reducefun(@(tf) sum(tf, 1) >= minNum, indrm);

Icols.Adaptor = setKnownSize(Icols.Adaptor, [1 NaN]);

if A.Adaptor.isSmallSizeKnown
    Icols.Adaptor = resetSmallSizes(Icols.Adaptor, A.Adaptor.SmallSizes);
end

[dimIsKnown, dimValue] = iCheckDim(dim);

if dimIsKnown
    if dimValue == 1
        % Use the row filter to remove missing rows
        indrm = Irows;
        B = filterslices(~indrm, A);
        B.Adaptor = A.Adaptor;
        B.Adaptor = resetTallSize(B.Adaptor);
    else
        % Use the column filter to remove missing cols
        indrm = Icols;
        B = slicefun(@(a, ic) a(:, ~ic), A, indrm);
        B.Adaptor = A.Adaptor;
        B.Adaptor = resetSmallSizes(B.Adaptor, NaN);
    end
    
    indrm = setKnownType(indrm, 'logical');
else
    % Conditionally apply the correct filter, depending on the value of dim
    [B, indrm] = partitionfun(@iRmRowsOrCols, A, Irows, Icols, dim, isscalar(A));
    [B, indrm] = iSetOutputAdaptors(A, B, indrm);
    % As B and I are derived from partitionfun, the framework assumes these
    % contain partition dependent data. We must correct this before them to
    % the user.
    [B, indrm] = copyPartitionIndependence(B, indrm, A);
end
end

%--------------------------------------------------------------------------
function [hasFinished, B, I] = iRmRowsOrCols(info, A, Irows, Icols, dim, inputIsScalar)
% Remove either rows or cols that contain at least minNumMissing values,
% depending on the deferred value of dim.

if dim == 1 || inputIsScalar
    % Remove rows
    B = A(~Irows, :);
    I = Irows;
else
    % Remove cols
    B = A(:, ~Icols);
    
    % Conditionally emit the column filter for the second output
    if info.PartitionId == 1
        I = Icols;
    else
        I = matlab.bigdata.internal.util.indexSlices(Icols, []);
    end
end

hasFinished = info.IsLastChunk;
end

%--------------------------------------------------------------------------
function [dim, opts] = iParseInputs(funName, A, varargin)
% Parse and validate optional inputs for tall/rmmissing and tall/rmoutliers

% Defaults
opts.AisTable = istabular(A);
if opts.AisTable
    % DataVariables defaults to using all the variable names
    opts.dataVars = getVariableNames(A.Adaptor);
else
    opts.dataVars = {};
end
opts.dataVarsProvided = false;
opts.minNum = 1;
opts.byRows = [];
opts.isoutlierArgs = {}; % arguments needed for ISOUTLIER computation

% Extract 'OutlierLocations' if provided for 'isoutlier'. It must be a tall
% logical array of the same size as A.
doOutliers = funName == "rmoutliers";
extraArgs = varargin;

if doOutliers
    offsetMethod = 0;
    opts.locsProvided = false;
    ii = 1;
    while ii <= numel(varargin)
        thisArg = varargin{ii};
        if ~istall(thisArg) && matlab.internal.math.checkInputName(thisArg, 'OutlierLocations')
            if ii == numel(varargin)
                % OutlierLocations is the last element and has no
                % corresponding value.
                error(message('MATLAB:rmoutliers:NameValuePairs'));
            end
            parVal = varargin{ii+1};
            % Must be tall and have the same size as the first input.
            tall.checkIsTall(upper(funName), ii+2, parVal); % Need to count the input as well.
            parVal = tall.validateType(parVal, funName, {'logical'}, ii+2);
            [A ,parVal] = validateSameTallSize(A, parVal);
            [A, parVal] = tall.validateSameSmallSizes(A, parVal,...
                'MATLAB:bigdata:array:OutliersLocation');
            opts.locsProvided = true;
            opts.outlierLocs = parVal;
            extraArgs(ii:ii+1) = [];
            ii = ii + 2;
        elseif ii == 1 && ~istall(thisArg) && (ischar(thisArg) || isstring(thisArg))
            % Check if an outlier detection method has been specified. It
            % can only be placed in the first element of varargin.
            ind = matlab.internal.math.checkInputName(thisArg, ...
                {'median' 'mean' 'movmedian' 'movmean' 'percentiles' 'quartiles' 'grubbs' ...
                'gesd' 'SamplePoints' 'DataVariables' 'ThresholdFactor' 'OutlierLocations' ...
                'MinNumOutliers'});
            if sum(ind) ~= 1
                error(message('MATLAB:rmoutliers:SecondInputString'));
            end
            offsetMethod = any(ind(1:8)) + any(ind(3:5));
            ii = ii + 1;
        else
            % All the rest of arguments in varargin must not be tall.
            tall.checkNotTall(upper(funName), ii, thisArg);
            ii = ii + 1;
        end
    end

    % Match in-memory check for rmoutliers with OutlierLocations
    if opts.locsProvided && offsetMethod > 0
        error(message('MATLAB:rmoutliers:MethodNotAllowed'));
    end
else
    % Need to check for disallowed options before the tall check.
    if any(cellfun(@(x) iMatchNameArg(x, 'MissingLocations', 3), varargin))
        error(message('MATLAB:bigdata:array:MissingLocationsNotSupported'));
    end
    tall.checkNotTall(upper(funName), 1, varargin{:});
end

% Parse the rest of N-V pairs and inputs which need to be forwarded to
% ISOUTLIER
errorForDataVars = false;
opts = rmMissingOutliersVarargin(funName,A,...
    opts,errorForDataVars,extraArgs{:});

if isempty(opts.byRows)
    % Default DIM
    if opts.AisTable
        % Table & timetable default to removing rows with missing entries
        dim = tall.createGathered(1);
    else
        % Arrays follow the first non-singleton dim rule
        dim = findFirstNonSingletonDim(A);
        dim = lazyValidate(dim, {@(d) d==1 || d==2, ['MATLAB:', funName, ':NDArrays']});
    end
else
    if ~opts.byRows && opts.AisTable
        error(message('MATLAB:bigdata:array:UnsupportedTableColRemoval'));
    end
    dim = tall.createGathered(~opts.byRows+1); % Set DIM to 1 or 2
end

% We validate the extracted data variables with the tall private helper.
if opts.dataVarsProvided
    for ii = 1:numel(opts.dataVars)
        dv = checkDataVariables(A, opts.dataVars{ii}, funName);
    end
    opts.dataVars = dv;
end

% If the 'OutlierLocations' name-value pair was provided, we won't call
% isoutlier to do the rest of the parsing. Do it now here.
if doOutliers && opts.locsProvided
    parseLocateOutlierInputs(A, 'isoutlier', opts.isoutlierArgs{:});
end
end

%--------------------------------------------------------------------------
function [B, I] = iSetOutputAdaptors(A, B, I)
% Setup the output adaptors for the case where the dim could not be
% determined upfront

import matlab.bigdata.internal.adaptors.getAdaptorForType

% We at least know that both outputs are 2-D
szVec = [NaN NaN];
B.Adaptor = resetSizeInformation(A.Adaptor);
B.Adaptor = setKnownSize(B.Adaptor, szVec);

I.Adaptor = getAdaptorForType('logical');
I.Adaptor = setKnownSize(I.Adaptor, szVec);
end

%--------------------------------------------------------------------------
function [dimIsKnown, dimValue] = iCheckDim(dim)
% Given deferred dim, check whether the result is known and its local
% value.  The value will be [] when the dim is unknown.

import matlab.bigdata.internal.util.isGathered

[dimIsKnown, dimValue] = isGathered(hGetValueImpl(dim));
end

%--------------------------------------------------------------------------
function issueError(funName,errorId)
% Issue error from the correct error message catalog.
error(message(['MATLAB:', funName, ':', errorId]));
end

%--------------------------------------------------------------------------
function [lthresh, uthresh, center] = iGenerateExtraOutputs(headA)
% Thresholds and center are set to NaN/missing when the outlier locations
% are provided. They are always returned as a row/slice.

% Based on matlab.internal.math.rmMissingOutliers/applyFun.
sizeA = size(headA);
if istabular(headA)
    if sizeA(1) == 0
        % grow table so that defaultarrayLike returns NaN rather than empty
        % variables
        headA = matlab.internal.datatypes.lengthenVar(headA, 1);
    end
    lthresh = matlab.internal.datatypes.defaultarrayLike([1 sizeA(2)], "like", headA);
else
    lthresh = NaN([1 sizeA(2:end)], "like", headA);
end
uthresh = lthresh;
center = lthresh;
end

%--------------------------------------------------------------------------
function [lthresh, uthresh, center] = iSetExtraOutputAdaptors(A, lthresh, uthresh, center)
% Set the output adaptors for the extra outputs when 'OutlierLocations' is
% provided. They are guaranteed to be a row/slice of the same small sizes
% of A.

outAdaptor = resetTallSize(A.Adaptor);
outAdaptor = setTallSize(outAdaptor, 1);
lthresh.Adaptor = outAdaptor;
uthresh.Adaptor = outAdaptor;
center.Adaptor = outAdaptor;
end

%--------------------------------------------------------------------------
function tf = iValidateattributesPred(A,typesA,funName)
% Check the complexity of A with validateattributes and return true as the
% predicate if the validation doesn't error. A predicate is required by
% tall/lazyValidate.
validateattributes(A,typesA,{'real'},funName,'A',1);
tf = true;
end

%--------------------------------------------------------------------------
function tf = iValidateTabularVars(A, dataVars)
% Validate tabular variables and return true as the predicate if the
% validation doesn't error. A predicate is required by tall/lazyValidate.
for k = 1:numel(dataVars)
    vark = A{:, dataVars(k)};
    if ~isreal(vark) || ~isfloat(vark) || ~(isempty(vark) || iscolumn(vark))
        error(message('MATLAB:rmoutliers:TableVarInvalid'));
    end
end
tf = true;
end

%--------------------------------------------------------------------------
function tf = iMatchNameArg(arg, name, minlength)
% Performs case-insensitive partial matching of arg to name
tf = isNonTallScalarString(arg) && strlength(arg)>minlength && startsWith(name, arg, 'IgnoreCase', true);
end
