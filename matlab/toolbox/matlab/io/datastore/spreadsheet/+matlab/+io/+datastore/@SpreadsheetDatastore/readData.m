function [data, info] = readData(ds)
%READDATA Read subset of data from a datastore.
%   T = READDATA(SSDS) reads some data from SSDS.
%   T is a table with variables governed by SSDS.SelectedVariableNames.
%   Number of rows in T is governed by SSDS.ReadSize.
%   read(SSDS) errors if there is no more data in TDS, and should be used
%   with hasdata(SSDS).
% 
%   [T,info] = READDATA(SSDS) also returns a structure with additional
%   information about SSDS. The fields of info are:
%       Filename     - Name of the file from which data was read.
%       FileSize     - Size of the file in bytes.
%       SheetNames   - Sheet names from which the data was read.
%       SheetNumbers - Sheet numbers from which the data was read.
%       NumDataRows  - Vector of number of rows read from each sheet.
%
%   Example:
%   --------
%      % Create a SpreadsheetDatastore
%      ssds = spreadsheetDatastore('airlinesmall_subset.xlsx')
%      % We are only interested in the Arrival Delay data
%      ssds.SelectedVariableNames = 'ArrDelay'
%      % Preview the first 8 rows of the data as a table
%      tab8 = preview(ssds)
%      % Sum the Arrival Delays
%      sumAD = 0;
%      ssds.ReadSize = 'sheet';
%      while hasdata(ssds)
%         tab = read(ssds);
%         data = tab.ArrDelay(~isnan(tab.ArrDelay)); % filter data
%         sumAD = sumAD + sum(data);
%      end
%      sumAD
%
%   See also - matlab.io.datastore.SpreadsheetDatastore, hasdata, readall, preview, reset.

%   Copyright 2015-2024 The MathWorks, Inc.

    % imports
    import matlab.io.spreadsheet.internal.createWorkbook;
    import matlab.io.datastore.SpreadsheetDatastore;
    import matlab.io.datastore.SplittableDatastore;

    % error early if no data is available
    if ~hasdata(ds)
        error(message('MATLAB:datastoreio:splittabledatastore:noMoreData'));
    end
    
    % get data from splitreader if there is no data already available to
    % convert
    if ~ds.IsDataAvailableToConvert
        % get data from the split reader
        [currFileName, ds.CurrInfo] = getNext(ds.SplitReader);

        % If the splitIdx is 1, then bookObject is created already
        % (in reset) so no need to create one
        if ds.SplitIdx ~= 1 || isempty(ds.BookObject)
            % cache previous book, sheet and rangeVector
            prevBookObj = ds.BookObject;

            % create a book, sheet object from the current file name
            try
                fmt = matlab.io.spreadsheet.internal.getExtension(currFileName);
                if fmt == "gsheet"
                    currFileName = matlab.io.internal.common.validators.extractGoogleSheetIDFromURL(currFileName);
                    ds.BookObject = createWorkbook(fmt, currFileName, 2, 1);
                else
                    ds.BookObject = createWorkbook(fmt, currFileName);
                end
            catch ME
                [data, info] = matlab.io.datastore.FileBasedDatastore.errorHandlerRoutine(ds, ME);
                if isa(data,'MException')
                    % restore previous results
                    ds.BookObject = prevBookObj;
                    throwAsCaller(data);
                end
                return;
            end
            ds.IsFirstFileBook = false;
        end
        % set datastore state properties
        ds.SheetsToReadIdx = 1;
        ds.IsDataAvailableToConvert = true;
        ds.NumRowsAvailableInSheet = 0;
    end
    
    % set-up info
    ds.CurrInfo = setUpInfo(ds.CurrInfo);
    
    % call the appropriate method based on ReadSize.
    try
        if isnumeric(ds.ReadSize)
            [data, info] = readRows(ds);
        elseif strcmp(ds.ReadSize, SpreadsheetDatastore.READSIZE_FILE)
            [data, info] = readFile(ds);
        else
            [data, info] = readSheets(ds);
        end
        data = ds.convertReadData(data);
    catch ME
        if strcmpi(ds.ReadFailureRule,'skipfile') && ~isempty(ds.SplitReader.Split)
            data = matlab.io.datastore.TabularDatastore.emptyTabularWithVarTypes(...
                ds, ds.SelectedVariableNames, ds.TextType);
            info = struct('Filename',ds.SplitReader.Split.Filename,'FileSize', ...
                ds.SplitReader.Split.FileSize);
            info = setUpInfo(info);
            [~,splitIdx] = ismember(ds.SplitReader.Split.Filename, ds.Files);
            ds.PrivateReadFailuresList(splitIdx) = 1;
            if (ds.MaxFailures > 1 && sum(ds.PrivateReadFailuresList) > ds.MaxFailures) ...
                || (sum(ds.PrivateReadFailuresList) > numel(ds.Files)*ds.MaxFailures)
                error(message('MATLAB:datastoreio:filebaseddatastore:maxErrorsExceeded'));
            end
            if ds.SplitReader.Split.FileIndex < numel(ds.Files)
                ds.moveToSplit(splitIdx+1);
            else
                ds.SplitReader.Split = [];
                ds.IsDataAvailableToConvert = 0;
            end
        else
            % restore previous results
            throwAsCaller(ME);
        end
    end
    % convert variables to string datatype
    if ~isempty(data)
        for ii = 1 : numel(data.Properties.VariableNames)
            if strcmpi(ds.VariableTypes{ds.SelectedVariableNamesIdx(ii)},'string')
                varName = data.Properties.VariableNames{ii};
                if ~isa(data.(varName),'string')
                    data.(varName) = string(data.(varName));
                end
            end
        end
    end
end

function [data, info] = readSheets(ds)
%READSHEETS reads sheet worth of data from the current split.

    % imports
    import matlab.io.datastore.SpreadsheetDatastore;

    % setup the book object and the sheets to read
    bookObj = ds.BookObject;
    sheetsToRead = getSheetsToRead(bookObj, ds.Sheets);
    sheetsToReadIdx = ds.SheetsToReadIdx;
    
    % get the sheet info based on the sheet number to read from
    [ds.SheetObject, sheetName, sheetNumber] = getCurrSheetInfo(bookObj, sheetsToRead, sheetsToReadIdx);
    ds.RangeVector = SpreadsheetDatastore.getRangeVector(ds.SheetObject, ds.Range);
    
    % handle empty sheets
    if ~isempty(ds.RangeVector)
        ds.CurrRangeVector = ds.RangeVector + [ds.NumHeaderLines + ds.ReadVariableNames 0 ...
                                              -ds.NumHeaderLines - ds.ReadVariableNames 0];
    else
        ds.CurrRangeVector = [];
    end
    
    % empty sheets/ 0 row ranges just return an empty table
    if isempty(ds.CurrRangeVector) || (ds.CurrRangeVector(3) == 0)
        data = table;
    else
        data = convertReaderData(ds);
    end
    
    % update the info
    info = ds.CurrInfo;
    info.SheetNames{end+1} = sheetName;
    info.SheetNumbers(end+1) = sheetNumber;
    info.NumDataRows(end+1) = size(data,1);
    
    % update the sheets to read index
    sheetsToReadIdx = sheetsToReadIdx + 1;
    
    % is more data available to convert
    if sheetsToReadIdx <= numel(sheetsToRead)
        ds.IsDataAvailableToConvert = true;
    else
        ds.IsDataAvailableToConvert = false;
    end
    
    % update the SheetsToReadIdx property for use in the next read
    ds.SheetsToReadIdx = sheetsToReadIdx;
end

function [data, info] = readFile(ds)
%READFILE reads file worth of data from the current split.

    % imports
    import matlab.io.datastore.SpreadsheetDatastore;
    import matlab.io.spreadsheet.internal.createWorkbook;
    import matlab.io.internal.vfs.stream.RemoteToLocal;
    import matlab.io.internal.common.validators.isGoogleSheet;
    import matlab.io.internal.common.validators.extractGoogleSheetIDFromURL;

    % setup the book object and the sheets to read
    if ~isEmptyFiles(ds) && ~ds.IsFirstFileBook
        if isGoogleSheet(ds.SplitReader.Split.Filename)
            fileName = extractGoogleSheetIDFromURL(ds.SplitReader.Split.Filename);
            bookObj = createWorkbook('gsheet', fileName, 2, 1);
        else
            rtlObject = RemoteToLocal(ds.SplitReader.Split.Filename);
            fileName = rtlObject.LocalFileName;
            fmt = matlab.io.spreadsheet.internal.getExtension(fileName);
            bookObj = createWorkbook(fmt, fileName);
        end
        ds.BookObject = bookObj;
    else
        bookObj = ds.BookObject;
    end
    sheetsToRead = getSheetsToRead(bookObj, ds.Sheets);
    sheetsToReadIdx = ds.SheetsToReadIdx;
    info = ds.CurrInfo;
    
    % set up the output data
    tblCells = cell(1, numel(sheetsToRead));
    
    while sheetsToReadIdx <= numel(sheetsToRead)
        
        % get the sheet info and the range vector
        [ds.SheetObject, sheetName, sheetNumber] = getCurrSheetInfo(bookObj, sheetsToRead, sheetsToReadIdx);
        ds.RangeVector = SpreadsheetDatastore.getRangeVector(ds.SheetObject, ds.Range);
        
        % handle empty sheets
        if ~isempty(ds.RangeVector)
            ds.CurrRangeVector = ds.RangeVector + [ds.NumHeaderLines + ds.ReadVariableNames 0 ...
                                                  -ds.NumHeaderLines - ds.ReadVariableNames 0];
        else
            ds.CurrRangeVector = [];
        end
        
         % empty sheets/ 0 row ranges just return an empty table
         if isempty(ds.CurrRangeVector) || (ds.CurrRangeVector(3) == 0)
             tblCells{sheetsToReadIdx} = table;
         else
             tblCells{sheetsToReadIdx} = convertReaderData(ds);
         end
         
         % update info
         info.SheetNames{end+1} = sheetName;
         info.SheetNumbers(end+1) = sheetNumber;
         info.NumDataRows(end+1) = size(tblCells{sheetsToReadIdx},1);
         
         % update the SheetsToReadIdx property for use in the next read
         sheetsToReadIdx = sheetsToReadIdx + 1;
         ds.SheetsToReadIdx = sheetsToReadIdx;
    end
    
    % aggregate data
    data = vertcat(tblCells{:});
    
    % no more data available in the current split to convert
    ds.IsDataAvailableToConvert = false;
end

function [data, info] = readRows(ds)
%READROWS reads up to the specified number of rows.
    
    % imports
    import matlab.io.datastore.SpreadsheetDatastore;
    
    % set-up the book object and the sheets to read
    bookObj = ds.BookObject;
    sheetsToRead = getSheetsToRead(bookObj, ds.Sheets);
    
    % local vars
    readSize = ds.ReadSize;
    numSheetsToRead = numel(sheetsToRead);
    tblCells = cell(1, numSheetsToRead);
    numRowsToRead = readSize;
    sheetsToReadIdx = ds.SheetsToReadIdx;
    info = ds.CurrInfo;
    
    while ds.IsDataAvailableToConvert && numRowsToRead > 0
        
        if ds.NumRowsAvailableInSheet == 0
            % get the sheet info and the range vector
            [ds.SheetObject, sheetName, sheetNumber] = getCurrSheetInfo(bookObj, sheetsToRead, sheetsToReadIdx);            
            ds.RangeVector = SpreadsheetDatastore.getRangeVector(ds.SheetObject, ds.Range);
            
            % handle empty sheets
            if ~isempty(ds.RangeVector)
                ds.CurrRangeVector = ds.RangeVector + [ds.NumHeaderLines + ds.ReadVariableNames 0 ...
                                                      -ds.NumHeaderLines - ds.ReadVariableNames 0];
                ds.NumRowsAvailableInSheet = ds.CurrRangeVector(3);
            else
                ds.CurrRangeVector = [];
                ds.NumRowsAvailableInSheet = 0;
            end
        else
            sheetName = ds.SheetObject.Name;
            [~,sheetNumber] = ismember(sheetName, bookObj.SheetNames);
        end
        
        % empty sheets/ 0 row ranges just return an empty table
         if isempty(ds.CurrRangeVector) || (ds.CurrRangeVector(3) == 0)
             tblCells{sheetsToReadIdx} = table;
         else
             tblCells{sheetsToReadIdx} = convertReaderData(ds, numRowsToRead);
         end
         
         % update numRowsToRead
         numRowsToRead = numRowsToRead - size(tblCells{sheetsToReadIdx},1);
         
         % update info
         info.SheetNames{end+1} = sheetName;
         info.SheetNumbers(end+1) = sheetNumber;
         info.NumDataRows(end+1) = size(tblCells{sheetsToReadIdx},1);
         
         if ds.NumRowsAvailableInSheet == 0
             sheetsToReadIdx = sheetsToReadIdx + 1;
         end
         
         if sheetsToReadIdx <= numSheetsToRead
             ds.IsDataAvailableToConvert = true;
         else
             ds.IsDataAvailableToConvert = false;
         end
         
         % update the SheetsToReadIdx property for use in the next read
         ds.SheetsToReadIdx = sheetsToReadIdx;
    end
    
    % aggregate data
    data = vertcat(tblCells{:});
end

function sheetsToRead = getSheetsToRead(bookObj, sheetsToRead)
%GETSHEETSTOREAD gets the sheets to read. It returns sheetsToRead as is
%unless it is empty or a string. For an empty string it returns the sheet
%names in the current split. For a non-empty string it converts it into a
%cellstr.

    % imports
    import matlab.io.internal.validators.isCharVector;

    % '' indicates all the sheets in the current split which can be
    % different across splits, convert a string into a cellstr here for
    % easy update of info in the read methods.
    if isCharVector(sheetsToRead) 
        if isempty(sheetsToRead)
            sheetsToRead = bookObj.SheetNames;
        else
            sheetsToRead = {sheetsToRead};
        end
    end
end

function [sheetObject, sheetName, sheetNumber] = getCurrSheetInfo(bookObj, sheetsToRead, sheetsToReadIdx)
%GETSHEETINFO returns the sheet information based on the book object, the
%sheets to read and the sheet to read index

    if isnumeric(sheetsToRead)
        sheetNumber = sheetsToRead(sheetsToReadIdx);
        sheetName = bookObj.SheetNames{sheetNumber};
        sheetObject = bookObj.getSheet(sheetNumber);
    else
        sheetName = sheetsToRead{sheetsToReadIdx};
        [~,sheetNumber] = ismember(sheetName, bookObj.SheetNames);
        sheetObject = bookObj.getSheet(sheetName);
    end
end

function info = setUpInfo(info)
%SETUPINFO set up info struct for the read method

    info.SheetNames = {};
    info.SheetNumbers = [];
    info.NumDataRows = [];
end
