function results = detect(tree,options,supplied)
% This function is undocumented and will change in a future release.

%   Copyright 2021-2024 The MathWorks, Inc.
    results = struct(...
        "VariableNamesRow",0,...
        "NumVariables",0,...
        "TableSelector", options.TableSelector);
    results.VariableNames = {};
    results.SelectedVariables = false(1,0);
    results.Type = {};

    selector = options.TableSelector;
    if ismissing(selector)
        selector = "descendant-or-self::w:tbl";
        results.TableSelector = selector;
    end
    selectedTable = tree.xpath(selector);

    if isempty(selectedTable)
        if ~supplied.TableSelector
            allTables = tree.xpath("descendant-or-self::w:tbl");
            if isempty(allTables)
                error(message('MATLAB:io:word:detection:NoTablesFound'));
            end
            if isfield(supplied,'TableIndex') && supplied.TableIndex
                error(message('MATLAB:io:word:detection:TableIndexOutOfRange',...
                    numel(allTables)));
            end
        end
        error(message('MATLAB:io:word:detection:TableSelectorInvalidSelection'));
    end

    selectedTable = selectedTable(1);
    if selectedTable.Name ~= "tbl"
        error(message('MATLAB:io:word:detection:TableSelectorInvalidSelection'));
    end
    tableStringData = matlab.io.word.internal.wordTable2str(selectedTable, options);

    if isempty(tableStringData)
        return
    end

    detectOpts.ThousandsSeparator = options.ThousandsSeparator;
    detectOpts.DecimalSeparator = options.DecimalSeparator;
    detectOpts.ExponentCharacter = options.ExponentCharacter;
    detectOpts.DateLocale = options.DateLocale;
    detectOpts.TrimNonnumeric = options.TrimNonNumeric;

    typeIDs = matlab.io.text.internal.detectDatatypeFromString(...
        tableStringData, detectOpts);

    tdto.EmptyColumnType = options.EmptyColumnType;
    tdto.DetectVariableNames =  ~supplied.ReadVariableNames;
    tdto.ReadVariableNames = options.ReadVariableNames;
    tdto.MetaRows = 0;
    tdto.DetectMetaRows = options.DetectMetaLines;

    detectResults = matlab.io.internal.detectTypes(typeIDs,tdto);

    % default text type is string; DetectImportOptions massages to char as needed
    detectResults.Types = string(detectResults.Types);
    detectResults.Types(detectResults.Types == "char") = "string";

    meta = options.setMetaLocations(supplied, detectResults.MetaRows);

    for f = fieldnames(detectResults).'
        results.(f{1}) = detectResults.(f{1});
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
    % Empty rows are detected as meta.
    % If the user asks for empty rows, we still want them read at the
    % beginning of data.
    if options.EmptyRowRule=="read"
        while metaRows > 0 && all(typeIDs(metaRows,:)==5)
            metaRows = metaRows - 1;
        end
    end

    if ~supplied.DataRows
        results.DataRows = [metaRows + 1, Inf];
    end

    variableNamesRow = results.VariableNamesRow;

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
