function [ax,ycodes,ctrs,xnames] = categoricalHist(ax,y,x)
%CATEGORICALHIST  internal helper for HIST to chart a histogram bar plot.

%   Copyright 2009-2018 The MathWorks, Inc.

% Shift inputs if necessary.
if ishandle(ax) % hist(ax,y) or hist(ax,y,x)
    if nargin < 3
        x = [];
    end
elseif isa(ax,'categorical') % hist(y) or hist(y,x)
    narginchk(0,2);
    if nargin > 1
        x = y;
    else
        x = [];
    end
    y = ax;
    ax = [];
else
    error(message('MATLAB:hist:InvalidInput'));
end

% If N-D, force to a matrix to be consistent with hist function.
y = matlab.internal.datatypes.matricize(y);

% Figure out what categories to use for the bars.
useAllCategories = isempty(x);
if useAllCategories
    xnames = categories(y);
elseif ~isa(x,'categorical')
    if ~matlab.internal.datatypes.isText(x, true, false)
        error(message('MATLAB:hist:InvalidCategories'));
    end
    xnames = cellstr(x(:)); % a column
    if isordinal(y) && ~isempty(setdiff(xnames,y.categoryNames))
        error(message('MATLAB:hist:UnrecognizedCategories'));
    end
elseif x.isOrdinal == y.isOrdinal %% isa(x,'categorical')
    % If x is categorical, its ordinalness has to match y, and if they are
    % ordinal, their categories have to match.
    if isordinal(y) && ~isequal(y.categoryNames,x.categoryNames)
        error(message('MATLAB:categorical:OrdinalCategoriesMismatch'));
    end
    % The histogram bars will be based on x's values, not its categories
    xnames = cellstr(x(:)); % a column
else
    error(message('MATLAB:hist:OrdinalMismatch'));
end

ctrs = 1:length(xnames);

% Convert y's internal codes into contiguous bin numbers for hist (we may be
% plotting bars for an out of order subset of y's categories). Need to force
% hist to ignore undefined elements in y, and elements of y from categories not
% specified in x -- set those bin numbers to NaN.
[~,ix] = ismember(y.categoryNames,xnames);
ix(ix == 0) = NaN;
ix = [NaN; ix(:)]; % prepend a NaN for zero codes (undefined elements)
ycodes = ix(y.codes+1);