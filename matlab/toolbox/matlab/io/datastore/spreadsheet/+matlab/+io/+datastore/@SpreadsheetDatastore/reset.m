function reset(ds)
%RESET Reset the SpreadsheetDatastore to the start of the data.
%   RESET(SSDS) resets SSDS to the beginning of the datastore.
%
%   Example:
%   --------
%      % Create a SpreadsheetDatastore
%      ssds = spreadsheetDatastore('airlinesmall_subset.xlsx')
%      % We are only interested in the Arrival Delay data
%      ssds.SelectedVariableNames = 'ArrDelay'
%      ssds.ReadSize = 'sheet';
%      [tab,info] = read(ssds);
%      % Since reading from the datastore above affected the state
%      % of ssds, reset to the beginning of the datastore:
%      reset(ssds)
%      % Sum the Arrival Delays
%      sumAD = 0;
%      while hasdata(ssds)
%         tab = read(ssds);
%         data = tab.ArrDelay(~isnan(tab.ArrDelay)); % filter data
%         sumAD = sumAD + sum(data);
%      end
%      sumAD
%
%   See also - matlab.io.datastore.SpreadsheetDatastore, read, readall, hasdata, preview.

%   Copyright 2015-2024 The MathWorks, Inc.

    import matlab.io.datastore.SpreadsheetDatastore;
    import matlab.io.spreadsheet.internal.createWorkbook;

    try
        reset@matlab.io.datastore.FileBasedDatastore(ds);
    catch ME
        throw(ME);
    end

    % reset the sheets to read index and set state to signify that there is
    % no data available to convert.
    ds.SheetsToReadIdx = 1;
    ds.IsDataAvailableToConvert = false;
    ds.NumRowsAvailableInSheet = 0;
    % Create a BookObject and SheetObject from the first file
    if ~isEmptyFiles(ds) && ~ds.IsFirstFileBook
        fileName = getFirstFileName(ds);
        fmt = matlab.io.spreadsheet.internal.getExtension(fileName);

        % set up book, sheet and range using the first file
        if fmt == "gsheet"
            fileName = matlab.io.internal.common.validators.extractGoogleSheetIDFromURL(fileName);
            ds.BookObject = createWorkbook(fmt, fileName, 2, 1);
        else
            ds.BookObject = createWorkbook(fmt, fileName);
        end
        ds.SheetObject = SpreadsheetDatastore.getSheetObject(ds.BookObject, ds.Sheets);
    
        % RangeVector corresponds to the Range of all the data in the
        % current File.
        ds.RangeVector = SpreadsheetDatastore.getRangeVector(ds.SheetObject, ds.Range);

        % No need to create BookObject unless a new BookObject for first file is needed
        % after reading from a different file
        ds.IsFirstFileBook = true;
    end
end
