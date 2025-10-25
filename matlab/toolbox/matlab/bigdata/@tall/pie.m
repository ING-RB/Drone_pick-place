function hh = pie(varargin)
%PIE    Pie chart for tall categorical data.
%   PIE(X)
%   PIE(X,EXPLODE)
%   PIE(X,EXPLODE,LABELS)
%   PIE(AX,...)
%   H = PIE(...)
%
%   Limitations:
%   X must be a tall categorical array.
%
%   Example
%      tx = tall(categorical({'cat';'dog';'cat';'cat';'dog';'fish'}));
%      pie(tx, 'fish')
%
%   See also CATEGORICAL/PIE.

%   Copyright 2016-2019 The MathWorks, Inc.

[cax,args] = axescheck(varargin{:});
x = args{1};

% We only support categorical inputs since these give a summary plot. other
% inputs must be in memory.
if ~isequal(tall.getClass(x), 'categorical')
    error(message('MATLAB:bigdata:array:CategoricalPie'));
end
tall.checkNotTall(upper(mfilename), 1, args{2:end});

% Process arguments (copied from categorical/pie)
categoryNames = categories(x);
switch numel(args)
    case 1
        explode = {};
        labels = {};
    case 2
        explode = args{2};
        labels = {};
    case 3
        explode = args{2};
        labels = args{3};
    otherwise
        error(message('MATLAB:narginchk:tooManyInputs'));
end

if isstring(labels) || ischar(labels)
    labels = cellstr(labels);
elseif ~iscellstr(labels)
    error(message('MATLAB:pie:InvalidLabel'));
end

% Input is treated as a vector no matter its dimensionality. HISTCOUNTS
% will do that for us.
counts = histcounts(x);

% gather all data
[counts, categoryNames] = gather(counts, categoryNames);

% Convert 'explode' from names to logicals. Note that when expressed as
% strings the explode entries must match the category names, not the
% display names.
if iscellstr(explode) || isstring(explode) || ischar(explode)
    if any(~ismember(explode, categoryNames))
        error(message('MATLAB:pie:InvalidExplodeName'));
    end
    
    explode = ismember(categoryNames, explode);
end

% Now just call standard PIE
if isempty(cax)
    h = pie(counts, explode);
else
    h = pie(cax, counts, explode);
end

% Make sure the labels are correct
if isempty(cax)
    legend(categoryNames); legend('off');
else
    legend(cax, categoryNames); legend(cax, 'off');
end
pieInsertLabels(h, labels, categoryNames, counts);

% Only assign output if requested
if nargout
    hh = h;
end

end % pie


%%%%%%%%%%%%%%%%%%%%%%%%% HELPER PIEINSERTLABELS %%%%%%%%%%%%%%%%%%%%%%%%%%
function labels = pieInsertLabels(h, labels, catNames, catCounts)
if isempty(labels)    
    percentageStrings = compose('(%.0f%%)',100*catCounts(:)./sum(catCounts));
    labels = strcat(catNames, {' '}, percentageStrings);
elseif isscalar(labels)
    try %#ok<TRYNC>
        % hgcastvalue to confirm that this is a valid formatting operator
        hgcastvalue('matlab.graphics.datatype.PrintfFormat',labels{1});
        percentageStrings = compose(labels{1},100*catCounts(:)./sum(catCounts));
        labels = strcat(catNames, {' '}, percentageStrings);
    end
end

% Set labels to categories and corresponding percentages
hText = findobj(h,'Type','text');
labels = reshape(labels, size(hText));
set(hText,{'String'},labels);
end
