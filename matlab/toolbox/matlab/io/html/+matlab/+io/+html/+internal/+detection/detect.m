function results = detect(tree,options,supplied)
% This function is undocumented and will change in a future release.

%   Copyright 2021-2024 The MathWorks, Inc.
    results = struct(...
        "VariableNamesRow",0,...
        "NumVariables",0,...
        "TableSelector", options.TableSelector);
    results.VariableNames = {};
    results.SelectedVariables = false(1,0);
    results.Types = {};

    selector = options.TableSelector;
    if ismissing(selector)
        selector = "descendant-or-self::TABLE";
        results.TableSelector = selector;
    end
    selectedTable = tree.xpath(selector);

    if isempty(selectedTable)
        if ~supplied.TableSelector
            allTables = tree.xpath("descendant-or-self::TABLE");
            if isempty(allTables)
                error(message('MATLAB:io:html:detection:NoTablesFound'));
            end
            if isfield(supplied,'TableIndex') && supplied.TableIndex
                error(message('MATLAB:io:html:detection:TableIndexOutOfRange',...
                    numel(allTables)));
            end
        end
        error(message('MATLAB:io:html:detection:TableSelectorInvalidSelection'));
    end

    selectedTable = selectedTable(1);
    if selectedTable.Name ~= "TABLE"
        error(message('MATLAB:io:html:detection:TableSelectorInvalidSelection'));
    end

    tableStringData = matlab.io.html.internal.htmlTable2str(selectedTable, options);

    detectOpts.ThousandsSeparator = options.ThousandsSeparator;
    detectOpts.DecimalSeparator = options.DecimalSeparator;
    detectOpts.ExponentCharacter = options.ExponentCharacter;
    detectOpts.TrimNonnumeric = options.TrimNonNumeric;
    detectOpts.DateLocale = options.DateLocale;

    typeIDs = matlab.io.text.internal.detectDatatypeFromString(...
        tableStringData, detectOpts);
    typeIDs = reshape(typeIDs,size(tableStringData)); % for empty

    tdto.EmptyColumnType = options.EmptyColumnType;
    tdto.DetectVariableNames =  ~supplied.ReadVariableNames;
    tdto.ReadVariableNames = options.ReadVariableNames;
    tdto.MetaRows = 0;
    tdto.DetectMetaRows = options.DetectMetaLines;

    detectResults = matlab.io.internal.detectTypes(typeIDs,tdto);
    % Empty rows are detected as meta.
    % If the user asks for empty rows, we still want them read at the
    % beginning of data.
    if options.EmptyRowRule=="read"
        while detectResults.MetaRows > 1 && ...
            all(typeIDs(detectResults.MetaRows,:)==5)
            detectResults.MetaRows = detectResults.MetaRows - 1;
        end
    end
    meta = options.setMetaLocations(supplied, detectResults.MetaRows);

    % default text type is string; DetectImportOptions massages to char as needed
    detectResults.Types = string(detectResults.Types);
    detectResults.Types(detectResults.Types == "char") = "string";

    for f = fieldnames(detectResults).'
        results.(f{1}) = detectResults.(f{1});
        if isfield(supplied,f{1}) && supplied.(f{1})
            results.(f{1}) = options.(f{1});
        end
    end
    for f = fieldnames(meta).'
        results.(f{1}) = meta.(f{1});
        if isfield(supplied,f{1}) && supplied.(f{1})
            results.(f{1}) = options.(f{1});
        end
    end

    metaRows = detectResults.MetaRows;
    if ~options.DetectMetaLines
        metaRows = 0;
    end

    if ~supplied.DataRows
        results.DataRows = [metaRows + 1, Inf];
    end

    % reading HTML, we should take a starting row with <th>
    % as variable names, even if the data types do not suggest them.
    variableNamesRow = results.VariableNamesRow;
    if variableNamesRow == 0 && ~supplied.VariableNamesRow && tdto.DetectMetaRows
        headerRow = selectedTable.xpath("TR[normalize-space(.) != ''][1]");
        if ~isempty(headerRow) && ~isempty(headerRow.xpath("TH"))
            variableNamesRow = numel(headerRow.xpath("preceding-sibling::TR"))+1;
        end
    end

    if variableNamesRow == 0 || variableNamesRow > size(tableStringData,1) ...
        || ~options.ReadVariableNames
        nVars = size(tableStringData,2);
        names = strings(1,nVars);
    else
        names = tableStringData(variableNamesRow,:);
    end

    [names,wasEmptyName] = matlab.io.internal.makeVariableNamesWithSpans(...
        names,options.PreserveVariableNames,options.MergedCellColumnRule);

    results.VariableNames = names;
    variableHasData = any(strlength(tableStringData) > 0,1);
    results.SelectedVariables = ~wasEmptyName | variableHasData;
    if options.EmptyColumnRule == "read"
        results.SelectedVariables = true(size(names));
    end
    results.VariableNamesRow = variableNamesRow;
end

function str = header2str(node)
    str = node.HTMLtext;
    n = get(node,'colspan');
    if ~ismissing(n) && ~isempty(n)
        n = str2double(n);
        if n > 1
            str = [str, repelem(string(missing),1,n-1)];
        end
    end
end
