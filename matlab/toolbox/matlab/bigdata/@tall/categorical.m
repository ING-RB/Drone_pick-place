function tc = categorical(tdata,varargin)
%CATEGORICAL Create a tall categorical array.
%   C = CATEGORICAL(DATA)
%   C = CATEGORICAL(DATA,VALUESET)
%   C = CATEGORICAL(DATA,VALUESET,CATEGORYNAMES)
%   C = CATEGORICAL(DATA, ..., 'Ordinal',ORD)
%   C = CATEGORICAL(DATA, ..., 'Protected',PROTECT)
%
%   See also CATEGORICAL.

%   Copyright 2016-2023 The MathWorks, Inc.

narginchk(1,7);

tall.checkIsTall(upper(mfilename), 1, tdata);

% If VALUESET was provided then the list of categories is the same
% everywhere. If not, we must assume we have to force it to be the same.
if nargin>1 && isValueSet(varargin{1})
    % All workers will automatically get the same categories
    tc = mycategorical(tdata, varargin{:});

elseif tall.getClass(tdata) == "categorical" && ~isempty(getCategories(tdata.Adaptor))
    categories = getCategories(tdata.Adaptor);
    tc = mycategorical(tdata, categories, varargin{:});

else
    % Ensure same categories.
    warning(message("MATLAB:bigdata:array:InefficientCategorical"));
    tvalueSet = reducefun(@determineValueSet, tdata);
    tc = elementfun(@buildCategorical, tdata, matlab.bigdata.internal.broadcast(tvalueSet));
    tc = setKnownType(tc, 'categorical');
    if nargin > 1
        tc = mycategorical(tc, varargin{:});
    end

end

% Work out the correct output adaptor. We need to build a categorical
% adaptor with protected and ordinal set correctly but with the size output
% by elementfun.
outAdaptor = iGetOutputAdaptor(tdata,varargin{:});
tc.Adaptor = outAdaptor.copySizeInformation(tc.Adaptor);

end

function tf = isParam(x)
% Does an argument match one of the PV pair parameters?
tf = isNonTallScalarString(x) && (strcmpi("Ordinal", x) || strcmpi("Protected", x));
end

function tf = isValueSet(x)
% We assume the input is a valueset unless it is a match for one of the
% param-value pairs 'Ordinal' or 'Protected'.
if istall(x)
    tf = true;
    return;
end
tf = ~isNonTallScalarString(x) || ~isParam(x);
end

function tc = mycategorical(tdata,varargin)
vars = cellfun(@matlab.bigdata.internal.broadcast, varargin, 'UniformOutput', false);
tc = elementfun(@categorical, tdata, vars{:});
end

function adap = iGetOutputAdaptor(varargin)
% Determine the correct output adaptor given the list arguments.

% Check if valueset and category names have been provided as in-memory
% arrays. If so, capture them to propagate them to the output adaptor.
nonTallValueSetProvided = nargin > 1 && (~istall(varargin{2}) && isValueSet(varargin{2}));
nonTallCategoryNamesProvided = nargin > 2 && (~istall(varargin{3}) && ~isParam(varargin{3}));
extraArgs = {};
% Use missing as the sample. If the category names have been provided as an
% in-memory array, use them as value set. If only valueset has been
% provided (no category names, either tall or in-memory),
% convert it to string to use a string-based valueset.
sample = missing;
isTallCategoryNames = numel(varargin) > 2 && istall(varargin{3});
if nonTallValueSetProvided
    valueSet = varargin{2};
    if nonTallCategoryNamesProvided
        extraArgs = [extraArgs, varargin(3)];
    elseif ~isTallCategoryNames
        extraArgs = [extraArgs, {string(valueSet)}];
    end
end

% If the data is already categorical, default to the same, otherwise
% default false. They can then be over-ridden by subsequent param-value
% pairs.
tdata = varargin{1};
if tall.getClass(tdata) == "categorical"
    % Now check whether we know the categories of the provided categorical.
    % If the user hasn't specified new categories, propagate the input
    % categories.
    if ~(nargin > 1 && isValueSet(varargin{2}))
        if ~isempty(getCategories(tdata.Adaptor))
            extraArgs = [extraArgs, {getCategories(tdata.Adaptor)}];
        end
    end
    % Only set if not default
    if isprotected(tdata)
        extraArgs = [extraArgs, 'Protected', true];
    end
    if isordinal(tdata)
        extraArgs = [extraArgs, 'Ordinal', true];
    end
end

% Build a local categorical array using flag arguments, valueset and
% category names if provided as in-memory arrays. Find the start of the
% param-value pairs.
idxFirstParam = find(cellfun(@isParam, varargin), 1, 'first');
if isempty(idxFirstParam)
    % No flags
    localData = categorical(sample, extraArgs{:});
else
    localData = categorical(sample, extraArgs{:}, varargin{idxFirstParam:end});
end

% Create the adaptor from the local data
adap = matlab.bigdata.internal.adaptors.CategoricalAdaptor(localData);

end

function cats = determineValueSet(x)
% Determine the complete value set to pass to categorical construction. We
% do this in terms of value set and not list of categories in order to
% ensure the final order is sorted by value type instead of by string
% representation.
cx = categorical(x);
[cvals, cidx] = unique(uint64(cx));
% We want to ignore missing values, which are represented by 0 inside
% categoricals.
if ~isempty(cvals) && cvals(1) == 0
    cidx(1) = [];
end
cats = x(cidx);
end

function c = buildCategorical(x, valueSet)
% Build a categorical, accounting for cases where we determine a value set
% for data types that does not support the value set syntax for
% categorical.
if iscalendarduration(valueSet)
    % CalendarDuration does not support relational operations due to
    % ambiguity of units (E.G. is 30 calendar days a calendar month? it
    % depends). So we must do this via setcats (which work based on string
    % equality).
    cats = categories(categorical(valueSet));
    c = setcats(categorical(x), cats);
else
    c = categorical(x, valueSet);
end
end
