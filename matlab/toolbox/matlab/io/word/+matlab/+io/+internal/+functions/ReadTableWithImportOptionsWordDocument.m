classdef ReadTableWithImportOptionsWordDocument < matlab.io.internal.functions.ExecutableFunction &...
        matlab.io.internal.functions.AcceptsReadableFilename &...
        matlab.io.internal.functions.AcceptsImportOptions &...
        matlab.io.internal.functions.AcceptsDateLocale &...
        matlab.io.internal.shared.ReadTableInputs
    % This class is undocumented and will change in a future release.

    % Copyright 2021 The MathWorks, Inc.

    methods
        function [T, func] = executeImpl(func,supplied)
            checkWrongParamsWrongType(supplied)

            opts_struct = func.Options.getOptionsStruct();

            try
                WordDocument = func.WordDocument;
                assert(isa(WordDocument,' matlab.io.xmltree.internal.XMLTree'));
            catch
                WordDocument =  matlab.io.xmltree.internal.XMLTree.fromDOCX(func.Filename);
                WordDocument.registerNamespace("w","http://schemas.openxmlformats.org/wordprocessingml/2006/main");
            end

            selector = opts_struct.TableSelector;
            if ismissing(selector)
                selector = "descendant-or-self::w:tbl";
            end
            selectedTable = WordDocument.xpath(selector);

            if isempty(selectedTable)
                numSelectedVars = numel(func.Options.SelectedVariableNames);

                tableStringData = strings(0,numSelectedVars);
            else
                selectedTable = selectedTable(1);

                if selectedTable.Name ~= "tbl"
                   error(message('MATLAB:io:html:detection:TableSelectorInvalidSelection'));
                end

                [tableStringData,rowsWithHorzSpan,colsWithVertSpan] = ...
                    matlab.io.word.internal.wordTable2str(selectedTable, func.Options);
            end

            lastRow = size(tableStringData,1);
            dropRow = true(lastRow,1);
            rows = func.Options.DataRows;
            if isscalar(rows)
                rows = [rows, inf];
            end
            for k=1:size(rows,1)
                row = rows(k,:);
                if row(1) > lastRow
                    continue;
                end
                if row(2) > lastRow
                    row(2) = lastRow;
                end
                dropRow(row(1):row(2)) = false;
            end
            if func.Options.MergedCellColumnRule == "omitrow"
                dropRow(rowsWithHorzSpan) = true;
            end

            if opts_struct.EmptyRowRule == "skip"
                dropRow = dropRow | all(ismissing(tableStringData) | strlength(tableStringData) < 1, 2);
            elseif opts_struct.EmptyRowRule == "error"
                emptyRows = all(ismissing(tableStringData) | strlength(tableStringData) < 1, 2);
                if any(emptyRows)
                    error(message('MATLAB:textio:io:EmptyRowRuleError', find(emptyRows,1)));
                end
            end

            string_opts = matlab.io.TextVariableImportOptions("Type", "string");
            whitespace = sprintf(' \b\t\n\r');

            % process variable units
            if func.Options.VariableUnitsRow > 0
                [out.Units,~] = matlab.io.text.internal.convertFromText(...
                  string_opts,tableStringData(func.Options.VariableUnitsRow,:), whitespace);
            else
                out.Units = {};
            end

            % process variable descriptions
            if func.Options.VariableDescriptionsRow > 0
                [out.Descriptions,~] = matlab.io.text.internal.convertFromText(...
                  string_opts,tableStringData(func.Options.VariableDescriptionsRow,:), whitespace);
            else
                out.Descriptions = {};
            end

            varnames = func.Options.VariableNames;

            if func.ReadVariableNames ...
                && func.Options.namesAreGenerated() ...
                && func.Options.VariableNamesRow > 0 ...
                && func.Options.VariableNamesRow < size(tableStringData,1)
                % VariableNamesLine or VariableNamingRule
                % may have changed since detection
                varnames = tableStringData(func.Options.VariableNamesRow,:);
                varnames = matlab.io.internal.makeVariableNamesWithSpans(...
                    varnames,func.Options.PreserveVariableNames,func.Options.MergedCellColumnRule);
            end

            tableStringData(dropRow,:) = [];

            vopts = opts_struct.VariableOptions;

            missingRule = string(func.Options.MissingRule);
            errorRule = string(func.Options.ImportErrorRule);
            numSelectedVars = numel(func.Options.SelectedVariableNames);

            omitvars = ~ismember(func.Options.VariableNames,func.Options.SelectedVariableNames);
            omitrows = false(size(tableStringData, 1), 1);

            if func.Options.MergedCellRowRule == "omitvar"
                omitvars(colsWithVertSpan) = true;
            end

            out.Data = mat2cell(tableStringData,size(tableStringData,1),repelem(1,1,size(tableStringData,2)));
            for i = 1:numel(out.Data)
                if i <= numel(vopts)
                    vopt = vopts{i};
                elseif func.Options.ExtraColumnsRule == "addvars"
                    vopt = matlab.io.TextVariableImportOptions;
                else
                    omitvars(i) = true;
                    continue;
                end
                [out.Data{i}, col_info] = matlab.io.text.internal.convertFromText(vopt,out.Data{i}, whitespace);
                missingOrPlaceholders = col_info.Placeholders(:, 1);
                [omitrows, omitvars] = processRule(missingOrPlaceholders, missingRule,...
                    omitrows, omitvars, "MATLAB:io:word:readtable:MissingRuleError", i);
                [omitrows, omitvars] = processRule(col_info.Errors, errorRule,...
                    omitrows, omitvars, "MATLAB:io:word:readtable:ImportErrorRuleError", i);
            end

            % add names for any added variables
            if numel(varnames) < size(out.Data,2)
                enumerated = varnames(matches(varnames,"ExtraVar"+digitsPattern));
                numbers = str2double(extractAfter(enumerated,"ExtraVar"));
                nextNum = max([0,numbers]) + 1;
                varnames = [varnames, "ExtraVar" + (nextNum:nextNum+(size(out.Data,2)-numel(varnames)-1))];
            end

            % process row names
            rowNamesColumn = func.Options.RowNamesColumn;
            readRowNames = rowNamesColumn > 0;
            if readRowNames
                rowNames = tableStringData(:,rowNamesColumn);
                [rowNames, row_info] = matlab.io.text.internal.convertFromText(string_opts, rowNames, whitespace);
                missing_idx = row_info.Placeholders(:, 1) | row_info.Errors(:, 1);
                row_nums = find(missing_idx);
                rowNames(missing_idx) = compose("Row%d", row_nums);
                rowNames = matlab.lang.makeUniqueStrings(rowNames);
            else
                rowNames = {};
            end

            % remove any omitted variables
            if any(omitvars)
                varnames(omitvars) = [];
                out.Data(:, omitvars) = [];
                if ~isempty(out.Units), out.Units(omitvars) = []; end
                if ~isempty(out.Descriptions), out.Descriptions(omitvars) = []; end
            end

            % remove any omitted rows
            if any(omitrows)
                if ~isempty(rowNames)
                    rowNames(omitrows) = [];
                end
                for i = 1:numel(out.Data)
                   data = out.Data{i};
                   data = data(~omitrows, :);
                   if ~iscell(data)
                       data = {data};
                   end
                   out.Data(i) = data;
                end
            end

            %TODO: HANDLE dimension names
            dimNames = matlab.internal.tabular.private.metaDim().labels;
            readVarNames = false;

            T = matlab.io.internal.functions.ReadTable.buildTableFromData(out.Data,...
                varnames, rowNames, dimNames, readVarNames, readRowNames,...
                func.Options.PreserveVariableNames);

            T.Properties.VariableUnits = out.Units;
            T.Properties.VariableDescriptions = out.Descriptions;
        end

        function T = execute(func, supplied)
            T = func.executeImpl(supplied);
        end
    end
end

%%

function [omitrows, omitvars] = processRule(info, rule, omitrows, omitvars, errMessage, variableIndex)
    if rule == "error" && any(info, 'all')
        [rowIndex, ~] = find(info, 1);
        error(message(errMessage, variableIndex, rowIndex));
    elseif rule == "omitrow" && any(info, 'all')
        omitrows = omitrows | any(info, 2);
    elseif rule == "omitvar" && any(info, 'all')
        omitvars(variableIndex) = true;
    end
end

function checkWrongParamsWrongType(supplied)
persistent params
if isempty(params)
    getParams = @(me) string({me.PropertyList([me.PropertyList.Parameter]).Name});
    params = getParams(?matlab.io.internal.functions.ReadTableWithImportOptionsSpreadsheet);
    params = setdiff(params, [getParams(?matlab.io.internal.shared.ReadTableInputs), ...
                              getParams(?matlab.io.internal.functions.AcceptsReadableFilename)]);
    params = ["Encoding", params];
end
wrongparams = params;
if supplied.Options
    wrongparams = ["ReadVariableNames", "ReadRowNames", "DateLocale", wrongparams];
end
matlab.io.internal.utility.assertUnsupportedParamsForFileType(wrongparams,supplied,'word')
end

