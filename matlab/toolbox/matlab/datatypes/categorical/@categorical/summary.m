function s = summary(a,varargin)
%

%   Copyright 2006-2024 The MathWorks, Inc.

import matlab.internal.display.lineSpacingCharacter

isDimSet = false;
doCounts = true;

if nargin > 1
    dim = varargin{1};
    if ~matlab.internal.datatypes.isScalarText(dim)
        if ~matlab.internal.datatypes.isScalarInt(dim,1)
            error(message('MATLAB:getdimarg:dimensionMustBePositiveInteger'));
        end
        isDimSet = true;
    end
    indStart = 1 + isDimSet;
    istabularorlogical = false;
    [isStatisticsSet,specifiedStats,doCounts] = ...
        matlab.internal.math.parseSummaryNVArgs(varargin(indStart:end),istabularorlogical,istabularorlogical,a);
else
    isStatisticsSet = false;
    specifiedStats = {};
end

if ~isDimSet
    dim = matlab.internal.math.firstNonSingletonDim(a);
end

% Compute non-count statistics
[stats,statFields,isfcnhandles] = matlab.internal.math.createStatsList(a,dim,isStatisticsSet,specifiedStats);
tempS = matlab.internal.math.datasummary(a,stats,statFields,isfcnhandles,dim);
catnames = a.categoryNames;

% Compute counts
if doCounts
    c = countcats(a,dim);
    numUndefined = sum(isundefined(a),dim);
    if isfield(tempS,'NumMissing') && nargout ~= 1 && ~isempty(a)
        % For display output, include <undefined> counts in c with the
        % category counts
        c = cat(dim,c,numUndefined);
        catnames = [catnames;categorical.undefLabel];
    end
end

% Display or return output
if nargout < 1
    dataName = inputname(1);
    if matlab.internal.display.isDesktopInUse % the environment supports boldface
        varnameFmt = '<strong>%s</strong>';
    else
        % The display environment may not support boldface
        varnameFmt = '%s';
    end

    % Display size and type
    fprintf(lineSpacingCharacter);
    if ~isempty(dataName)
        fprintf([varnameFmt ': '],dataName);
    end
    sz = size(a);

    % matlab.internal.display.getDimensionSpecifier returns the small 'x'
    % character for size, e.g., 'mxn'
    szStr = [sprintf('%d',sz(1)) sprintf([matlab.internal.display.getDimensionSpecifier,'%d'],sz(2:end))];
    
    if isordinal(a)
        typeLabel = getString(message('MATLAB:summary:Ordinal',tempS.Type));
    else
        typeLabel = tempS.Type;
    end
    fprintf('%s %s\n',szStr,typeLabel);
    tempS = rmfield(tempS,{'Size';'Type'});

    % Print counts
    if doCounts && ~isempty(a)
        % When the number of categories is large, we may print the head and
        % tail of the count list, followed by a hyperlink to display all
        % categories.
        numCats = numel(catnames);
        numRowsInTruncation = determineTruncation(numCats,dim,ismatrix(a));
        if numRowsInTruncation && ~isempty(dataName)
            printTruncatedSummary(catnames,c,numRowsInTruncation);
            if isfield(tempS,'NumMissing')
                printHyperlink(dataName,numCats-1);
            else
                printHyperlink(dataName,numCats);
            end
        else
            fprintf(lineSpacingCharacter);
            printFullSummary(numCats,catnames,dim,c);
        end

        % No need to print NumMissing twice, so remove it from the struct
        if isfield(tempS,'NumMissing')
            tempS = rmfield(tempS,'NumMissing');
        end
    end
    
    % Print non-count stats
    labels = fieldnames(tempS);
    if ~isempty(labels)
        fprintf(lineSpacingCharacter);
        additionalStatsLabel = getString(message('MATLAB:summary:AdditionalStatistics'));
        fprintf('%s:\n',additionalStatsLabel);
        matlab.internal.math.displaySummaryStats(tempS,a,sz,labels,varnameFmt,dim);
    end
else
    s = struct;
    % Populate struct for output
    s.Size = size(a);
    s.Type = class(a);
    s.Categories = catnames;
    if doCounts
        s.Counts = c;
    end
    
    % Merge structs s and tempS. Maintain the field order of s, so that
    % Categories and Counts are before the rest of the stats.
    tempS = rmfield(tempS,{'Size','Type'});
    fdnames = fieldnames(tempS);
    for fd_i = 1:numel(fdnames)
        s.(fdnames{fd_i}) = tempS.(fdnames{fd_i});
    end
end
end

%--------------------------------------------------------------------------
function printFullSummary(numCats,catnames,dim,c)
% Blockwise process and output summary
blockSize = 200;

for jBegin = 1:blockSize:numCats
    % End of range for this block
    % -1 to avoid duplicating last/first category between blocks.
    jEnd = min(jBegin+blockSize-1, numCats);

    % Preserve quotes in category names by substituting with an obscure
    % character here. These quotes are recovered at the end after all
    % intermediate processing
    blockCatnames = strrep(catnames(jBegin:jEnd), '''', char(1));

    % Wrap bold-tags around each category name in the headings
    blockHeadings = permute(blockCatnames,circshift(1:max(dim,2),[0 dim-1]));
    if matlab.internal.display.isDesktopInUse % verify display supports HTML parsing
        blockHeadings = append('<strong>', blockHeadings, '</strong>');
    end

    % Get categorical counts subset along the user specified dimension
    block_c_index = repmat({':'}, 1, ndims(c));
    block_c_index{dim} = jBegin:jEnd;
    block_c = c(block_c_index{:});

    % Convert the counts to char and put them into a cell array for display.
    % Avoid num2cell() as cell display inserts unwanted '[]' around
    % numbers.
    block_c = reshape(cellstr(int2str(block_c(:))),size(block_c));
    if dim < 3
        % Add row headers for column summaries and column headers for row summaries.
        if ~ismatrix(block_c)
            tile = size(block_c); tile(1:2) = 1;
            blockHeadings = repmat(blockHeadings,tile);
        end
        block_c = cat(3-dim,blockHeadings,block_c);
    end

    % Leverage cell display output for proper alignment of mixed text
    % (category names) and numeric (category counts).
    summaryStr = char(matlab.display.internal.obsoleteCellDisp(block_c));

    % Do some regexp magic to put the category names into summaries along higher dims.
    if dim > 2
        for i = 1:length(blockHeadings)
            pattern = ['(\(\:\,\:' repmat('\,[0-9]',[1,dim-3]) '\,)' ...
                '(' num2str(i) ')' ...
                '(' repmat('\,[0-9]',[1,ndims(block_c)-dim]) '\) *= *\n)'];
            rep = ['$1' blockHeadings{i} '$3'];
            summaryStr = regexprep(summaryStr,pattern,rep);
        end
    end

    % Remove trailing newlines. Their location varies with format loose
    % vs format compact, so use regexp.
    summaryStr = regexprep(summaryStr, '\n*$', '');

    % Remove quotes that enclose each category name.
    summaryStr = strrep(summaryStr, '''', ' ');
    % Recover quotes originally embedded in category names.
    summaryStr = strrep(summaryStr, char(1), '''');

    % Display summary text for this block
    disp(summaryStr);
end
end

%--------------------------------------------------------------------------
function printTruncatedSummary(catnames,c,numRows) %#ok<INUSD>
% Assumes dim is 1 and c is a matrix

cattable = array2table(c,RowNames=catnames); %#ok<NASGU>
% defaults used in disp
bold = matlab.internal.display.isDesktopInUse; indent = 4; fullChar = false; nestedLevel = 0; %#ok<NASGU>
summaryStr = evalc('disp(cattable,bold,indent,fullChar,nestedLevel,numRows)');

% Remove quotes
summaryStr = strrep(summaryStr, '''', ' ');

% Remove the column header
lf = newline;
firstTwoLineFeeds = find(summaryStr==lf,2,'first');
summaryStr(1:firstTwoLineFeeds(end)) = [];

fprintf('%s',summaryStr);
end

%-----------------------------------------------------------------------
function numRows = determineTruncation(numCats,dim,AisMatrix)
% Adapted from tabular/display
% Returns the total number of rows (both the beginning and end of the
% summary to display combined) if the summary should be truncated to fit in
% the command window and 0 otherwise.

if dim ~= 1 || ~AisMatrix || ~matlab.internal.display.isHot
    numRows = 0;
    return
end

% the maximum distance users should have to scroll when their command
% window is about the same size as the summary height, i.e. number of
% categories
scrollDistance = 5;
numRows = getNumRowsInTruncatedTable(numCats);
withinScrollRange = numRows <= (numCats - scrollDistance);

% check to see if we're displaying somewhere where hyperlinks work,
% that the height is higher than the 20 row threshold, and that
% we're not truncating when the summary can almost fit in the command
% window. If all true, then truncate
truncationThreshold = 20; % need at least 20 rows in the summary to consider truncating it
truncate = numCats > truncationThreshold && withinScrollRange;
numRows = truncate * numRows;
end

%-----------------------------------------------------------------------
function numRows = getNumRowsInTruncatedTable(numCats)
% Adapted from tabular/display
import matlab.internal.display.formatSpacing;

isLoose = (formatSpacing == "loose");
cwHeight = getCommandWindowHeight();

% Subtract the number of non-data lines (the cmd that displayed the table, the header,
% ellipsis, link, the trailing command prompt, and blank lines) from the cmd window
% height.
numNonDataLines = 8 + isLoose*8;
dynamicNumRows = floor((cwHeight - numNonDataLines)/2); % floor ensures the cmd is fully visible

% then, choose either the default number of rows or the dynamic number
% if the command window is large enough to handle it
numRowsHalf = 5; % display at least 5 rows from the top and 5 rows from the bottom
numRowsHalf = max(numRowsHalf,dynamicNumRows);

% check to make sure that we're not printing more than half the table's
% worth of rows from the top/bottom of obj
if numRowsHalf >= numCats/2
    numRowsHalf = floor(numCats/2 - 1);
end
numRows = numRowsHalf * 2;
end

%-----------------------------------------------------------------------
function cwHeight = getCommandWindowHeight()
% Adapted from tabular/display
if isdeployed
    cwHeight = 25;
else
    cwHeight = builtin('_getcmdwinrows');
end
end

%-----------------------------------------------------------------------
function printHyperlink(catName,numCats)
% Adapted from tabular/display
import matlab.internal.display.lineSpacingCharacter;
% Construct the hyperlink. takes inputname here, as we have to grab
% the variable from the workspace (not the variable given to us)
msg = getString(message('MATLAB:summary:DisplayLinkMissingCategorical', catName));
% Before trying to display the whole summary, the link will verify a
% categorical with that name exists.
codeToExecute = "if exist('" + catName + "','var') && iscategorical(" + ...
    catName + "),displayWholeSummary(" + catName + "),else,fprintf('" + msg + "\n');end";
linkText = getString(message('MATLAB:summary:DisplayAllCategoriesLink', numCats));
fprintf("\t<a href=""matlab:%s"">%s</a>\n"+lineSpacingCharacter,codeToExecute,linkText);
end
