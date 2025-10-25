function [data,types] = readSpreadsheetMatrix(sheet,opts,args)
%READSPREADSHEETMATRIX reads a spreadsheet file according to the import options

% Copyright 2016-2024 The MathWorks, Inc.

    import matlab.io.internal.handleReplacement

    params = parseArguments(args);

    if ~isempty(params.Sheet)
        opts.Sheet = params.Sheet;
    end

    [~,selectedIDs] = ismember(opts.SelectedVariableNames',opts.VariableNames);

    % DATARANGE
    [data,errorIDs,missingIDs,dataRanges] = handleDataRange(selectedIDs, ...
        opts, sheet, params.Preview, params.UseExcel);
    varOpts = getVarOptsStruct(opts,selectedIDs);
    [data,omitVars,omitRecords] = handleReplacement(data,varOpts,opts.ImportErrorRule,opts.MissingRule,errorIDs,missingIDs);

    if nargout == 2
        if ~isempty(data)
            % numRanges will be greater than 1 if and only if
            % the DataRange supplied was specified as a N-by-2 array
            % containing N different row ranges.
            numRanges = size(dataRanges, 1);

            % precompute the types matrix size
            numRows = sum(dataRanges(:, 3), 'all');

            numCols = dataRanges(1, 4);
            types = zeros(numRows, numCols, 'uint8');

            startIdx = 1;
            for i = 1:numRanges
                endIdx = dataRanges(i, 3) + startIdx - 1;
                types(startIdx:endIdx, :) = sheet.types(dataRanges(i, :));
                startIdx = endIdx + 1;
            end
            types = types(:,selectedIDs);

            % Remove omitted variables
            if any(omitVars)
                types(:,omitVars) = [];
            end
            % handle omit-records
            if any(omitRecords)
                types(omitRecords,:) = [];
            end
        else
            types = [];
        end
    end
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
        parser.addParameter('MergedCellColumnRule', 'placeleft', @(rhs)isstring(rhs) || ischar(rhs));
        parser.addParameter('MergedCellRowRule', 'placetop', @(rhs)isstring(rhs) || ischar(rhs));
    end

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

function [data, missingIDs, errorIDs] = readDataFromSheet(sheet, dataRange, ...
    varOpts, selectedVarIDs, mergedCellColumnRule, mergedCellRowRule, numHeaderLines)
    import matlab.io.spreadsheet.internal.subRange;
    import matlab.io.spreadsheet.internal.readSpreadsheetVariable;

    numVars = numel(selectedVarIDs);
    data = [];
    % dataRange fails when it has width or height of zero
    if numVars == 0 || any(dataRange(3:4) == 0)
        missingIDs = false(dataRange(3:4));
        errorIDs = missingIDs;
        return
    end
    % To read data, we want to turn get the two-corner version within the used
    % range.
    if mergedCellColumnRule ~= "placeleft" || mergedCellRowRule ~= "placetop"
        typeIDs = sheet.types(dataRange, mergedCellColumnRule, mergedCellRowRule, ...
            numHeaderLines);
    else
        typeIDs = sheet.types(dataRange);
    end
    blankIDs = (typeIDs(:,selectedVarIDs) == sheet.BLANK) | ...
        (typeIDs(:,selectedVarIDs) == sheet.EMPTY);
    errorIDs = (typeIDs(:,selectedVarIDs) == sheet.ERROR);
    missingIDs = false(size(errorIDs));

    % Get data from the correct column.
    i = selectedVarIDs(1);
    varRange = dataRange;
    [data, err, placeholder, typeIDVector] = readSpreadsheetVariable(...
        varOpts{i}.Type, varOpts{i}, sheet, varRange, typeIDs(:,:), ...
        string(mergedCellColumnRule), string(mergedCellRowRule), false);
    missingIDs(placeholder) = true;
    if mergedCellColumnRule ~= "placeleft" || mergedCellRowRule ~= "placetop"
        % In readSpreadsheetVariable, all rows that are to be omitted are
        % marked as Inf, which translates to 255 for uint8
        [omittedRows, ~] = find(typeIDVector == 255);
        % remove the omitted rows from the data
        data(omittedRows, :) = [];
        % remove omitted rows from missing, error, blank, and placeholder matrices
        missingIDs(omittedRows, :) = [];
        errorIDs(omittedRows, :) = [];
        blankIDs = (typeIDVector == sheet.BLANK) | (typeIDVector == sheet.EMPTY);
        blankIDs(omittedRows, :) = [];
        err(omittedRows, :) = [];
        placeholder(omittedRows, :) = [];
    end
    if strcmp(varOpts{i}.EmptyFieldRule,'error')
        errorIDs(blankIDs) = true;
    elseif strcmp(varOpts{i}.EmptyFieldRule,'missing')
        missingIDs(blankIDs) = true;
    end
    err(placeholder) = false;
    err = err(:,selectedVarIDs);
    errorIDs(err) = true;
    if ~isempty(data) && size(data,2) >= numel(selectedVarIDs)
        data = data(:,selectedVarIDs);
    end
end

function [data,errorIDs,missingIDs,dataRanges] = handleDataRange(selectedIDs, ...
    opts, sheet, rowsToRequest, useExcelFlag)
    import matlab.io.spreadsheet.internal.combinedDataRangeForGoogleSheet;
    numvars = numel(selectedIDs);
    numRanges = size(opts.DataRange,1);
    dataRanges = zeros(numRanges, 4);

    % Get the data range and remove headers and footers
    if(~useExcelFlag)
        if opts.MergedCellColumnRule ~= "placeleft" || opts.MergedCellRowRule ~= "placetop"
            % do not apply optimized data span algorithm in this case
            % since it will remove all merged cells on the boundaries
            usedRangeStr = sheet.getDataSpan(opts.MergedCellColumnRule, ...
                opts.MergedCellRowRule);
        else
            usedRangeStr = sheet.getDataSpan();
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
    if ~isempty(selectedIDs)
        varOpts = opts.VariableOptions(selectedIDs(1));
        switch varOpts.Type
            case 'string'
                varchunks = string.empty();
            case 'char'
                varchunks = cell.empty();
            case 'datetime'
                varchunks = datetime.empty();
            case 'duration'
                varchunks = duration.empty();
            case 'categorical'
                varchunks = categorical.empty();
            otherwise
                varchunks = cast([],opts.VariableOptions(selectedIDs(1)).Type);
        end
    else
        varchunks = [];
    end

    missingIDs = logical.empty(0,numvars);
    errorIDs = logical.empty(0,numvars);
    numVars = numel(opts.VariableNames);
    numHeaderLines = min(dataRanges(:, 1)) - 1;
    if numHeaderLines < 0
        numHeaderLines = 0;
    end

    dataRangeInitialized = false;
    if sheet.is_format_gsheet() && numRanges > 1
        for i = 1 : numRanges
            dataRanges(i, :) = matlab.io.spreadsheet.internal.getDataRange(sheet,...
                opts.DataRange(i, :), numVars, usedRange, rowsToRequest);
        end

        removeHeaderLines = false;
        addedHeaderLines = false;
        if numHeaderLines > 0
            % add header lines to range so we add them to cache for Google
            % sheets
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

        dataRangeInitialized = true;
    end

    % find the datarange
    for i = 1 : numRanges
        if ~dataRangeInitialized
            % Excel case
            dataRanges(i, :) = matlab.io.spreadsheet.internal.getDataRange(...
                sheet, opts.DataRange(i, :), numVars, usedRange, rowsToRequest);
        end
        varopts = getVarOptsStruct(opts,1:numVars);
        
        [vars, mIDs, eIDs] = readDataFromSheet(sheet, dataRanges(i, :), varopts, ...
            selectedIDs, opts.MergedCellColumnRule, opts.MergedCellRowRule, ...
            numHeaderLines);
        if iscategorical(vars)
            varchunks = categorical(varchunks,...
                categories(vars),...
                'Ordinal',isordinal(vars),...
                'Protected',isprotected(vars));
            varchunks = [varchunks; vars]; %#ok<AGROW>
        else
            varchunks = [varchunks; vars]; %#ok<AGROW>
        end
        missingIDs = [missingIDs; mIDs]; %#ok<AGROW>
        errorIDs = [errorIDs; eIDs]; %#ok<AGROW>
    end

    data = varchunks;
end
