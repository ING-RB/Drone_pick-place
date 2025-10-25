function dtType = coerceDatetimeType(opts, in, book)
    %COERCEDATETIMETYPE convert the datetime into expected output type.
    
    % Copyright 2016 The MathWorks, Inc.
    switch opts.datetimeType
        case 'datetime'
            dtType = in;
        case 'text'
            dtType = datetimeToString(in);
            if opts.textType == "string"
                dtType = string(dtType);
            end
        case 'exceldatenum'
            dtType = datetimeToExcelDatenum(in, book);
        case 'platformdependent'
            if book.Interactive
                % Read as char in interactive mode
                dtType = datetimeToString(in);
            else
                dtType = datetimeToExcelDatenum(in, book);
            end
        otherwise
            error('Invalid DatetimeType option. Must be ''datetime'', ''char'', or ''platformdependent''.');
    end
end

% ----------------------------------------------------------------------- %
function ednum = datetimeToExcelDatenum(dt, book)
    % In basic mode, read as Excel serial datenums, with
    % respect to the date origin of the workbook
    if book.AreDates1904
        dateOrigin = '1904';
    else
        dateOrigin = '1900';
    end
    ednum = exceltime(dt, dateOrigin);
end

% ----------------------------------------------------------------------- %
function s = datetimeToString(d)
    nats = isnat(d);
    if any(nats)
        s = cell(size(d));
        s(nats) = {''};
        s(~nats) = cellstr(d(~nats),[],'system');
    else
        s = cellstr(d,[],'system');
    end
end
