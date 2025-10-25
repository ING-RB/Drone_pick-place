function [str,rowsWithHorzSpan,colsWithVertSpan] = wordTable2str(tree, opts)
% This function is undocumented and will change in a future release.

%   Copyright 2021 The MathWorks, Inc.

    if nargin==1
        opts = matlab.io.internal.functions.ReadTable();
    end

    % TODO: Useful error messages

    assert(tree.Name == "tbl");
    rows = tree.children;
    rows = rows({rows.Name}=="tr");

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
            handleRow(str,covered,rows(k),k,opts);
        rowsWithSpan(localRowsWithSpan) = true;
        colsWithSpan(localColsWithSpan) = true;
    end
    str = strtrim(str);
    rowsWithHorzSpan = find(rowsWithSpan);
    colsWithVertSpan = find(colsWithSpan);
end

function [str,covered,rowWithSpan,colWithSpan] = handleRow(str,covered,row,k,opts)
rowWithSpan = false;
colWithSpan = false;
td = row.children;
td = td({td.Name}=="tc");
actualColumn = 1;

vertRule = opts.MergedCellRowRule;

for sourcecol=1:numel(td)
    if k <= size(covered,1)
        while actualColumn <= size(covered,2) && covered(k,actualColumn)
            actualColumn = actualColumn + 1;
        end
    end
    [colspan,spanFromAbove] = readSpanInfo(td(sourcecol));

    if colspan > 1
        rowWithSpan(k) = true;
    end
    if spanFromAbove
        if k > 1 && k-1 <= numel(rowWithSpan) && rowWithSpan(k-1)
            rowWithSpan(k) = true;
        end
        colWithSpan(actualColumn) = true;
    end

    covered(k,actualColumn:(actualColumn+colspan-1)) = true;
    str(k,actualColumn+colspan-1) = missing; % ensure str is large enough

    targetCol = analyzeColspan(colspan,sourcecol,k,opts) + actualColumn;

    if spanFromAbove && k > 1
        % spanFromAbove should imply k>1 anyway
        switch vertRule
        case "duplicate"
            str(k,targetCol) = str(k-1,targetCol);
        case "placebottom"
            str(k,targetCol) = str(k-1,targetCol);
            str(k-1,targetCol) = missing;
        case "error"
            error(message("MATLAB:io:word:readtable:MergedCellRowRuleError",sourcecol,k));
        otherwise % default, placetop, omitvar
            str(k,targetCol) = missing;
        end
    else
        str(k,targetCol) = td(sourcecol).HTMLtext;
    end
end
end


function [colspan,spanFromAbove] = readSpanInfo(tc)
    colspan = tc.xpath("./w:tcPr/w:gridSpan").get("val");
    if isempty(colspan) || string(colspan) == "1"
        colspan = 1;
    else
        colspan = str2double(string(colspan));
    end
    rowspan = tc.xpath("./w:tcPr/w:vMerge");
    spanFromAbove = ~isempty(rowspan) && ...
        (ismissing(rowspan.get("val")) || ...
            rowspan.get("val") == "continue");
end

function targetCol = analyzeColspan(colspan,sourcecol,k,opts)
    if colspan > 1
        horzRule = opts.MergedCellColumnRule;
    else
        horzRule = "placeleft";
    end

    switch horzRule
    case "error"
        error(message("MATLAB:io:word:readtable:MergedCellColumnRuleError",sourcecol,k));
    case "duplicate"
        targetCol = 0:(colspan-1);
    case "placeright"
        targetCol = colspan-1;
    otherwise % placeleft, default - also used for omitrow
        targetCol = 0;
    end
end



