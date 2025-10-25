function [n, catnames] = histcountsCategorical(C, varargin)
%histcounstsCategorical - histcounts on tall categorical

% Copyright 2016-2023 The MathWorks, Inc.

try
    [catsToCount, normalization] = parseinputs(varargin{:});
catch e
    throwAsCaller(e);
end

% Work out how many categories we need to count (NaN for unknown).
if isempty(catsToCount)
    % Make sure we count all cats.
    catsToCount = categories(C);
    outputNumCols = NaN;
elseif isa(catsToCount, "pattern")
    % We don't know how many categories will match.
    outputNumCols = NaN;
else
    outputNumCols = length(catsToCount);
end

catsToCount = matlab.bigdata.internal.broadcast(catsToCount);
[n, catsToCount] = aggregatefun(@chunkCatCounter, @combineCatCounts, C, catsToCount);
[n, catnames] = clientfun(@postProcessCatCounts, n, catsToCount, normalization);

% Setup the output adaptors:
% * 1st output class is always double and 2nd is always cell
% * Size is always a row vector and # of columns should have been set for
%   cases when it is determinable from the input arguments.
import matlab.bigdata.internal.adaptors.getAdaptorForType

n.Adaptor = setKnownSize(getAdaptorForType('double'), [1 outputNumCols]);
catnames.Adaptor = setKnownSize(getAdaptorForType('cell'), [1 outputNumCols]);
end

% Input parsing copied from toolbox/matlab/datatypes/@categorical/histcounts.m
% Refactored as follows:
%  * Applied default values for categories = {} and Normalization = 'count'
%  * Removed redundant logic as a result of default values
function [requestedCats, normalization]= parseinputs(varargin)
persistent p;
if isempty(p)
    p = inputParser;
    addOptional(p, 'categories', {}, @isValidCategoryList )
    addParameter(p, 'Normalization', 'count', ...
        @(x) validateattributes(x,{'char'},{}));
end

parse(p,varargin{:})
requestedCats = p.Results.categories;
normalization = validatestring(p.Results.Normalization, {'count',...
    'probability', 'countdensity', 'pdf', 'cumcount', 'cdf'});
end

function tf = isValidCategoryList(cats)
if isa(cats,"pattern")
    tf = true;
else
    tf = (iscellstr(cats) || isstring(cats) || iscategorical(cats)) ...
        && (isvector(cats) || isempty(cats)) ...
        && length(cats)==length(unique(cats));
end
end

function [N, cats] = chunkCatCounter(C, cats)
[N, cats] = histcounts(C, cats);
end

function [N, cats] = combineCatCounts(N, cats)
N = sum(N, 1);
cats = cats(1,:);
end

function [N, cats] = postProcessCatCounts(N, countedCats, normalization)
% Always output cats as a row
cats = reshape(countedCats, 1, []);

if iscategorical(countedCats)
    cats = cellstr(countedCats);
end

switch normalization
    case 'cumcount'
        N = cumsum(N);
    case {'probability','pdf'}
        N = N / sum(N);
    case 'cdf'
        N = cumsum(N / sum(N));
end
end