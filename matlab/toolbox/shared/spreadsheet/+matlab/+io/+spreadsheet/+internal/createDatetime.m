function dt = createDatetime(data, fmttype, tz)
%CREATEDATETIME   Return date & time as Spreadsheet date strings on OS format.
%
%

%   Copyright 2015-2023 The MathWorks, Inc.

    if iscell(data)
        dt = datetime.fromMillis([data{:}]');
    else% must be array
        dt = datetime.fromMillis(data);
    end
    dt.Format = determineFormat(dt, fmttype);
    if ~isempty(tz)
        % Excel has no notion of time zones. When we get an serial day num
        % from a spreadsheet, we want the "clockface" time of the resulting
        % datetime to be the same as it appears in the spreadsheet, regardless
        % of whether we're creating an unzoned datetime or a zoned one. If the 
        % former, all we need do is convert Excel's number into our number, and
        % create an unzoned datetime -- this makes a datetime that "looks" just
        % as it does in the spreadsheet. If the latter, we do that and then
        % assign to the datetime's .Format. This assignment adjusts the internal
        % number so it is relative to UTC, but preserves the "clockface" of the
        % datetime so the zoned result still "looks" the same as in the spreadsheet.
        dt.TimeZone = tz;
    end
end

function fmt = determineFormat(d, fmttype)
    import matlab.io.spreadsheet.internal.dateFormats;
    [df, dtf, dtmf] = dateFormats(fmttype);
    [h, m, s] = hms(d);

    if ~all(s-floor(s) < 1e-3 )
        % Excel stores dates with more fractional precision than they need and that
        % leads to rounding errors near zero. We only display miliseconds, so if
        % that part is zero for all elements in the range, choose hh:mm:ss over
        % hh:mm:ss.SSS
        fmt = dtmf;
    elseif all((h == 0) & (m == 0) & (s < 1))
        % if the time won't display anything but midnight, don't display it.
        fmt = df;
    else
        fmt = dtf;
    end
end
