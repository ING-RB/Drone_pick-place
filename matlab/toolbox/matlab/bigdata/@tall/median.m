function out = median(tX,varargin)
%MEDIAN Median value.
%   M = MEDIAN(A)
%   M = MEDIAN(A,DIM)
%   M = MEDIAN(...,NANFLAG)
%
%   Limitations:
%   1) Computations of median along the first dimension
%      is only supported for column vector A.
%   2) Tall table and timetable inputs are not supported.
%   3) The 'Weights' name-value argument is not supported.
%
%   See also MEDIAN

%   Copyright 2016-2023 The MathWorks, Inc.

tall.checkNotTall(upper(mfilename), 1, varargin{:});
tall.checkIsTall(upper(mfilename), 1, tX);

% Explicit error for disabled tabular maths
if istabular(tX)
    error(message("MATLAB:bigdata:array:TabularMathUnsupported", upper(mfilename)))
end

tX = tall.validateType(tX, mfilename, ...
    {'numeric', 'logical', 'duration', 'datetime','categorical'}, 1);
adaptor = tX.Adaptor;
[dim, nanFlag] = iParseParameters(adaptor, varargin{:});

% Check if it's a simple slice-wise call
if ~isReducingTallDimension(dim)
    medianFunctionHandle = @(x) median(x, varargin{:});
    out = slicefun(medianFunctionHandle, tX);
    out.Adaptor = tX.Adaptor;
    out.Adaptor = computeReducedSize(out.Adaptor, tX.Adaptor, dim, false);
    return;
end

% If we get here, we need to reduce the tall dimension. tall/SORT only
% supports column vectors, so MEDIAN has the same limitation.
tX = tall.validateColumn(tX, 'MATLAB:bigdata:array:MedianMustBeColumn');

if any(strcmp(nanFlag,'omitnan'))
    tX = filterslices(~ismissing(tX),tX);
end

classIn = adaptor.Class;
switch classIn
    case 'categorical'
        half = length(tX)/2;
        medianXtmp = iMiddleCategorical(tX, half);
        medianX = clientfun(@iCategoricalMean, medianXtmp);
        % TODO(g1548470): Condition and else branch to be removed when tall/histcounts will be
        % extended for datetime objects (meanwhile we just sort everything)
    case {'datetime','duration'}
        half = length(tX)/2;
        tX = sort(tX,1);
        % form a vector of 1:size(tX,1)
        absoluteIndices = tall(matlab.bigdata.internal.lazyeval.getAbsoluteSliceIndices(hGetValueImpl(tX)));
        medianXtmp = filterslices(absoluteIndices == floor(half+1) | ...
            absoluteIndices == round(half), tX);
        medianX = clientfun(@mean, medianXtmp, 1, 'native');
    otherwise
        medianXtmp = percentileDataBin(tX, 50);
        medianX = clientfun(@iLogicalNumericMean, medianXtmp{1}, 1, 'native');
end

medianX.Adaptor = matlab.bigdata.internal.adaptors.getAdaptorForType(classIn);
% Return missing if there is any
out = ternaryfun(any(ismissing(tX)), head(filterslices(ismissing(tX),tX),1), medianX);
out.Adaptor = tX.Adaptor;
out.Adaptor = computeReducedSize(out.Adaptor, tX.Adaptor, dim, false);
end

function [dim, nanFlag] = iParseParameters(adaptor, varargin)
% Check that the input parameters are valid and supported
try
    % Weights are not supported for tall.
    if ~isempty(find(cellfun(@(x) matlab.internal.math.checkInputName(x,'Weights'), varargin), 1))
        error(message('MATLAB:bigdata:array:WeightsUnsupported'));
    end

    if strcmp(adaptor.Class,'datetime')
        median(datetime, varargin{:});
    elseif strcmp(adaptor.Class,'categorical')
        % Parse categoricals separately as well because they also accept
        % 'includeundefined'/'omitundefined' as valid NaN flags.
        median(categorical(1, 'Ordinal', true), varargin{:});
    else
        median(1, varargin{:});
    end
    [args, trailingArgs] = splitArgsAndFlags(varargin{:});
    
    % If no dimension specified, try to deduce it (will be empty if we can't).
    if numel(args) == 0
        dim = matlab.bigdata.internal.util.deduceReductionDimension(adaptor);
    else
        dim = args{1};
        % DIM is allowed to be a column or row vector. We want a row vector.
        if iscolumn(dim)
            dim = dim';
        end
    end
    
    if isempty(dim)
        error(message('MATLAB:bigdata:array:MedianDimRequired'));
    end

    nanFlagCell = adaptor.interpretReductionFlags(upper(mfilename), trailingArgs);
    assert(~isempty(nanFlagCell)); % We need the nan flag at the client to switch implementations.
    nanFlag = nanFlagCell{1};
catch err
    throwAsCaller(err);
end
end

function medianXtmp = iMiddleCategorical(tX, half)
% Compute middle elements for categorical array
n = countcats(tX,1); % countcats instead as this gives me the same
n = cumsum(n,1);
cats = categories(tX);
valueset = tall(matlab.bigdata.internal.lazyeval.getAbsoluteSliceIndices(hGetValueImpl(cats)));
cat1 = nnz(n < round(half)) + 1;                   % lower middle category index
cat1 = categorical(cat1, valueset, cats, 'Ordinal', true); % lower middle category
cat2 = nnz(n < floor(half+1)) + 1;                 % upper middle category index
cat2 = categorical(cat2, valueset, cats, 'Ordinal', true); % upper middle category
% Until tall/vertcat is not in place we just use clientfun
medianXtmp = clientfun(@vertcat, cat1, cat2);
medianXtmp.Adaptor = tX.Adaptor;
end

function yCategoricalMean = iCategoricalMean(xCategorical)
% Compute the "mean" of two-elements categorical
if isempty(xCategorical) || isempty(categories(xCategorical)) || any(ismissing(xCategorical))
    % TODO(g1548484) use cast like
    xCategorical(1) = missing;
    yCategoricalMean = xCategorical(1);
else
    midCategoryIndx = round(mean(double(xCategorical)));
    cats = categories(xCategorical);
    yCategoricalMean = categorical(midCategoryIndx, 1:numel(cats), cats, 'Ordinal', true);
end
end

function yLogicalNumericMean = iLogicalNumericMean(x, varargin)
% Compute the mean of numeric and logical inputs keeping the input
% datatype. Even if we use the 'native' flag, core MATLAB returns double
% for mean() with logical inputs. Cast back to logical if needed.
yLogicalNumericMean = mean(x, varargin{:});
if islogical(x)
    yLogicalNumericMean = logical(yLogicalNumericMean);
end
end
