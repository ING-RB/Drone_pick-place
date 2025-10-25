function [var,errid,placeholder, typeIDs] = readSpreadsheetVariable(type, varopts, ...
    sheet, subrange, typeIDs, mergedCellColumnRule, mergedCellRowRule, returnEmptyVar)
%read a variable based on its type

%   Copyright 2019-2024 The MathWorks, Inc.
    arguments
        type (1, :) char;
        varopts
        sheet
        subrange
        typeIDs
    end
    arguments (Input, Repeating)
        mergedCellColumnRule (1, :) char;
        mergedCellRowRule (1, :) char;
        % returnEmptyVar is used to indicate whether variables to be
        % omitted are returned as empty from C++
        returnEmptyVar (1, 1) logical;
    end

    if isempty(mergedCellColumnRule)
        mergedCellColumnRule = {'placeleft'};
    end
    if isempty(mergedCellRowRule)
        mergedCellRowRule = {'placetop'};
    end
    if isempty(returnEmptyVar)
        returnEmptyVar = {false};
    end

    switch type
        case {'double','single','int8','uint8','int16','uint16','int32','uint32','int64','uint64'}
            %obj = matlab.io.NumericVariableImportOptions('Type',newType);
            [var, errid, placeholder, typeIDs] = readNumericSpreadsheetVariable(varopts, ...
                sheet, subrange, typeIDs, mergedCellColumnRule{1}, ...
                mergedCellRowRule{1}, returnEmptyVar{1});
        case {'char','string'}
            %obj = matlab.io.TextVariableImportOptions('Type',newType);
            [var, errid, placeholder, typeIDs] = readTextSpreadsheetVariable(varopts, ...
                sheet, subrange, typeIDs, mergedCellColumnRule{1}, ...
                mergedCellRowRule{1}, returnEmptyVar{1});
        case 'datetime'
            %obj = matlab.io.DatetimeVariableImportOptions();
            [var, errid, placeholder, typeIDs] = readDatetimeSpreadsheetVariable(varopts, ...
                sheet, subrange, typeIDs, mergedCellColumnRule{1}, ...
                mergedCellRowRule{1}, returnEmptyVar{1});
        case 'duration'
            %obj = matlab.io.DurationVariableImportOptions();
            [var, errid, placeholder, typeIDs] = readDurationSpreadsheetVariable(varopts, ...
                sheet, subrange, typeIDs, mergedCellColumnRule{1}, ...
                mergedCellRowRule{1}, returnEmptyVar{1});
        case 'categorical'
            %obj = matlab.io.CategoricalVariableImportOptions();
            [var, errid, placeholder, typeIDs] = readCategoricalSpreadsheetVariable(varopts, ...
                sheet, subrange, typeIDs, mergedCellColumnRule{1}, ...
                mergedCellRowRule{1}, returnEmptyVar{1});
        case 'logical'
            %obj = matlab.io.LogicalVariableImportOptions();
            [var, errid, placeholder, typeIDs] = readLogicalSpreadsheetVariable(varopts, ...
                sheet, subrange, typeIDs, mergedCellColumnRule{1}, ...
                mergedCellRowRule{1}, returnEmptyVar{1});
        otherwise
            assert(false);
    end
end
%%

function [data, var, mask, typeIDs] = updateTypeIdsForMergedCells(data, var, ...
    omitrows, omitvars, mask, mergedCells, typeIDs)
    % Set the output data for this variable by removing rows that should be omitted, or
    % setting the variable to empty if the variable itself is to be omitted
    if isempty(data)
        var = [];
        return;
    end
    if isempty(mergedCells)
        return;
    end

    if ~isempty(omitrows)
        % sort in descending so the rows can be removed and won't cause an issue
        % with number of existing rows
        if max(omitrows) <= size(data, 1)
            if ~omitrows
                % uint8 Inf == 255
                typeIDs(omitrows + 1, :) = Inf;
            else
                typeIDs(omitrows, :) = Inf;
            end
        end
    end

    if ~isempty(omitvars)
        data(:, omitvars) = [];
        var(:, omitvars) = [];
        mask(:, omitvars) = [];
        typeIDs(:, omitvars) = [];
    end
end

function [var, errid, placeholder, typeIDs] = readNumericSpreadsheetVariable(varopts, ...
    sheet, subrange, typeIDs, mergedCellColumnRule, mergedCellRowRule, returnEmptyVar)
    % Create an empty vector to hold our results
    var = zeros(size(typeIDs), varopts.Type);

    % Initialize errid logical vector
    errid = false(size(typeIDs));
    placeholder = false(size(typeIDs));

    textmask = typeIDs == sheet.STRING;
    if any(textmask,'all')
        % Read the string data
        if mergedCellColumnRule == "placeleft" && mergedCellRowRule == "placetop"
            data = sheet.readStrings(subrange, 'string');
        else
            if returnEmptyVar
                [data, mergedCells, omitrows] = sheet.readStrings(...
                    subrange, 'string', mergedCellColumnRule, mergedCellRowRule);
                omitvars = [];
            else
                [data, mergedCells, omitrows, omitvars] = sheet.readStrings(subrange, ...
                    'string', mergedCellColumnRule, mergedCellRowRule);
            end

            [data, var, textmask, typeIDs] = updateTypeIdsForMergedCells(data, var, ...
                omitrows, omitvars, textmask, mergedCells, typeIDs);
        end

        for i = 1 : size(data,2)
            textmaskInd = textmask(:, i);
            [numericData, errData, placeholdermask] = ...
                matlab.io.text.internal.datatypeConvertFromString(varopts,data(textmaskInd,i));
            
            % Assign results back into the larger vectors containing
            % all data and error ids
            % Assign durationData after some initial formatting
            errid(textmaskInd,i) = errData;
            placeholder(textmaskInd,i) = placeholdermask;
            var(textmaskInd,i) = numericData;
        end
    else
        placeholder = false(size(typeIDs));
    end

    datemask = typeIDs == sheet.DATETIME;
    if any(datemask,'all')
        % Use readDatesAsDoubles to ensure 1904-based datenums are imported correctly
        if mergedCellColumnRule == "placeleft" && mergedCellRowRule == "placetop"
            data = sheet.readDatesAsDoubles(subrange);
        else
            if returnEmptyVar
                [data, mergedCells, omitrows] = sheet.readDatesAsDoubles(subrange, ...
                    mergedCellColumnRule, mergedCellRowRule);
                omitvars = [];
            else
                [data, mergedCells, omitrows, omitvars] = sheet.readDatesAsDoubles(subrange, ...
                    mergedCellColumnRule, mergedCellRowRule);
            end
            [data, var, datemask, typeIDs] = updateTypeIdsForMergedCells(data, var, ...
                omitrows, omitvars, datemask, mergedCells, typeIDs);
        end
        if ~isempty(var)
            var(datemask) = data(datemask);
        end
    end

    boolmask = typeIDs == sheet.BOOLEAN;
    if any(boolmask,'all')
        if mergedCellColumnRule == "placeleft" && mergedCellRowRule == "placetop"
            data = sheet.readBooleans(subrange);
        else
            if returnEmptyVar
                [data, mergedCells, omitrows] = sheet.readBooleans(...
                    subrange, mergedCellColumnRule, mergedCellRowRule);
                omitvars = [];
            else
                [data, mergedCells, omitrows, omitvars] = sheet.readBooleans(subrange, ...
                    mergedCellColumnRule, mergedCellRowRule);
            end
            [data, var, boolmask, typeIDs] = updateTypeIdsForMergedCells(data, var, ...
                omitrows, omitvars, boolmask, mergedCells, typeIDs);
        end
        if ~isempty(var)
            var(boolmask) = data(boolmask);
        end
    end

    % read both numbers and durations as numbers
    numbermask = typeIDs == sheet.NUMBER | typeIDs == sheet.DURATION;
    if any(numbermask,'all')
        if mergedCellColumnRule == "placeleft" && mergedCellRowRule == "placetop"
            data = sheet.readNumbers(subrange);
        else
            if returnEmptyVar
                [data, mergedCells, omitrows] = sheet.readNumbers(subrange, ...
                    mergedCellColumnRule, mergedCellRowRule);
                omitvars = [];
            else
                [data, mergedCells, omitrows, omitvars] = sheet.readNumbers(subrange, ...
                    mergedCellColumnRule, mergedCellRowRule);
            end

            [data, var, numbermask, typeIDs] = updateTypeIdsForMergedCells(data, ...
                var, omitrows, omitvars, numbermask, mergedCells, typeIDs);
        end
        if ~isempty(var)
            var(numbermask == 1) = data(numbermask == 1);
        end
    end
    if ~isempty(var)
        var((typeIDs == sheet.BLANK | typeIDs == sheet.EMPTY)) = NaN;
    end
end

%% 

function [var, errid, placeholder, typeIDs] = readTextSpreadsheetVariable(varopts, ...
    sheet, subrange, typeIDs, mergedCellColumnRule, mergedCellRowRule, returnEmptyVar)
    % Construct a placeholder var based on datatype - string or char
    if strcmp(varopts.Type, 'string')
        var = strings(size(typeIDs));
    else
        var = repmat({''},size(typeIDs));
    end

    % Initialize errid + placeholder logical vector
    errid = false(size(typeIDs));
    placeholder = errid;

    % If varopts is not a struct, convert to a struct
    if ~(isstruct(varopts))
        varopts = getOptsStruct(varopts);
    end

    textmask = typeIDs == sheet.STRING;
    if any(textmask,'all')
        if mergedCellColumnRule == "placeleft" && mergedCellRowRule == "placetop"
            data = sheet.readStrings(subrange, 'string');
        else
            if returnEmptyVar
                [data, mergedCells, omitrows] = sheet.readStrings(subrange, 'string', ...
                    mergedCellColumnRule, mergedCellRowRule);
                omitvars = [];
            else
                [data, mergedCells, omitrows, omitvars] = sheet.readStrings(...
                    subrange, 'string', mergedCellColumnRule, mergedCellRowRule);
            end
            [data, var, textmask, typeIDs] = updateTypeIdsForMergedCells(data, ...
                var, omitrows, omitvars, textmask, mergedCells, typeIDs);
        end

        % Operate column-wise
        for i = 1:size(data,2)
            textmaskInd = textmask(:,i);
            [textData, errData, placeholdermask] = matlab.io.text.internal.datatypeConvertFromString(varopts,data(textmaskInd,i));
            placeholder(textmaskInd,i) = placeholdermask;
            errid(textmaskInd,i) = errData;
            var(textmaskInd,i) = textData;
        end
    else
        placeholder = false(size(typeIDs));
    end

    datemask = typeIDs == sheet.DATETIME;
    if any(datemask,'all')
        if mergedCellColumnRule == "placeleft" && mergedCellRowRule == "placetop"
            complexRepDates = sheet.readDates(subrange);
        else
            if returnEmptyVar
                [complexRepDates, mergedCells, omitrows] = sheet.readDates(subrange, ...
                    mergedCellColumnRule, mergedCellRowRule);
                omitvars = [];
            else
                [complexRepDates, mergedCells, omitrows, omitvars] = sheet.readDates(...
                    subrange, mergedCellColumnRule, mergedCellRowRule);
            end
            [complexRepDates, var, datemask, typeIDs] = updateTypeIdsForMergedCells(...
                complexRepDates, var, omitrows, omitvars, datemask, ...
                mergedCells, typeIDs);
        end
        dates = matlab.io.spreadsheet.internal.createDatetime(complexRepDates(datemask), 'default', '');
        var(datemask) = cellstr(dates, [], 'system');
    end

    boolmask = typeIDs == sheet.BOOLEAN;
    if any(boolmask,'all')
        % Convert to 'true' and 'false'
        values = {'true'; 'false'};
        if mergedCellColumnRule == "placeleft" && mergedCellRowRule == "placetop"
            data = sheet.readBooleans(subrange);
        else
            if returnEmptyVar
                [data, mergedCells, omitrows] = sheet.readBooleans(subrange, ...
                    mergedCellColumnRule, mergedCellRowRule);
                omitvars = [];
            else
                [data, mergedCells, omitrows, omitvars] = sheet.readBooleans(subrange, ...
                    mergedCellColumnRule, mergedCellRowRule);
            end
            [data, var, boolmask, typeIDs] = updateTypeIdsForMergedCells(data, ...
                var, omitrows, omitvars, boolmask, mergedCells, typeIDs);
        end
        var(boolmask) = values(2 - data(boolmask),:);
    end

    numbermask = typeIDs == sheet.NUMBER;
    if any(numbermask,'all')
        if mergedCellColumnRule == "placeleft" && mergedCellRowRule == "placetop"
            data = sheet.readNumbers(subrange);
        else
            if returnEmptyVar
                [data, mergedCells, omitrows] = sheet.readNumbers(subrange, ...
                    mergedCellColumnRule, mergedCellRowRule);
                omitvars = [];
            else
                [data, mergedCells, omitrows, omitvars] = sheet.readNumbers(subrange, ...
                    mergedCellColumnRule, mergedCellRowRule);
            end
            [data, var, numbermask, typeIDs] = updateTypeIdsForMergedCells(data, var, ...
                omitrows, omitvars, numbermask, mergedCells, typeIDs);
        end
        data(~numbermask) = [];
        strdata = printNumber(data(:));
        var(numbermask) = cellstr(strdata);
    end
end

%% 

function [var, errid, placeholder, typeIDs] = readDatetimeSpreadsheetVariable(varopts, ...
    sheet, subrange, typeIDs, mergedCellColumnRule, mergedCellRowRule, returnEmptyVar)
    % Create an empty vector to hold our results
    var = NaT(size(typeIDs));
    var.TimeZone = varopts.TimeZone;

    if varopts.DatetimeFormat == "preserveinput"
        % Using preserveinput does not make sense when importing 
        % datetime data from spreadsheet files.
        varopts.DatetimeFormat = "default";
    end

    % store InputFormat in a temp variable
    OutputFormat = varopts.InputFormat;

    % Initialize errid logical vector
    errid = false(size(typeIDs));
    placeholder = false(size(typeIDs));

    textmask = typeIDs == sheet.STRING;
    if any(textmask,'all')
        if mergedCellColumnRule == "placeleft" && mergedCellRowRule == "placetop"
            data = sheet.readStrings(subrange, 'string');
        else
            if returnEmptyVar
                [data, mergedCells, omitrows] = sheet.readStrings(subrange, ...
                    'string', mergedCellColumnRule, mergedCellRowRule);
                omitvars = [];
            else
                [data, mergedCells, omitrows, omitvars] = sheet.readStrings(...
                    subrange, 'string', mergedCellColumnRule, mergedCellRowRule);
            end
            [data, var, textmask, typeIDs] = updateTypeIdsForMergedCells(data, ...
                var, omitrows, omitvars, textmask, mergedCells, typeIDs);
        end
        for i = 1:size(data,2)
            textmaskInd = textmask(:,i);
            [datetimeData, errData, placeholdermask] = matlab.io.text.internal.datatypeConvertFromString(varopts,data(textmaskInd,i));
            
            % Assign results back into the larger vectors containing
            % all data and error ids
            % Assign durationData after some initial formatting
            errid(textmaskInd,i) = errData;
            placeholder(textmaskInd,i) = placeholdermask;
            
            % Format datetime
            OutputFormat = varopts.DatetimeFormat;
            if strcmp(OutputFormat,'default')
                OutputFormat = varopts.InputFormat;
            end
            
            OutputFormat = getDatetimeFormat(datetimeData.Data,OutputFormat);
            var(textmaskInd,i) = datetime.fromMillis(datetimeData.Data,OutputFormat,varopts.TimeZone);
        end
    end

    datemask = typeIDs == sheet.DATETIME;
    if any(datemask,'all')
        if mergedCellColumnRule == "placeleft" && mergedCellRowRule =="placetop"
            complexRepDates = sheet.readDates(subrange);
        else
            if returnEmptyVar
                [complexRepDates, mergedCells, omitrows] = sheet.readDates(subrange, ...
                    mergedCellColumnRule, mergedCellRowRule);
                omitvars = [];
            else
                [complexRepDates, mergedCells, omitrows, omitvars] = sheet.readDates(...
                    subrange, mergedCellColumnRule, mergedCellRowRule);
            end
            [complexRepDates, var, datemask, typeIDs] = updateTypeIdsForMergedCells(...
                complexRepDates, var, omitrows, omitvars, datemask, ...
                mergedCells, typeIDs);
        end
        if ~isempty(complexRepDates)
            dates = matlab.io.spreadsheet.internal.createDatetime(complexRepDates(datemask), 'default', varopts.TimeZone);
            var(datemask) = dates;
        end
    end

    boolmask = typeIDs == sheet.BOOLEAN;
    if any(boolmask,'all')
        % We don't convert logicals to datetimes
        errid(boolmask) = true;
    end

    numbermask = typeIDs == sheet.NUMBER;
    if any(numbermask,'all')
        if mergedCellColumnRule == "placeleft" && mergedCellRowRule == "placetop"
            data = sheet.readNumbers(subrange);
        else
            if returnEmptyVar
                [data, mergedCells, omitrows] = sheet.readNumbers(subrange, ...
                    mergedCellColumnRule, mergedCellRowRule);
                omitvars = [];
            else
                [data, mergedCells, omitrows, omitvars] = sheet.readNumbers(...
                    subrange, mergedCellColumnRule, mergedCellRowRule);
            end
            [data, var, numbermask, typeIDs] = updateTypeIdsForMergedCells(data, ...
                var, omitrows, omitvars, numbermask, mergedCells, typeIDs);
        end
        % Excel serial datenums cannot be negative
        validNumberMask = numbermask & (data >= 0);
        errid(numbermask & (data < 0)) = true;
        if sheet.AreDates1904
            dateSystem = "excel1904";
        else
            dateSystem = "excel";
        end
        var(validNumberMask) = datetime(data(validNumberMask), ConvertFrom=dateSystem);
    end

    % If DatetimeFormat is default and an InputFormat was detected,
    % use that, otherwise use the DatetimeFormat
    if ~isempty(var)
        if varopts.DatetimeFormat == "default" && ~isempty(OutputFormat)
            var.Format = OutputFormat;
        else
            var.Format = varopts.DatetimeFormat;
        end
    end
end

%% 

function [var, errid, placeholder, typeIDs] = readDurationSpreadsheetVariable(varopts, ...
    sheet, subrange, typeIDs, mergedCellColumnRule, mergedCellRowRule, returnEmptyVar)
    persistent zeroEpochDatetime;
    % Create an empty vector to hold our results
    var = seconds(NaN(size(typeIDs)));

    % Initialize errid logical vector
    errid = false(size(typeIDs));
    placeholder = false(size(typeIDs));
    textmask = typeIDs == sheet.STRING;
    if any(textmask,'all')
        if mergedCellColumnRule == "placeleft" && mergedCellRowRule == "placetop"
            data = sheet.readStrings(subrange, 'string');
        else
            if returnEmptyVar
                [data, mergedCells, omitrows] = sheet.readStrings(subrange, ...
                    'string', mergedCellColumnRule, mergedCellRowRule);
                omitvars = [];
            else
                [data, mergedCells, omitrows, omitvars] = sheet.readStrings(...
                    subrange, 'string', mergedCellColumnRule, mergedCellRowRule);
            end
            [data, var, textmask] = updateTypeIdsForMergedCells(data, var, ...
                omitrows, omitvars, textmask, mergedCells);
        end
        for i = 1:size(data,2)
            textmaskInd = textmask(:,i);
            [durationData, errData, placeholdermask] = matlab.io.text.internal.datatypeConvertFromString(varopts,data(textmaskInd,i));
            
            % Assign results back into the larger vectors containing
            % all data and error ids
            % Assign durationData after some initial formatting
            errid(textmaskInd,i) = errData;
            placeholder(textmaskInd,i) = placeholdermask;
            
            fmt = varopts.DurationFormat;
            if strcmp(fmt,'default')
                if isempty(varopts.InputFormat)
                    fmt = duration.getFractionalSecondsFormat(durationData,'hh:mm:ss');
                else
                    fmt = varopts.InputFormat;
                end
            end
            var(textmaskInd,i) = milliseconds(durationData);
            var.Format = fmt;
        end
    end

    % We don't convert datetimes logicals to durations
    errid((typeIDs == sheet.BOOLEAN) | (typeIDs == sheet.DATETIME)) = true;

    numbermask = typeIDs == sheet.NUMBER;
    if any(numbermask,'all')
        if mergedCellColumnRule == "placeleft" && mergedCellRowRule == "placetop"
            data = sheet.readNumbers(subrange);
        else
            if returnEmptyVar
                [data, mergedCells, omitrows] = sheet.readNumbers(subrange, ...
                    mergedCellColumnRule, mergedCellRowRule);
                omitvars = [];
            else
                [data, mergedCells, omitrows, omitvars] = sheet.readNumbers(...
                    subrange, mergedCellColumnRule, mergedCellRowRule);
            end

            [data, var, numbermask, typeIDs] = updateTypeIdsForMergedCells(data, ...
                var, omitrows, omitvars, numbermask, mergedCells, typeIDs);
        end
        % Excel serial datenums cannot be negative
        validNumberMask = numbermask & (data >= 0);
        errid(numbermask & (data < 0)) = true;
        % Spreadsheet numbers are days.
        var(validNumberMask) = days(data(validNumberMask));
    end

    durationmask = typeIDs == sheet.DURATION;
    if any(durationmask, "all")
        if isempty(zeroEpochDatetime)
            zeroEpochDatetime = datetime(0,ConvertFrom="excel");
        end
        if mergedCellColumnRule == "placeleft" && mergedCellRowRule == "placetop"
            data = sheet.readNumbers(subrange);
        else
            if returnEmptyVar
                [data, mergedCells, omitrows] = sheet.readNumbers(subrange, ...
                    mergedCellColumnRule, mergedCellRowRule);
                omitvars = [];
            else
                [data, mergedCells, omitrows, omitvars] = sheet.readNumbers(...
                    subrange, mergedCellColumnRule, mergedCellRowRule);
            end

            [data, var, durationmask, typeIDs] = updateTypeIdsForMergedCells(data, ...
                var, omitrows, omitvars, durationmask, mergedCells, typeIDs);
        end
        % Excel serial datenums cannot be negative
        validDurationMask = durationmask & (data >= 0);
        errid(durationmask & (data < 0)) = true;
        % Google Sheets internally stores durations as days.
        var(validDurationMask) = datetime(data(validDurationMask), ...
            ConvertFrom="excel") - zeroEpochDatetime;
        var.Format = "hh:mm:ss";
    end
    if ~strcmp(varopts.DurationFormat,'default')
        var.Format = varopts.DurationFormat;
    end
end

%% 

function [var, errid, placeholder, typeIDs] = readCategoricalSpreadsheetVariable(varopts, ...
    sheet, subrange, typeIDs, mergedCellColumnRule, mergedCellRowRule, returnEmptyVar)
    % Initialize errid + placeholder logical vector
    errid = false(size(typeIDs));
    placeholder = false(size(typeIDs));

    % Initialize categorical as all undefined - anything that is defined will
    % overwrite this
    var = categorical(repmat({''},size(typeIDs)));
    textmask = (typeIDs == sheet.STRING);

    if mergedCellColumnRule == "placeleft" && mergedCellRowRule == "placetop"
        data = sheet.readStrings(subrange, 'string');
    else
        if returnEmptyVar
            [data, mergedCells, omitrows] = sheet.readStrings(subrange, 'string', ...
                mergedCellColumnRule, mergedCellRowRule);
            omitvars = [];
        else
            [data, mergedCells, omitrows, omitvars] = sheet.readStrings(...
                subrange, 'string', mergedCellColumnRule, mergedCellRowRule);
        end
        [data, var, textmask, typeIDs] = updateTypeIdsForMergedCells(data, var, ...
            omitrows, omitvars, textmask, mergedCells, typeIDs);
    end

    if any(textmask, 'all')
        % For categorical, if we get multiple columns, we treat them as one
        % collection of categorical variables
        [catData, errData, placeholdermask] = matlab.io.text.internal.datatypeConvertFromString(varopts,data(textmask));
        errid(textmask) = errData;
        placeholder(textmask) = placeholdermask;
        
        if numel(catData) == 2 % { cdata, category names }
            % Category names were pre-defined so the IDS are 1:N
            cats = catData{2};
            ids  = 1:numel(cats);
        else % { cdata, ids , category names}
            ids  = catData{2};
            cats = catData{3};
        end
        
        % any literal undefined or missing text should be removed.
        undef = find(ismember(cats,{'<undefined>','<missing>'}));
        
        cdata = catData{1};
        if ~isempty(undef)
            cdata(cdata==ids(undef)) = 0;
            cats(undef) = [];
            ids(undef) = [];
        end
        % Optimally create the final array
        var(textmask) = categorical(cdata,ids,cats);
    end

    datemask = typeIDs == sheet.DATETIME;
    if any(datemask,'all')
        if mergedCellColumnRule == "placeleft" && mergedCellRowRule =="placetop"
            complexRepDates = sheet.readDates(subrange);
        else
            if returnEmptyVar
                [complexRepDates, mergedCells, omitrows] = sheet.readDates(subrange, ...
                    mergedCellColumnRule, mergedCellRowRule);
                omitvars = [];
            else
                [complexRepDates, mergedCells, omitrows, omitvars] = sheet.readDates(...
                    subrange, mergedCellColumnRule, mergedCellRowRule);
            end

            [complexRepDates, var, datemask, typeIDs] = updateTypeIdsForMergedCells(...
                complexRepDates, var, omitrows, omitvars, datemask, ...
                mergedCells, typeIDs);
        end
        dates = matlab.io.spreadsheet.internal.createDatetime(complexRepDates, 'default', '');
        var(datemask) = categorical(dates(datemask));
    end

    boolmask = typeIDs == sheet.BOOLEAN;
    if any(boolmask,'all')
        if mergedCellColumnRule == "placeleft" && mergedCellRowRule == "placetop"
            data = sheet.readBooleans(subrange);
        else
            if returnEmptyVar
                [data, mergedCells, omitrows] = sheet.readBooleans(subrange, ...
                    mergedCellColumnRule, mergedCellRowRule);
                omitvars = [];
            else
                [data, mergedCells, omitrows, omitvars] = sheet.readBooleans(subrange, ...
                    mergedCellColumnRule, mergedCellRowRule);
            end

            [data, var, boolmask, typeIDs] = updateTypeIdsForMergedCells(data, ...
                var, omitrows, omitvars, boolmask, mergedCells, typeIDs);
        end
        var(boolmask) = categorical(data(boolmask));
    end

    numbermask = typeIDs == sheet.NUMBER;
    if any(numbermask,'all')
        if mergedCellColumnRule == "placeleft" && mergedCellRowRule == "placetop"
            data = sheet.readNumbers(subrange);
        else
            if returnEmptyVar
                [data, mergedCells, omitrows] = sheet.readNumbers(subrange, ...
                    mergedCellColumnRule, mergedCellRowRule);
                omitvars = [];
            else
                [data, mergedCells, omitrows, omitvars] = sheet.readNumbers(subrange, ...
                    mergedCellColumnRule, mergedCellRowRule);
            end
            [data, var, numbermask, typeIDs] = updateTypeIdsForMergedCells(data, ...
                var, omitrows, omitvars, numbermask, mergedCells, typeIDs);
        end
        var(numbermask) = categorical(data(numbermask));
    end

    if ~isempty(varopts.Categories)
        errid(~ismember(var,varopts.Categories)) = true;
        var = setcats(var,varopts.Categories);
    end
    var = categorical(var,'Ordinal',varopts.Ordinal,'Protected',varopts.Protected);
end

%% 

function [var, errid, placeholder, typeIDs] = readLogicalSpreadsheetVariable(varopts, ...
    sheet, subrange, typeIDs, mergedCellColumnRule, mergedCellRowRule, returnEmptyVar)
    % Create an empty vector to hold our results
    var = false(size(typeIDs));

    % Initialize errid logical vector
    errid = false(size(typeIDs));

    % Initialize placeholder logical vector
    placeholder = false(size(typeIDs));

    textmask = typeIDs == sheet.STRING;
    if any(textmask,'all')
        % Read the string data
        if mergedCellColumnRule == "placeleft" && mergedCellRowRule == "placetop"
            data = sheet.readStrings(subrange, 'string');
        else
            if returnEmptyVar
                [data, mergedCells, omitrows] = sheet.readStrings(subrange, ...
                    'string', mergedCellColumnRule, mergedCellRowRule);
                omitvars = [];
            else
                [data, mergedCells, omitrows, omitvars] = sheet.readStrings(subrange, ...
                    'string', mergedCellColumnRule, mergedCellRowRule);
            end
            [data, var, textmask, typeIDs] = updateTypeIdsForMergedCells(data, ...
                var, omitrows, omitvars, textmask, mergedCells, typeIDs);
        end
        
        for i = 1:size(data,2)
            textmaskInd = textmask(:,i);
            [logicalData, errData, placeholdermask] = matlab.io.text.internal.datatypeConvertFromString(varopts,data(textmaskInd,i));
            
            % Assign results back into the larger vectors containing
            % all data and error ids
            var(textmaskInd,i) = logicalData;
            errid(textmaskInd,i) = errData;
            placeholder(textmaskInd,i) = placeholdermask;
        end
    end

    datemask = typeIDs == sheet.DATETIME;
    if any(datemask,'all')
        % We don't convert datetimes to logicals
        errid(datemask) = true;
    end

    boolmask = typeIDs == sheet.BOOLEAN;
    if any(boolmask,'all')
        if mergedCellColumnRule == "placeleft" && mergedCellRowRule == "placetop"
            data = sheet.readBooleans(subrange);
        else
            if returnEmptyVar
                [data, mergedCells, omitrows] = sheet.readBooleans(subrange, ...
                    mergedCellColumnRule, mergedCellRowRule);
                omitvars = [];
            else
                [data, mergedCells, omitrows, omitvars] = sheet.readStrings(subrange, ...
                    'string', mergedCellColumnRule, mergedCellRowRule);
            end

            [data, var, boolmask, typeIDs] = updateTypeIdsForMergedCells(data, ...
                var, omitrows, omitvars, boolmask, mergedCells, typeIDs);
        end
        if ~isempty(data)
            var(boolmask) = data(boolmask);
        end
    end

    numbermask = typeIDs == sheet.NUMBER;
    if any(numbermask,'all')
        if mergedCellColumnRule == "placeleft" && mergedCellRowRule == "placetop"
            data = sheet.readNumbers(subrange);
        else
            if returnEmptyVar
                [data, mergedCells, omitrows] = sheet.readNumbers(subrange, ...
                    mergedCellColumnRule, mergedCellRowRule);
                omitvars = [];
            else
                [data, mergedCells, omitrows, omitvars] = sheet.readNumbers(...
                    subrange, mergedCellColumnRule, mergedCellRowRule);
            end
            [data, var, numbermask, typeIDs] = updateTypeIdsForMergedCells(data, ...
                var, omitrows, omitvars, numbermask, mergedCells, typeIDs);
        end
        var(numbermask) = logical(data(numbermask));
    end
end

function OutputFormat = getDatetimeFormat(datetimeData,OutputFormat)
    % If we are using the default and have at least 1 valid datetime
    % entry, then use that to determine the format
    isNaN = isnan(datetimeData);
    usingDefault = isempty(OutputFormat);
    if usingDefault && ~isempty(datetimeData(~isNaN))
        % mod milliseconds/day
        isDateOnly = all(mod(real(datetimeData(~isNaN)),24*60*60*1000)==0);
        isDateOnly = isDateOnly && all(imag(datetimeData(~isNaN))==0);
        
        if isDateOnly
            d = datetime('today');
            OutputFormat = d.Format;
        end
    end
end

function s = printNumber(numbers)
    % "%g" removes trailing zeros after conversion
    s = compose("%.15g", numbers);

    % Verify the shorter version converts back to the original
    truncated = eval("["+join(s,';')+"]") ~= numbers;
    if any(truncated)
        % Use more precision for those that weren't matched. This is the best
        % once can do for doubles. Also exponential notation is required.
        s(truncated) = compose("%.17e", numbers(truncated));
    end
end
