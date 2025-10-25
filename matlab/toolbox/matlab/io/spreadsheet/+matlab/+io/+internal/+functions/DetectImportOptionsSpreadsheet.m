classdef DetectImportOptionsSpreadsheet < matlab.io.internal.functions.ExecutableFunction ...
        & matlab.io.internal.shared.SpreadsheetInputs ...
        & matlab.io.internal.functions.TableMetaDataFromDetection ...
        & matlab.io.internal.shared.CommonVarOpts ...
        & matlab.io.internal.shared.TreatAsMissingInput ...
        & matlab.io.internal.shared.RangeInput ...
        & matlab.io.internal.shared.PreserveVariableNamesInput ...
        & matlab.io.internal.parameter.SpanHandlingProvider
    %
    
    %   Copyright 2018-2024 The MathWorks, Inc.
    
    properties
        WorkSheet = matlab.io.internal.functions.UsesWorksheet();
    end
    
    properties (Hidden)
        % Whether the function enables detecting non-empty header lines 
        DetectHeader(1,1) logical = true;
    end
    
    properties (Hidden, Constant)
        % The number of rows to inspect when detecting  header lines and
        % variable types.
        NumInspectionRows(1, 1) double = 250;
    end

    methods
        function opts = execute(func, supplied)
            import matlab.io.spreadsheet.internal.*;
            checkWrongParamsWrongType(supplied);
            fmt = getExtension(func.LocalFileName);
            % On Windows for ODS and XLSB files error when UseExcel is set to false by the user
            if(ispc && contains(fmt, {'ods', 'xlsb'}, 'IgnoreCase',true)... 
                && isfield(supplied,'UseExcel') && supplied.UseExcel && ~func.UseExcel)
                error(message('MATLAB:spreadsheet:book:fileTypeUnsupported', fmt));
            end

            openBookAndSheet(func, supplied, fmt, true);
            try
                [opts,func] = func.getOptsFromSheet(supplied);
            catch ME
                invalidRangeId = "MATLAB:spreadsheet:sheet:invalidNamedRangeOrOutOfBounds";
                if ME.identifier == "MATLAB:spreadsheet:sheet:EmptyRange"
                    openBookAndSheet(func, supplied, fmt, false);
                    [opts,func] = func.getOptsFromSheet(supplied);
                elseif ME.identifier == invalidRangeId && fmt ~= "gsheet"
                    % try to check if the named range exists on any other
                    % sheet, load entire workbook
                    func.WorkSheet.WorkbookObj = createWorkbook(fmt, func.LocalFileName, false);
                    numSheets = numel(func.WorkSheet.WorkbookObj.SheetNames);
                    % iterate over sheets in workbook and get named ranges
                    for ii = 1 : numSheets
                        func.WorkSheet.SheetObj = func.WorkSheet.WorkbookObj.getSheet(ii);
                        try
                            [opts,func] = func.getOptsFromSheet(supplied);
                        catch ME
                            if ME.identifier == invalidRangeId && ii < numSheets
                                continue;
                            else
                                throw(ME);
                            end
                        end
                    end
                else
                    throw(ME);
                end
            end
            opts = func.setNonDetectionProperties(opts);
        end

        % --------------------------
        function openBookAndSheet(func, supplied, fmt, useRange)
            import matlab.io.spreadsheet.internal.SheetTypeFactory;
            import matlab.io.spreadsheet.internal.SheetType;
            if ~useRange
                rangeVal = '';
            else
                rangeVal = func.Range;
            end

            % if VariableNamesRange, DataRange, VariableUnitsRange, or
            % VariableDescriptionsRange is specified, don't apply the
            % row-only loading optimization since any of these ranges could
            % lie outside the loaded range.
            if useRange && (supplied.VariableNamesRange || ...
                    supplied.VariableUnitsRange || ...
                    supplied.VariableDescriptionsRange)
                rangeVal = '';
            end

            if fmt == "gsheet" && isfield(supplied, "MergedCellColumnRule") && ...
                    (func.MergedCellColumnRule ~= "placeleft" || ...
                    func.MergedCellRowRule ~= "placetop")
                error(message("MATLAB:spreadsheet:gsheet:MergingRulesNotSupported"));
            end

            if fmt ~= "gsheet" && isfield(supplied, "Sheet") && ...
                    SheetTypeFactory.makeSheetType(func.Sheet) == SheetType.Invalid
                error(message("MATLAB:spreadsheet:importoptions:BadSheet"));
            end

            if isfield(supplied,'UseExcel')
                if func.UseExcel && fmt == "gsheet"
                    error(message("MATLAB:spreadsheet:gsheet:UseExcelNotAllowed"));
                end

                func.WorkSheet.openBook(func.LocalFileName, func.Sheet, fmt, ...
                    func.UseExcel, rangeVal, func.InputFilename);
            else
                % detectImportOptions does not have a 'UseExcel' parameter
                % and relies on 'UseExcel' false by default
                func.WorkSheet.openBook(func.LocalFileName, func.Sheet, fmt, ...
                    false, rangeVal, func.InputFilename);
            end
            func.WorkSheet.openSheet(func.Sheet);
        end

        % --------------------------
        function [opts,func] = getOptsFromSheet(func, supplied)
            import matlab.io.spreadsheet.internal.*;
            sheet = func.WorkSheet.SheetObj;
            if supplied.DataRange
                func.Range = func.DataRange;
            end

            % If VariableNamesRange='', set ReadVariableNames to false.
            if supplied.VariableNamesRange && isempty(func.VariableNamesRange)
                supplied.VariableNamesRange = false;
                supplied.ReadVariableNames = true;
                func.ReadVariableNames = false;
            end
            
            if (supplied.Range || supplied.DataRange) && ~isempty(func.Range)
                [rangeToUse,bindRanges,rangeStr,typeIDs] = func.getRangeFromSheet(supplied);
            else
                [rangeToUse,bindRanges,rangeStr,typeIDs] = func.getRangeFromUsedRange();
            end
            
            if isempty(rangeToUse) || all(typeIDs(:) == sheet.BLANK ...
                    | typeIDs(:) == sheet.EMPTY ...
                    | typeIDs(:) == sheet.ERROR)
                opts = matlab.io.spreadsheet.SpreadsheetImportOptions('NumVariables',size(typeIDs,2),'Sheet',func.Sheet);
                if supplied.Range
                    if isempty(rangeStr)
                        opts.DataRange = func.Range;
                    else
                        opts.DataRange = rangeStr;
                    end
                    opts = setvartype(opts,func.EmptyColumnType);
                end
                opts = func.setFileProps(supplied,opts);
                return;
            end
            
            % Find header rows/cols and leading empty rows
            if ~supplied.NumHeaderLines && ~bindRanges(1) && func.DetectHeader
                func.NumHeaderLines = getHeaderRows(typeIDs);
            elseif ~supplied.NumHeaderLines && ~bindRanges(1) && ~func.DetectHeader
                func.NumHeaderLines = countLeadingEmptyRows(typeIDs);
            elseif ischar(func.NumHeaderLines) && func.NumHeaderLines == "auto"
                func.NumHeaderLines = 0;
            end
            headerRows = func.NumHeaderLines;

            % detect types
            tdto.EmptyColumnType = func.EmptyColumnType;
            tdto.DetectVariableNames =  ~supplied.ReadVariableNames;
            tdto.ReadVariableNames = func.ReadVariableNames;
            tdto.MetaRows = 0;
            tdto.DetectMetaRows = func.DetectMetaLines;
            
            detectionResults = matlab.io.internal.detectTypes(typeIDs(headerRows+1:end,:),tdto);
            
            meta = func.setMetaLocations(supplied, detectionResults.MetaRows);
            backupVarNameRange = [];

            if ~supplied.VariableNamesRange
                if meta.VarNames
                    % get the row range used to read var names
                    varNameRange = [rangeToUse(1) + headerRows, rangeToUse(2), 1, numel(detectionResults.Types)];
                    backupVarNameRange = varNameRange;
                    % read the variables, converting any names
                    tvio = matlab.io.TextVariableImportOptions();
                    typesRow = min(height(typeIDs),headerRows+1);
                    names = matlab.io.spreadsheet.internal.readSpreadsheetVariable(tvio.Type, ...
                        tvio, sheet, varNameRange, typeIDs(typesRow,:), ...
                        "placeleft", "placetop", true);
                else
                    % Var1, Var2, ... , VarN
                    names = strings(1,size(typeIDs,2));
                    if meta.RowNames
                        names(1) = "Row";
                    end
                    names = cellstr(names);
                end
            else
                tvio = matlab.io.TextVariableImportOptions();
                
                varNameRange = func.VariableNamesRange;
                if isnumeric(varNameRange) && isscalar(varNameRange)
                    % Convert scalar integer ranges into a a start cell
                    % range, i.e. A1.
                    varNameRange = getCellName(varNameRange, rangeToUse(2));
                end

                [varRangeToUse, bindVarRange] = getRangeInfo(sheet, varNameRange);
                if ~bindVarRange(2)
                    varRangeToUse(4) = rangeToUse(4);
                end
                varTypeIDs = repmat(sheet.STRING, 1, varRangeToUse(4));
                names = matlab.io.spreadsheet.internal.readSpreadsheetVariable(tvio.Type, ...
                    tvio, sheet, varRangeToUse, varTypeIDs, ...
                    string(func.MergedCellColumnRule), string(func.MergedCellRowRule), true);
            end
            
            if ~func.DetectMetaLines
                detectionResults.MetaRows = 0;
            end

            backupNames = names;
            if meta.RowNames
                L = columnLetter(rangeToUse(2));
                rowNamesRange = L+":"+L;
                names(1) = [];
                detectionResults.Types(1) = [];
            else
                rowNamesRange = '';
            end

            if meta.VarNames
                varNamesRow = rangeToUse(1) + headerRows;
                startCol = rangeToUse(2) + meta.RowNames;
                varNameRange = getCellName(varNamesRow, startCol);
                if bindRanges(2)
                    if numel(names) > 0
                        % Only set VariableNamesRange to a bound
                        % rectangular range if there is at least 1 Variable
                        endCol = startCol + numel(names) - 1;
                        varNameRange = strjoin({varNameRange, getCellName(varNamesRow, endCol)}, ':');
                    else
                        % there are zero variables so VariableNamesRange 
                        % can't be set to a bound rectangular range
                        varNameRange = '';
                    end
                end
            else
                varNameRange = '';
            end

            % update data range based on variable range
            if ~headerRows && ~detectionResults.MetaRows
                if ~isempty(backupVarNameRange)
                    % compare with row range used to read var names
                    if rangeToUse(1) == backupVarNameRange(1) && ...
                            rangeToUse(2) == backupVarNameRange(2)
                        rangeToUse(1) = rangeToUse(1) + backupVarNameRange(1);
                    end
                else
                    % use the metadata information to update data range
                    if meta.VarNames && rangeToUse(1) == columnNumber(varNameRange(1)) && ...
                            rangeToUse(2) == varNameRange(2)
                        rangeToUse(1) = rangeToUse(1) + columnNumber(varNameRange(1));
                    end
                end
            end

            startRow = rangeToUse(1) + headerRows + detectionResults.MetaRows;
            startCol = rangeToUse(2) + meta.RowNames;
            dataRange = getCellName(startRow, startCol);
            if bindRanges(1)
                if numel(backupNames) - meta.RowNames > 0
                    % only try setting a bound range if there 
                    % is at least 1 variable
                    if contains(rangeStr,':')
                        rangeStr = strsplit(rangeStr,':');
                        dataRange = strjoin({dataRange,rangeStr{2}},':');
                    else
                        dataRange = [dataRange ':' dataRange];
                    end
                end
            end

            if supplied.ExpectedNumVariables
                numVars = min([numel(names),func.ExpectedNumVariables]);
                names = names(1:numVars);
                detectionResults.Types = detectionResults.Types(1:numVars);
            end

            if numel(names) < numel(detectionResults.Types)
                idx = numel(names)+1:numel(detectionResults.Types);
                names(idx) = {''};
            elseif numel(names) > numel(detectionResults.Types)
                names(numel(detectionResults.Types)+1:end) = [];
            end

            opts = matlab.io.spreadsheet.SpreadsheetImportOptions(NumVariables=numel(detectionResults.Types), ...
                MergedCellColumnRule=func.MergedCellColumnRule, MergedCellRowRule=func.MergedCellRowRule);

            opts.PreserveVariableNames = func.PreserveVariableNames;
            opts.VariableTypes = detectionResults.Types;
            opts.Sheet = func.Sheet;
            opts.VariableNamesRange = varNameRange;

            specifiedNames = (strlength(names)>0);
            % Only normalize variable names if PreserveVariableNames is set
            % to false.
            if ~func.PreserveVariableNames
                names(specifiedNames) = matlab.lang.makeValidName(names(specifiedNames));
            end
            names(specifiedNames) = matlab.lang.makeUniqueStrings(names(specifiedNames),{},namelengthmax);

            opts.DataRange = dataRange;
            opts.RowNamesRange = rowNamesRange;
            typeIDs(1:meta.DataRow-1,:) = [];
            if meta.RowNames
                % Remove the column associated with the RowNames from typeIDs
                typeIDs(:, 1) = [];
            end
            
            blanks = all(typeIDs == sheet.BLANK | typeIDs == sheet.EMPTY | typeIDs == sheet.ERROR,1);
            opts = opts.setvartype(blanks(1:numel(names)),func.EmptyColumnType);
            opts.fast_var_opts = opts.fast_var_opts.setVarNames(1:numel(names), names(:));
            opts = func.setVariableProps(supplied,opts);
            opts = func.setFileProps(supplied,opts);
        end
        
        function opts = setFileProps(func,supplied,opts)
            if supplied.DataRange,                  opts.DataRange = func.DataRange;end
            if supplied.VariableNamesRange,         opts.VariableNamesRange = func.VariableNamesRange;end
            if supplied.VariableUnitsRange,         opts.VariableUnitsRange = func.VariableUnitsRange;end
            if supplied.VariableDescriptionsRange,  opts.VariableDescriptionsRange = func.VariableDescriptionsRange;end
            if supplied.RowNamesRange,              opts.RowNamesRange = func.RowNamesRange;end
        end
        
        function n = getNumVars(~)
            n = inf;
        end
    end
    
    methods (Access = private)
        function opts = setNonDetectionProperties(func,opts)
            opts.VariableUnitsRange = func.VariableUnitsRange;
            opts.VariableDescriptionsRange = func.VariableDescriptionsRange;
        end
        
        % --------------------------
        function [rangeToUse,bindRanges,rangeStr,typeIDs] = getRangeFromUsedRange(func)
            % bindRanges is always the logical vector [false false] when
            % the Range and DataRange name-value pairs are not supplied.
            bindRanges = [false false];
            comObject = func.WorkSheet.IsComObject;
            if comObject
                [rangeToUse, rangeStr, typeIDs] = func.getNonLibXLRangeFromUsedRange();
            elseif func.WorkSheet.WorkbookObj.Format == "GSHEET"
                [rangeToUse, rangeStr, typeIDs] = func.getNonLibXLRangeFromUsedRange();
            else
                [rangeToUse, rangeStr, typeIDs] = func.getLibxlRangeFromUsedRange();
            end
        end

        function [rangeToUse, rangeStr, typeIDs] = getNonLibXLRangeFromUsedRange(func)
            sheet = func.WorkSheet.SheetObj;
            % usedDataRange returns the smallest range that includes used
            % cells. Excludes rows and columns that only contain BLANK, 
            % EMPTY, and ERROR cells.
            if func.WorkSheet.WorkbookObj.Format == "GSHEET" && ...
                    ~startsWith(class(func),"matlab.io.internal.functions.Read")
                % Pass in true to indicate that sheet.prefetch should be called
                [rangeStr,typeIDs] = matlab.io.spreadsheet.internal.usedDataRange(sheet, true);
            else
                % Pass in false to indicate that sheet.types should be called
                [rangeStr,typeIDs] = matlab.io.spreadsheet.internal.usedDataRange(sheet, false);
            end
            % Only use the first 250 non-empty (NumInspectionRows) for 
            % type detection.
            typeIDs(func.NumInspectionRows:end, :) = [];
            if isempty(rangeStr)
                typeIDs = uint8([]);
                rangeToUse = [];
            else
                rangeToUse = sheet.getRange(rangeStr, false);
                % Only use the first 250 non-empty rows (NumInspectionRows) 
                % during detection.
                if numel(rangeToUse) == 4 && rangeToUse(3) > func.NumInspectionRows
                    rangeToUse(3) = func.NumInspectionRows;
                end
            end
        end

        function [rangeToUse, rangeStr, typeIDs] = getLibxlRangeFromUsedRange(func)
            sheet = func.WorkSheet.SheetObj;
            % getDataSpan returns the smallest range that includes used
            % cells. Excludes rows and columns that only contain BLANK, 
            % EMPTY, and ERROR cells.
            if func.MergedCellColumnRule ~= "placeleft" || ...
                func.MergedCellRowRule ~= "placetop"
                % do not apply optimized data span algorithm in this case
                % since it will remove all merged cells on the boundaries
                rangeStr = sheet.getDataSpan(func.MergedCellColumnRule, func.MergedCellRowRule);
            else
                rangeStr = sheet.getDataSpan();
            end
            if isempty(rangeStr)
                typeIDs = uint8([]);
                rangeToUse = [];
            else
                rangeToUse = sheet.getRange(rangeStr, false);
                if numel(rangeToUse) == 4 && rangeToUse(3) > func.NumInspectionRows
                    % Only use the first 250 non-empty rows (NumInspectionRows) 
                    % during detection.
                    rangeToUse(3) = func.NumInspectionRows;
                end
                typeIDs = sheet.types(rangeToUse);
            end
        end

        function rangeToUse = getUsedRange(func)
            sheet = func.WorkSheet.SheetObj;
            comObject = func.WorkSheet.IsComObject;
            if comObject
                % usedDataRange returns the smallest range that includes used
                % cells. Excludes rows and columns that only contain BLANK, 
                % EMPTY, and ERROR cells.
                [rangeStr, ~] = matlab.io.spreadsheet.internal.usedDataRange(sheet);
            else
                % getDataSpan returns the smallest range that includes used
                % cells. Excludes rows and columns that only contain BLANK, 
                % EMPTY, and ERROR cells.
                if func.MergedCellColumnRule ~= "placeleft" || ...
                        func.MergedCellRowRule ~= "placetop"
                    % do not apply optimized data span algorithm in this case
                    % since it will remove all merged cells on the boundaries
                    rangeStr = sheet.getDataSpan(func.MergedCellColumnRule, ...
                        func.MergedCellRowRule);
                else
                    rangeStr = sheet.getDataSpan;
                end
            end

            if isempty(rangeStr)
                rangeToUse = [];
            else
                rangeToUse = sheet.getRange(rangeStr, false);
            end
        end

        % --------------------------
        function [rangeToUse,bindRanges,rangeStr,typeIDs] = getRangeFromSheet(func,supplied)
            [rangeToUse, bindRanges, rangeType] = getRangeInfo(func.WorkSheet.SheetObj,func.Range);
            
            % Only 'column-select' (A:B) ranges are supported
            % in conjunction with NumHeaderLines.
            if supplied.NumHeaderLines && (supplied.Range || supplied.DataRange) && ~strcmp(rangeType, 'column-only')
                error(message('MATLAB:spreadsheet:sheet:NumHeaderLinesAndRange'));
            end
            
            if (supplied.Range || supplied.DataRange) && any(~bindRanges)
                % Take the extent of the range from the SHEET's used range.
                % Do not use func.getRangeFromUsedRange() because it trims 
                % the range to include only 250 (NumInspectionRows) rows.
                usedRange = func.getUsedRange();
                if ~isempty(usedRange) 
                    usedExtent = usedRange([3 4]) + usedRange([1 2]);
                    givenExtent = rangeToUse([1 2]);
                    newExtent = usedExtent - givenExtent;

                    toUse = [false false ~bindRanges];

                    if any(newExtent(~bindRanges) < 1)
                        % The unbounded region of the supplied Range is not
                        % within the used Range.
                        rangeToUse(toUse) = 0;
                        rangeStr = '';
                        typeIDs = uint8.empty(0);
                        return
                    else
                        % Need to clip to the UsedRange
                        rangeToUse(toUse) = newExtent(~bindRanges);
                    end
                end
            end

            % Only examine the first 250 (NumInspectionRows) rows during 
            % header line and type detection. Avoid examing every cell for
            % type and header line detection.
            typeDetectionRange = rangeToUse;
            if typeDetectionRange(3) > func.NumInspectionRows
                if func.WorkSheet.WorkbookObj.Format ~= "GSHEET" || ...
                        (func.WorkSheet.WorkbookObj.Format == "GSHEET" && ...
                        ~startsWith(class(func), "matlab.io.internal.functions.Read"))
                    % only cap range limit for Excel spreadsheets, and
                    % detectImportOptions calls for Google Sheets
                    typeDetectionRange(3) = func.NumInspectionRows;
                end
            end

            if func.WorkSheet.WorkbookObj.Format == "GSHEET" && ...
                    ~startsWith(class(func), "matlab.io.internal.functions.Read")
                % This is detectImportOptions code path for Google Sheets,
                % using prefetch method
                typeIDs = func.WorkSheet.SheetObj.prefetch(typeDetectionRange);
            else
                % Use types method for all other cases
                typeIDs = func.WorkSheet.SheetObj.types(typeDetectionRange);
            end

            % Make sure to return the full range instead of the
            % trimmed version. This ensures DataRange is set to the
            % appropriate value when Range is supplied instead of DataRange.
            rangeStr = string(matlab.io.spreadsheet.internal.columnLetter(...
                rangeToUse(2))) + string(rangeToUse(1));
            rangeStr = rangeStr + ':' + string(matlab.io.spreadsheet.internal.columnLetter(...
                rangeToUse(2)+rangeToUse(4)-1)) + string(rangeToUse(1)+rangeToUse(3)-1);
        end
    end
end

% --------------------------
function [rangeToUse, bindRanges, rangeType] = getRangeInfo(sheet,range)
    [rangeToUse, rangeType, boundedRange] = sheet.getRange(range, false);
    if ~boundedRange
        % end row or end column returned is MAX Excel limit and the end
        % limits could not be determined. Try loading full book in this
        % case
        error(message("MATLAB:spreadsheet:sheet:EmptyRange"));
    end
    switch(rangeType)
        case 'single-cell'
            bindRanges = [false false];
        case 'column-only'
            bindRanges = [false true];
        case 'row-only'
            bindRanges = [true false];
        otherwise
            bindRanges = [true true];
    end
end

% --------------------------
function numHeaderRows = getHeaderRows(typeIDs)
    import matlab.io.text.internal.detectHeaderLines;

    % Get cumulative max of each row, to only consider leading empty rows
    numVars = cummax(countNumVarsPerRow(typeIDs));

    emptyRows = (numVars == 0);

    % Remove Empty Rows for detectHeaderLines
    numVars(emptyRows) = [];

    headers = detectHeaderLines(double(abs(numVars-double(median(uint64(numVars))))));

    % Add the empty rows back in
    if any(emptyRows)
        if headers > 0
            lastHeader = max([0;find(~emptyRows,headers)]); % Find the last non-empty header row
        else
            lastHeader = max([1;find(~emptyRows,1)])-1; 
        end
        % take into account empty rows after the last header line.
        numHeaderRows = lastHeader + max([0,find(~emptyRows((lastHeader+1):end),1)-1]);
    else
        numHeaderRows = headers;
    end
end

function numEmptyRows = countLeadingEmptyRows(typeIDs)

    numVars = countNumVarsPerRow(typeIDs);

    % Get cumulative max of each row, to only consider leading empty rows
    cummaxNumVars = cummax(numVars);

    numEmptyRows = sum(cummaxNumVars == 0);
end

function numVarsPerRow = countNumVarsPerRow(typeIDs)
    import matlab.io.spreadsheet.internal.Sheet;

    % Create a matrix to indicate which cells are BLANK or EMPTY
    blanks = (typeIDs == Sheet.BLANK | typeIDs == Sheet.EMPTY);

    % Define a function to get the number of non-blank cells in a specific row
    getNumVarsInRow = @(i)max([0,find(~blanks(i,:),1,'last')]);

    % Define a column vector to index each row of typeIDs
    rowIdxVec = (1:size(typeIDs,1))';

    % Apply function to each row of data
    numVarsPerRow = arrayfun(getNumVarsInRow, rowIdxVec);
end

function cell = getCellName(r,c)
    cell = sprintf('%s%d',matlab.io.spreadsheet.internal.columnLetter(c),r);
end

function checkWrongParamsWrongType(supplied)
    persistent params
    if isempty(params)
        me = {?matlab.io.internal.shared.DelimitedTextInputs, ...
            ?matlab.io.internal.shared.FixedWidthInputs, ...
            ?matlab.io.internal.shared.TextInputs,...
            ?matlab.io.internal.shared.NumericVarOptsInputs,...
            ?matlab.io.internal.parameter.TableIndexProvider,...
            ?matlab.io.xml.internal.parameter.AttributeSuffixProvider,...
            ?matlab.io.xml.internal.parameter.DetectNamespacesProvider,...
            ?matlab.io.xml.internal.parameter.ImportAttributesProvider,...
            ?matlab.io.xml.internal.parameter.NodeNameProvider,...
            ?matlab.io.xml.internal.parameter.RowNodeNameProvider,...
            ?matlab.io.xml.internal.parameter.RegisteredNamespacesProvider,...
            ?matlab.io.xml.internal.parameter.RepeatedNodeRuleProvider,...
            ?matlab.io.xml.internal.parameter.SelectorProvider,...
            ?matlab.io.xml.internal.parameter.RowSelectorProvider, ...
            ?matlab.io.xml.internal.parameter.TableSelectorProvider, ...
            ?matlab.io.json.internal.read.parameter.JSONParsingInputs, ...
            ?matlab.io.json.internal.read.parameter.ParsingModeProvider, ...
            ?matlab.io.internal.parameter.RowParametersProvider, ...
            ?matlab.io.internal.parameter.ColumnParametersProvider};

        params = cell(1,numel(me));
        for i = 1:numel(me)
            params{i} = string({me{i}.PropertyList([me{i}.PropertyList.Parameter]).Name});
        end
        params = ["DurationType" "HexType" "BinaryType" "MultipleDelimsAsOne" params{:}];
    end
    matlab.io.internal.utility.assertUnsupportedParamsForFileType(params,supplied,'spreadsheet')
end
