classdef ReadCellSpreadsheet < matlab.io.internal.functions.ExecutableFunction ...
        & matlab.io.internal.functions.AcceptsReadableFilename ...
        & matlab.io.internal.functions.AcceptsImportOptions ...
        & matlab.io.internal.shared.ReadTableInputs ...
        & matlab.io.internal.functions.AcceptsSheetNameOrNumber ...
        & matlab.io.internal.functions.AcceptsUseExcel ...
        & matlab.io.internal.functions.AcceptsDatetimeTextType
    %
    
    % Copyright 2018-2024 The MathWorks, Inc.

    methods
        function func = ReadCellSpreadsheet()
            func.Options = spreadsheetImportOptions();
        end
    end
    
    methods (Access = protected)
        function [rhs,obj] = setSheet(obj,rhs)
            if ~isa(obj.Options,'matlab.io.spreadsheet.SpreadsheetImportOptions')
                error(message('MATLAB:textio:detectImportOptions:ParamWrongFileType','Sheet','text'))
            end
            obj.Options.Sheet = rhs;
        end
    end
    methods
        function C = execute(func,supplied)
            persistent zeroEpochDatetime;
            checkWrongParamsWrongType(supplied);
            try
                sheet = func.WorkSheet.SheetObj;
                assert(~isempty(sheet));
            catch
                [S, func] = executeImplCatch(func);
                sheet = S.Sheet;
            end

            try
                UseExcel = func.WorkSheet.IsComObject;
            catch
                UseExcel = func.UseExcel;
            end
            
            if supplied.TextType
                func.Options = setvartype(func.Options, func.TextType);
            end

            % Get the data ranges matrix.
            dataRanges = computeDataRanges(func, sheet, UseExcel);
            numRanges = size(dataRanges, 1);
            if numRanges == 0 
                if func.Options.AddedExtraVar
                    C = cell.empty(0, 0);
                    return;
                end
                numSelectedVars = numel(func.Options.SelectedVariableNames);
                C = cell.empty(0, numSelectedVars);
                return;
            end

            % Get the matrix of typeIDs that corresponds 
            % to the DataRanges matrix.
            if isfield(supplied, "Options")
                mergedCellColumnRule = func.Options.MergedCellColumnRule;
                mergedCellRowRule = func.Options.MergedCellRowRule;
            elseif isfield(supplied, "MergedCellColumnRule")
                mergedCellColumnRule = func.MergedCellColumnRule;
                mergedCellRowRule = func.MergedCellRowRule;
            else
                mergedCellColumnRule = 'placeleft';
                mergedCellRowRule = 'placetop';
            end

            [typeIDs, numRows, numHeaderLines] = getTypeIDs(func, sheet, ...
                dataRanges, mergedCellColumnRule, mergedCellRowRule);

            [~,selectedVarIDs] = ismember(func.Options.SelectedVariableNames',func.Options.VariableNames);

            if numel(selectedVarIDs) == 0
                C = cell.empty(0, 0);
                return;
            end
            typeIDs = typeIDs(:, selectedVarIDs);
            [indices, typeStruct] = getTypesStructs(typeIDs, sheet);                

            rowIntervals = reshape(dataRanges(:, [1 3])', 1, []);              
            locationStruct.RowIntervals = rowIntervals;
            locationStruct.ColumnIndices = selectedVarIDs' + dataRanges(1, 2) - 1;

            % Read Excel Dates as doubles instead of as SerialDatenums if
            % DatetimeType == "exceldatenum"
            readDatetimes = func.DatetimeType ~= "exceldatenum";

            if mergedCellColumnRule == "placeleft" && mergedCellRowRule == "placetop"
                outputData = sheet.readCellArray(locationStruct, typeIDs, ...
                    typeStruct, readDatetimes);
                omitrows = [];
                omitvars = [];
            else
                if isfield(supplied, "UseExcel") && func.UseExcel
                    error(message("MATLAB:spreadsheet:sheet:FeatureOffInUseExcelMode"));
                end
                [outputData, ~, omitrows, omitvars] = sheet.readCellArray(...
                    locationStruct, typeIDs, typeStruct, readDatetimes, ...
                    mergedCellColumnRule, mergedCellRowRule);
            end

            if ~isempty(omitrows)
                mergedOmitrows = false(size(typeIDs, 1), 1);
                % We need to add 1 here since indexing is 0-based (in C++)
                % and for readtable this is fine since variable names would
                % be the first row
                if numHeaderLines
                    mergedOmitrows(omitrows) = true;
                else
                    mergedOmitrows(omitrows + 1) = true;
                end
                omitrows = mergedOmitrows;
            else
                omitrows = false(size(typeIDs, 1), 1);
            end
            if ~isempty(omitvars)
                mergedOmitvars = false(1, size(typeIDs, 2));
                mergedOmitvars(omitvars) = true;
                omitvars = mergedOmitvars;
            else
                omitvars = false(1, size(typeIDs, 2));
            end

            % Initialize cell array that is the size of the requested
            % range
            C = cell(numRows, numel(selectedVarIDs));

            % Fill cell array with dates according to DatetimeType and
            % TextType
            dates = matlab.io.spreadsheet.internal.createDatetime(outputData.dates, 'default', '');
            if strcmp(func.DatetimeType,'datetime')
                C(indices.dateIDs) = num2cell(dates);
            elseif strcmp(func.DatetimeType,'text') && strcmp(func.TextType,'string')
                stringDates = string(dates, [], 'system');
                C(indices.dateIDs) = num2cell(stringDates);
            elseif strcmp(func.DatetimeType,'text') && strcmp(func.TextType,'char')
                charDates = char(dates, [], 'system');
                C(indices.dateIDs) = cellstr(charDates);
            end

            C(indices.boolIDs) = num2cell(outputData.logicals);

            % add durations
            durationTypes = typeIDs == sheet.DURATION;
            if any(durationTypes, 'all')
                if isempty(zeroEpochDatetime)
                    zeroEpochDatetime = datetime(0,ConvertFrom="excel");
                end
                durationVals = datetime(outputData.durations, ...
                    ConvertFrom="excel") - zeroEpochDatetime;
                durationVals.Format = "hh:mm:ss";
                C(indices.durationIDs) = num2cell(durationVals);
            end

            if ~readDatetimes
                C(indices.numIDs | indices.dateIDs) = num2cell(outputData.doubles);
            else
                C(indices.numIDs) = num2cell(outputData.doubles);
            end

            vOpts = func.Options.VariableOptions;
            [textDataAsStrings, info] = matlab.io.text.internal.convertFromText(vOpts(1), outputData.text);
            if isstring(textDataAsStrings)
                textDataAsStrings = num2cell(textDataAsStrings);
            end

            C(indices.textIDs) = textDataAsStrings;
            C(indices.errorIDs) = {missing};

            % Initialize vectors to store whether a row is omitted
            omitvarsMissing = false(1, size(C, 2));
            omitrowsMissing = false(size(C, 1), 1);
            omitvarsError = false(1, size(C, 2));
            omitrowsError = false(size(C, 1), 1);

            % Compute the rows and/or columns to omit according to
            % MissingRule and ImportErrorRule
            if (func.Options.ImportErrorRule == "fill")
                C(indices.errorIDs) = {missing};
            else
                [omitrowsError, omitvarsError] = processImportErrorRule(func.Options.ImportErrorRule,...
                    indices.errorIDs, func.TextType);
            end

            if (func.Options.MissingRule == "fill")
                C(indices.blankIDs) = {missing};
            else
                [omitrowsMissing, omitvarsMissing] = processMissingRule(func.Options.MissingRule,...
                    indices.blankIDs, indices.textIDs, info);
            end

            % Remove the rows and columns computed
            omitrows = or(omitrows, or(omitrowsMissing, omitrowsError));
            omitvars = or(omitvars, or(omitvarsMissing, omitvarsError));

            C(omitrows, :) = [];
            C(:, omitvars) = [];

            if isempty(C)
                C = {};
            end
        end
    end
    
        methods (Access = protected)
        function dataRanges = computeDataRanges(func, sheet, useExcel)
            % get the rectangular range that spans over all "used" cells in
            % the sheet.
            if(~useExcel)
                fields = fieldnames(func);
                if any(contains(fields, "MergedCellColumnRule"))
                    mergedColRule = func.MergedCellColumnRule;
                    mergedRowRule = func.MergedCellRowRule;
                else
                    mergedColRule = func.Options.MergedCellColumnRule;
                    mergedRowRule = func.Options.MergedCellRowRule;
                end
                if mergedColRule ~= "placeleft" || mergedRowRule ~= "placetop"
                    % do not apply optimized data span algorithm in this case
                    % since it will remove all merged cells on the boundaries
                    usedRangeStr = sheet.getDataSpan(mergedColRule, mergedRowRule);
                else
                    usedRangeStr = sheet.getDataSpan;
                end
                if(isempty(usedRangeStr))
                    usedRange = [];
                else
                    usedRange = sheet.getRange(usedRangeStr, false);
                end
            else
                usedRangeStr = sheet.usedRange();
                if isempty(usedRangeStr)
                    usedRange = [];
                else
                    usedRange = sheet.getRange(usedRangeStr, false);
                end
            end

            numVars = numel(func.Options.VariableNames);

            % If DataRange is specified as matrix of Row Ranges, 
            % i.e. [1 10; 20 100], numRanges can be greater than 1.
            numRanges = size(func.Options.DataRange, 1);

            dataRanges = zeros(numRanges, 4);
            
            badDataRanges = false(numRanges, 1);
            for i = 1:numRanges
                dataRanges(i, :) = matlab.io.spreadsheet.internal.getDataRange(sheet, ...
                    func.Options.DataRange(i, :), numVars, usedRange, 0);
                
                % A data Range fails when it has width or height of zero
                if any(dataRanges(i, 3:4) == 0)
                    badDataRanges(i) = true;
                end
            end
            
            % remove all DataRanges whose width or height are zero
            dataRanges(badDataRanges, :) = [];
        end
        
        function [typeIDs, numRows, numHeaderLines] = getTypeIDs(func, sheet, dataRanges, ...
                mergedCellColumnRule, mergedCellRowRule)
            import matlab.io.spreadsheet.internal.combinedDataRangeForGoogleSheet;
            numRows = sum(dataRanges(:, 3), 'all');
            numVars = numel(func.Options.VariableNames);
            typeIDs = zeros(numRows, numVars, 'uint8');
            numRanges = size(dataRanges, 1);
            startIndex = 1;

            numHeaderLines = min(dataRanges(:,1))-1;
            if numHeaderLines < 0
                numHeaderLines = 0;
            end

            if sheet.is_format_gsheet()
                removeHeaderLines = false;
                addedHeaderLines = false;
                if numHeaderLines > 0
                    % add header lines to range so we add them to cache for
                    % Google Sheets
                    dataRanges(1, 1) = dataRanges(1, 1) - numHeaderLines;
                    removeHeaderLines = true;
                end

                if numRanges > 1
                    % combine disparate DataRange intervals to make a single
                    % Google query
                    combinedRange = combinedDataRangeForGoogleSheet(dataRanges, numRanges);
                    if removeHeaderLines
                        combinedRange(3) = combinedRange(3) + numHeaderLines;
                        addedHeaderLines = true;
                    end
                    sheet.types(combinedRange);
                elseif ~any(dataRanges(3:4) == 0)
                    % don't make this call for empty data, will throw
                    if removeHeaderLines
                        % increment number of rows in dataRange to
                        % accommodate header lines
                        dataRanges(3) = dataRanges(3) + numHeaderLines;
                        addedHeaderLines = true;
                    end
                    sheet.types(dataRanges);
                end

                % Remove header lines from the range so further range-based
                % computations are correct
                if removeHeaderLines
                    dataRanges(1, 1) = dataRanges(1, 1) + numHeaderLines;
                    if addedHeaderLines
                        dataRanges(3) = dataRanges(3) - numHeaderLines;
                    end
                end
            end

            for i = 1 : numRanges
                endIndex = dataRanges(i, 3) + startIndex - 1;
                if mergedCellColumnRule ~= "placeleft" || ...
                        mergedCellRowRule ~= "placetop"
                    typeIDs(startIndex:endIndex, :) = sheet.types(dataRanges(i, :), ...
                        mergedCellColumnRule, mergedCellRowRule, numHeaderLines);
                else
                    typeIDs(startIndex:endIndex, :) = sheet.types(dataRanges(i, :));
                end
                startIndex = endIndex + 1;
            end
        end
    end
end

function [typeIndexStruct, typeStruct] = getTypesStructs(typeIDs, sheet)
    typeIndexStruct.blankIDs = (typeIDs == sheet.BLANK)|(typeIDs == sheet.EMPTY);
    typeIndexStruct.errorIDs  = (typeIDs == sheet.ERROR);
    typeIndexStruct.dateIDs = (typeIDs == sheet.DATETIME);
    typeIndexStruct.boolIDs = (typeIDs == sheet.BOOLEAN);
    typeIndexStruct.numIDs = (typeIDs == sheet.NUMBER);
    typeIndexStruct.textIDs = (typeIDs == sheet.STRING);
    typeIndexStruct.durationIDs = (typeIDs == sheet.DURATION);

    typeStruct.NumDates = cast(sum(typeIndexStruct.dateIDs, 'all'), 'uint64');
    typeStruct.NumBool = cast(sum(typeIndexStruct.boolIDs, 'all'), 'uint64');
    typeStruct.NumDouble = cast(sum(typeIndexStruct.numIDs, 'all'), 'uint64');
    typeStruct.NumText = cast(sum(typeIndexStruct.textIDs, 'all'), 'uint64');
    typeStruct.NumDuration = cast(sum(typeIndexStruct.durationIDs, 'all'), 'uint64');
end

function [omitrows, omitvars] = processMissingRule(rule, blankIDs, textIDs, text_info)
    missingIds = text_info.Placeholders;
    linearIDs = find(textIDs);
    blankIDs(linearIDs(missingIds)) = true;
    omitvars = false(1, size(blankIDs, 2));
    omitrows = false(size(blankIDs, 1), 1); 
    if rule == "omitvar"
        omitvars = any(blankIDs, 1);
    elseif rule == "omitrow"
        omitrows = any(blankIDs, 2);
    elseif rule == "error"
        [row, col] = find(blankIDs, 1);
        if isscalar(row)
            error(message("MATLAB:spreadsheet:importoptions:MissingRuleError", col, row));
        end
    end
end

function [omitrows, omitvars] = processImportErrorRule(rule, errorIDs, textType)
    omitvars = false(1, size(errorIDs, 2));
    omitrows = false(size(errorIDs, 1), 1); 
    if rule == "omitvar"
        omitvars = any(errorIDs, 1);
    elseif rule == "omitrow"
        omitrows = any(errorIDs, 2);
    elseif rule == "error"
        [row, col] = find(errorIDs, 1);
        if isscalar(row)
            error(message("MATLAB:spreadsheet:importoptions:ErrorRuleError", col, row, textType));
        end
    end
end

function checkWrongParamsWrongType(supplied)
persistent params
if isempty(params)
    me = {?matlab.io.internal.functions.AcceptsDateLocale, ...
        ?matlab.io.internal.shared.EncodingInput};
    params = cell(1,numel(me));
    for i = 1:numel(me)
        params{i} = string({me{i}.PropertyList([me{i}.PropertyList.Parameter]).Name});
    end
    params = [params{:}, "MaxRowsRead", "ExtraColumnsRule","ConsecutiveDelimitersRule", ...
                         "LeadingDelimitersRule", "DataLines",...
                         "VariableNamesLine", "RowNamesColumn",...
                         "VariableUnitsLine", "VariableDescriptionsLine"];
end

matlab.io.internal.utility.assertUnsupportedParamsForFileType(params,supplied,'spreadsheet');

end
