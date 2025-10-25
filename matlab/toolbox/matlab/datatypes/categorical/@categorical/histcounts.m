function [n,catnames] = histcounts(x, varargin)
%

%   Copyright 1984-2024 The MathWorks, Inc.

if ~iscategorical(x)
    error(message('MATLAB:categorical:histcounts:NonCategoricalX'));
end

persistent p;
if isempty(p)
    % Set the persistent var only when the inputParser is completely
    % initialized to avoid ctrl-C exposing incomplete persistents.
    parser = inputParser;
    addParameter(parser, 'Categories', NaN);
    addParameter(parser, 'Normalization', 'count', @validateNormalizationInput);
    p = parser;
end

catnames = NaN;
if nargin == 1
    % just get the default values
    p.parse();
elseif mod(nargin,2) == 1
    % if the number of arguments is odd, assume we're parsing all NV pairs
    p.parse(varargin{:});
elseif mod(nargin,2) == 0
    % If the number of arguments is even, assume the second is the optional
    % categories.
    catnames = varargin{1};
    if isa(catnames,"pattern")
        if ~isscalar(catnames)
            error(message('MATLAB:categorical:InvalidNamesOrPattern','CATEGORIES'));
        end
        catnames = x.categoryNames(matches(x.categoryNames,catnames));
    else
        catnames = validateCategories(x,catnames);
    end
    p.parse(varargin{2:end});
end

normalization = validateNormalization(p.Results.Normalization);  
if ~matches("Categories",p.UsingDefaults)
    catnames = validateCategories(x,p.Results.Categories);
end
    

% Figure out what categories to count
if isnumeric(catnames)  % Categories not specified, use categories in X
    catnames = x.categoryNames;
end

% Convert CATEGORIES' internal codes into contiguous bin numbers (we may be
% counting an out of order subset of x's categories). Make sure to
% ignore undefined elements in x, and elements of x from categories not
% specified in CATEGORIES -- set those bin numbers to NaN.
[~,ix] = ismember(x.categoryNames,catnames);
ix(ix == 0) = NaN;
ix = [NaN; ix(:)]; % prepend a NaN for zero codes (undefined elements)
xcodes = ix(x.codes+1);

if ~isempty(catnames)
    n = histcounts(xcodes,0.5:length(catnames)+0.5);
else
    n = zeros(1,0);
end
catnames = reshape(catnames, 1, []);

switch normalization
    % For normalization methods probability, pdf, percentage, and cdf, use the
    % total number of elements including non-finite values and values outside
    % the bins.
    case 'cumcount'
        n = cumsum(n);
    case {'probability','pdf'}
        n = n / numel(x);
    case 'percentage'
        n = (100 * n) / numel(x);
    case 'cdf'
        n = cumsum(n / numel(x));
end
    
end

function arg = validateNormalization(arg)
arg = validatestring(arg,...
        {'count','probability', 'percentage', 'countdensity', 'pdf', 'cumcount', 'cdf'});
end
function validateNormalizationInput(arg)
% return for scalar text, use the validation error from validateNormalize
% otherwise.
if ~matlab.internal.datatypes.isScalarText(arg)
    validateNormalization(arg);
end
end

function cats = validateCategories(x,cats)
% The categories must a vector or empty array of unique values.
if ~isvector(cats) && ~isempty(cats)
    error(message('MATLAB:categorical:InvalidNamesOrPattern','CATEGORIES'));
end

if numel(cats) ~= numel(unique(cats))
    error(message('MATLAB:categorical:histcounts:RepeatedCategories'));
end

if isstring(cats) || iscellstr(cats) 
    cats = cellstr(cats(:)); % a column
    % ordinal is stricter, cannot include categories not in the
    % categorical, and order of categories must be the same
    if x.isOrdinal
        if ~all(ismember(cats,x.categoryNames))
            error(message('MATLAB:categorical:histcounts:UnrecognizedCategories'));
        end
    end
elseif iscategorical(cats)
    if ~(x.isOrdinal == cats.isOrdinal)
        error(message('MATLAB:categorical:histcounts:OrdinalMismatch'));
    end
    % If CATEGORIES is categorical, its ordinalness has to match x, and if they are
    % ordinal, their categories have to match.
    if isordinal(x) && ~isequal(x.categoryNames,cats.categoryNames)
        error(message('MATLAB:categorical:histcounts:OrdinalCategoriesMismatch'));
    end
    % Use CATEGORIES' values, not its categories
    % Filter out undefined categories before extracting category names
    cats.codes(cats.codes==0) = []; % categorical.undefCode
    cats = cellstr(cats(:)); % a column
else
    error(message('MATLAB:categorical:InvalidNamesOrPattern','CATEGORIES'));
end
end




















