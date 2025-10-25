function [variables,metadata,omittedvarsmap] = readSpreadsheet(sheet, opts, args)
    %READSPREADSHEET reads a spreadsheet file according to the import options
    
    % Copyright 2016-2024 The MathWorks, Inc.
    params = parseArguments(args);

    if ~isempty(params.Sheet)
        opts.Sheet = params.Sheet;
    end

    [~,selectedIDs] = ismember(opts.SelectedVariableNames',opts.VariableNames);

    % DATARANGE
    [variables,errorIDs,missingIDs,dataRange, selectedIDs, numHeaderLines] = handleDataRange(selectedIDs, ...
        opts, sheet, params.Preview, params.UseExcel, ...
        char(params.MergedCellColumnRule), char(params.MergedCellRowRule));
    
    % VARIABLE NAMES
    numVars = numel(opts.VariableNames);
    if params.ReadVariableNames && ~isempty(opts.VariableNamesRange)
        metadata.VariableNames = readVariableMetadata(sheet, opts.VariableNamesRange, ...
            numVars, char(params.MergedCellColumnRule), char(params.MergedCellRowRule), ...
            numHeaderLines);
        if params.MergedCellRowRule ~= "omitvar"
            metadata.VariableNames = metadata.VariableNames(selectedIDs);
        end
        empties = strlength(metadata.VariableNames) == 0;
        metadata.VariableNames(empties) = compose('Var%d',find(empties));
        if params.FixVariableNames 
            metadata.VariableNames = matlab.lang.makeValidName(metadata.VariableNames);
            metadata.VariableNames = matlab.lang.makeUniqueStrings(metadata.VariableNames,{'RowNames','Properties'});
        end
    else
        metadata.VariableNames = opts.VariableNames(selectedIDs);
    end
    
    % VARIABLE UNITS 
    metadata.VariableUnits = {};
    if ~isempty(opts.VariableUnitsRange)
        metadata.VariableUnits = readVariableMetadata(sheet, opts.VariableUnitsRange, ...
            numVars, char(params.MergedCellColumnRule), char(params.MergedCellRowRule), ...
            numHeaderLines);
        metadata.VariableUnits = metadata.VariableUnits(selectedIDs);
    end
    
    % VARIABLE DESCRIPTIONS 
    metadata.VariableDescriptions = {};
    if ~isempty(opts.VariableDescriptionsRange)
        metadata.VariableDescriptions = readVariableMetadata(sheet, opts.VariableDescriptionsRange, ...
            numVars, char(params.MergedCellColumnRule), char(params.MergedCellRowRule), ...
            numHeaderLines);
        metadata.VariableDescriptions = metadata.VariableDescriptions(selectedIDs);
    end
    
    % ROWNAMES
    metadata.RowDimNames = {};
    metadata.RowNames = {};
    if ~isempty(opts.RowNamesRange)
        metadata.RowNames = readRowNames(sheet,opts.RowNamesRange,dataRange);
        emptyNames = cellfun('isempty',metadata.RowNames);
        emptyNames = emptyNames | any(params.TreatAsMissing(:)' == string(metadata.RowNames(:)),2);
        
        if any(emptyNames(:))
            metadata.RowNames(emptyNames) = compose('Row%d',find(emptyNames));
        end
        metadata.RowNames = matlab.lang.makeUniqueStrings(metadata.RowNames);
    end
    
    varOpts = opts.getVarOptsStruct(selectedIDs);
    [variables, omittedvarsmap, ~, metadata] = matlab.io.internal.handleReplacement(...
        variables, varOpts, opts.ImportErrorRule, opts.MissingRule, ...
        errorIDs, missingIDs, metadata);
end

function params = parseArguments(args)
    persistent parser
    if isempty(parser)
        parser = inputParser;
        parser.FunctionName = 'readtable';
        parser.addParameter('ReadVariableNames',false,@(rhs)validateLogicalScalar(rhs,'ReadVariableNames')); 
        parser.addParameter('ReadRowNames',true,@(rhs)validateLogicalScalar(rhs,'ReadRowNames'));
        parser.addParameter('Sheet','');
        parser.addParameter('Basic',true,@(rhs)validateLogicalScalar(rhs,'Basic'));
        parser.addParameter('UseExcel',false,@(rhs)validateLogicalScalar(rhs,'UseExcel'));
        parser.addParameter('Preview',false,@(rhs)validateattributes(rhs,{'numeric'},{'nonnegative','integer'}));
        parser.addParameter('FixVariableNames',true,@(rhs)validateLogicalScalar(rhs,'FixVariableNames'));
        parser.addParameter('EmptyColumnType','double',@(rhs)validatestring(rhs,{'double','char'}));
        parser.addParameter('TreatAsMissing',{}, @(rhs)isstring(rhs));
        parser.addParameter('MergedCellColumnRule', 'placeleft', @(rhs)isstring(rhs));
        parser.addParameter('MergedCellRowRule', 'placetop', @(rhs)isstring(rhs));
    end
    [args{:}] = convertCharsToStrings(args{:});
    parser.parse(args{:});
    params = parser.Results;
    if ~any(strcmp(parser.UsingDefaults,'UseExcel'))
        return;
    elseif ~any(strcmp(parser.UsingDefaults,'Basic'))
        params.UseExcel = ~params.Basic;
    end
end

% Validation function 
function validateLogicalScalar(rhs,propname)
    if ~isnumeric(rhs) && ~isscalar(rhs)
        error(message('MATLAB:table:InvalidLogicalVal',propname));
    end
end

function [variables,missingIDs,errorIDs] = readDataFromSheet(sheet, dataRange, ...
    varOpts, selectedVarIDs, mergedCellColumnRule, mergedCellRowRule, numHeaderLines)
    import matlab.io.spreadsheet.internal.subRange;
    import matlab.io.spreadsheet.internal.readSpreadsheetVariable;
    
    numVars = numel(selectedVarIDs);
    variables = cell(1,numVars);
    % dataRange fails when it has width or height of zero
    if numVars == 0
        missingIDs = false(dataRange(3:4));
        errorIDs = missingIDs;
        return
    end
    % To read data, we want to get the two-corner version within the used
    % range.
    if any(dataRange(3:4)==0)
        typeIDs = uint8.empty(dataRange(3:4));
        errorIDs = false(size(typeIDs));
        missingIDs = false(size(typeIDs));
        blankIDs = false(size(typeIDs));
    else
        if mergedCellColumnRule == "placeleft" && mergedCellRowRule == "placetop"
            typeIDs = sheet.types(dataRange);
        else
            typeIDs = sheet.types(dataRange, mergedCellColumnRule, ...
                mergedCellRowRule, numHeaderLines);
        end
        blankIDs = (typeIDs(:,selectedVarIDs) == sheet.BLANK) | ...
            (typeIDs(:,selectedVarIDs) == sheet.EMPTY);
        errorIDs  = (typeIDs(:,selectedVarIDs) == sheet.ERROR);
        missingIDs = false(size(errorIDs));
    end

    % Logical value indicating that merging rules are not default values
    nonDefaultMergeValues = mergedCellColumnRule ~= "placeleft" || ...
        mergedCellRowRule ~= "placetop";
    for k = 1:numel(selectedVarIDs)
        % Get data from the correct column.
        i = selectedVarIDs(k);
        varRange = subRange(dataRange,i);
        % The output typeIDVector is the updated typeIDs in case
        % non-default values were passed for MergedCellColumnRule or
        % MergedCellRowRule
        [variables{k}, err, placeholder, typeIDVector] = readSpreadsheetVariable(...
            varOpts{i}.Type, varOpts{i}, sheet, varRange, typeIDs(:,i), ...
            mergedCellColumnRule, mergedCellRowRule, true);
        missingIDs(placeholder,k) = true;
        if nonDefaultMergeValues
            if ~isempty(variables{k})
                % For uint8, Inf becomes 255. In readSpreadsheetVariable,
                % we've marked all rows that should be omitted as Inf
                variables{k}(typeIDVector == 255) = [];
            end
            % set blankIDs correctly since this will be used for setting missingIDs
            blankIDs(:, k) = (typeIDVector == sheet.BLANK)|(typeIDVector == sheet.EMPTY);
            % Remove rows from type IDs vector as well
            typeIDVector(typeIDVector == 255) = [];
            if all(~typeIDVector) && mergedCellRowRule == "omitvar"
                % Remove variable if type is 0 and MergedCellRowRule is set
                % to omitvar
                variables{k} = [];
            end
        end

        if strcmp(varOpts{i}.EmptyFieldRule,'error')
            errorIDs(blankIDs(:,k),k) = true;
        elseif strcmp(varOpts{i}.EmptyFieldRule,'missing')
            missingIDs(blankIDs(:,k),k) = true;
        end
        err(placeholder) = false;
        errorIDs(err,k) = true;
    end
end

function names = readVariableMetadata(sheet, loc, numVars, mergedCellColumnRule, ...
    mergedCellRowRule, numHeaderLines)
    if numVars == 0
        names = {};
        return
    end
    if isnumeric(loc) && isscalar(loc)
        % Row number
        range = sheet.getRange(sheet.usedRange,false);
        range(1) = loc;
        range(3) = 1;
    else
        range = sheet.getRange(loc,false);
    end
    range = matlab.io.spreadsheet.internal.subRange(range,1:numVars);
    vopts = matlab.io.TextVariableImportOptions();
    if mergedCellColumnRule == "placeleft" && mergedCellRowRule ~= "placetop"
        typesMatrix = sheet.types(range);
    else
        typesMatrix = sheet.types(range, mergedCellColumnRule, ...
            mergedCellRowRule, numHeaderLines);
    end
    names = matlab.io.spreadsheet.internal.readSpreadsheetVariable(vopts.Type, ...
        vopts, sheet, range, typesMatrix, mergedCellColumnRule, ...
        mergedCellRowRule, false);
end

function names = readRowNames(sheet,loc,dataRange)
    if isnumeric(loc) && isscalar(loc)
        % Column Number, get the used range, and select the column
        range([1 3 2 4]) = [dataRange([1 3]) loc 1];
    else
        [range,type] = sheet.getRange(loc,false);
        if strcmp(type,'single-cell')
            range(3) = dataRange(3);
        elseif strcmp(type,'column-only')
            range([1 3]) = dataRange([1 3]);
        else
            % will error if it's not correct.
        end
    end
    vopts = matlab.io.TextVariableImportOptions();
    names = matlab.io.spreadsheet.internal.readSpreadsheetVariable(vopts.Type, ...
        vopts, sheet, range, sheet.types(range));
end

function [variables, errorIDs, missingIDs, dataRange, selectedIDs, numHeaderLines] = handleDataRange(...
    selectedIDs, opts, sheet, rowsToRequest, useExcelFlag, mergedCellColumnRule, ...
    mergedCellRowRule)
    import matlab.io.spreadsheet.internal.combinedDataRangeForGoogleSheet;
    numvars = numel(selectedIDs);
    numRanges = size(opts.DataRange,1);
    
    % Get the data range and remove headers and footers
    if(~useExcelFlag)
        if mergedCellColumnRule == "placeleft" && mergedCellRowRule == "placetop"
            usedRangeStr = sheet.getDataSpan();
        else
            % do not apply optimized data span algorithm in this case
            % since it will remove all merged cells on the boundaries
            usedRangeStr = sheet.getDataSpan(mergedCellColumnRule, mergedCellRowRule);
        end
        if isempty(usedRangeStr)
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
    
    varchunks = [];
    missingIDs = logical.empty(0,numvars);
    errorIDs = logical.empty(0,numvars);

    dataRange = zeros(numRanges, 4);
    % find the datarange
    for i = 1 : numRanges
        range = convertStringsToChars(opts.DataRange(i,:));
        if iscell(range)
            range = range{:};
        elseif ~isscalar(range) && isnumeric(range)
            % replace inf with the end of the usedRange
            if any(isinf(range))
                range(2) = usedRange(1) + usedRange(3) - 1;
            end
            range = [num2str(range(1)),':',num2str(range(2))];
        end
        if numel(usedRange) > 2
            rowsToRequest = min(rowsToRequest,usedRange(3)-usedRange(1));
        end
        numVars = numel(opts.VariableNames);
        dataRange(i, :) = getDataRange(sheet,range,numVars,usedRange,rowsToRequest);
    end

    % get the number of header lines
    numHeaderLines = min(dataRange(:, 1))-1;
    if numHeaderLines < 0
        numHeaderLines = 0;
    end

    isGoogleSheet = sheet.is_format_gsheet();
    if isGoogleSheet
        % For Google Sheets, adjust the range interval to accommodate the
        % header lines. This allows making single Google query.
        removeHeaderLines = false;
        addedHeaderLines = false;
        if numHeaderLines > 0
            % add header lines to range so we add them to cache for Google
            % sheets
            dataRange(1, 1) = dataRange(1, 1) - numHeaderLines;
            removeHeaderLines = true;
        end

        if numRanges > 1
            % combine disparate DataRange intervals to make a single
            % Google query
            combinedRange = combinedDataRangeForGoogleSheet(dataRange, numRanges);
            if removeHeaderLines
                combinedRange(3) = combinedRange(3) + numHeaderLines;
                addedHeaderLines = true;
            end
            sheet.types(combinedRange);
        elseif ~any(dataRange(3:4) == 0)
            % don't make this call for empty data, will throw
            if removeHeaderLines
                % increment number of rows in dataRange to
                % accommodate header lines
                dataRange(3) = dataRange(3) + numHeaderLines;
                addedHeaderLines = true;
            end
            sheet.types(dataRange);
        end

        % Remove header lines from the range so further range-based
        % computations are correct
        if removeHeaderLines
            dataRange(1, 1) = dataRange(1, 1) + numHeaderLines;
            if addedHeaderLines
                dataRange(3) = dataRange(3) - numHeaderLines;
            end
        end
    end

    for i = 1 : numRanges
        varopts = getVarOptsStruct(opts,1:numVars);
        [vars,mIDs,eIDs] = readDataFromSheet(sheet, dataRange(i, :), varopts, selectedIDs, ...
            mergedCellColumnRule, mergedCellRowRule, numHeaderLines);

        % omit variables based on merging rules
        if mergedCellRowRule == "omitvar"
            remainingVars = ~cellfun(@isempty, vars);
            vars = vars(remainingVars);
            mIDs = mIDs(:, remainingVars);
            eIDs = eIDs(:, remainingVars);
            selectedIDs = selectedIDs(remainingVars);
        end

        varchunks = [varchunks; vars]; %#ok<AGROW>
        missingIDs = [missingIDs; mIDs]; %#ok<AGROW>
        errorIDs = [errorIDs; eIDs]; %#ok<AGROW>
    end
    if numRanges == 0
        dataRange = '';
    end
    numvars = size(vars,2);
    variables = cell(0,numvars);
    % clean up variables
    for i = 1:numvars
        variables{i} = vertcat(varchunks{:,i});
    end

end

function dataRange = getDataRange(sheet,dataloc,numVars,usedRange,rowsToRequest)
    if isempty(usedRange)
        usedRange = [1 1 0 0];  
    end
    
    if isempty(dataloc)
        dataRange = [1 1 0 0];
    else
        if isnumeric(dataloc) && isscalar(dataloc)
            % dataloc = Row/Column number
            usedRange(1) = dataloc; % first row
            dataRange = matlab.io.spreadsheet.internal.subRange(usedRange,[1 numVars]);
        else
            if usedRange(3) < rowsToRequest
                % get more rows
                usedRange(3) = usedRange(1) + rowsToRequest - 1;
            end
            [dataRange,type] = sheet.getRange(dataloc,false);
            switch (type)
                case 'single-cell'
                    % Start cell, read numVars columns, and all the rows until the end range.
                    dataRange    = matlab.io.spreadsheet.internal.subRange(dataRange,[1 numVars]);
                    % get last usedRange row number
                    lastUsedRow  = usedRange(1) + usedRange(3) - 1;
                    % set the number of rows
                    dataRange(3) = lastUsedRow - dataRange(1) + 1;
                case 'row-only'
                    % Read numVars columns from the first column in the usedRange.
                    dataRange(2) = usedRange(2);
                    dataRange = matlab.io.spreadsheet.internal.subRange(dataRange,[1 numVars]);
                case 'column-only'
                    
                case 'named'
                    if dataRange(4) ~= numVars
                        error(message('MATLAB:spreadsheet:importoptions:VarNumberMismatch','DataRange'));
                    end
            end
        end
    end
    % if the used range is empty, then we may end up with negative values for
    % the extents [1 1 -1 -1]. Since this is invalid, we replace them with
    % zero.
    dataRange(dataRange < 0) = 0;
end
