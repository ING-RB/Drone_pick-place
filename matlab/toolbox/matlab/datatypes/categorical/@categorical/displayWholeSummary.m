function displayWholeSummary(a,dim)
% Internal helper for displaying an entire summary of categorical counts.
% This function is for internal use only and will change in a future
% release. Do not use this function.

%   Copyright 2006-2024 The MathWorks, Inc.

if nargin==1
    % Not the first non-singleton, but this helper assumes dim is 1.
    dim = 1;
end
c = countcats(a,dim);
catnames = a.categoryNames;
nundefs = sum(isundefined(a),dim);
c = cat(dim,c,nundefs);
if nargout ~= 1
    catnames = [catnames;categorical.undefLabel];
end

% Blockwise process and output summary
blockSize = 200;
numCats = length(catnames);

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