function [str,rowsWithHorzSpan,colsWithVertSpan] = htmlTable2str(tree, opts_struct)
% This function is undocumented and will change in a future release.

%   Copyright 2021-2023 The MathWorks, Inc.

    if nargin==1
        opts_struct = struct();
    end

    % TODO: Useful error messages

    assert(tree.Name == "TABLE");
    children = tree.children;
    rows = children;
    if any({rows.Name}=="TBODY")
        body = rows({rows.Name}=="TBODY");
        rows = [body(1).children];
    end
    if any({children.Name}=="THEAD")
        head = children({children.Name}=="THEAD");
        rows = [head(1).children;rows];
    end
    if any({children.Name}=="TFOOT")
        foot = children({children.Name}=="TFOOT");
        rows = [rows;foot(1).children];
    end

    rows = rows({rows.Name}=="TR");
    if isempty(rows)
        str = strings(0,0);
        rowsWithHorzSpan = [];
        colsWithVertSpan = [];
        return
    end

    str = strings(0,0);
    covered = false(0,0); % track cells under spans
    rowsWithSpan = false(0,0);
    colsWithSpan = false(0,0);

    for k = 1:numel(rows)
        [str,covered,localRowsWithSpan,localColsWithSpan] = ...
            handleRow(str,covered,rows(k),k,opts_struct);
        rowsWithSpan(localRowsWithSpan) = true;
        colsWithSpan(localColsWithSpan) = true;
    end
    str = strtrim(str);

    % HTML sometimes has empty rows at the beginning, confusing the meta lines
    % detection. Skip those, unconditionally, before looking for meta lines.
    emptyRows = all(ismissing(str) | strlength(str) < 1, 2);
    firstNonEmpty = find(~emptyRows,1);
    str(1:(firstNonEmpty-1),:) = [];
    if size(rowsWithSpan,1) >= firstNonEmpty
        rowsWithSpan(1:(firstNonEmpty-1),:) = [];
    else
        rowsWithSpan = [];
    end

    rowsWithHorzSpan = find(rowsWithSpan);
    colsWithVertSpan = find(colsWithSpan);
end

function [str,covered,rowWithSpan,colWithSpan] = handleRow(str,covered,row,k,opts_struct)
rowWithSpan = false;
colWithSpan = false;
td = row.children;
td = td({td.Name}=="TD" | {td.Name}=="TH");
actualColumn = 1;
for sourcecol=1:numel(td)
    if k <= size(covered,1)
        while actualColumn <= size(covered,2) && covered(k,actualColumn)
            actualColumn = actualColumn + 1;
        end
    end
    [colspan,rowspan] = readSpanInfo(td(sourcecol));

    if colspan > 1
        rowWithSpan(k:(k+rowspan-1)) = true;
    end
    if rowspan > 1
        colWithSpan(actualColumn:(actualColumn+colspan-1)) = true;
    end

    covered(k:(k+rowspan-1),actualColumn:(actualColumn+colspan-1)) = true;
    str(k+rowspan-1,actualColumn+colspan-1) = missing; % ensure str is large enough

    sourceStr = td(sourcecol).HTMLtext;

    targetCol = analyzeColspan(colspan,sourcecol,k,opts_struct) + actualColumn;
    targetRow = analyzeRowspan(rowspan,sourcecol,k,opts_struct);

    str(targetRow,targetCol) = sourceStr;
end
end


function [colspan,rowspan] = readSpanInfo(td)
    colspan = td.get("colspan");
    % HTML says colspan must be NUMBER, but let's not rely on valid HTML
    colspan = extract(colspan,digitsPattern);
    if ~isscalar(colspan) || ismissing(colspan) || isempty(colspan) || colspan == "1"
        colspan = 1;
    else
        colspan = str2double(colspan);
    end
    rowspan = td.get("rowspan");
    rowspan = extract(rowspan,digitsPattern);
    if ~isscalar(rowspan) || ismissing(rowspan) || isempty(rowspan) || rowspan == "1"
        rowspan = 1;
    else
        rowspan = str2double(rowspan);
    end
end

function targetCol = analyzeColspan(colspan,sourcecol,k,opts_struct)
    if colspan > 1 && isfield(opts_struct,'MergedCellColumnRule')
        horzRule = opts_struct.MergedCellColumnRule;
    else
        horzRule = "placeleft";
    end

    switch horzRule
    case "error"
        error(message("MATLAB:io:html:readtable:MergedCellColumnRuleError",sourcecol,k));
    case "duplicate"
        targetCol = 0:(colspan-1);
    case "placeright"
        targetCol = colspan-1;
    otherwise % placeleft, default - also used for omitrow
        targetCol = 0;
    end
end

function targetRow = analyzeRowspan(rowspan,sourcecol,k,opts_struct)
    if rowspan > 1 && isfield(opts_struct,'MergedCellRowRule')
        vertRule = opts_struct.MergedCellRowRule;
    else
        vertRule = "placetop";
    end

    switch vertRule
    case "error"
        error(message("MATLAB:io:html:readtable:MergedCellRowRuleError",sourcecol,k));
    case "duplicate"
        targetRow = k:(k+rowspan-1);
    case "placebottom"
        targetRow = k+rowspan-1;
    otherwise % placetop, default - also used for omitcol
        targetRow = k;
    end
end
