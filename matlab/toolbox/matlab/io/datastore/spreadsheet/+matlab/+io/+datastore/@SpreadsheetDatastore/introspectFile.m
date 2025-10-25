function introspectFile(ds)
%INTROSPECTFILE Setup variable names and format information.
%   This function is responsible for setting up VariableNames,
%   VariableTypes, SelectedVariableNames and SelectedVariableTypes.

%   Copyright 2015-2024 The MathWorks, Inc.

    % imports
    import matlab.internal.datatypes.warningWithoutTrace;

    % early return if files are empty
    if isempty(ds.Files)
        % set properties of the empty datastore that were removed in
        % initSheetProperties
        datastorePropSetter(ds,ds.PrivateSheetFormatInfo);
        return;
    end

    % variable name and format information as passed by the user during
    % datastore construction. These are always cellstrs.
    inStruct = ds.PrivateSheetFormatInfo;

    % detect variable names and variable types. Both always are returned as
    % cellstrs.    
    [varNames, varTypes] = readVarNamesTypes(ds, inStruct);

    % local vars
    allVarNames = inStruct.VariableNames;
    sVarNames = inStruct.SelectedVariableNames;
    sVarTypes = inStruct.SelectedVariableTypes;

    % when both ReadVariableNames is true and VariableNames are provided
    % the detected VariableNames are overwritten by the specified ones
    % after issuing a warning message.
    if ~isempty(allVarNames)

        % ReadVariableNames is true by default
        if ds.ReadVariableNames
            warningWithoutTrace(message('MATLAB:datastoreio:tabulartextdatastore:replaceReadVariableNames'));
        end

        % number of VariableNames and TextscanFormats must match
        if numel(allVarNames) ~= numel(varTypes)
            error(message('MATLAB:datastoreio:tabulartextdatastore:varFormatMismatch', ...
                                      'VariableNames', 'VariableTypes'));
        end

        varNames = allVarNames;
    end
    
    % make valid variable names based on the value of PreserveVariableNames
    validVarNames = normalizeVariableNames(ds, varNames);

    % this is explicitly done so that the numel check happens in the actual
    % setters of VariableNames and VariableTypes and that they are in the
    % right state
    ds.PrivateVariableNames = validVarNames;
    ds.PrivateVariableTypes = varTypes;

    % final sets
    ds.VariableNames = validVarNames;
    ds.VariableTypes = varTypes;

    if isempty(sVarNames)
        if ~isempty(sVarTypes)
            % SelectedVariableTypes cannot be specified without
            % SelectedVariableNames
            error(message('MATLAB:datastoreio:spreadsheetdatastore:invalidSelectedVarTypes'));
        end
        ds.SelectedVariableNames = validVarNames;
    else
        % make the SelectedVariableNames valid differently based on VariableNamingRule.
        if ds.VariableNamingRule == "preserve"
            mode = 'warnLength';
        else
            mode = 'warn';
        end
        ds.SelectedVariableNames = matlab.internal.tabular.makeValidVariableNames(sVarNames, mode);
        
        % set SelectedVariableTyes if specified.
        if ~isempty(sVarTypes)
            ds.SelectedVariableTypes = sVarTypes;
        end
    end
    if ~isempty(inStruct.TextType)
        ds.TextType = inStruct.TextType;
    end
end

function [varNamesCell, matlabVarTypes] = readVarNamesTypes(ds, inStruct)
%readvarFormat detects variable names and variable types.

    % imports
    import matlab.io.datastore.SpreadsheetDatastore;
    import matlab.io.internal.validators.isCellOfCharVectors;
    import matlab.io.spreadsheet.internal.readSpreadsheetFile;
    import matlab.io.spreadsheet.internal.createWorkbook;

    % local variables
    hdrLines = ds.NumHeaderLines;
    readVarNames = ds.ReadVariableNames;

    % create book, sheet and range objects
    if ds.ConstructionDone % create using the first file
        fileName = getFirstFileName(ds);

        fmt = matlab.io.spreadsheet.internal.getExtension(fileName);

        % set up book, sheet and range using the first file
        if matlab.io.internal.common.validators.isGoogleSheet(fileName)
            fileName = matlab.io.internal.common.validators.extractGoogleSheetIDFromURL(fileName);
            sheetType = 2;
            bookObj = createWorkbook(fmt, fileName, sheetType, 1);
        else
            sheetType = 0;
            bookObj = createWorkbook(fmt, fileName, sheetType);
        end

        sheetObj = SpreadsheetDatastore.getSheetObject(bookObj, ds.Sheets);
        rangeVec = SpreadsheetDatastore.getRangeVector(sheetObj, ds.Range);
    else % use the already set up ones
        bookObj = ds.BookObject;
        sheetObj = ds.SheetObject;
        rangeVec = ds.RangeVector;
    end

    % empty Range
    if isempty(rangeVec)
        if readVarNames
            error(message('MATLAB:datastoreio:spreadsheetdatastore:emptyVarLine', sheetObj.Name, ds.Files{1}));
        else
            error(message('MATLAB:datastoreio:spreadsheetdatastore:emptyDataLine', sheetObj.Name, ds.Files{1}));
        end
    end

    % handle header lines and setup the range to read atmost 2 rows
    vnDataRange = rangeVec + [hdrLines 0 -hdrLines 0];
    % since we cache data when we query types for Google Sheets, don't
    % update the row count here in case of Google Sheets
    if ~sheetObj.is_format_gsheet()
        vnDataRange(3) = readVarNames + 1;
    end

    txtType = inStruct.TextType;
    if isempty(txtType)
        txtType = ds.TextType;
    end
    % setup the options structure.
    rdOpts = getBasicReadOpts(ds, bookObj, sheetObj, readVarNames, txtType);
    rdOpts.range = vnDataRange;

    % read atmost 2 rows
    out = readSpreadsheetFile(rdOpts);

    % block of code which detects VariableNames from the file.
    if readVarNames
        % extract the variable names
        varNamesCell = out.varNames;

        % there must be some data to detect variable names from.
        if all(cellfun(@(x) isempty(x), varNamesCell))
            error(message('MATLAB:datastoreio:spreadsheetdatastore:emptyVarLine', sheetObj.Name, ds.Files{1}));
        end
    end

    % struct fields
    matlabVarTypes = inStruct.VariableTypes;

    % varTypes empty means detect types from file.
    if isempty(matlabVarTypes)

        % extract the data line
        dataLine = out.variables;

        % there must be some data to detect variable types from.
        if all(cellfun(@(x) isempty(x), dataLine))
            error(message('MATLAB:datastoreio:spreadsheetdatastore:emptyDataLine', sheetObj.Name, ds.Files{1}));
        end

        % extract the data types based on the data line
        matlabVarTypes = convertDataToTypes(dataLine, ds.PrivateSheetFormatInfo.TextType);
    end

    % number of variables must be equal to the number of types
    if readVarNames
        if numel(varNamesCell) ~= numel(matlabVarTypes)
            error(message('MATLAB:datastoreio:spreadsheetdatastore:unequalVarnamesVarTypes'));
        end
    else
        varNamesCell = matlab.internal.tabular.defaultVariableNames(1:numel(matlabVarTypes));
    end

    % setup the datastores book, sheet and range objects if introspection
    % succeeeds
    if ds.ConstructionDone
        ds.BookObject = bookObj;
        ds.SheetObject = sheetObj;
        ds.RangeVector = rangeVec;
    end
end

function matlabVarTypes = convertDataToTypes(dataLine, textType)
%CONVERTDATATYTYPES detects data types from the data line. We do not
%support logicals.
    numTypes = numel(dataLine);
    matlabVarTypes = cell(1,numTypes);
    for i = 1:numTypes
        switch class(dataLine{i})
            case 'double'
                matlabVarTypes{i} = 'double';
            case 'datetime'
                matlabVarTypes{i} = 'datetime';
            case 'cell'
                %TODO: This is not needed. readSpreadsheetFile needs to return
                % a string array instead of a cell of string class.
                d = dataLine{i};
                if ~isempty(d)
                    if isa(d{1},'char')
                        matlabVarTypes{i} = textType;
                    else
                        matlabVarTypes{i} = class(d{1});
                    end
                else
                    matlabVarTypes{i} = 'char';
                end
            case 'string'
                matlabVarTypes{i} = 'string';
            otherwise
                matlabVarTypes{i} = 'char';
        end
    end
end

function datastorePropSetter(ds,inStruct)
%DATASTOREPROPSETTER sets the properties of the datastore that were removed
%in initSheetProperties, when the datastore is initialized without files.
ds.PrivateVariableNames = inStruct.VariableNames;
ds.PrivateVariableTypes = inStruct.VariableTypes;
ds.PrivateSelectedVariableNames = inStruct.SelectedVariableNames;
ds.PrivateSelectedVariableTypes = inStruct.SelectedVariableTypes;
end
