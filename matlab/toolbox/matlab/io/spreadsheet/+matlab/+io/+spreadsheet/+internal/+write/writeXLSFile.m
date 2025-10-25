function writeXLSFile(inputTable, filename, ext, writeParams, args)
%WRITEXLSFILE Write a table to an Excel spreadsheet file.

%   Copyright 2012-2024 The MathWorks, Inc.
arguments
    inputTable (:, :) table;
    filename (1, :) char;
    ext (:, :) char;
    writeParams (1, 1) struct;

    % Name-Value pairs
    args.Sheet (1, :) {mustBeNumericOrString} = 1;
    args.Range (1, :) char {mustBeNonEmptyRange};
    args.DateLocale (1, :) char = 'system';
    args.UseExcel (1, 1) double = 0;
    args.Basic (1, 1) logical = true;
    args.AutoFitWidth (1, 1) logical = true;
    args.PreserveFormat (1, 1) logical = true;
end

isGoogleSheet = ext == "gsheet";

if isGoogleSheet
    % Existence check for Google Sheets happens in writetable. If the
    % Google spreadsheet did not exist, error would be thrown from
    % writetable itself and code would not reach here.
    fileExists = true;
else
    fileExists = isfile(filename);
    if fileExists && isfield(args, "Range") && writeParams.WriteMode == "append"
        error(message('MATLAB:table:write:AppendAndRange'))
    end
end

if ~isfield(args, "Range")
    args.Range = 'A1';
end

% Only write row names if asked to, and if they exist.
writeRowNames = (writeParams.WriteRowNames && ~isempty(inputTable.Properties.RowNames));

[book, args.PreserveFormat] = createWorkbook(filename, ext, args.UseExcel, ...
    args.Sheet, writeParams.WriteMode, fileExists, args.PreserveFormat);
if book.AreDates1904
    dateOrigin = '1904';
else
    dateOrigin = '1900';
end

% if WriteMode is overwritesheet, clear contents of sheet
if writeParams.WriteMode == "overwritesheet"
    [sheetObj, args.PreserveFormat] = overwriteSheetFromBook(book, ...
        args.Sheet, args.PreserveFormat);
else
    [sheetObj, args.PreserveFormat] = getSheetFromBook(book, args.Sheet, ...
        args.PreserveFormat);
    % use the status of WriteVariableNames based on return value from
    % getSheetFromBook, specifically for WriteMode append
end

if fileExists && writeParams.WriteMode == "append" && ~writeParams.SuppliedWriteVarNames
    % The default should be write var names only if there's nothing in the
    % sheet
    writeVarNames = isempty(sheetObj.usedRange);
else
    writeVarNames = writeParams.WriteVarNames;
end

parsedRange = parseRange(args.Range, sheetObj, inputTable);

% Determine the maximum number of columns we can write
if parsedRange.TruncateColumns
    maxCol = parsedRange.ColumnEnd;
else
    maxCol = Inf;
end

% How many rows are we supposed to write.
if parsedRange.TruncateRows && (parsedRange.RowEnd - parsedRange.RowStart + 1 <= size(inputTable,1))
    dataHeight = parsedRange.RowEnd - parsedRange.RowStart + 1 - writeVarNames;
else
    dataHeight = size(inputTable,1);
end

vars = cell(dataHeight + writeVarNames, 0);

% Write row names.
if writeRowNames
    rownames = inputTable.Properties.RowNames(1:dataHeight);
    if writeVarNames
        rownames = [inputTable.Properties.DimensionNames{1}; rownames];
    end
    vars = [vars rownames];
end

import matlab.internal.datatypes.matricize
import matlab.io.spreadsheet.internal.write.Datatypes;
cells = {};
typesMatrix = [];

colCount = parsedRange.ColumnStart;
varNames = inputTable.Properties.VariableNames;
varTypes = string(varfun(@class,inputTable,"OutputFormat","cell"));
for j = 1:size(inputTable,2)

    if colCount > maxCol, break; end

    varnamej = varNames{j};

    if dataHeight > 0
        varj = inputTable.(j);
        varj = extractVarChunk(varj, 1, dataHeight);
        if iscell(varj)
            % xlswrite cannot write out non-scalar-valued cells -- convert cell
            % variables to a cell of the appropriate width containing only
            % scalars.

            [nrows,ncols] = size(varj); % Treat N-D as 2-D
            cellCols = zeros(nrows,1);
            quotedStrings = 0;
            % check whether cell contains a cell array
            for iter = 1 : nrows
                if ~isempty(varj) && any(strcmpi(class(varj{iter}),{'cell','string'}))
                    % Error if the variable cell array contains empty
                    % elements
                    empties = cellfun(@isempty, varj{iter});
                    chars = strcmp(cellfun(@class,varj{iter},'UniformOutput',false),'char');
                    if any(empties&~chars)
                        error(message('MATLAB:table:write:NestedCellElementEmpty', varnamej));
                    end

                    [nrows_iter, ncols_iter] = size(varj{iter});
                    % Error if the table variable contains
                    % cell column vector values.
                    if nrows_iter > 1
                        error(message('MATLAB:table:write:CellColumnVectorsUnsupported', varnamej));
                    end
                    if ncols_iter > 1
                        % this is a cell array
                        cellCols(iter) = ncols_iter;
                        quotedStrings = 1;
                    end
                end
            end
            if any(quotedStrings)
                ncellColsj = max(unique(cellCols));
            else
                ncellColsj = max(cellfun(@ncolsCell,matricize(varj)),[],1);
            end

            newNumCols = sum(ncellColsj);
            newVarj = cell(dataHeight,newNumCols);
            if isGoogleSheet
                typesVarj = repmat(Datatypes.EMPTY, dataHeight, newNumCols);
            end

            % Expand out each column of varj into as many columns as needed to
            % have only scalar-valued cells, possibly padded with empty cells.
            cnt = 0;
            for jj = 1:ncols
                varjj = varj(:,jj);
                num = ncellColsj(jj);
                newVarjj = cell(dataHeight,num);
                if isGoogleSheet
                    typesVarjj = repmat(Datatypes.EMPTY, dataHeight, num);
                end
                for i = 1:dataHeight
                    % Expand each cell with non-scalar contents into a row of cells containing scalars
                    varjj_i = varjj{i};
                    if ischar(varjj_i)
                        % Put each string into its own cell.  If there are no
                        % strings (zero rows or zero pages in the original char
                        % array), the output will be a single empty cell.
                        vals = TransformToCellFromChar(varjj_i); % creates a 2-D cellstr
                        if isempty(vals), vals = {''}; end
                        thisType = Datatypes.CHAR;
                    elseif isstring(varjj_i)
                        vals = TransformToCellFromString(varjj_i);
                        thisType = Datatypes.STRING;
                    elseif isnumeric(varjj_i)
                        vals = TransformToCellFromNumeric(varjj_i);
                        thisType = Datatypes.DOUBLE;
                    elseif islogical(varjj_i)
                        vals = TransformToCellFromLogical(varjj_i);
                        thisType = Datatypes.LOGICAL;
                    elseif isa(varjj_i,'categorical')
                        vals = TransformToCellFromCategorical(varjj_i);
                        thisType = Datatypes.CATEGORICAL;
                    elseif isa(varjj_i,'duration') || isa(varjj_i,'calendarDuration')
                        vals = TransformToCellFromDuration(varjj_i, args.DateLocale, isGoogleSheet);
                        if isa(varjj_i,'duration')
                            thisType = Datatypes.DURATION;
                        else
                            thisType = Datatypes.CALENDARDURATION;
                        end
                    elseif isa(varjj_i,'datetime')
                        vals = TransformToCellFromDatetime(varjj_i, args.DateLocale, ...
                            dateOrigin, false);
                        thisType = Datatypes.DATETIME;
                    elseif isa(varjj_i,'cell')
                        vals = varjj_i;
                        thisType = Datatypes.CELL;
                    else
                        vals = cell(0,0); % write out only an empty cell
                        thisType = Datatypes.EMPTY;
                    end
                    newVarjj(i,1:numel(vals)) = vals(:)';

                    if isGoogleSheet
                        typesVarjj(i, 1:numel(vals)) = thisType(:)';
                    end
                end
                newVarj(:,cnt+(1:num)) = newVarjj;

                if isGoogleSheet
                    typesVarj(:, cnt + (1:num)) = typesVarjj;
                end
                cnt = cnt + num;
            end

            varj = newVarj;
        else
            [m, n] = size(varj);
            switch(varTypes(j))
                case "char"
                    varj = TransformToCellFromChar(varj);
                    if isGoogleSheet
                        typesVarj = repmat(Datatypes.CHAR, m, n);
                    end
                case "string"
                    varj = TransformToCellFromString(varj);
                    if isGoogleSheet
                        typesVarj = repmat(Datatypes.STRING, m, n);
                    end
                case "categorical"
                    varj = TransformToCellFromCategorical(matricize(varj));
                    if isGoogleSheet
                        typesVarj = repmat(Datatypes.CATEGORICAL, m, n);
                    end
                case {"duration","calendarDuration"}
                    varj = TransformToCellFromDuration(matricize(varj), args.DateLocale, isGoogleSheet);
                    if isGoogleSheet
                        if varTypes(j) == "duration"
                            typesVarj = repmat(Datatypes.DURATION, m, n);
                        else
                            typesVarj = repmat(Datatypes.CALENDARDURATION, m, n);
                        end
                    end
                case "datetime"
                    varj = TransformToCellFromDatetime(varj, args.DateLocale, ...
                        dateOrigin, true);
                    if isGoogleSheet
                        typesVarj = repmat(Datatypes.DATETIME, m, n);
                    end
                case "logical"
                    varj = TransformToCellFromLogical(matricize(varj));
                    if isGoogleSheet
                        typesVarj = repmat(Datatypes.LOGICAL, m, n);
                    end
                otherwise
                    if isa(varj,'tabular')
                        error(message('MATLAB:table:write:NestedTables'));
                    elseif isenum(varj)
                        varj = TransformToCellFromString(varj);
                        if isGoogleSheet
                            typesVarj = repmat(Datatypes.ENUM, m, n);
                        end
                    elseif isnumeric(varj)
                        varj = TransformToCellFromNumeric(varj);
                        if isGoogleSheet
                            typesVarj = repmat(Datatypes.DOUBLE, m, n);
                        end
                    else
                        varj = cell(dataHeight,1);
                        if isGoogleSheet
                            typesVarj = repmat(Datatypes.CELL, m, n);
                        end
                    end
            end
        end
    else
        varj = cell(0, 1);
    end

    [~,ncols] = size(varj); % Treat N-D as 2-D
    if writeVarNames
        if ncols > 1
            if isGoogleSheet
                typesVarj = [repmat(Datatypes.CHAR, 1, ncols); typesVarj]; %#ok<AGROW>
            end
            varj = [strcat({varnamej},'_',num2str((1:ncols)'))'; varj]; %#ok<AGROW>
        else
            if isGoogleSheet && ~isempty(inputTable)
                typesVarj = [Datatypes.CHAR; typesVarj]; %#ok<AGROW>
            end
            varj = [{varnamej}; varj]; %#ok<AGROW>
        end
    end
    vars = [vars varj]; %#ok<AGROW>
    colCount = colCount + ncols;
    % Appending the new columns to the existing data
    colsAppended = 1:size(vars,2);
    cells(:,end + colsAppended) = vars; %#ok<AGROW>
    vars = cell(dataHeight + writeVarNames,0);
    if isGoogleSheet && ~isempty(inputTable)
        typesMatrix = [typesMatrix, typesVarj]; %#ok<AGROW>
    end
end

% in case matricizing grew it beyond the bounds we care to write
[~, numCols] = size(cells);
if parsedRange.TruncateColumns
    endCol = min(parsedRange.ColumnEnd - parsedRange.ColumnStart + 1, numCols);
    cells = cells(:,1:endCol);
end

% validate the range by trying to get the range to write to. if it is
% beyond the edges, the call to getRange() will throw
try
    [hght, wdth] = size(cells);
    writeRng = [parsedRange.RowStart, parsedRange.ColumnStart, hght, wdth];
    if ~isempty(inputTable)
        sheetObj.getRange(writeRng);
    end
catch% only one thing could go wrong, we are using a numeric range
    throwTooBigForFormatError(book.Format, writeRng, filename);
end

% Prior to writing, unmerge all the cells in the range
% Writing to merged cells will drop the 2nd->Nth items in the range
% without error.
if ~isempty(inputTable)
    sheetObj.unmerge(writeRng);
end

try
    if isempty(inputTable)
        % don't write anything for Google Sheets when table contains no
        % data and no variable names
        if (isGoogleSheet && ~isempty(cells)) || ~isGoogleSheet
            sheetObj.write(cells, '', args.PreserveFormat);
        end
    else
        if writeParams.WriteMode == "append"
            % get the used range from the sheet
            usedSheetRange = sheetObj.usedRange;
            % if Range was not specified as an input parameter, append
            % to bottom of used range
            appendRange = getRangeToWrite(usedSheetRange);
            if isempty(appendRange)
                % when no range is specified and sheet being written to
                % is empty
                appendRange = args.Range;
            end
            % Get the numeric representation of the appended range
            numRange = sheetObj.getRange(appendRange, false);
            % create final range to write
            writeRng = [numRange(1), numRange(2), hght, wdth];
        end
        if any(typesMatrix(:) == Datatypes.DURATION)
            % only relevant for Google Sheets
            sheetObj.write(cells, writeRng, args.PreserveFormat, find(typesMatrix == Datatypes.DURATION)-1);
        else
            sheetObj.write(cells, writeRng, args.PreserveFormat);
        end
    end
catch ME
    if strcmp(ME.identifier, 'MATLAB:spreadsheet:sheet:failedWrite')
        error(message('MATLAB:table:write:FailedWrite', sheetObj.Name, book.getFileName));
    else
        throw(ME);
    end
end

if ~isempty(inputTable) && args.AutoFitWidth
    sheetObj.autoFitColumns(writeRng);
end

try
    book.save(filename);
catch ME
    if ispc && strcmp(ME.identifier, 'MATLAB:spreadsheet:book:save') ...
            && exist(filename, 'file')
        error(message('MATLAB:table:write:FileOpenInAnotherProcess', filename));
    else
        throw(ME);
    end
end

end % writeXLSFile function

%--------------------------------------------------------------------------
function str = TransformToCellFromString(str)
    str = cellstr(str);
end

%--------------------------------------------------------------------------
function cs = TransformToCellFromChar(c)
% Convert a char array to a cell array of strings, each cell containing a
% single string. Treat each row as a separate string, including rows in
% higher dims.

% Create a cellstr array the same size as the original char array (ignoring
% columns), except with trailing dimensions collapsed down to 2-D.
[n,~,d] = size(c); szOut = [n,d];

if isempty(c)
    % cellstr would converts any empty char to {''}.  Instead, preserve the
    % desired size.
    cs = repmat({''},szOut);
else
    % cellstr does not accept N-D char arrays, put pages as more rows.
    if ~ismatrix(c)
        c = permute(c,[2 1 3:ndims(c)]);
        c = reshape(c,size(c,1),[])';
    end
    cs = reshape(num2cell(c,2),szOut);
end
end

%--------------------------------------------------------------------------
function num = TransformToCellFromNumeric(num)
    if issparse(num)
        num = num2cell(full(num));
    else
        num = num2cell(real(num));
    end
end

%--------------------------------------------------------------------------
function logicalValue = TransformToCellFromLogical(logicalValue)
    logicalValue = num2cell(logicalValue);
end

%--------------------------------------------------------------------------
function categoricalValue = TransformToCellFromCategorical(categoricalValue)
    categoricalValue = strrep(cellstr(categoricalValue), '<undefined>', '');
end

%--------------------------------------------------------------------------
function dtValue = TransformToCellFromDatetime(dtValue, locale, dateOrigin, nonCell)
    if any(exceltime(dtValue, dateOrigin) < 0)
        if nonCell
            dtValue = matlab.internal.datatypes.matricize(dtValue);
        end
        dtValue = cellstr(dtValue, [], locale);
    else
        % datetimes are represented as complex numbers in C++. The
        % signals libmwspreadsheet that the data is a datetime and
        % should be treated as such.
        dtValue = arrayfun(@(x){complex(x,0)}, exceltime(dtValue));
    end
end

%--------------------------------------------------------------------------
function dValue = TransformToCellFromDuration(durationValue, locale, isGoogleSheet)
    if isGoogleSheet && isa(durationValue, "duration")
        % convert to cell array of durations
        dValue = num2cell(days(durationValue));
    else
        dValue = strrep(cellstr(durationValue, [], locale), 'NaN', '');
    end
end

%--------------------------------------------------------------------------
function sheetObj = handleOpenSheetNameError(book, sheet)
    % Add sheet with supplied name
    sheetObj = book.addSheet(sheet);
end

%--------------------------------------------------------------------------
function [sheetObj, preserveFormat] = overwriteSheetFromBook(book, sheet, preserveFormat)
try
    % get the original sheet from the workbook
    sheetObj = book.getSheet(sheet);
    sheetObj.clear();
catch ME
    % sheet does not exist, add new sheet
    if strcmp(ME.identifier, "MATLAB:spreadsheet:book:openSheetName")
        sheetObj = handleOpenSheetNameError(book, sheet);
        preserveFormat = false;
    elseif strcmp(ME.identifier, "MATLAB:spreadsheet:book:openSheetIndex")
        % Add a new sheet using Excel's sheet naming convention
        sheetObj = book.addSheet(['Sheet' num2str(sheet)], sheet);
        preserveFormat = false;
    else
        rethrow(ME);
    end
end
end

%--------------------------------------------------------------------------
function [sheetObj, preserveFormat] = getSheetFromBook(book, sheet, ...
    preserveFormat)
import matlab.lang.makeUniqueStrings;
try
    scalarSheetNames = isscalar(book.SheetNames);
    isSheetIndexMatch = isnumeric(sheet) && book.loadedSheetIndex() == sheet;
    isSheetNameMatch = ~isnumeric(sheet) && any(sheet == book.SheetNames);
    % For the performance optimization of loading a single sheet, we need
    % to determine that the input sheet index matches the sheet of interest,
    % or the sheet name matches the loaded sheet. In the case that sheet
    % name or sheet index is provided as input but does not yet exist,
    % we would write to the wrong sheet if we simply perform the scalar
    % sheetnames check.
    if scalarSheetNames && (isSheetNameMatch || isSheetIndexMatch)
        % performance optimization - only sheet of interest is loaded
        sheetObj = book.getSheet(1);
    else
        % entire workbook is loaded
        sheetObj = book.getSheet(sheet);
    end
catch ME
    if strcmp(ME.identifier, 'MATLAB:spreadsheet:book:openSheetName')
        sheetObj = handleOpenSheetNameError(book, sheet);
        preserveFormat = false;
    elseif strcmp(ME.identifier, 'MATLAB:spreadsheet:book:openSheetIndex')
        % Add blank sheets leading up to the index specified.
        sheetNames = book.SheetNames;
        nSheets = numel(sheetNames);
        blanksToAdd = sheet - nSheets - 1;

        % If blanksToAdd <= 0, we do nothing
        for i = 1:blanksToAdd
            sheetNum = nSheets + i;
            % Blank sheets to be added should have unique sheet names
            uniqueSheetName = makeUniqueStrings(compose("Sheet%d", ...
                sheetNum), sheetNames);
            book.addSheet(char(uniqueSheetName), sheetNum);
        end

        % Add a new sheet using Excel's sheet naming convention at the
        % specified index.
        sheetNameToAdd = ['Sheet' num2str(sheet)];
        if any(sheetNameToAdd == sheetNames)
            % get a unique sheet name since the constructed sheet name
            % already exists
            uniqueSheetNameToAdd = makeUniqueStrings(sheetNameToAdd, sheetNames);
        else
            uniqueSheetNameToAdd = sheetNameToAdd;
        end
        sheetObj = book.addSheet(char(uniqueSheetNameToAdd), sheet);
        preserveFormat = false;
        oldState = warning('off','backtrace');
        % Use the same warning xlswrite does.
        warning(message('MATLAB:xlswrite:AddSheet'));
        warning(oldState);
    else
        rethrow(ME);
    end
end
end

%--------------------------------------------------------------------------
function parsedRange = parseRange(range, sheet, t)
% Transform the range into one we can parse using the spreadsheet
% library.
try
    if ~ischar(range)
        % Only accept non-numeric ranges
        error(message('MATLAB:table:write:InvalidRange'));
    end

    % Get the numeric representation of the range, and the range type.
    [numRange, rangetype] = sheet.getRange(range, false);

    % Assign output variables.
    parsedRange.RowStart = numRange(1);
    parsedRange.ColumnStart = numRange(2);
    parsedRange.RowEnd = parsedRange.RowStart + numRange(3) - 1;
    parsedRange.ColumnEnd = parsedRange.ColumnStart + numRange(4) - 1;

    switch rangetype
        case {'two-corner', 'named'}
            parsedRange.TruncateColumns = true;
            parsedRange.TruncateRows = true;
        case 'single-cell'
            parsedRange.TruncateColumns = false;
            parsedRange.TruncateRows = false;
        case 'column-only'
            parsedRange.RowStart = 1;
            parsedRange.RowEnd = size(t,1);
            parsedRange.TruncateColumns = true;
            parsedRange.TruncateRows = false;
        case 'row-only'
            parsedRange.ColumnStart = 1;
            parsedRange.ColumnEnd = size(t,2);
            parsedRange.TruncateColumns = false;
            parsedRange.TruncateRows = true;
        otherwise
            parsedRange.TruncateColumns = true;
            parsedRange.TruncateRows = true;
    end

catch ME
    if strcmp(ME.identifier, 'MATLAB:spreadsheet:sheet:rangeParseInvalid')
        % Throw our own range validation error.
        error(message('MATLAB:table:write:InvalidRange'));
    else
        % If we get an unexpected error, rethrow it.
        rethrow(ME);
    end
end
end

%--------------------------------------------------------------------------
function [book, preserveFormat] = createWorkbook(filename, ext, sheetType, sheetName, ...
    writeMode, fileExists, preserveFormat)
% If the workbook exists, open it.  Otherwise create a new workbook.
import matlab.io.spreadsheet.internal.createWorkbook;
if writeMode ~= "replacefile" && fileExists
    try
        if any(ext == ["xlsx", "xlsm", "xltx", "xltm"])
            % performance optimization is applicable to all Excel files
            % that are XML-based.
            book = createWorkbook(ext, filename, sheetType, sheetName, ...
                false, [], true);
        else
            book = createWorkbook(ext, filename, sheetType);
        end
    catch ME
        if ME.identifier == "MATLAB:spreadsheet:book:fileOpen"
            % The file exists but is invalid or encrypted with a password.
            error(message('MATLAB:table:write:CorruptOrEncrypted', filename));
        elseif ME.identifier == "MATLAB:spreadsheet:book:openSheetName"
            % load entire book since sheet was not found, error later
            book = createWorkbook(ext, filename, sheetType);
        else
            throw(ME);
        end
    end
else
    if ext == "gsheet"
        % don't create a new Google spreadsheet, it must exist already
        book = createWorkbook(ext, filename, sheetType, 1, false);
        allSheetNames = book.SheetNames;

        % We differentiate Sheet provided as an index vs string. For the
        % string case, we need to check whether a sheet with that name
        % exists. If so, clear that sheet and remove all other sheets. If
        % not, add sheet with that name and remove all other sheets. For
        % numeric case, remove all sheets except the first sheet. If first
        % sheet is named Sheet1, clear the sheet. If not, add a sheet named
        % Sheet1 and then remove the first sheet.
        if isnumeric(sheetName)
            % remove sheets from the end leaving behind the first sheet --
            % cannot remove all sheets, Google Sheets will throw an
            % exception
            for ii = numel(allSheetNames) : -1 : 2
                book.removeSheet(char(allSheetNames(ii)));
            end

            if allSheetNames(1) == "Sheet1"
                % if name of first sheet is Sheet1, clear contents of sheet
                sheet1 = book.getSheet(1);
                sheet1.clear();
            else
                % if name of first sheet is not Sheet1, add a new sheet
                % named Sheet1 and remove the first sheet
                book.addSheet('Sheet1');
                book.removeSheet(char(allSheetNames(1)));
                preserveFormat = false;
            end
        else
            % for named sheet, check if already exists. If exists, remove
            % all other sheets. If does not exist, first add this new sheet,
            % then remove all other sheets.
            if ~any(allSheetNames == sheetName)
                book.addSheet(sheetName);
                preserveFormat = false;
            end

            % remove sheets from the end, new sheet is not part of original
            % list of sheet names so won't be removed
            for ii = numel(allSheetNames) : -1 : 1
                if allSheetNames(ii) == sheetName
                    book.getSheet(ii).clear();
                else
                    book.removeSheet(char(allSheetNames(ii)));
                end
            end
        end
    else
        % The file doesn't exist so we need to create one. By default Sheet1 is present.
        book = createWorkbook(ext, [], sheetType, sheetName);
        % If a sheet name is provided and is not called 'Sheet1',
        % replace the default 'Sheet1' with user provided sheet name.
        sheetOne = book.SheetNames(1);
        if ischar(sheetName) && ~strcmp(sheetName,sheetOne)
            book.addSheet(sheetName,1);
            book.removeSheet(2);
        end
    end
end
end

%--------------------------------------------------------------------------
function m = ncolsCell(c)
% How many columns will be needed to write out the contents of a cell?
if ischar(c)
    % Treat each row as a separate string, including rows in higher dims.
    [n,~,d] = size(c);
    % Each string gets one "column".  Zero rows (no strings) gets a single
    % column to contain the empty string, even for N-D,.  In particular,
    % '' gets one column.
    m = max(n*d,1);
elseif isnumeric(c) || islogical(c) || isa(c,'categorical') || isduration(c)
    m = max(numel(c),1); % always write out at least one empty field
else
    m = 1; % other types are written as an empty field
end
end

%--------------------------------------------------------------------------
function varChunk = extractVarChunk(var, rowStart, rowFinish)
% A chunked version of matlab.internal.datatypes.matricize
if ischar(var)
    varChunk = var(rowStart:rowFinish, :, :);
    [n,m,d] = size(varChunk);
    if d > 1
        % Convert the N-D char into an N*DxM "column" of char rows.
        varChunk = permute(varChunk,[1 3:ndims(varChunk) 2]);
        varChunk = reshape(varChunk,[n*d,m]);
    end
    % Convert the column of char rows to an N*Dx1 cellstr and reshape to NxD.
    varChunk = reshape(num2cell(varChunk,2), [n d]);
else % 2D indexing automatically 'matricize' ND non-char arrays
    varChunk = var(rowStart:rowFinish, :);
end
end

%--------------------------------------------------------------------------
function throwTooBigForFormatError(fmt, writerng, spreadsheetId)
% We only care about the size limits of the given format. We don't want
% to start Excel, so if the format is XLSB, use XLSX since they are the
% same size.
if strcmpi(fmt, 'xlsb')
    fmt = 'xlsx';
end
% create a non-interactive book
if fmt == "GSHEET"
    b = matlab.io.spreadsheet.internal.createWorkbook(fmt, spreadsheetId, 2);
else
    b = matlab.io.spreadsheet.internal.createWorkbook(fmt, [], 0);
end
s = b.getSheet(1);

maxColsRange = s.getRange('1:1', false);
maxRowsRange = s.getRange('A:A', false);
maxrange = [maxRowsRange(3), maxColsRange(4)];
writerngRC = writerng(1:2) + writerng(3:4) - 1;

exceedsByRC = max(writerngRC - maxrange, [0 0]);

writeStartCell = s.getRange([writerng(1) writerng(2) 1 1]);
error(message('MATLAB:table:write:DataExceedsSheetBounds', writeStartCell, exceedsByRC(1), exceedsByRC(2)));
end

%--------------------------------------------------------------------------
function rangeVal = getRangeToWrite(sheetWrittenRange)
% This function takes a range of the form Corner1:Corner2 (e.g. A1:F18) and
% returns the first cell from where to begin appending (e.g. A19)
if ~isempty(sheetWrittenRange)
    % separate out the range to get where to begin writing next
    startRow = extractBefore(sheetWrittenRange,":");
    startNumInRow = strfind(startRow, digitsPattern);
    startRow = startRow(1 : startNumInRow(1) - 1);
    endCol = extractAfter(sheetWrittenRange,":");
    startNumInRow = strfind(endCol, digitsPattern);
    endCol = str2double(endCol(startNumInRow(1) : end)) + 1;
    rangeVal = char(sprintf("%s%d",startRow,endCol));
else
    rangeVal = [];
end
end

%--------------------------------------------------------------------------
% Input validators
function mustBeNumericOrString(sheet)
    if ~isa(sheet, "string") && ~isa(sheet, "numeric") && ~isa(sheet, "char")
        error(message("MATLAB:spreadsheet:book:invalidSheetSpec"));
    end
end

function mustBeNonEmptyRange(range)
    if isempty(range) || range  == ""
        error(message('MATLAB:table:write:InvalidRange'));
    end
end
