function dtstr = cnv2icudf(formatstr,escaping)
%   CNV2ICUDF maps date format tokens to ICU date format tokens
%   ICUFORMAT = CNV2ICUDF(MLFORMAT) transforms a date/time format that uses
%   DATESTR's format tokens into one that uses the ICU format tokens. MLFORMAT
%   is a char vector containing a user specified format as described below.
%   ICUFORMAT is a char vector containing the transformed format. Characters in
%   MLFORMAT not listed in Note 1 are "escaped" with single quotes in ICUFORMAT.
%
%   ICUFORMAT = CNV2ICUDF(MLFORMAT,FALSE) does not escape invalid characters.
%   This is useful only for use by FORMATDATE.
%
%   The format specifier allows free-style date/time format using the following
%   tokens:
%      dddd => day is formatted as full name of weekday
%      ddd  => day is formatted as abbreviated name of weekday
%      dd   => day is formatted as two digit day of month
%      d    => day is formatted as first letter of name of weekday
%      mmmm => month is formatted as full of name of month
%      mmm  => month is formatted as three letter abbreviation of name of month
%      mm   => month is formatted as two digit month of year
%      m    => month is formatted as one or two digit month of year
%      yyyy => year is formatted as four digit year
%      yy   => year is formatted as two digit year
%      QQ   => quarter is formatted as 'Q' and one digit quarter of year
%      HH   => hour is formatted as two digit hour of the day
%      MM   => minute is formatted as two digit minute of the hour
%      SS   => second is formatted as two digit second of the minute
%      FFF  => millisecond is formatted as three digit ms of the second
%      PM or PM  => day period is formatted as 'AM' or 'PM'
%   MLFORMAT may contain separators and other delimiters. At most one of
%   the year tokens, is allowed; similarly for the month tokens or the day
%   name tokens (although both day number and day name are allowed). The
%   quarter token is only allowed with one of the year tokens.
%
%
%------------------------------------------------------------------------------

% Copyright 2002-2019 The MathWorks, Inc.

dtstr = formatstr;
if nargin == 1
    escaping = true;
end
% Replace AM/PM with 'a' to avoid confusion with months and minutes.
showAmPm = [strfind(lower(dtstr), 'am'), strfind(lower(dtstr), 'pm')];
wrtAmPm = numel(showAmPm);
if wrtAmPm > 0
    if wrtAmPm > 1
        error(message('MATLAB:formatdate:ampmFormat', formatstr));
    end
    dtstr(showAmPm) = [];  % delete the 'a' or the 'p'
    dtstr(showAmPm) = 'a'; % overwrite the 'm'
end

% Day, millisecond, hour, quarter, second, and year are case insensitive, standardize them.
dtstr = strrep(dtstr, 'd', 'D'); % some of which ultimately become 'd', some 'e'
dtstr = strrep(dtstr, 'f', 'F'); % which ultimately becomes 'S'
dtstr = strrep(dtstr, 'h', 'H'); % which MAY ultimately become 'h', if AM/PM is present
dtstr = strrep(dtstr, 'q', 'Q');
dtstr = strrep(dtstr, 'S', 's');
dtstr = strrep(dtstr, 'Y', 'y');

% Swap 'm' and 'M' to output 'M' for month and 'm' for minute.
minuteLocs = strfind(dtstr,'M');
dtstr = strrep(dtstr,'m','M');
dtstr(minuteLocs) = 'm';

% Escape unused characters.
if escaping
    dtstr = regexprep(dtstr,'((?=[A-Za-z])([^amsyDFHMQ]))*','''$1''');
end

showYr   = strfind(dtstr,'y'); wrtYr   = numel(showYr);
showMo   = strfind(dtstr,'M'); wrtMo   = numel(showMo);
showDay  = strfind(dtstr,'D'); wrtDay  = numel(showDay);
showHr   = strfind(dtstr,'H'); wrtHr   = numel(showHr);
showMin  = strfind(dtstr,'m'); wrtMin  = numel(showMin);
showSec  = strfind(dtstr,'s'); wrtSec  = numel(showSec);
showMsec = strfind(dtstr,'F'); wrtMsec = numel(showMsec);
showQrt  = strfind(dtstr,'Q'); wrtQrt  = numel(showQrt);

% Format date
if wrtYr > 0
    if (wrtYr ~= 4 && wrtYr ~= 2) || showYr(end) - showYr(1) >= wrtYr
        error(message('MATLAB:formatdate:yearFormat', formatstr));
    end
end
if wrtQrt > 0
    if wrtQrt ~= 2 || showQrt(2) - showQrt(1) > 1
        error(message('MATLAB:formatdate:quarterFormat', formatstr));
    end
    if any([wrtMo, wrtDay, wrtAmPm, wrtHr, wrtMin, wrtSec, wrtMsec] > 0)
        error(message('MATLAB:formatdate:quarterFormatMismatch',formatstr));
    end
    dtstr = strrep(dtstr, 'QQ', 'QQQ'); % output exactly 'QQQ' for quarter
end
if wrtMo > 0
    if wrtMo > 4 || showMo(end) - showMo(1) >= wrtMo
        error(message('MATLAB:formatdate:monthFormat', formatstr));
    end
end
if wrtDay > 0
    % 'D' is special in that it ultimately maps to _two_ tokens, one of which is
    % a literal char. Ultimately the day name token will be 'e', but that can be
    % confused with 'e' intended as a literal. d/D have been standardized to
    % 'D', so recognize day name vs. day number fields and temporarily
    % distinguish between them using case. d/D are non-literal chars, so we're
    % not stepping on anything.
    dtstr = strrep(dtstr, 'DDDDDD', 'DDDDdd'); % split into day name/number pieces
    dtstr = strrep(dtstr, 'DDDDD',  'DDDdd'); % split into day name/number pieces
    % The above two strreps match _all_ 'DDDDDD' or 'DDDDD' ovelapping substrings,
    % so seven or more contiguous D's become something illegal caught below. One to
    % four contiguous D's are left alone, to be handled next.
    % Leave 'DDDD' as is
    % Leave 'DDD' as is
    dtstr = regexprep(dtstr,'(?<!D)(DD)(?!D)','dd'); % 'DD'->'dd', leaving DDDD and DDD alone
    dtstr = regexprep(dtstr,'(?<!D)(D)(?!D)','DDDDD'); % 'D'->'DDDDD', leaving DDDD and DDD alone
    showNday = strfind(dtstr,'d'); wrtNday = numel(showNday);
    if wrtNday > 0
        if wrtNday ~= 2 || showNday(2) - showNday(1) ~= 1
            error(message('MATLAB:formatdate:dayFormat', formatstr));
        end
    end
    if escaping
        % Find D's to validate the format, and only then replace 'D' with 'e'.
        showWday = strfind(dtstr,'D'); wrtWday = numel(showWday);
        dtstr = strrep(dtstr,'D','e'); % now replace 'D' with 'e'
    else
        % Preserve existing behavior: formatDate (and therefore datestr) is the
        % one caller who doesn't want escaped literals, and it expects E's. If we're
        % not escaping, replace 'D' with 'E' before looking for E's, which means that
        % E's don't work correctly when intended as literals. Also formatdate expects
        % only one E where there was a single D.
        dtstr = strrep(dtstr,'DDDDD','D'); % exactly 'DDDDD' -> exactly 'D'
        dtstr = strrep(dtstr,'D','E'); % all D's -> 'E'
        showWday = strfind(dtstr,'E'); wrtWday = numel(showWday);
    end
    if wrtWday > 0
        if wrtWday > 5 || showWday(end) - showWday(1) >= wrtWday
            error(message('MATLAB:formatdate:dayFormat', formatstr));
        end
    end
end

% Format time
if wrtHr > 0
    if wrtHr == 2 && showHr(2) - showHr(1) == 1
        if wrtAmPm
            dtstr = strrep(dtstr,'H','h'); % output 12-hour field if am/pm present
        end
    else
        error(message('MATLAB:formatdate:hourFormat', formatstr));
    end
end
if wrtMin > 0
    if wrtMin ~= 2 || showMin(2) - showMin(1) ~= 1
        error(message('MATLAB:formatdate:minuteFormat', formatstr));
    end
end
if wrtSec > 0
    if wrtSec ~= 2 || showSec(2) - showSec(1) ~= 1
        error(message('MATLAB:formatdate:secondFormat', formatstr));
    end
end
if wrtMsec > 0
    if wrtMsec ~= 3 || showMsec(3) - showMsec(1) ~= 2
        error(message('MATLAB:formatdate:millisecondFormat', formatstr));
    end
    dtstr = strrep(dtstr, 'F', 'S'); % output 'S' for milliseconds.
end
