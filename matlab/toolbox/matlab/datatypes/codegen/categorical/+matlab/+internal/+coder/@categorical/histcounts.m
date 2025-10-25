function [n,catnames] = histcounts(x, varargin) %#codegen
%HISTCOUNTS  Histogram bin counts of a categorical array.

%   Copyright 2020 The MathWorks, Inc.

coder.internal.assert(iscategorical(x),'MATLAB:categorical:histcounts:NonCategoricalX');

catnames = x.categoryNames; % If categories not specified, use categories in X for counting
if nargin == 1
    % just get the default values
    [parsedNormalization,categories,usingDefaultCategories] = parse();
elseif mod(nargin,2) == 1
    % if the number of arguments is odd, assume we're parsing all NV pairs
    [parsedNormalization,categories,usingDefaultCategories] = parse(varargin{:});
elseif mod(nargin,2) == 0
    % If the number of arguments is even, assume the second is the optional
    % categories.
    catnames = validateCategories(x,varargin{1});
    [parsedNormalization,categories,usingDefaultCategories] = parse(varargin{2:end});
end

normalization = validateNormalization(parsedNormalization);
if ~usingDefaultCategories
    catnames = validateCategories(x,categories);
end


% Convert CATEGORIES' internal codes into contiguous bin numbers (we may be
% counting an out of order subset of x's categories). Make sure to
% ignore undefined elements in x, and elements of x from categories not
% specified in CATEGORIES -- set those bin numbers to NaN.
[~,ix] = matlab.internal.coder.datatypes.cellstr_ismember(x.categoryNames,catnames);
ix(ix == 0) = NaN;
ix = [NaN; ix(:)]; % prepend a NaN for zero codes (undefined elements)
xcodes = ix(reshape(x.codes,[],1)+1);

if ~isempty(catnames)
    n = histcounts(xcodes,0.5:length(catnames)+0.5);
else
    n = zeros(1,0);
end
catnames = reshape(catnames, 1, []);

switch normalization
    case 'cumcount'
        n = cumsum(n);
    case {'probability','pdf'}
        n = n / numel(x);
    case 'cdf'
        n = cumsum(n / numel(x));
end

end

function arg = validateNormalization(arg)
arg = validatestring(arg,...
        {'count','probability', 'countdensity', 'pdf', 'cumcount', 'cdf'},'histcounts');
end
function validateNormalizationInput(arg)
% return for scalar text, use the validation error from validateNormalize
% otherwise.
if ~matlab.internal.coder.datatypes.isScalarText(arg)
    validateNormalization(arg);
end
end

function outCats = validateCategories(x,inCats)
% The categories must be a vector or empty array of unique values.
coder.internal.assert(isstring(inCats) || iscellstr(inCats) || iscategorical(inCats),'MATLAB:InputParser:ArgumentFailedValidation','categories','@(c) isstring(c) || iscategorical(c) || iscellstr(c)');
coder.internal.assert(isvector(inCats) || isempty(inCats),'MATLAB:InputParser:ArgumentFailedValidation','categories','isvector(c) || isempty(c)');

if iscategorical(inCats)
    coder.internal.assert(numel(inCats) == numel(unique(reshape(inCats,[],1))),'MATLAB:categorical:histcounts:RepeatedCategories');
    coder.internal.assert(x.isOrdinal == inCats.isOrdinal,'MATLAB:categorical:histcounts:OrdinalMismatch');
    % If CATEGORIES is categorical, its ordinalness has to match x, and if they are
    % ordinal, their categories have to match.
    coder.internal.errorIf(isordinal(x) && ~isequal(x.categoryNames,inCats.categoryNames),'MATLAB:categorical:histcounts:OrdinalCategoriesMismatch');
    % Use CATEGORIES' values, not its categories
    % Filter out undefined categories before extracting category names
    definedCategories = inCats(inCats.codes~=0); % categorical.undefCode
    outCats = reshape(cellstr(definedCategories),[],1); % a column
else % isstring(inCats) || iscellstr(inCats)
    if isstring(inCats)
        coder.internal.assert(numel(inCats)==1,'Coder:common:TypeSpecMCOSArrayNotSupported','string');
        outCats = reshape(cellstr(inCats),[],1); % a column
        % ordinal is stricter, cannot include categories not in the
        % categorical, and order of categories must be the same
        coder.internal.errorIf(x.isOrdinal && ~all(matlab.internal.coder.datatypes.cellstr_ismember(outCats,x.categoryNames),'all'),'MATLAB:categorical:histcounts:UnrecognizedCategories');
    else % iscellstr(inCats)
        inCatsTmp = inCats;
        if coder.internal.isConst(size(inCats)) 
            coder.varsize('inCatsTmp',[1 length(inCats)],[0 0]);
        end
        coder.internal.assert(numel(inCats) == numel(matlab.internal.coder.datatypes.cellstr_unique(inCatsTmp)),'MATLAB:categorical:histcounts:RepeatedCategories');
        outCats = reshape(inCats,[],1); % a column
        % ordinal is stricter, cannot include categories not in the
        % categorical, and order of categories must be the same
        coder.internal.errorIf(x.isOrdinal && ~all(matlab.internal.coder.datatypes.cellstr_ismember(outCats,x.categoryNames),'all'),'MATLAB:categorical:histcounts:UnrecognizedCategories');
    end
end
end

function [normalization, categories, usingDefaultCategories] = parse(varargin)
    coder.inline('always');

    pnames = {'Categories','Normalization'};
    poptions = struct( ...
        'CaseSensitivity',false, ...
        'PartialMatching','unique', ...
        'StructExpand',false);
    
    argIndices = coder.internal.parseParameterInputs(pnames,poptions,varargin{:});
    if argIndices.Categories
        categories = varargin{argIndices.Categories};
        usingDefaultCategories = false;
    else
        categories = NaN;
        usingDefaultCategories = true;
    end
    if argIndices.Normalization
        normalization = varargin{argIndices.Normalization};
        validateNormalizationInput(normalization);
    else
        normalization = 'count';
    end
end
