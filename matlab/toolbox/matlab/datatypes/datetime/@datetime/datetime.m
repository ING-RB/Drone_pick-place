classdef (Sealed, InferiorClasses = {?duration, ?calendarDuration ?matlab.graphics.axis.Axes}) datetime ...
        < matlab.mixin.internal.datatypes.TimeArrayDisplay ...
        & matlab.mixin.internal.indexing.Paren ...
        & matlab.mixin.internal.indexing.ParenAssign ...
        & matlab.mixin.CustomArraySerialization
    %

    %   Copyright 2014-2024 The MathWorks, Inc.

    %#ok<*MGMD>
    properties(GetAccess='public', Dependent)
        Format
        TimeZone
        Year
        Month
        Day
        Hour
        Minute
        Second
    end % public dependent properties

    %=======================================================================
    methods(Access='public', Static)
        function tz = SystemTimeZone()
            tz = datetime.getsetLocalTimeZone('uncanonical');
        end
    end

    %=======================================================================
    properties(GetAccess='public', Constant, Hidden)
        % These properties are for internal use only and will change in a
        % future release. Do not use these properties.
        UTCZoneID = 'UTC';
        UTCLeapSecsZoneID = "UTCLeapSeconds";
        ISO8601Format = 'uuuu-MM-dd''T''HH:mm:ss.SSS''Z''';
        ISO8601FormatPattern = regexpPattern("uuuu-MM-dd'T'HH:mm:ss(\.S{1,9})?'Z'");
        epochDN = 719529; % 1-Jan-1970 00:00:00

        % The MonthsOfYear property contains the month names localized in
        % the system locale. The property is a scalar struct with 'Short'
        % and 'Long' fields, each containing a cell array of character vectors for
        % the short and long month names, respectively.
        MonthsOfYear = struct('Short',{matlab.internal.datetime.getMonthNames('short', matlab.internal.datetime.getDatetimeSettings('locale'))}, ...
            'Long',{matlab.internal.datetime.getMonthNames('long', matlab.internal.datetime.getDatetimeSettings('locale'))});

        % The DayNames property contains the day names localized in the system locale.
        % The property is a scalar struct with 'Short' and 'Long' fields, each containing
        % a cell array of character vectors for the short and long day names, respectively.
        DaysOfWeek = struct('Short',{matlab.internal.datetime.getDayNames('short', matlab.internal.datetime.getDatetimeSettings('locale'))}, ...
            'Long',{matlab.internal.datetime.getDayNames('long', matlab.internal.datetime.getDatetimeSettings('locale'))});
    end % hidden public constant properties

    %=======================================================================
    properties(GetAccess='protected', SetAccess='protected')
        % Count milliseconds (including fractional) from epoch as a double-double
        % stored in complex

        data

        % Display format. When this field is empty the global setting will
        % be used

        fmt = '';

        % A time zone ID, e.g. America/Los_Angeles. Empty character vector means the array
        % contains no time zone information, i.e., it's not a fully specified
        % value, and cannot be mixed with "real-world" datetimes

        tz = '';

        % Beginning in R2020a, isDateOnly is no longer a property. When loading
        % a post-R2019b mat file, releases up through R2019b automatically set
        % that (missing, to them) property to false. When loading a pre-2020a
        % mat file releases from 2020a and on automatically ignore the (extra,
        % to them) property.

    end % protected properties

    %=======================================================================
    properties(GetAccess='protected', Constant)
        dfltPivot = matlab.internal.datetime.getDefaults('pivotyear');
    end % protected constant properties

    %=======================================================================
    methods(Access='public')
        function this = datetime(inData,varargin)
            import matlab.internal.datetime.createFromString
            import matlab.internal.datetime.verifyLocale
            import matlab.internal.datatypes.parseArgs

            if nargin == 0 % same as datetime('now')
                this.data = currentTime();
                return
            end

            haveStrings = false;
            haveNumeric = false;
            haveNamedInstant = false;

            if ischar(inData) || (isstring(inData) && isscalar(inData))
                switch lower(inData)
                    case 'now',       haveNamedInstant = true; yesterdayTodayTomorrow = 1;
                    case 'yesterday', haveNamedInstant = true; yesterdayTodayTomorrow = 2;
                    case 'today',     haveNamedInstant = true; yesterdayTodayTomorrow = 3;
                    case 'tomorrow',  haveNamedInstant = true; yesterdayTodayTomorrow = 4;
                    otherwise, haveNamedInstant = false; yesterdayTodayTomorrow = 0;
                end
                if ~haveNamedInstant
                    haveStrings = true;
                    inData = string(inData);
                end
            elseif isnumeric(inData)
                haveNumeric = true;
            elseif isstring(inData)
                haveStrings = true;
            elseif matlab.internal.datatypes.isCharStrings(inData) % cellstr
                haveStrings = true;
            elseif isa(inData, 'missing')
                inData = NaT(size(inData));
            elseif isa(inData, 'py.datetime.datetime') || isa(inData, 'py.numpy.ndarray') || isa(inData, 'py.numpy.datetime64')
                try 
                    inData = matlab.internal.py2datetime(inData);
                catch e
                    e.throwAsCaller()
                end
            end

            % Find how many numeric inputs args: count up until the first non-numeric.
            numNumericArgs = haveNumeric; % include inData if it's numeric
            if haveNumeric
                for i = 1:length(varargin)
                    if ~isnumeric(varargin{i}), break, end
                    numNumericArgs = numNumericArgs + 1;
                end
                numericArgs = varargin(1:numNumericArgs-1);
                varargin = varargin(max(numNumericArgs,1):end);
            end

            dfltFmt = '';
            tryFmts = {};
            preserveInputFmt = false;
            if isempty(varargin)
                % Default format and the local time zone and locale.
                inputFmt = dfltFmt;
                fmt = dfltFmt; %#ok<*PROP>
                tz = '';
                locale = '';
                pivot = datetime.dfltPivot;
                epoch = [];
                ticksPerSec = 1;
                supplied = this.noConstructorParamsSupplied;
                isUTCLeapSecs = false;
            else
                % Process explicit parameter name/value pairs.
                pnames = {'ConvertFrom' 'InputFormat' 'Format' 'TimeZone' 'Locale'      'PivotYear'          'Epoch' 'TicksPerSecond'};
                dflts =  {''            ''             dfltFmt ''          ''            datetime.dfltPivot   0       1              };
                [convertFrom,inputFmt,fmt,tz,locale,pivot,epoch,ticksPerSec,supplied] = parseArgs(pnames, dflts, varargin{:});

                % Canonicalize the TZ name. This make US/Eastern ->
                % America/New_York, but it will also make EST -> Etc/GMT+5,
                % because EST is an offset, not a time zone.
                if supplied.TimeZone, tz = verifyTimeZone(tz); end
                if supplied.Locale, locale = verifyLocale(locale); end
                if supplied.PivotYear, verifyPivot(pivot); end
                isUTCLeapSecs = (tz == datetime.UTCLeapSecsZoneID);
                if isUTCLeapSecs
                    if supplied.InputFormat
                        if ~matches(inputFmt,datetime.ISO8601FormatPattern)
                            error(message('MATLAB:datetime:InvalidUTCLeapSecsFormatString'));
                        end
                    else
                        inputFmt = datetime.ISO8601Format;
                    end
                    if supplied.Format
                        if ~matches(fmt,datetime.ISO8601FormatPattern)
                            error(message('MATLAB:datetime:InvalidUTCLeapSecsFormatString'));
                        end
                        fmt = convertStringsToChars(fmt);
                    else
                        fmt = datetime.ISO8601Format;
                    end
                else
                    if supplied.Format
                        if strcmpi(fmt,"preserveinput")
                            if ~haveStrings
                                error(message('MATLAB:datetime:InvalidPreserveInput'));
                            end
                            preserveInputFmt = true;
                            supplied.Format = false;
                        else
                            checkConflicts = haveStrings && ~supplied.InputFormat; % only when also used to read strings
                            fmt = verifyFormat(fmt,tz,checkConflicts,true);
                        end
                    end
                end
                if supplied.ConvertFrom && numNumericArgs ~= 1
                    % Require exactly one numeric input if ConvertFrom is provided.
                    error(message('MATLAB:datetime:WrongNumInputsConversion'));
                end
            end

            if haveNumeric
                if supplied.ConvertFrom % datetime(x,'ConvertFrom',type,...)
                    thisData = datetime.convertFrom(inData,convertFrom,tz,epoch,ticksPerSec);
                else
                    if numNumericArgs == 1 % datetime([y,mo,d],...) or datetime([y,mo,d,h,mi,s],...)
                        ncols = size(inData,2);
                        if ~ismatrix(inData) || ((ncols ~= 3) && (ncols ~= 6))
                            error(message('MATLAB:datetime:InvalidNumericData'));
                        end
                        inData = num2cell(full(double(inData)),1); % split into separate vectors.
                    else % datetime(y,mo,d,...), datetime(y,mo,d,h,mi,s,...), or datetime(y,mo,d,h,mi,s,ms,...)
                        inData = expandNumericInputs([{inData} numericArgs]);
                    end

                    try %#ok<ALIGN>
                        thisData = matlab.internal.datetime.createFromDateVec(inData,tz); % or datevec + millis
                    catch ME, throw(ME), end
                end

            elseif haveNamedInstant
                % Get the system clock. If the requested result is zoned, the system time zone's
                % offset is removed to translate the value to UTC.
                thisData = currentTime(tz);
                if yesterdayTodayTomorrow > 1
                    % Floor to get today, then subtract or add a day for yesterday or tomorrow.
                    ucal = datetime.dateFields;
                    thisData = matlab.internal.datetime.datetimeFloor(thisData,ucal.DAY_OF_MONTH,tz);
                    thisData = matlab.internal.datetime.addToDateField(thisData,yesterdayTodayTomorrow-3,ucal.DAY_OF_MONTH,tz);
                end

            elseif haveStrings
                % Construct from a cell array of date strings of any shape. Error if none
                % of the strings can be parsed. Returning all NaT would give an indication
                % that something went wrong, but offer s no help on what to do. For example,
                % error if one string is given and it can't be parsed.
                if isUTCLeapSecs
                    try %#ok<ALIGN>
                        %inputFmt = convertStringsToChars(inputFmt);
                        thisData = createFromString(inData,inputFmt,1,tz,locale,pivot);
                    catch ME, throw(ME), end
                else
                    try
                        if supplied.InputFormat
                            % output of validateFormatTokens converts string to char.
                            inputFmt = matlab.internal.datetime.validateFormatTokens(inputFmt,true);
                            try
                                thisData = createFromString(inData,inputFmt,1,tz,locale,pivot);
                            catch ME
                                % First call verifyFormat to check for any issues with the format
                                % if it succeeds then rethrow the same exception.
                                verifyFormat(inputFmt,tz);
                                rethrow(ME);
                            end
                        else
                            if supplied.Format, tryFmts = {fmt}; end
                            [thisData,inputFmt] = guessFormat(inData,tryFmts,1,tz,locale,pivot);
                        end
                    catch ME
                        if ME.identifier == "MATLAB:datetime:ParseErrs"
                            handleParseErrors(inData,supplied,fmt,inputFmt,locale);
                        else
                            throw(ME)
                        end
                    end
                    if ~supplied.Format
                        if preserveInputFmt
                            fmt = inputFmt;
                        end
                    end
                end

            elseif isa(inData,'datetime') % construct from an array of datetimes
                % Take values from the input array rather than from the defaults.
                if ~supplied.Format, fmt = inData.fmt; end
                if ~supplied.TimeZone, tz = inData.tz; end

                % Adjust for a new time zone.
                thisData = timeZoneAdjustment(inData.data,inData.tz,tz);

            else
                error(message('MATLAB:datetime:InvalidData'));
            end
            this.data = thisData;
            this.fmt = fmt;
            this.tz = tz;
        end

        %% Conversions to numeric types
        % No direct conversions, need to subtract a time origin

        %% Conversions to string types
        function s = char(this,format,locale)
            import matlab.internal.datetime.getDatetimeSettings
            import matlab.internal.datetime.formatAsString
            import matlab.internal.datetime.verifyLocale
            import matlab.internal.datetime.validateFormatTokens

            if nargin < 2 || isequal(format,[])
                format = getDisplayFormat(this);
            else
                format = validateFormatTokens(format,false,true);
            end

            try
                if nargin < 3 || isequal(locale,[])
                    s = char(formatAsString(this.data,format,this.tz,false,getDatetimeSettings('locale')));
                else
                    s = char(formatAsString(this.data,format,this.tz,false,verifyLocale(locale)));
                end
            catch ME
                % First call verifyFormat to check for any issues with the format
                % if it succeeds then rethrow the same exception.
                verifyFormat(format,this.tz);
                rethrow(ME);
            end
        end

        function c = cellstr(this,format,locale)
            import matlab.internal.datetime.getDatetimeSettings
            import matlab.internal.datetime.formatAsString
            import matlab.internal.datetime.verifyLocale
            import matlab.internal.datetime.validateFormatTokens

            if nargin < 2 || isequal(format,[])
                format = getDisplayFormat(this);
            else
                format = validateFormatTokens(format,false,true);
            end
            try
                if nargin < 3 || isequal(locale,[])
                    c = formatAsString(this.data,format,this.tz,false,getDatetimeSettings('locale'));
                else
                    c = formatAsString(this.data,format,this.tz,false,verifyLocale(locale));
                end
            catch ME
                % First call verifyFormat to check for any issues with the format
                % if it succeeds then rethrow the same exception.
                verifyFormat(format,this.tz);
                rethrow(ME);
            end
        end

        function s = string(this,format,locale)
            import matlab.internal.datetime.getDatetimeSettings
            import matlab.internal.datetime.formatAsString
            import matlab.internal.datetime.verifyLocale
            import matlab.internal.datetime.validateFormatTokens

            if nargin < 2 || isequal(format,[])
                format = getDisplayFormat(this);
            else
                format = validateFormatTokens(format,false,true);
            end
            try
                if nargin < 3 || isequal(locale,[])
                    s = formatAsString(this.data,format,this.tz,true,getDatetimeSettings('locale'));
                else
                    s = formatAsString(this.data,format,this.tz,true,verifyLocale(locale));
                end
            catch ME
                % First call verifyFormat to check for any issues with the format
                % if it succeeds then rethrow the same exception.
                verifyFormat(format,this.tz);
                rethrow(ME);
            end

            % Convert 'NaT' to missing string. String method is a
            % conversion, not a text representation, and thus NaT should be
            % converted to its equivalent in string, which is the missing
            % string.
            s(isnat(this)) = string(missing);
        end

        %% Conversions to the legacy types
        function dn = datenum(this)
            %

            % Convert to unzoned, no leap seconds.
            thisData = timeZoneAdjustment(this.data,this.tz,'');

            % Get the day number (including fractional days) since 0-Jan-0000 00:00:00.
            millisPerDay = 86400*1000;
            datenumOffset = datetime.epochDN*millisPerDay;
            dn = (real(thisData) + datenumOffset) / millisPerDay; % round trip exact up to ms
        end

        function s = datestr(this,varargin)
            s = datestr(datenum(this),varargin{:}); %#ok<DATNM,DATST> 
        end

        function [y,mo,d,h,m,s] = datevec(this)
            %

            % This preserves the zoned component values.
            if nargout <= 1
                y = matlab.internal.datetime.getDateVec(this.data,this.tz);
            else
                [y,mo,d,h,m,s] = matlab.internal.datetime.getDateVec(this.data,this.tz);
            end
        end

        %% Conversions to other time types
        function jd = juliandate(this,kind)
            import matlab.internal.datatypes.getChoice;
            if nargin == 1
                kind = 1;
            else
                kind = getChoice(kind,["juliandate" "jd" "modifiedjuliandate" "mjd"],[1 1 2 2], ...
                    "MATLAB:datetime:InvalidJulianDateType");
            end
            % This does not try to account for JD(UTC) vs. JD(UT1) vs. JD(TT), it simply
            % accepts the date/time components as is. The one exception is that for a
            % datetime set to 'UTCLeapSeconds', the fractional part of the JD on a day
            % with a leap second is normalized by 86401, not 86400. For JD, those are
            % [noon-noon) "days", for MJD they are [midnight-midnight) days.
            ucal = datetime.dateFields;
            if (kind == 1)
                jd = matlab.internal.datetime.getDateFields(this.data,ucal.JULIAN_DATE,this.tz);
            else
                jd = matlab.internal.datetime.getDateFields(this.data,ucal.MODIFIED_JULIAN_DATE,this.tz);
            end
        end

        function p = posixtime(this)
            millisPerSec = 1000;
            thisData = this.data;
            if (this.tz == datetime.UTCLeapSecsZoneID)
                % POSIX time doesn't count leap seconds, remove them.
                [thisData,isLeapSec] = matlab.internal.datetime.removeLeapSeconds(thisData);
                % The POSIX time during a leap second is defined equal to the corresponding
                % time in 0th second of the next minute, so shift those times ahead one second.
                thisData = matlab.internal.datetime.datetimeAdd(thisData,millisPerSec*isLeapSec);
            end
            p = real(thisData) / millisPerSec; % ms -> s
        end

        function e = exceltime(this,timeSystem)
            thisData = timeZoneAdjustment(this.data,this.tz,'');
            millisPerDay = 86400*1000;
            excelOffset1900 = 25568 * millisPerDay;
            e = (real(thisData) + excelOffset1900) / millisPerDay; % consistent with datenum
            e = e + (e >= 60); % Correction for Excel's 1900 leap year bug
            if nargin > 1
                if (timeSystem == "1904") || isequal(timeSystem,1904)
                    e = e - 1462; % "1904" epoch is 0-Jan-1904
                elseif (timeSystem == "1900") || isequal(timeSystem,1900)
                    % OK
                else
                    error(message('MATLAB:datetime:exceltime:InvalidTimeSystem'));
                end
            end
            % There's no check here for out-of-range results, some find those useful.
        end

        function pd = yyyymmdd(this)
            ucal = datetime.dateFields;
            fieldIDs = [ucal.EXTENDED_YEAR ucal.MONTH ucal.DAY_OF_MONTH];
            [y,mo,d] = matlab.internal.datetime.getDateFields(this.data,fieldIDs,this.tz);
            if any(y < 1)
                % Gregorian calendar has no year zero, and there's no non-confusing
                % way to convert pre-01-Jan-0001 dates to yyyymmdd.
                error(message('MATLAB:datetime:YYYYMMDDConversionOutOfRange',char(datetime(1,1,1))));
            end
            pd = y*10000 + mo*100 + d;

            % Preserve Infs. These have become NaNs from NaNs in month/day
            % components. Use year, which will be the appropriate non-finite.
            nonfinites = ~isfinite(pd);
            pd(nonfinites) = y(nonfinites);
        end


        %% Date/time component methods
        % These return datetime components as integer values (and sometimes
        % names), except for seconds, which returns non-integer values

        function [y,m,d] = ymd(this)
            [y,m,d] = matlab.internal.datetime.getDateVec(this.data,this.tz,false); % only get y/m/d
        end

        function [h,m,s] = hms(this)
            [h,m,s] = matlab.internal.datetime.getDateVec(this.data,this.tz,true); % only get h/m/s
        end

        function y = year(this,kind)
            import matlab.internal.datatypes.getChoice;
            if nargin == 1
                kind = 1;
            else
                kind = getChoice(kind,["ISO" "Gregorian"],"MATLAB:datetime:InvalidYearType");
            end
            ucal = datetime.dateFields;
            fieldIDs = [ucal.EXTENDED_YEAR ucal.YEAR];
            y = matlab.internal.datetime.getDateFields(this.data,fieldIDs(kind),this.tz);
        end

        function q = quarter(this)
            ucal = datetime.dateFields;
            q = matlab.internal.datetime.getDateFields(this.data,ucal.QUARTER,this.tz);
        end

        function m = month(this,kind)
            import matlab.internal.datetime.getDatetimeSettings
            import matlab.internal.datetime.getMonthNames
            import matlab.internal.datatypes.getChoice;

            ucal = datetime.dateFields;
            fieldIDs = ucal.MONTH;
            m = matlab.internal.datetime.getDateFields(this.data,fieldIDs,this.tz);
            if nargin > 1
                kind = getChoice(kind,["MonthOfYear" "MoY" "Name" "LongName" "ShortName"],[1 1 2 2 3], ...
                    "MATLAB:datetime:InvalidMonthType");
                if kind > 1
                    if kind == 2
                        names = matlab.internal.datetime.getMonthNames('long', getDatetimeSettings('locale'));
                    else % kind == 3
                        names = matlab.internal.datetime.getMonthNames('short', getDatetimeSettings('locale'));
                    end
                    names{end+1} = ''; % return empty character vector for NaT
                    m(isnan(m)) = length(names);
                    m = reshape(names(m),size(this));
                end
            end
        end

        function w = week(this,kind)
            import matlab.internal.datatypes.getChoice;
            if nargin == 1
                kind = 1;
            else
                kind = getChoice(kind,["WeekOfYear" "WoY" "WeekOfMonth" "WoM" "ISO-WeekOfYear" "ISO-WoY" "ISO-WeekOfMonth" "ISO-WoM"], ...
                    [1 1 2 2 3 3 4 4], "MATLAB:datetime:InvalidWeekType");
            end
            if kind < 3
                ucal = datetime.dateFields;
                fieldIDs = [ucal.WEEK_OF_YEAR ucal.WEEK_OF_MONTH];
                w = matlab.internal.datetime.getDateFields(this.data,fieldIDs(kind),this.tz);
            elseif kind == 3 % ISO WoY
                ucal = datetime.dateFields;
                thisData = this.data(:);
                doy = matlab.internal.datetime.getDateFields(thisData,ucal.DAY_OF_YEAR,this.tz); % day(this,"doy");
                dow = matlab.internal.datetime.getDateFields(thisData,ucal.DAY_OF_WEEK,this.tz); dow = mod(dow-2,7) + 1; % day(this(:),"isodow");
                w = floor((10 + doy - dow)/7);

                % w==53 is a partial week possibly in next year: w((w==53)&(dow<4)) = 1. w==0 is a partial
                % week definitely in previous year: w(w==0) = [52 or 53]. Do both at same time, e.g.
                % https://webspace.science.uu.nl/~gent0113/calendar/isocalendar.htm. Credited to Amos
                % Shapir: "An ISO calendar year is long (53 ISO weeks) if and only if the corresponding
                % Gregorian year either begins or ends (or both) on a Thursday."
                y = matlab.internal.datetime.getDateFields(thisData,ucal.EXTENDED_YEAR,this.tz); % year(this(:),"iso")
                y = y - [2 1 0]; % previous^2, previous, current year
                dowEOY = mod(y + floor(y/4) - floor(y/100) + floor(y/400),7); % ISO day of week of 31 Dec
                longYear = (dowEOY(:,1:2)==3) | (dowEOY(:,2:3)==4); % prev/current year begins or ends on a Thu, thus has 53 ISO weeks
                nweeks = 52 + longYear; % number of ISO weeks in prev/current year
                w(w > nweeks(:,2)) = 1; % first week of next year
                i = (w == 0);
                w(i) = nweeks(i,1); % last week of prev year

                w = reshape(w,size(this));
            else % kind == 4, "ISO" WoM, similar computation to WoY above
                thisSize = size(this.data);
                this.data = this.data(:);
                dom = day(this,"dom");
                dow = day(this,"iso-dow");
                w = floor((10 + dom - dow)/7);

                % w==5 is a partial week possibly in next month: w((w>[4 or 5]) = 1. w==0 is a partial
                % week definitely in previous month: w(w==0) = [4 or 5]. Do both at same time: a calendar
                % month is long (5 ISO weeks) iff there are more than 27 days following its first Thursday.
                firstDOM = [dateshift(this,"start","month","prev") dateshift(this,"start","month")]; % first day in prev/current month
                firstThu = dateshift(firstDOM,"dayofweek",5); % first thursday in prev/current month
                lastDOM = dateshift(firstThu,"end","month"); % last day in prev/current month
                longMonth = (day(lastDOM,"dom") - day(firstThu,"dom")) > 27; % prev/curr month has 5 ISO weeks
                nweeks = 4 + longMonth; % number of ISO weeks in prev/current month
                w(w > nweeks(:,2)) = 1; % first week of next month
                i = (w == 0);
                w(i) = nweeks(i,1); % last week of prev month

                w = reshape(w,thisSize);
            end
        end

        function d = day(this,kind) % DoM, DoY, DoW, ShortName, LongName
            import matlab.internal.datetime.getDatetimeSettings
            import matlab.internal.datetime.getDayNames
            import matlab.internal.datatypes.getChoice;

            if nargin == 1
                kind = 1;
            else
                kind = getChoice(kind,["DayOfMonth" "DoM" "DayOfWeek" "DoW" "ISO-DayOfWeek" "ISO-DoW" "DayOfYear" "DoY" "Name" "LongName" "ShortName"], ...
                    [1 1 2 2 3 3 4 4 5 5 6 6],"MATLAB:datetime:InvalidDayType");
            end
            ucal = datetime.dateFields;
            fieldIDs = [ucal.DAY_OF_MONTH ucal.DAY_OF_WEEK ucal.DAY_OF_WEEK ucal.DAY_OF_YEAR ucal.DAY_OF_WEEK ucal.DAY_OF_WEEK];
            d = matlab.internal.datetime.getDateFields(this.data,fieldIDs(kind),this.tz);

            if kind == 3 % ISO
                d = mod(d-2,7) + 1; % 1==Sun -> 1==Mon
            elseif kind > 4
                if kind == 5
                    names = getDayNames('long', getDatetimeSettings('locale'));
                else % kind == 6
                    names = getDayNames('short', getDatetimeSettings('locale'));
                end
                names{end+1} = ''; % return empty character vector for NaT
                d(isnan(d)) = length(names);
                d = reshape(names(d),size(this.data));
            end
        end

        function h = hour(this)
            ucal = datetime.dateFields;
            h = matlab.internal.datetime.getDateFields(this.data,ucal.HOUR_OF_DAY,this.tz);
        end

        function m = minute(this)
            ucal = datetime.dateFields;
            m = matlab.internal.datetime.getDateFields(this.data,ucal.MINUTE,this.tz);
        end

        function s = second(this,kind)
            import matlab.internal.datatypes.getChoice;
            if nargin == 1
                kind = 1;
            else
                kind = getChoice(kind,["SecondOfMinute" "SoM" "SecondOfDay" "SoD"],[1 1 2 2], ...
                    "MATLAB:datetime:InvalidSecondType");
            end
            ucal = datetime.dateFields;
            if kind == 1 % second+fraction within current minute
                s = matlab.internal.datetime.getDateFields(this.data,ucal.SECOND,this.tz);
            else         % second+fraction within current day
                s = matlab.internal.datetime.getDateFields(this.data,ucal.MILLISECOND_OF_DAY,this.tz) / 1000;
            end
        end

        function [tod,date] = timeofday(this)
            date = dateshift(this,'start','day');
            tod = this - date;
        end

        function [tz,dst] = tzoffset(this)
            if isempty(this.tz)
                tz = NaN(size(this.data));
                dst = tz;
            else
                ucal = datetime.dateFields;
                [tz,dst] = matlab.internal.datetime.getDateFields(this.data,[ucal.ZONE_OFFSET ucal.DST_OFFSET],this.tz);
            end
            % Add the raw offset and the DST offset to get the total offset
            tz = duration.fromMillis(1000*(tz+dst),'hh:mm');
            if nargout > 1
                dst = duration.fromMillis(1000*dst,'hh:mm');
            end
        end

        % no need for eomday method, that's day(dateshift(t,'end','month'))
        % no need for weekday method, that's day(t,'dayofweek')

        % These return logicals

        function tf = isweekend(this)
            ucal = datetime.dateFields;
            dow = matlab.internal.datetime.getDateFields(this.data,ucal.DAY_OF_WEEK,this.tz);
            tf = (dow == 1) | (dow == 7); % Sunday is always day 1, regardless of locale
        end

        function tf = isdst(this)
            ucal = datetime.dateFields;
            tf = matlab.internal.datetime.getDateFields(this.data,ucal.DST_OFFSET,this.tz) ~= 0;
            tf(isnan(this.data)) = false;
        end


        %% Array methods
        function [varargout] = size(this,varargin)
            [varargout{1:nargout}] = size(this.data,varargin{:});
        end
        function l = length(this)
            l = length(this.data);
        end
        function n = ndims(this)
            n = ndims(this.data);
        end

        function n = numel(this,varargin)
            if nargin == 1
                n = numel(this.data);
            else
                n = numel(this.data,varargin{:});
            end
        end

        function t = isempty(a),  t = isempty(a.data);  end
        function t = isscalar(a), t = isscalar(a.data); end
        function t = isvector(a), t = isvector(a.data); end
        function t = isrow(a),    t = isrow(a.data);    end
        function t = iscolumn(a), t = iscolumn(a.data); end
        function t = ismatrix(a), t = ismatrix(a.data); end

        function result = cat(dim,varargin)
            if ~isnumeric(dim)
                error(message('MATLAB:datetime:cat:NonNumericDim'))
            end
            try
                [argsData,result] = datetime.catUtil(varargin);
                result.data = cat(dim,argsData{:}); % use fmt/tz from the first array
            catch ME
                throw(ME);
            end
        end
        function result = horzcat(varargin)
            try
                [argsData,result] = datetime.catUtil(varargin);
                result.data = horzcat(argsData{:});
            catch ME
                throw(ME);
            end
        end
        function result = vertcat(varargin)
            try
                [argsData,result] = datetime.catUtil(varargin);
                result.data = vertcat(argsData{:});
            catch ME
                throw(ME);
            end
        end

        function this = ctranspose(this)
            try
                this.data = transpose(this.data); % NOT ctranspose
            catch ME
                throw(ME);
            end
        end
        function this = transpose(this)
            try
                this.data = transpose(this.data);
            catch ME
                throw(ME);
            end
        end
        function this = reshape(this,varargin)
            this.data = reshape(this.data,varargin{:});
        end
        function this = permute(this,order)
            this.data = permute(this.data,order);
        end

        %% Relational operators
        function t = eq(a,b)
            try
                [aData,bData] = datetime.compareUtil(a,b);
                t = relopSign(aData,bData) == 0;
            catch ME
                throw(ME);
            end
        end

        function t = ne(a,b)
            try
                [aData,bData] = datetime.compareUtil(a,b);
                t = relopSign(aData,bData) ~= 0;
            catch ME
                throw(ME);
            end
        end

        function t = lt(a,b)
            try
                [aData,bData] = datetime.compareUtil(a,b);
                t = relopSign(aData,bData) < 0;
            catch ME
                throw(ME);
            end
        end

        function t = le(a,b)
            try
                [aData,bData] = datetime.compareUtil(a,b);
                t = relopSign(aData,bData) <= 0;
            catch ME
                throw(ME);
            end
        end

        function t = ge(a,b)
            try
                [aData,bData] = datetime.compareUtil(a,b);
                t = relopSign(aData,bData) >= 0;
            catch ME
                throw(ME);
            end
        end

        function t = gt(a,b)
            try
                [aData,bData] = datetime.compareUtil(a,b);
                t = relopSign(aData,bData) > 0;
            catch ME
                throw(ME);
            end
        end

        function t = isequal(varargin)
            narginchk(2,Inf);
            try
                argsData = datetime.isequalUtil(varargin);
            catch ME
                if ME.identifier == "MATLAB:datetime:InvalidComparison"
                    % silently return false
                elseif any(matches(ME.identifier,["MATLAB:datetime:IncompatibleTZ" "MATLAB:datetime:IncompatibleTZLeapSeconds"]))
                    % silently return false
                elseif any(matches(ME.identifier,["MATLAB:datetime:AutoConvertString" "MATLAB:datetime:AutoConvertStrings"]))
                    warning(message('MATLAB:datetime:AutoConvertStrings'));
                else
                    throw(ME);
                end
                t = false;
                return
            end
            t = isequal(argsData{:});
        end

        function t = isequaln(varargin)
            narginchk(2,Inf);

            % Ensure the logic to check equality is consistent between isequaln and
            % keyMatch.
            try
                argsData = datetime.isequalUtil(varargin);
            catch ME
                if ME.identifier == "MATLAB:datetime:InvalidComparison"
                    % silently return false
                elseif matches(ME.identifier,["MATLAB:datetime:IncompatibleTZ" "MATLAB:datetime:IncompatibleTZLeapSeconds"])
                    % silently return false
                elseif matches(ME.identifier,["MATLAB:datetime:AutoConvertString" "MATLAB:datetime:AutoConvertStrings"])
                    warning(message('MATLAB:datetime:AutoConvertStrings'));
                else
                    throw(ME);
                end
                t = false;
                return
            end
            t = isequaln(argsData{:});
        end

        function t = keyMatch(d1,d2)
            if isa(d1,"datetime") && isa(d2,"datetime")
                d1Unzoned = isempty(d1.tz);
                d1LeapSecs = (d1.tz == datetime.UTCLeapSecsZoneID);
                % Check the internal data property if two datetimes are
                % comparable. Datetimes are considered comparable if either both
                % are unzoned or zoned. If both are zoned and one of them has
                % UTCLeapSeconds as its timezone, then the other one should also
                % have the same timezone.
                if (isempty(d2.tz) == d1Unzoned)
                    if d1Unzoned || ((d2.tz == datetime.UTCLeapSecsZoneID) == d1LeapSecs)
                        t = isequaln(d1.data,d2.data);
                    else
                        t = false;
                    end
                else
                    t = false;
                end
            else
                t = false;
            end
        end

        function h = keyHash(d)
            h = keyHash(d.data);
        end

    end % public methods block

    %=======================================================================
    methods(Access='public',Hidden)
        %% Arrayness
        function n = end(this,k,n)
            try
                n = builtin('end',this.data,k,n);
            catch ME
                throw(ME);
            end
        end

        %% Format
        function tf = hasDefaultFormat(this)
            % This function is for internal use only and will change in a
            % future release. Do not use this function.
            tf = isempty(this.fmt);
        end

        %% For createArray
        function d = createArrayLike(template, sz, fillval)
            % This function is for internal use only and will change in a future release.
            % Do not use this function.
            arguments
                template
                sz
                % Use missing as the default fill value instead of NaT to
                % ensure createArray doesn't error when the template is a
                % zoned datetime.
                fillval = missing;
            end
            d = matlab.internal.datatypes.createArrayLike(template, sz, fillval);
        end

        %% Subscripting
        this = subsasgn(this,s,rhs)
        that = subsref(this,s)
        that = parenReference(this,rowIndices,colIndices,varargin)
        this = parenAssign(this,that,rowIndices,colIndices,varargin)

        function sz = numArgumentsFromSubscript(~,~,~)
            % This function is for internal use only and will change in a
            % future release. Do not use this function.
            sz = 1;
        end

        %% Variable Editor methods
        % These functions are for internal use only and will change in a
        % future release. Do not use this function.
        [out,warnmsg] = variableEditorClearDataCode(this, varname, rowIntervals, colIntervals)
        [out,warnmsg] = variableEditorColumnDeleteCode(this, varName, colIntervals)
        out = variableEditorInsert(this, orientation, row, col, data)
        metadata = variableEditorMetadata(this)
        [out,warnmsg] = variableEditorMetadataCode(this, varName, index, propertyName, propertyString)
        out = variableEditorPaste(this, rows, columns, data)
        [out,warnmsg] = variableEditorRowDeleteCode(this, varName, rowIntervals)
        [out,warnmsg] = variableEditorSetDataCode(this, varname, row, col, rhs)
        [out,warnmsg] = variableEditorSortCode(~, varName, columnIndexStrings, direction)

        %% Error stubs
        % Methods to override functions and throw helpful errors
        function d = double(d), error(message('MATLAB:datetime:InvalidNumericConversion','double')); end %#ok<MANU>
        function d = single(d), error(message('MATLAB:datetime:InvalidNumericConversion','single')); end %#ok<MANU>
        function d = months(varargin), error(message('MATLAB:datetime:NoMonthsMethod')); end %#ok<STOUT>
        function d = timezone(d), error(message('MATLAB:datetime:NoTimeZoneMethod')); end %#ok<MANU>
        function d = format(d), error(message('MATLAB:datetime:NoFormatMethod')); end %#ok<MANU>
        function d = floor(varargin), error(message('MATLAB:datetime:UseDateshiftMethod','floor')); end %#ok<STOUT>
        function d = ceil(varargin), error(message('MATLAB:datetime:UseDateshiftMethod','ceil')); end %#ok<STOUT>
        function d = round(varargin), error(message('MATLAB:datetime:UseDateshiftMethod','round')); end %#ok<STOUT>
        function d = isuniform(d), error(message('MATLAB:datatypes:UseIsRegularMethod',mfilename)); end %#ok<MANU> 
    end % hidden public methods block

    %=======================================================================
    methods(Access='public', Static)
        setDefaultFormats(format,formatStr)
    end

    %=======================================================================
    methods(Access='public', Static, Hidden)
        function d = empty(varargin)
            d = datetime(); % fastest constructor call
            if nargin == 0
                dData = [];
            else
                dData = zeros(varargin{:});
                if numel(dData) ~= 0
                    error(message('MATLAB:class:emptyMustBeZero'));
                end
            end
            d.data = dData;
        end

        function tzs = allTimeZones()
            % This function is for internal use only and will change in a
            % future release. Do not use this function.
            tzs = cell2table(matlab.internal.datetime.getDefaults('TimeZones'), ...
                'VariableNames',{'Name' 'CanonicalName' 'UTCOffset' 'DSTOffset'});
        end

        function t = fromMillis(data,format,tz)
            % This function is for internal use only and will change in a
            % future release. Do not use this function.
            % Create a datetime with a format and time zone "like" another one,
            % or with specific format and tz.

            % Maintain a persistent copy of a scalar datetime that can be used
            % as a template when the caller does not provide one. This helps us
            % avoid calling datetime ctor for every call to fromMillis.
            persistent dtTemplate
            if isempty(dtTemplate)
                % We just need a datetime object with default values for fmt
                % and tz. The data will always be overwritten.
                dtTemplate = datetime(0,0,0);
            end

            haveTemplate = (nargin > 1) && isa(format,'datetime');
            if haveTemplate
                % Passing a template allows fromMillis to preserve a "default
                % format" setting (i.e. '') of an existing datetime. Otherwise a
                % caller would need to ask the datetime for its format, which would
                % return an explicit format, thus the output would not have the
                % "default format" setting.
                t = format; % 2nd arg is the template, not a format
            else
                t = dtTemplate;
                if nargin > 1
                    t.fmt = format;
                    if nargin > 2
                        t.tz = tz;
                    end
                end
            end
            t.data = data;
        end

        function [t,fmt,tz] = toMillis(this,zeroLowPart)
            % This function is for internal use only and will change in a
            % future release. Do not use this function.
            t = this.data;
            fmt = this.fmt;
            tz = this.tz;
            if nargin == 2 && zeroLowPart
                t = real(t);
            end
        end

        function fmt = getDefaultFormatForLocale(locale)
            % This function is for internal use only and will change in a
            % future release. Do not use this function.
            if nargin == 0
                locale = matlab.internal.datetime.getDefaults('locale');
            else
                locale = matlab.internal.datetime.verifyLocale(locale);
            end
            fmt = matlab.internal.datetime.getDefaults('localeformat',locale,'uuuuMMdd');
        end

        function setLocalTimeZone(tz)
            % This function is for internal use only and will change in a
            % future release. Do not use this function.
            if nargin == 0, tz = []; end
            datetime.getsetLocalTimeZone(tz);
        end

        function name = matlabCodegenRedirect(~)
            % Use the implementation in the class below when generating
            % code.
            name = 'matlab.internal.coder.datetime';
        end


        function d = codegenInit(data, fmt, tz)
            % In codegen empty char arrays are size 1 by 0. If these
            % fields are empty, make sure they return to MATLAB as 0 by 0.
            if isempty(fmt)
                fmt = '';
            end
            if isempty(tz)
                tz = '';
            end

            d = datetime.fromMillis(data,fmt,tz);
        end
    end % hidden static public methods block

    %=======================================================================
    methods(Access={?matlab.internal.tabular.private.explicitRowTimesDim, ?withtol})
        inds = timesubs2inds(subscripts,labels,tol)
    end

    %=======================================================================
    methods(Access='protected')
        this = subsasgnDot(this,s,rhs)
        this = subsasgnParens(this,s,rhs)
        value = subsrefDot(this,s)
        value = subsrefParens(this,s)
        fmt = getDisplayFormat(this)

        %-----------------------------------------------------------------------
        function chars = formatAsCharForDisplay(this)
            import matlab.internal.datetime.formatAsString
            import matlab.internal.datetime.getDatetimeSettings
            
            % Use the string display to remove possible new lines from the format.
            dispFmt = getDisplayFormat(this);
            dispFmt = matlab.internal.display.truncateLine(dispFmt,2*numel(dispFmt));
            chars = char(formatAsString(this.data,dispFmt,this.tz,false,getDatetimeSettings('locale')));
        end

        %-----------------------------------------------------------------------
        function missingText = getMissingTextDisplay(~)
            missingText = "NaT";
        end

        %-----------------------------------------------------------------------
        function [hasTime,hasFracSecs] = getDisplayResolution(this)
            domField = datetime.dateFields.DAY_OF_MONTH;
            wholeDayMillis = matlab.internal.datetime.datetimeFloor(this.data,domField,this.tz);
            fracDayMillis = matlab.internal.datetime.datetimeSubtract(this.data,wholeDayMillis,false); % non-negative
            if all(isnan(fracDayMillis),'all')
                % "All NaT" arbitrarily treated as "time, but no fractional seconds".
                hasTime = true;
                hasFracSecs = false;
            else
                % Otherwise NaT is ignored.
                hasTime = any(fracDayMillis > 0,'all');
                if nargout > 1
                    fracSecMillis = fracDayMillis - floor(fracDayMillis./1000).*1000; % non-negative
                    hasFracSecs = any(fracSecMillis > 0,'all');
                end
            end
        end
    end % protected methods block

    %=======================================================================
    methods(Access='protected', Static)
        [a,b,prototype] = compareUtil(a,b)
        [a,b] = arithUtil(a,b)
        [args,prototype] = isequalUtil(args)
        t = convertFrom(value,type,tz,epoch,ticksPerSec)

        function [args, prototype] = catUtil(args)
            try
                [args,prototype] = datetime.isequalUtil(args);
            catch ME
                if ME.identifier == "MATLAB:datetime:IncompatibleTZ"
                    error(message('MATLAB:datetime:cat:IncompatibleTZ'));
                elseif ME.identifier == "MATLAB:datetime:InvalidComparison"
                    error(message('MATLAB:datetime:cat:InvalidConcatenation'));
                else
                    throw(ME);
                end
            end
        end

        function [tz,noClientOverride] = getsetLocalTimeZone(tz)
            import matlab.internal.datetime.getDefaults

            persistent clientOverride  % canonicalized client override, may be []
            persistent systemTZ % canonicalized system setting
            persistent rawTZ    % uncanonicalized system setting or client override

            if isempty(systemTZ) % first time called
                rawTZ = getDefaults('SystemTimeZone');
                [systemTZ,rawTZ] = canonicalizeTZforLocal(rawTZ);
            end

            if nargout > 0 % get syntax
                if nargin == 0
                    % return the "current" value that should be used for 'local'
                    noClientOverride = isempty(clientOverride);
                    if noClientOverride
                        tz = systemTZ;
                    else
                        tz = clientOverride;
                    end
                elseif tz == "canonical"
                    % currentTime needs the actual system setting, avoiding warnings
                    tz = systemTZ;
                elseif tz == "uncanonical"
                    % verifyTimeZone needs the original value to possibly warn about it
                    tz = rawTZ;
                else
                    assert(false);
                end
            else % set syntax
                if isequal(tz,[]) % remove the client override
                    clientOverride = [];
                    rawTZ = getDefaults('SystemTimeZone');
                    munlock % no longer strictly necessary
                else % setting a client override
                    mlock % do this only when necessary to preserve the client override
                    [clientOverride,rawTZ] = canonicalizeTZforLocal(tz);
                end
            end
        end
    end % static protected methods block

    methods (Access=?timerange)
        function fmt = defaultFormat(dt)
            % 
            
            % Get the default format (date + time) for the given datetime.
            % This would be the default format from the preference panel
            % for most datetimes or it would be the required format for
            % cases that enforce a special format requirement.
            if (dt.tz == datetime.UTCLeapSecsZoneID)
                fmt = dt.fmt;
            else
                fmt = matlab.internal.datetime.getDatetimeSettings('defaultformat');
            end
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access='public', Static, Hidden)
        modifyOutgoingSerializationContent(sObj, obj, context)
        modifyIncomingSerializationContent(sObj)
    end

    %======================= Testing Infrastructure ========================
    properties(GetAccess=?matlab.unittest.TestCase, Constant)
        dateFields = initDateFieldsStructure;
        noConstructorParamsSupplied = struct('ConvertFrom',false, 'InputFormat',false, 'Format',false, 'TimeZone',false, 'Locale',false, 'PivotYear',false, 'Epoch',false, 'TicksPerSecond',false);
    end

    methods(Static, Access=?matlab.unittest.TestCase)
        function methodList = methodsWithNonDatetimeFirstArgument, methodList = {'setDefaultFormats','cat'}; end
    end
end % classdef


%%%%%%%%%%%%%%%%% Local functions %%%%%%%%%%%%%%%%%

%-----------------------------------------------------------------------
function [canonicalTZ,tz] = canonicalizeTZforLocal(tz)
import matlab.internal.datetime.getCanonicalTZ

try
    % Validate a time zone to use as the local setting. getCanonicalTZ will error if
    % it's invalid, and we fall back to UTC with a warning. Tell getCanonicalTZ to
    % not warn if it's just non-standard, because many places we just need the offset.
    % But use of 'local' later on (e.g. datetime('now','TimeZone','local') will still
    % lead (once) to a warning from verifyTimeZone if the tz is non-standard.
    canonicalTZ = getCanonicalTZ(tz,false);
catch ME
    if ME.identifier == "MATLAB:datetime:UnknownTimeZone"
        warning(message('MATLAB:datetime:InvalidSystemTimeZone',tz));
        tz = datetime.UTCZoneID;
        canonicalTZ = tz;
    else
        throwAsCaller(ME);
    end
end
end

%-----------------------------------------------------------------------
function pivot = verifyPivot(pivot)

import matlab.internal.datatypes.isScalarInt

if ~isScalarInt(pivot)
    error(message('MATLAB:datetime:InvalidPivotYear'));
end
end

%-----------------------------------------------------------------------
function thisData = currentTime(tz)
try %#ok<ALIGN>
    if nargin == 0 || isempty(tz) % unzoned
        [localTZ,noClientOverride] = datetime.getsetLocalTimeZone();
        if noClientOverride
            % Get the posix time (not leap-second-aware) adjusted to the local time
            % zone's offset.
            thisData = matlab.internal.datetime.millisSinceEpoch(true);

            % For unzoned, millisSinceEpoch automatically returns a "pretty" value for
            % which (today + (now - today)) is equal to now, don't need to normalize.
        else
            % If there's a client value set to override the system time zone setting,
            % get the posix (UTC) time (not leap-second-aware) and shift it to an unzoned
            % value in the client time zone.
            thisData = matlab.internal.datetime.millisSinceEpoch();
            thisData = timeZoneAdjustment(thisData,localTZ,'');
            thisData = renormalize(thisData,localTZ); % See comment below.
        end
    else
        % Get the posix (UTC) time (not leap-second-aware), no time zone adjustment is needed.
        thisData = matlab.internal.datetime.millisSinceEpoch();
        if tz == "UTC"
            % OK, no (re)normaliztion needed
        elseif tz == datetime.UTCLeapSecsZoneID
            % The internal value was created without accounting for leap seconds, add them.
            thisData = matlab.internal.datetime.addLeapSeconds(thisData);
        else
            % For cosmetics, want (today + (now - today)) equal to now. For UTC,
            % millisSinceEpoch already does that, don't need to renormalize. For zoned not
            % UTC, millisSinceEpoch can't easily get tz's today, so renormalize here.
            thisData = renormalize(thisData,tz);
        end
    end
catch ME, throwAsCaller(ME), end
end
function thisData = renormalize(thisData,tz)
t0 = matlab.internal.datetime.datetimeFloor(thisData,13,tz); % datetime.dateFields.DAY_OF_MONTH == 13
dt = matlab.internal.datetime.datetimeSubtract(thisData,t0);
thisData = matlab.internal.datetime.datetimeAdd(t0,dt);
end

%-----------------------------------------------------------------------
function inData = expandNumericInputs(inData)
sz = [1 1];
for i = 1:length(inData)
    field = inData{i};
    if ~isscalar(field)
        sz = size(field);
        break
    end
end
for i = 1:length(inData)
    field = inData{i};
    if isscalar(field)
        inData{i} = repmat(full(double(field)),sz);
    else % let createFromDateVec check for size mismatch
        inData{i} = full(double(field));
    end
end
end

%-----------------------------------------------------------------------
function handleParseErrors(inData,supplied,fmt,inputFmt,locale)

try %#ok<ALIGN>
    if isempty(locale)
        locale = matlab.internal.datetime.getDefaults('locale');
    end
    if supplied.InputFormat || supplied.Format
        if supplied.InputFormat, fmt = inputFmt; end
        if supplied.Locale
            if isscalar(inData)
                error(message('MATLAB:datetime:ParseErrWithLocale',inData{1},fmt,locale));
            else
                error(message('MATLAB:datetime:ParseErrsWithLocale',fmt,locale));
            end
        elseif ~isempty(regexp(fmt,'[eMz]{3,}','match','once'))
            if isscalar(inData)
                error(message('MATLAB:datetime:ParseErrSuggestLocale',inData{1},fmt,locale));
            else
                error(message('MATLAB:datetime:ParseErrsSuggestLocale',fmt,locale));
            end
        else
            if isscalar(inData)
                error(message('MATLAB:datetime:ParseErr',inData{1},fmt));
            else
                error(message('MATLAB:datetime:ParseErrs',fmt));
            end
        end
    else % guessing a format
        if supplied.Locale
            if isscalar(inData)
                error(message('MATLAB:datetime:UnrecognizedDateStringWithLocale',inData{1},locale));
            else
                error(message('MATLAB:datetime:UnrecognizedDateStringsWithLocale',locale));
            end
        else
            if isscalar(inData)
                error(message('MATLAB:datetime:UnrecognizedDateStringSuggestLocale',inData{1},locale));
            else
                error(message('MATLAB:datetime:UnrecognizedDateStringsSuggestLocale',locale));
            end
        end
    end

catch ME, throwAsCaller(ME); end
end

%-----------------------------------------------------------------------
function ds = initDateFieldsStructure
ds = struct( ...
    'ERA', 1, ...
    'JULIAN_DATE', 2, ...
    'MODIFIED_JULIAN_DATE', 3, ...
    'EXTENDED_YEAR', 4, ... % Map datetime component 'Year' to ICU 'EXTENDED_YEAR'
    'Year', 4, ...          % Map datetime component 'Year' to ICU 'EXTENDED_YEAR'
    'YEAR', 5, ...
    'YEAR_WOY', 6, ...
    'QUARTER', 7, ...
    'MONTH', 8, ... % Map datetime component 'Month' to ICU 'MONTH'
    'Month', 8, ... % Map datetime component 'Month' to ICU 'MONTH'
    'IS_LEAP_MONTH', 9, ...
    'WEEK_OF_YEAR', 10, ...
    'WEEK_OF_MONTH', 11, ...
    'DATE', 12, ...
    'DAY_OF_MONTH', 13, ... % Map datetime component 'Day' to ICU 'DAY_OF_MONTH'
    'Day', 13, ...          % Map datetime component 'Day' to ICU 'DAY_OF_MONTH'
    'DAY_OF_YEAR', 14, ...
    'DAY_OF_WEEK', 15, ...
    'DAY_OF_WEEK_IN_MONTH', 16, ...
    'AM_PM', 17, ...
    'HOUR', 18, ...
    'HOUR_OF_DAY', 19, ... % Map datetime component 'Hour' to ICU 'HOUR_OF_DAY'
    'Hour', 19, ...        % Map datetime component 'Hour' to ICU 'HOUR_OF_DAY'
    'MINUTE', 20, ... % Map datetime component 'Minute' to ICU 'MINUTE'
    'Minute', 20, ... % Map datetime component 'Minute' to ICU 'MINUTE'
    'SECOND', 21, ... % Map datetime component 'Second' to ICU 'SECOND'
    'Second', 21, ... % Map datetime component 'Second' to ICU 'SECOND'
    'MILLISECOND_OF_DAY', 22, ...
    'ZONE_OFFSET', 23, ...
    'DST_OFFSET', 24);
end
