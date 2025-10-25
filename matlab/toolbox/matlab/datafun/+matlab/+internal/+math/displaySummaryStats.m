function displaySummaryStats(S,x,sz,labels,varnameFmt,dim,dimIsAll)
%displaySummaryStats Print the statistics table for summary and
%   categorical/summary.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2024 The MathWorks, Inc.

import matlab.internal.display.lineSpacingCharacter

if nargin < 7
    dimIsAll = false;
end
values = struct2cell(S);
% Orient the displayed statistics table
if isrow(x) || isequal(dim,1) || dimIsAll
    if isempty(x)
        vt = cell2table(values,RowNames=labels);
    else
        % values is an mx1 cell for m statistics. Each cell has n elements.
        % Convert this configuration to an 1xn cell. Each cell has m stats.
        n = numel(values{1});
        m = numel(values);
        out = cell(1,numel(values{1}));
        for ii = 1:n
            stats_ii = cell(m,1);
            for jj = 1:m
                stats_ii{jj} = values{jj}(ii);
            end
            out{ii} = stats_ii;
        end
        % Convert the 1xn cell to an mxn table. Each row is a statistic.
        varnames = matlab.internal.tabular.defaultVariableNames(1:n);
        vt = table.init(out,m,labels,n,varnames);
    end
    removeColumnHeaderNames = true;
    printInOneTable = dimIsAll || ismatrix(x);
    if ~printInOneTable
        fprintf(lineSpacingCharacter);
    end
elseif isequal(dim,2) && ~isempty(x)
    % Each column is a statistic
    fprintf(lineSpacingCharacter);
    values = values';
    vt = table(values{:},VariableNames=labels);
    removeColumnHeaderNames = false;
    printInOneTable = ismatrix(x);
else
    % Each statistic will have its own section, so we do not need a
    % statistics table
    printInOneTable = false;
    fprintf(lineSpacingCharacter);
end

% Print
if printInOneTable
    printPageSummary(vt,removeColumnHeaderNames);
else
    if isequal(dim,1) && ~isempty(x)
        % x is a multi-dimensional array
        pageWidth = sz(2);
        heading = ones(1,numel(sz));
        summaryLabel = getString(message('MATLAB:summary:Summary'));
        for ii = 1:pageWidth:width(vt)
            % Print heading text
            fprintf(['(:,:' sprintf(',%i',heading(3:end)) ') ' summaryLabel ':\n']);

            % Print stats (along 1st dim) for a page
            printPageSummary(vt(:,ii:(ii+pageWidth-1)),removeColumnHeaderNames);

            if ii + pageWidth < width(vt)
                heading = incrementHeading(heading,sz);
            end
        end
    elseif isequal(dim,2) && ~isempty(x)
        % x is a multi-dimensional array

        heading = ones(1,numel(sz));
        summaryLabel = getString(message('MATLAB:summary:Summary'));
        ii = 1;
        while ii <= prod(sz(3:end))
            % Print heading text
            if ii > 1
                heading = incrementHeading(heading,sz);
            end
            fprintf(['(:,:' sprintf(',%i',heading(3:end)) ') ' summaryLabel ':\n']);

            % Print stats (along 2nd dim) for a page
            fprintf(lineSpacingCharacter);
            currentDims = num2cell(heading(3:numel(sz)));
            vt_i = varfun(@(x) x(:,:,currentDims{:}), vt);
            vt_i.Properties.VariableNames = labels;
            printPageSummary(vt_i,removeColumnHeaderNames);
            ii = ii + 1;
        end
    else
        % For vecdim or dim >= 3, or empty input that doesn't display
        % nicely in a single table, each statistic has its own section
        for stat_i = 1:length(labels)
            fprintf([varnameFmt ':\n'],labels{stat_i});
            statValue = S.(labels{stat_i});
            if isempty(statValue)
                szV = size(statValue);
                szStr = [sprintf('%d',szV(1)) sprintf([matlab.internal.display.getDimensionSpecifier,'%d'],szV(2:end))];
                fprintf('\t%s %s\n',szStr,class(statValue));
                fprintf(lineSpacingCharacter);
            else
                disp(statValue);
            end
        end
    end
end
end
%--------------------------------------------------------------------------
function printPageSummary(vt,removeColumnHeaderNames) %#ok<INUSD>
% Call disp rather than display to skip the unnnecessary table heading
bold = matlab.internal.display.isDesktopInUse; %#ok<NASGU>
c = evalc('disp(vt,bold)');

% The labels, and perhaps some of the values, are text in a cellstr,
% they display with enclosing braces and quotes. Remove those.
c = strrep(c, '''', ' ');
c = strrep(c, '{', ' ');
c = strrep(c, '}', ' '); % might be spaces between the quote and the right brace

% Remove brackets
c = strrep(c, '[', ' ');
c = strrep(c, ']', ' ');

% Remove the column header
lf = newline;
firstTwoLineFeeds = find(c==lf,2,'first');
if removeColumnHeaderNames
    c(1:firstTwoLineFeeds(end)) = [];
else
    % Only remove horizontal lines
    c((firstTwoLineFeeds(1)+1):firstTwoLineFeeds(end)) = [];
end

fprintf(c);
end

%--------------------------------------------------------------------------
function H = incrementHeading(H,sz)
% Calculates the next heading to print for a multidimensional array
d = 3;
while d <= numel(sz)
    if H(d) + 1 > sz(d)
        H(d) = 1;
        d = d + 1;
    else
        H(d) = H(d) + 1;
        break;
    end
end
end