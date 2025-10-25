function out = readSpreadsheetFile(rdOpts, suppliedUseExcel)
    %
    % Takes an input options structure & an optional suppliedUseExcel parameter 
    % to read and provides a scalar structure with data in the output.
    %
    % OUT = readSpreadsheetFile(IN)
    %
    % IN field names (all fields required):
    %   - file              : char array | Book instance.
    %     String filename or book instance.
    %
    %   - format            : char array
    %     String format, e.g. XLSX, XLS, XLSB, ODS, etc.
    %
    %   - sheet             : char array | numeric scalar | Sheet instance
    %     Sheet name or index or a sheet instance.
    %
    %   - range             : char array | numeric vector
    %     Range string or numeric vector. '' is allowed to mean used range.
    %
    %   - readVarNames      : scalar logical
    %     Whether to read variable names.
    %
    %   - UseExcel             : scalar logical
    %     Whether to use Microsoft® Excel® for Windows®. Affects sheets with live update.
    %     Uses a different date format for datetime import if not used.
    %
    %   - treatAsEmpty      : cellstr
    %     String to treat as empty when reading numeric data.
    %
    %   Optional fields:
    %   - logicalType       : char array
    %     'logical' imports as logical (default)
    %     'char' imports as cellstr
    %
    %   - datetimeType      : char array
    %     'datetime' imports as datetime
    %     'text' imports as TextType
    %     'platformdependent' imports as char in UseExcel 
    %      mode and as Excel serial day datenum otherwise
    %     'exceldatenum' imports as an Excel serial day datenum
    %
    %   - textType          : char array
    %     'char' imports as cellstr (default)
    %     'string' imports as MATLAB string
    %
    %   - datetimeFormat    : char array
    %     'osdep' imports as Windows short date and long time setting in live
    %     mode (Windows with Excel and UseExcel = true) and MATLAB datetime
    %     (default for datetime type 'char') default format in non-live (UseExcel
    %     = false) mode.
    %     'default' will use the MATLAB datetime default format. (default for
    %     datetime type 'datetime')
    %
    % OUT field names (all fields provided):
    %
    %   - varNames          : empty double | cellstr
    %     Variable names read based on IN. Empty double if these were not needed.
    %
    %   - variables         : cell array of variable data
    %     Data for each variable put into a cell array. The type mapping is as
    %     follows for each variable.
    %
    %   Consistent data:
    %     NUMERIC : double
    %     LOGICAL : logical
    %     EMPTY   : NaN
    %     DATETIME: datetime
    %
    %   Consistent but for empties:
    %     NUMBER  : double with NaN
    %     DATETIME: datetime with NaT
    %
    %   Mixture of number, string, logical where all strings can be treated
    %   as empty.
    %     STRING(as empty) | LOGICAL | NUMBER : double with NaN (logical as double)
    %
    %   Otherwise, cellstr.
    %
    %   NOTE: If treat as empty matched a few strings but the entire column was
    %   not determined to be numeric, the strings that matched treat as empty
    %   are not replaced with empty strings.
    %
    
    % Copyright 2015-2019 The MathWorks, Inc.
    
    % initial pre processing
    opts = process(rdOpts);

    % readSpreadsheetFile is called without passing suppliedUseExcel parameter
    if (nargin < 2)
        suppliedUseExcel = false;
    end

    book = getBook(opts, suppliedUseExcel);
    sheet = getSheet(opts, book);
    isCOM = book.Interactive;
    [range, types] = getRangeAndTypes(opts, sheet, isCOM);
    
    varNames  = [];
    variables = {};

    if isempty(range)
        out.varNames  = varNames;
        out.variables = variables;
        return;
    end
    
    if opts.readVarNames
        vnrange = [range(1), range(2), 1, range(4)];
        varNames = sheet.read(vnrange);
        datarange = range;
        datarange(1) = datarange(1) + 1;
        datarange(3) = datarange(3) - 1;
        types = types(2:end, :);
    else
        datarange = range;
    end
    
    if ~isCOM % osdep is only for interactive mode.
        opts.datetimeFormat = 'default';
    end

    % On a PC, if 'UseExcel' or 'Basic' is not supplied by user,
    % continue to default to osdep to maintain backwards compatability.
    if ispc && ~suppliedUseExcel && nargin == 2
        opts.datetimeFormat = 'osdep';
    end

    
    variables = getVariables(opts, book, sheet, datarange, types, opts.treatAsEmpty, opts.datetimeFormat);
    
    if opts.readVarNames && ~iscellstr(varNames)
        varNames = matlab.io.spreadsheet.internal.stringize(varNames, opts.datetimeFormat);
    end
    
    out.varNames  = varNames;
    out.variables = variables;
end

% local functions %
% ----------------------------------------------------------------------- %
function opts = process(opts)
    if isempty(opts.UseExcel), opts.UseExcel = false; end
    
    if ~any(strcmp('', opts.treatAsEmpty)), opts.treatAsEmpty{end+1} = ''; end
    
    if isempty(opts.sheet), opts.sheet = 1; end
    
    if ~isfield(opts, 'logicalType')
        opts.logicalType = 'logical';
    end
    
    if ~isfield(opts, 'datetimeType')
        opts.datetimeType = 'text';
    end
    
    if ~isfield(opts, 'textType')
        opts.textType = 'char'; 
    end
    
    if ~isfield(opts, 'datetimeFormat')
        if any(strcmp(opts.datetimeType, {'text' 'platformdependent' 'datetime'}))
            opts.datetimeFormat = 'osdep';
        else
            opts.datetimeFormat = 'default';
        end
    end
end

% ----------------------------------------------------------------------- %
function book = getBook(opts,suppliedUseExcel)
    if isa(opts.file, 'matlab.io.spreadsheet.internal.Book')
        book = opts.file;
        return;
    end
    
    filename = opts.file;
    fmt = opts.format;
    
    try
         % On Windows for ODS and XLSB files error when UseExcel is set to false by the user
        if(ispc && contains(fmt, {'ods', 'xlsb'}, 'IgnoreCase',true) && suppliedUseExcel && ~opts.UseExcel)
            error(message('MATLAB:spreadsheet:book:fileTypeUnsupported', fmt));
        end
        book = matlab.io.spreadsheet.internal.createWorkbook(...
            fmt, filename, opts.UseExcel, opts.sheet);
    catch ME % try matching as the partial path
        if (strcmp(ME.identifier,'MATLAB:spreadsheet:book:fileTypeUnsupported'))
            rethrow(ME)
        end
        f = which(filename);
        if ~isempty(f)
            filename = f;
        end
        book = matlab.io.spreadsheet.internal.createWorkbook(...
            fmt, filename, opts.UseExcel, opts.sheet);
    end
end

% ----------------------------------------------------------------------- %
function sheet = getSheet(opts, book)
    if isa(opts.sheet, 'matlab.io.spreadsheet.internal.Sheet')
        sheet = opts.sheet;
        return;
    end

    % if only one sheet is loaded, get the first sheet, else get the sheet
    % in correct order
    if book.isSheetLoaded
        sheet = book.getSheet(1);
    else
        sheet = book.getSheet(opts.sheet);
    end
end

% ----------------------------------------------------------------------- %
function [numrange, types] = getRangeAndTypes(opts, sheet, isCOM)
    if strcmp(opts.range, '')
        if(~isCOM)
            range = sheet.getDataSpan;
            types = sheet.getTypes;
        else
            [range, types] = matlab.io.spreadsheet.internal.usedDataRange(sheet);
        end
    else
        range = opts.range;
        types = sheet.types(range);
    end
    if isempty(range)
        numrange = [];
        types = uint8([]);
        return;
    end
    numrange = sheet.getRange(range, false);
end

% ----------------------------------------------------------------------- %
function variables = getVariables(opts, book, sheet, datarange, types, treatAsEmpty, fmttype)
    EMPTY=sheet.EMPTY; BLANK=sheet.BLANK; ERROR=sheet.ERROR;
    STRING=sheet.STRING;
    DATETIME=sheet.DATETIME;
    BOOLEAN=sheet.BOOLEAN;
    NUMBER=sheet.NUMBER;
    
    import matlab.io.spreadsheet.internal.createDatetime;
    import matlab.io.spreadsheet.internal.coerceDatetimeType;
    
    variables = cell(1, size(types,2));
    
    charText = strcmp(opts.textType, 'char');
    stringText = strcmp(opts.textType, 'string');
       
    for ii = 1:numel(variables)
        coltypes = types(:,ii);
        
        empties = (coltypes == EMPTY)|(coltypes == BLANK)|(coltypes == ERROR);
        if all(empties)
            variables{ii} = NaN(size(coltypes));
            continue;
        end
        
        r = datarange;
        r(2) = r(2) + ii - 1;
        r(4) = 1;
        
        if all(coltypes == NUMBER)
            % valid only if all types are numbers
            variables{ii} = sheet.readNumbers(r);
            continue;
        end
        
        if all(coltypes == DATETIME)
            % valid only if all types are datetimes
            variables{ii} = coerceDatetimeType(opts, createDatetime(sheet.readDates(r), fmttype, ''), book);
            continue;
        end
        
        if all(coltypes == BOOLEAN)
            % valid only if all types are booleans
            data = sheet.readBooleans(r);
            switch opts.logicalType
                case 'logical'
                case 'char'
                    cells = cell(size(data));
                    cells(data)  = {'true'};
                    cells(~data) = {'false'};
                    data = cells;
                otherwise
                    error('Invalid logicalType option. Must be ''logical'' or ''char''.');
            end
            variables{ii} = data;
            continue;
        end
        
        if isequal(opts.logicalType, 'char')
            % if a string output is requested for logical type
            % bypass reading by numbers and just read them as cellstrs.
            boolColtypes = false(size(coltypes));
        else
            boolColtypes = (coltypes == BOOLEAN);
        end
        
        if all(coltypes == NUMBER | empties | boolColtypes)
            % syntax that allows empties, logicals and numbers
            variables{ii} = sheet.readNumbers(r, coltypes);
            continue;
        end
        
        % have to read the cell array
        data = sheet.read(r, coltypes, opts.textType);
        
        % if we are reading text as strings, make a string array
        if charText
            out = data;
        elseif stringText
            out = strings(size(data));
        end
        
        strs = coltypes == STRING;
        if any(strs) && charText
            data(strs) = strtrim(data(strs));
            out(strs) = data(strs);
        elseif any(strs) && stringText
            d = data(strs);
            data(strs) = strtrim(d);
            out(strs) = strtrim([d{:}]');
        end
        
        dtmask = (coltypes == DATETIME);
        if all(empties | dtmask)
            newdata = NaT(size(data));
            dt = createDatetime([data{dtmask}]', fmttype, '');
            newdata.Format = dt.Format;
            newdata(dtmask) = dt;
            variables{ii} = coerceDatetimeType(opts, newdata, book);
            continue;
        end
        
        %
        % could be all numbers considering empties, string treat as
        % empties, and logicals
        %
        if all(empties | (coltypes==NUMBER) | strs | (coltypes == BOOLEAN))
            isnumnan = strcmpi('NaN', data);
            for jj = 1:numel(treatAsEmpty)
                isnumnan = isnumnan | strcmp(treatAsEmpty{jj}, data);
            end
            
            %
            % * strs are known strings
            % * empties are empty strings
            % * isnumnan are strcmp/strcmpi outputs which return false for
            %   non-strings.
            %
            % We are essentially checking that all strings are convertible
            % to numeric NaNs.
            %
            % We don't need to check isnumnan|empties because process()
            % adds '' to the TreatAsEmpty list.
            %
            if all((strs|empties) == isnumnan)
                val = NaN(size(data));
                nums = coltypes == NUMBER;
                val(nums) = [data{nums}]';
                if any(coltypes == BOOLEAN)
                    logs = coltypes == BOOLEAN;
                    % logicals become double
                    val(logs) = [data{logs}]';
                end
                variables{ii} = val;
                continue;
                
                %
                % do not replace the possibly numeric strings with
                % anything.
                %
                % the current policy is: if the whole column can be a
                % number, replace the treat as empty matches, else, leave
                % the original strings be.
                %
            end
        end
        
        % convert everything to string; logicals don't specialize on empty
        typemask = coltypes == DATETIME;
        if any(typemask)
            dt = coerceDatetimeType(opts, createDatetime(data(typemask), fmttype, ''), book);
            if (strcmp(opts.datetimeType, 'platformdependent') && ~book.Interactive) ...
                    || strcmp(opts.datetimeType, 'exceldatenum')               
                if charText
                    % If we are going to ouput dates as Excel serial datenums, we
                    % need to mark them as numbers.
                    coltypes(typemask) = NUMBER;
                    
                    out(typemask) = num2cell(dt);
                    data(typemask) = out(typemask);
                elseif stringText
                    out(typemask) = dt;
                end
            else
                if ~iscell(dt) && charText
                    dt = cellstr(dt);
                elseif ~iscell(dt) && stringText
                    dt = string(dt);
                end
                out(typemask) = dt;
            end
        end
        
        typemask = coltypes == BOOLEAN;
        if any(typemask)
            logs = [data{typemask}]';
            if charText
                cs = cell(size(logs));
                cs(logs)  = {'true'};
                cs(~logs) = {'false'};
            elseif stringText
                cs = strings(size(logs));
                cs(logs)  = "true";
                cs(~logs) = "false";
            end
            
            out(typemask) = cs;
        end
        
        typemask = coltypes == NUMBER;
        if any(typemask)
            if charText
                out(typemask) = arrayfun(@num2str, [data{typemask}]', 'UniformOutput', false);
            elseif stringText
                out(typemask) = string([data{typemask}]');
            end
        end
        
        variables{ii} = out;
    end
end

