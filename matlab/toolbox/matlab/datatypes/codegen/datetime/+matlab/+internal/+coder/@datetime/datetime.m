%#codegen
classdef (Sealed, InferiorClasses = {?matlab.internal.coder.duration}) datetime < coder.mixin.internal.indexing.Paren  & ...
         coder.mixin.internal.indexing.ParenAssignSupportInParfor &...
         coder.mixin.internal.SpoofReport
    %DATETIME Arrays to represent dates and times.
    %   datetime arrays store values that represent points in time, including a date
    %   and a time of day. Use the DATETIME constructor to create an array of datetimes
    %   from strings, character vectors, or from vectors of date/time components.
    %   Use DATETIME('now'), DATETIME('today'), DATETIME('yesterday'), or DATETIME('tomorrow')
    %   to create scalar datetimes at or around the current moment.
    %
    %   You can subscript and manipulate datetime arrays just like ordinary numeric
    %   arrays. Datetime arrays also support sorting and comparison, mathematical
    %   calculations, as well as operations involving date and time components.
    %
    %   Each element of a datetime array represents one point in time. Use a
    %   duration array to represent lengths of time in fixed-length time units.
    %   Use a calendarDuration array to represent lengths of time in terms of
    %   flexible-length calendar units.
    %
    %   A datetime array T has properties that store metadata, such as the display
    %   format, and properties that allow you to access and modify the array's
    %   values via its date/time components. Access or assign to a property using
    %   P = T.PropName or T.PropName = P, where PropName is one of the following:
    %
    %   DATETIME properties:
    %       Format   - A character vector or string scalar describing the
    %                  format in which the array's values display.
    %       TimeZone - A character vector or string scalar representing the
    %                  time zone in which the array's values are interpreted.
    %       Year     - An array containing each element's year number.
    %       Month    - An array containing each element's month number.
    %       Day      - An array containing each element's day of month number.
    %       Hour     - An array containing each element's hour.
    %       Minute   - An array containing each element's minute.
    %       Second   - An array containing each element's second, including a
    %                  fractional part.
    %
    %   DATETIME methods and functions:
    %     Creating arrays of datetimes:
    %       datetime           - Create an array of datetimes.
    %       isdatetime         - True for a array of datetimes.
    %     Extract date and time components:
    %       ymd                - Year, month, and day numbers of datetimes.
    %       hms                - Hour, minute, and second numbers of datetimes.
    %       year               - Year numbers of datetimes.
    %       quarter            - Quarter numbers of datetimes.
    %       month              - Month numbers or names of datetimes.
    %       week               - Week numbers of datetimes.
    %       day                - Day numbers or names of datetimes.
    %       hour               - Hour numbers of datetimes.
    %       minute             - Minute numbers of datetimes.
    %       second             - Second numbers of datetimes.
    %       timeofday          - Elapsed time since midnight for datetimes.
    %       tzoffset           - Time zone offset of datetimes.
    %       isdst              - True for datetimes occurring during Daylight Saving Time.
    %       isweekend          - True for datetimes occurring on a weekend.
    %     Calendar calculations with datetimes:
    %       dateshift          - Shift datetimes or generate sequences according to a calendar rule.
    %       between            - Difference between datetimes as calendar durations.
    %       caldiff            - Successive differences between datetimes as calendar durations.
    %     Mathematical calculations with datetimes:
    %       plus               - Datetime addition.
    %       minus              - Datetime subtraction.
    %       diff               - Successive differences between datetimes as durations.
    %       colon              - Create equally-spaced sequence of datetimes.
    %       linspace           - Create equally-spaced sequence of datetimes.
    %       mean               - Mean of datetimes.
    %       median             - Median of datetimes.
    %       mode               - Most frequent datetime value.
    %       isnat              - True for datetimes that are Not-a-Time.
    %       isinf              - True for datetimes that are +Inf or -Inf.
    %       isfinite           - True for datetimes that are finite.
    %     Comparisons between datetimes:
    %       eq                 - Equality comparison for datetimes.
    %       ne                 - Not-equality comparison for datetimes.
    %       lt                 - Less than comparison for datetimes.
    %       le                 - Less than or equal comparison for datetimes.
    %       ge                 - Greater than or equal comparison for datetimes.
    %       gt                 - Greater than comparison for datetimes.
    %       isbetween          - Determine if datetimes are contained in an interval.
    %       min                - Find minimum of datetimes.
    %       max                - Find maximum of datetimes.
    %       sort               - Sort datetimes.
    %       sortrows           - Sort rows of a datetime array.
    %       issorted           - True for sorted datetime vectors and matrices.
    %     Set membership:
    %       intersect          - Find datetimes common to two arrays.
    %       ismember           - Find datetimes in one array that occur in another array.
    %       setdiff            - Find datetimes that occur in one array but not in another.
    %       setxor             - Find datetimes that occur in one or the other of two arrays, but not both.
    %       unique             - Find unique datetimes in an array.
    %       union              - Find datetimes that occur in either of two arrays.
    %     Plotting:
    %       plot               - Plot datetimes.
    %     Conversion to other numeric representations:
    %       convertTo          - Convert datetimes to numeric time representation.
    %       exceltime          - Convert datetimes to Excel serial day numbers.
    %       posixtime          - Convert datetimes to Posix time values.
    %       juliandate         - Convert datetimes to Julian dates.
    %       yyyymmdd           - Convert datetimes to YYYYMMDD numeric values.
    %       datenum            - Convert datetimes to datenum values.
    %       datevec            - Convert datetimes to date vectors.
    %     Conversion to text:
    %       cellstr            - Convert datetimes to cell array of character vectors.
    %       char               - Convert datetimes to character matrix.
    %       datestr            - Convert datetimes to character vectors.
    %       string             - Convert datetimes to strings.
    %
    %   Examples:
    %
    %      % Create a datetime array for the first 5 months in 2014.
    %      t1 = datetime(2014,1:5,1)
    %
    %      % Add a random number of calendar days to each datetime. Extract
    %      % the day component.
    %      t1 = t1 + caldays(randi([0 15],1,5))
    %      day = t1.Day
    %
    %      % Add a random amount of time to each datetime.
    %      t1 = t1 + hours(rand(1,5))
    %
    %      % Shift each datetime to the end of its month.
    %      t2 = dateshift(t1,'end','month')
    %
    %      % Find the time difference in hours/minutes/seconds between the two
    %      % sets of datetimes.
    %      d = t2 - t1
    %
    %      % Find the calendar time difference between the two sets of datetimes.
    %      d2 = between(t1,t2)
    %
    %   See also DATETIME, DURATION.
    
    %   Copyright 2019-2023 The MathWorks, Inc.
    
    properties(GetAccess='protected', SetAccess='protected')
        % Count milliseconds (including fractional) from epoch as a double-double
        % stored in complex
        data
        
        % Display format. When this field is empty the global setting will
        % be used
        fmt = char(zeros(1,0)); % in codegen '' is 1x0 char instead of 0x0 char
        
        % A time zone ID, e.g. America/Los_Angeles. Empty character vector means the array
        % contains no time zone information, i.e., it's not a fully specified
        % value, and cannot be mixed with "real-world" datetimes
        tz = char(zeros(1,0)); % in codegen '' is 1x0 char instead of 0x0 char
        
    end
    
    properties(GetAccess='public', Dependent=true)
        %FORMAT Display format property for datetime arrays.
        %   The Format property specifies the format used to display the datetimes in
        %   the array. This property is a character vector constructed using the characters
        %   A-Z and a-z to represent date and time components of the datetimes. See the
        %   <a href="matlab:doc('datetime.Format')">datetime.Format property reference page</a> for the complete specification.
        %
        %   Changing the display format does not change the datetime values in the
        %   array, only their display.
        %
        %   The factory setting for the default value when you create a datetime array
        %   is locale-dependent. For information on how to change the default in
        %   the Preferences dialog box, see <a href="matlab:helpview('matlab','matlab_env_commandwindow_prefs')">Set Command Window Preferences</a>. Datetime
        %   arrays whose time zone is set to 'UTCLeapSeconds' must use the format
        %   'uuuu-MM-dd''T''HH:mm:ss[.SSS]Z', where from 0 to 9 fractional seconds
        %   digits can be specified.
        %
        %   See also DATETIME.
        Format
        
        %TIMEZONE Time zone property for datetime arrays.
        %   The TimeZone property array specifies the time zone used to interpret the
        %   datetimes in the array. Specify the time zone as:
        %
        %      - '' to create "unzoned" datetimes that do not belong to a specific
        %        time zone.
        %      - The name of a time zone region from the IANA Time Zone Database, e.g.
        %        'America/Los_Angeles'. The array obeys the time zone offset and Daylight
        %        Saving Time rules associated with that region.
        %      - An ISO 8601 character vector of the form +HH:MM or -HH:MM.
        %      - 'UTC' to create datetimes in Coordinated Universal Time.
        %      - 'UTCLeapSeconds' to create datetimes in Coordinated Universal Time that
        %        account for leap seconds.
        %
        %   The default value for TimeZone when you create a datetime array is ''.
        %   Datetime arrays with no time zone can not be compared or combined with
        %   arrays that have their TimeZone property set to a specific time zone.
        %
        %   Changing the TimeZone property of a datetime array from one time zone to
        %   another does not change the underlying points in time that the array's
        %   elements represent. Only the representation in terms of days, hours, etc.
        %   changes. Changing the TimeZone property from '' to a specific time zone puts
        %   the datetime values in that time zone without altering their Year, Month,
        %   Day, Hour, Minute, and Second properties.
        %
        %   See also DATETIME, TIMEZONES.
        TimeZone
        
        %YEAR Datetime array year property.
        %   The Year property contains the year number of each datetime in the array.
        %   This property is the same size and shape as the datetime array.
        %
        %   Each year number is an integer value based on the proleptic Gregorian
        %   calendar. Years in the current era are positive, years in the previous era
        %   are zero or negative. For example, the year number of 1 BCE is 0.
        %
        %   If you set the Year property to a non-leap year for a datetime that occurs
        %   on a leap day (Feb 29th), the Day and Month properties change to Mar 1st.
        %
        %   See also DATETIME, MONTH, DAY, HOUR, MINUTE, SECOND
        Year
        
        %MONTH Datetime array month property.
        %   The Month property contains the month number of each datetime in the array.
        %   This property is the same size and shape as the datetime array.
        %
        %   Each month number is an integer value from 1 to 12, based on the proleptic
        %   Gregorian calendar. If you set a value outside that range, the Year property
        %   adjusts accordingly, and the Month property stays within that range. For
        %   example, month 0 corresponds to month 12 of the previous year.
        %
        %   If you change the Month property and the existing value of the Day property
        %   exceeds the length of the new month, the Month and Day property adjust
        %   accordingly. For example, if you set the Month property to 4 for a datetime
        %   that occurs on Jan 31, the resulting datetime adjusts to Jun 1.
        %
        %   See also DATETIME, YEAR, DAY, HOUR, MINUTE, SECOND
        Month
        
        %DAY Datetime array day property.
        %   The Day property contains the day number of each datetime in the array.
        %   This property is the same size and shape as the datetime array.
        %
        %   Each day number is an integer value from 1 to 28, 29, 30, or 31, depending
        %   on the month and year, and is based on the proleptic Gregorian calendar. If
        %   you set a value outside that range, the Month and Year properties adjust
        %   accordingly, and the Day property stays within that range. For example, day
        %   0 corresponds to the last day of the previous month.
        %
        %   See also DATETIME, YEAR, MONTH, HOUR, MINUTE, SECOND
        Day
        
        %HOUR Datetime array Hour property.
        %   The Hour property contains the hour number of each datetime in the array.
        %   This property is the same size and shape as the datetime array.
        %
        %   Each hour number is an integer value from 0 to 23. If you set a value
        %   outside that range, the Day, Month, and Year properties adjust accordingly,
        %   and the Hour property stays within that range. For example, hour -1
        %   corresponds to hour 23 of the previous day.
        %
        %   If a value you use to set the Hour property would create a non-existent
        %   datetime in the "spring ahead" gap of a daylight saving time shift, the Hour
        %   property adjusts to the next hour. If a value you use to set the Hour
        %   property would create an ambiguous datetime in the "fall back" overlap of a
        %   daylight saving time shift, the datetime adjusts to the second of the two
        %   times (i.e. in standard time) with that hour.
        %
        %   See also DATETIME, YEAR, MONTH, DAY, MINUTE, SECOND
        Hour
        
        %MINUTE Datetime array Minute property.
        %   The Minute property contains the minute number of each datetime in the
        %   array. This property is the same size and shape as the datetime array.
        %
        %   Each minute number is an integer value from 0 to 59. If you set a value
        %   outside that range, the Hour, Day, Month, and Year properties adjust
        %   accordingly, and the Minute property stays within that range. For example,
        %   minute -1 corresponds to minute 59 of the previous hour.
        %
        %   See also DATETIME, YEAR, MONTH, DAY, HOUR, SECOND
        Minute
        
        %SECOND Datetime array Second property.
        %   The Second property contains the second of each datetime in the array.
        %   This property is the same size and shape as the datetime array.
        %
        %   Each second value is a floating point value ordinarily ranging from 0 to
        %   strictly less than 60. If you set a value outside that range, the Minute,
        %   Hour, Day, Month, and Year properties adjust accordingly, and the Second
        %   property stays within that range. For example, second -1 corresponds to
        %   second 59 of the previous minute.
        %
        %   However, a datetime array whose TimeZone property is set to 'UTCLeapSeconds'
        %   has seconds ranging from 0 to strictly less than 61, with values from 60 to
        %   61 for datetimes that are during a leap second occurrence.
        %
        %   A datetime array represents points in time to an accuracy of at least 1 ns.
        %
        %   See also DATETIME, YEAR, MONTH, DAY, HOUR, MINUTE
        Second
    end
    
    methods
        function y = get.Year(d)
            [y,~,~,~,~,~] = matlab.internal.coder.datetime.getDateVec(d.data);
        end
        
        function d = set.Year(d,~) 
                coder.internal.assert(false,'MATLAB:datetime:PropertyChangeCodegen','Year');
        end
        
        function mo = get.Month(d)
            [~,mo,~,~,~,~] = matlab.internal.coder.datetime.getDateVec(d.data);
        end
        
        function d = set.Month(d,~) 
                coder.internal.assert(false,'MATLAB:datetime:PropertyChangeCodegen','Month');
        end
        
        function day = get.Day(d)
            [~,~,day,~,~,~] = matlab.internal.coder.datetime.getDateVec(d.data);
        end
        
        function d = set.Day(d,~) 
                coder.internal.assert(false,'MATLAB:datetime:PropertyChangeCodegen','Day');
        end
        
        function h = get.Hour(d)
            [~,~,~,h,~,~] = matlab.internal.coder.datetime.getDateVec(d.data);
        end
        
        function d = set.Hour(d,~) 
                coder.internal.assert(false,'MATLAB:datetime:PropertyChangeCodegen','Hour');
        end
        
        function m = get.Minute(d)
            [~,~,~,~,m,~] = matlab.internal.coder.datetime.getDateVec(d.data);
        end
        
        function d = set.Minute(d,~) 
                coder.internal.assert(false,'MATLAB:datetime:PropertyChangeCodegen','Minute');
        end
        
        function s = get.Second(d)
            [~,~,~,~,~,s] = matlab.internal.coder.datetime.getDateVec(d.data);
        end
        
        function d = set.Second(d,~) 
                coder.internal.assert(false,'MATLAB:datetime:PropertyChangeCodegen','Second');
        end
        
        function fmt = get.Format(d)
            fmt = getDisplayFormat(d);           
        end
        
        function d = set.Format(d,~)
                coder.internal.assert(false,'MATLAB:datetime:PropertyChangeCodegen','Format');
        end
        
        function tz = get.TimeZone(d)
            tz = d.tz;
        end
        
        function d = set.TimeZone(d,~)
                coder.internal.assert(false,'MATLAB:datetime:PropertyChangeCodegen','TimeZone');
        end
        
    end
    
    methods(Access='public', Static)
        %SYSTEMTIMEZONE System time zone setting.
        %   The SystemTimeZone property contains the time zone that the system is set to.
        %
        %   See also TIMEZONE.
        function tz = SystemTimeZone()
            tz = datetime.getsetLocalTimeZone('uncanonical');
        end
    end
    properties(GetAccess='public', Hidden, Constant)
        % These properties are for internal use only and will change in a
        % future release. Do not use these properties.
        UTCZoneID = 'UTC';
        UTCLeapSecsZoneID = 'UTCLeapSeconds';
        ISO8601Format = 'uuuu-MM-dd''T''HH:mm:ss.SSS''Z''';
        epochDN = 719529; % 1-Jan-1970 00:00:00
    end
    properties(GetAccess=?matlab.unittest.TestCase, Constant)
        dateFields = initDateFieldsStructure;
        noConstructorParamsSupplied = struct('ConvertFrom',uint32(0), 'InputFormat',uint32(0), 'Format',uint32(0), 'TimeZone',uint32(0), 'Locale',uint32(0), 'PivotYear',uint32(0), 'Epoch',uint32(0), 'TicksPerSecond',uint32(0));
    end
    
    methods(Access = 'public')
        function this = datetime(inData,varargin)
            %DATETIME Create an array of datetimes.
            %   D = DATETIME('now') returns the current date and time. D is a scalar
            %   datetime. A datetime is a value that represents a point in time. D is
            %   "unzoned", i.e., does not belong to a particular time zone. D = DATETIME
            %   with no inputs is equivalent to D = DATETIME('now').
            %
            %   D = DATETIME('today') returns the current date. D is an unzoned scalar
            %   datetime with the time portion set to 00:00:00.
            %
            %   D = DATETIME('tomorrow') returns the date of the following day. D is an
            %   unzoned scalar datetime with the time portion set to 00:00:00.
            %
            %   D = DATETIME('yesterday') returns the date of the previous day. D is an
            %   unzoned scalar datetime with the time portion set to 00:00:00.
            %
            %   D = DATETIME(DS,'InputFormat',INFMT) creates an array of datetimes from
            %   the character vectors or string array DS. DS contains date/time strings
            %   or character vectors in the format specified by INFMT. D also displays
            %   using INFMT. The text in each element of DS must have the same format.
            %
            %   INFMT is a datetime format constructed using the characters A-Z and a-z
            %   to represent date and time components of the date/time text in DS. See
            %   the description of the <a href="matlab:doc('datetime.Format')">Format property</a>
            %   for details. If you do not provide INFMT, DATETIME tries to determine
            %   the format automatically by first trying the value of the 'Format'
            %   parameter, followed by the default display format, followed by some
            %   other common formats.
            %
            %   For best performance, and to avoid ambiguities between MM/dd and dd/MM
            %   formats, always specify INFMT.
            %
            %   If INFMT does not include a date portion, DATETIME assumes the current
            %   day. If INFMT does not include a time portion, DATETIME assumes
            %   midnight.
            %
            %   D = DATETIME(DS,'InputFormat',INFMT,'Locale',LOCALE) specifies the
            %   locale that DATETIME uses to interpret the date/time text in DS. LOCALE
            %   must be a character vector or string scalar in the form xx_YY, where xx
            %   is a lowercase ISO 639-1 two-letter language code and YY is an
            %   uppercase ISO 3166-1 alpha-2 country code, for example ja_JP. LOCALE
            %   can also be 'system' to use the system locale setting. All strings or
            %   character vectors in DS must have the same locale.
            %
            %   D = DATETIME(DS,'InputFormat',INFMT,'PivotYear',PIVOT,...) specifies
            %   the pivot year that DATETIME uses to interpret the strings or character
            %   vectors in DS when FMT contains the two-digit year specifier 'yy'. The
            %   default is YEAR(DATETIME('NOW')) - 50. PIVOT only affects the year
            %   specifier 'yy' in FMT.
            %
            %   D = DATETIME(DV) creates a column vector of datetimes from a numeric
            %   matrix DV in the form [YEAR MONTH DAY HOUR MINUTE SECOND]. The first
            %   five columns must contain integer values, while the last may contain
            %   fractional seconds. DV may also be in the form [YEAR MONTH DAY], in
            %   which case the hours, minutes, and seconds are taken to be zero.
            %
            %   D = DATETIME(Y,MO,D,H,MI,S) or DATETIME(Y,MO,D) creates an array of
            %   datetimes from separate arrays. The arrays must be the same size, or
            %   any can be a scalar. Y, MO, D, H, and MI must contain integer values,
            %   while S may contain fractional seconds.
            %
            %   D = DATETIME(Y,MO,D,H,MI,S,MS) creates an array of datetimes from
            %   separate arrays, including milliseconds. The arrays must be the same
            %   size, or any can be a scalar. Y, MO, D, H, MI, and S must contain
            %   integer values, while MS may contain fractional milliseconds.
            %
            %   D = DATETIME(X,'ConvertFrom',TYPE) converts the numeric values in X to
            %   a DATETIME array D. D is the same size as X. TYPE specifies the type of
            %   values contained in X, and is one of the following:
            %
            %      'datenum'             The number of days since 0-Jan-0000 (Gregorian)
            %      'posixtime'           The number of seconds since 1-Jan-1970 00:00:00 UTC
            %      'excel'               The number of days since 0-Jan-1900
            %      'excel1904'           The number of days since 0-Jan-1904
            %      'juliandate'          The number of days since noon UTC 24-Nov-4714 BCE (Gregorian)
            %      'modifiedjuliandate'  The number of days since midnight UTC 17-Nov-1858
            %      'yyyymmdd'            A YYYYMMDD numeric value, e.g. 20140716
            %      'ntp'                 The number of (2^-32)s "clock ticks" since 1-Jan-1900 00:00:00 UTC
            %      '.net'                The number of 100ns "clock ticks" since 1-Jan-0001 00:00:00 UTC
            %      'ntfs'                The number of 100ns "clock ticks" since 1-Jan-1601 00:00:00 UTC
            %
            %   Unless 'TimeZone' is specified, D is an unzoned datetime array. For
            %   'posixtime', 'juliandate' and 'modifiedjuliandate', 'ntp', '.net', and
            %   'ntfs', the values in D when it is unzoned represent datetimes in UTC
            %   (and not your local time zone) that correspond to the given values of
            %   X.
            %
            %   D = DATETIME(X,'ConvertFrom','epochtime','Epoch',EPOCH) converts the
            %   numeric values in X to a DATETIME array D. X contains the number of
            %   seconds before or since the epoch. EPOCH is a scalar DATETIME or a
            %   date/time character vector or string scalar, representing the epoch
            %   time. The default epoch is 1-Jan-1970 00:00:00 UTC.
            %
            %   D = DATETIME(X,'ConvertFrom','epochtime','Epoch',EPOCH,'TicksPerSecond',N)
            %   converts the values in X from the numeric time representation specified
            %   by EPOCH and N, to a DATETIME array D. X is a numeric array
            %   representing time as the number of "clock ticks" before or since the
            %   epoch time. EPOCH is a scalar DATETIME or a date/time character vector
            %   or scalar string that specifies the epoch time. N is a scalar integer
            %   that specifies how many clock ticks there are per second.
            %
            %   D = DATETIME(...,'Format',FMT) creates D with the specified display
            %   format. FMT is a datetime format. See the description of the <a href="matlab:doc('datetime.Format')">Format property</a>
            %   for details. The factory setting for the default is locale-dependent.
            %   For information on setting the default in the Preferences dialog, see
            %   <a href="matlab:helpview('matlab','matlab_env_commandwindow_prefs')">Set Command Window Preferences</a>.
            %   When creating D from text, specify FMT as 'preserveinput' to use the
            %   'InputFormat' parameter (or the format that was determined
            %   automatically if 'InputFormat' was not given). Specify FMT as 'default'
            %   to use the default display format.
            %
            %   D = DATETIME(...,'TimeZone',TZ,...) specifies the time zone used to
            %   interpret the input data, and that the datetimes in D are in. TZ is the
            %   name of a time zone region, e.g. 'America/Los_Angeles', or an ISO 8601
            %   offset of the form +HH:MM or -HH:MM. Specify 'UTC' to create datetimes
            %   in Coordinated Universal Time. Specify '' to create "unzoned" datetimes
            %   that do not belong to a specific time zone. Specify 'local' to create
            %   datetimes in the system time zone. See the description of the <a
            %   href="matlab:doc('datetime.TimeZone')">TimeZone property</a> for more
            %   details. When the input data are text containing time zone offsets such
            %   as 'EST' or 'CEST', DATETIME converts all datetimes to the time zone
            %   specified by TZ.
            %
            %   Examples:
            %
            %      % Create a scalar datetime representing the current date and time.
            %      t = datetime
            %
            %      % Create a datatime array for the first 5 days in July, 2014.
            %      t = datetime(2014,7,1:5)
            %
            %      % Create a datetime array for the 5 days following 28 July, 2014.
            %      t = datetime(2014,7,28+(1:5))
            %
            %      % Create a datetime array from character vectors. Have the array use the default
            %      % format for display, then have it use the original format from the input.
            %      s = {'2014-07-28' '2014-07-29' '2014-07-30'}
            %      t1 = datetime(s,'InputFormat','yyyy-MM-dd')
            %      t2 = datetime(s,'Format','yyyy-MM-dd')
            %
            %   See also DATETIME, DURATION
            
            if nargin == 0 % same as datetime('now')
                this.data = currentTime(1);
                this.fmt = '';
                this.tz = '';
                return
            end
            
            if nargin == 1 && ...
                    isa(inData, 'matlab.internal.coder.datatypes.uninitialized')
                return
            end
           
            haveStrings = false;
            haveNumeric = false;
            haveNamedInstant = false;
            
            if ischar(inData) || (isstring(inData) && isscalar(inData))
                whichNamedInstant = (strcmpi(inData,{'now' 'yesterday' 'today' 'tomorrow'}));
                haveNamedInstant = any(whichNamedInstant);
                yesterdayTodayTomorrow = find(whichNamedInstant);
                haveStrings = ~haveNamedInstant;
                processedVarArgin = varargin;
                if haveNamedInstant
                     coder.internal.assert(coder.internal.isConst(inData), 'MATLAB:table:NonconstantParameterName');
                end
            elseif isnumeric(inData)
                haveNumeric = true;
            elseif matlab.internal.coder.datatypes.isCharStrings(inData)
                haveStrings = true;
            elseif isstring(inData)
                haveStrings = true;
            else
                processedVarArgin = varargin;
            end
            coder.internal.errorIf(haveStrings,'MATLAB:datetime:TextConstructionCodegen');
                       
            % Find how many numeric inputs args: count up until the first non-numeric.

            numNumericArgs = 0; % include inData if it's numeric
            
            if haveNumeric
                numNumericArgs = 1;
                for i = 1:length(varargin)
                    if ~isnumeric(varargin{i}), break, end
                    numNumericArgs = numNumericArgs + 1;
                end
                numericArgs = cell(1, numNumericArgs-1);
                
                for i = 1:numNumericArgs-1
                    numericArgs{i} = varargin{i};
                end
                processedVarArgin = cell(1, size(varargin,2) - (numNumericArgs-1));
                
                start = max(numNumericArgs,1);
                for i = start : size(varargin,2)
                    processedVarArgin{(i-start)+1} = varargin{i};
                end
            end
            
            dfltFmt = '';

            preserveInputFmt = false;
            isUTCLeapSecs = false;
            if isempty(varargin)
                % Default format and the local time zone and locale.
                fmt = dfltFmt; %#ok<*PROP>
                tz = '';
                epoch = [];
                ticksPerSec = 1;
                pstruct = this.noConstructorParamsSupplied;
                
            else
                % Process explicit parameter name/value pairs.
                pnames = {'ConvertFrom' 'InputFormat' 'Format' 'TimeZone' 'Locale' 'PivotYear' 'Epoch' 'TicksPerSecond'};
                poptions = struct( ...
                    'CaseSensitivity',false, ...
                    'PartialMatching','unique', ...
                    'StructExpand',false);

                pstruct = coder.internal.parseParameterInputs(pnames,poptions,processedVarArgin{:});

                convertFrom = coder.internal.getParameterValue(pstruct.ConvertFrom,'',processedVarArgin{:});
                fmt = coder.internal.getParameterValue(pstruct.Format,dfltFmt,processedVarArgin{:});
                tz = coder.internal.getParameterValue(pstruct.TimeZone,'',processedVarArgin{:});
                pivot = coder.internal.getParameterValue(pstruct.PivotYear,1969,processedVarArgin{:});
                epoch = coder.internal.getParameterValue(pstruct.Epoch,0,processedVarArgin{:});
                ticksPerSec = coder.internal.getParameterValue(pstruct.TicksPerSecond,1,processedVarArgin{:});
                    
                coder.internal.errorIf(pstruct.Format ~= 0,'MATLAB:datetime:FormatNotSupportedCodegen');
                coder.internal.errorIf(pstruct.TimeZone ~= 0,'MATLAB:datetime:TimeZoneNotSupportedCodegen');
                
                if pstruct.PivotYear, verifyPivot(pivot); end

                coder.internal.errorIf(pstruct.ConvertFrom ~= 0 && numNumericArgs ~= 1,'MATLAB:datetime:WrongNumInputsConversion'); % Require exactly one numeric input if ConvertFrom is provided.
            end
            
            if haveNumeric
                if pstruct.ConvertFrom % datetime(x,'ConvertFrom',type,...)
                    thisData = datetime.convertFrom(inData,convertFrom,tz,epoch,ticksPerSec);
                else
                    if numNumericArgs == 1 % datetime([y,mo,d],...) or datetime([y,mo,d,h,mi,s],...)
                        ncols = size(inData,2);
                        coder.internal.errorIf(~ismatrix(inData) || ((ncols ~= 3) && (ncols ~= 6)),'MATLAB:datetime:InvalidNumericData');
                        processedInData = cell(1,size(inData,2));
                        
                        for i = 1:size(inData,2)
                                coder.internal.errorIf(any(imag(full(inData(:,i))),'all'),'MATLAB:datetime:InputMustBeReal'); % complex input with imag = 0 is allowed
                                processedInData{i} = real(full(double(inData(:,i))));
                        end

                    else % datetime(y,mo,d,...), datetime(y,mo,d,h,mi,s,...), or datetime(y,mo,d,h,mi,s,ms,...)
                        processedInData = cell(1,numNumericArgs);
                        coder.internal.errorIf(any(imag(full(inData)),'all'),'MATLAB:datetime:InputMustBeReal'); % complex input with imag = 0 is allowed
                        processedInData{1} = real(full(double(inData)));
                        
                        
                        for i = 1:(numNumericArgs-1)
                                coder.internal.errorIf(any(imag(full(numericArgs{i})),'all'),'MATLAB:datetime:InputMustBeReal'); % complex input with imag = 0 is allowed
                                processedInData{i+1} = real(full(double(numericArgs{i})));
                            
                        end
                        
                        processedInData = expandNumericInputs(processedInData);
                    end

                    thisData = matlab.internal.coder.datetime.createFromDateVec(processedInData,tz); % or datevec + millis
                end
                
            elseif haveNamedInstant
                % Get the system clock. If the requested result is zoned, the system time zone's
                % offset is removed to translate the value to UTC.
                thisData = currentTime(yesterdayTodayTomorrow);
            else  % construct from an array of datetimes
                coder.internal.assert(isa(inData,'datetime'), 'MATLAB:datetime:InvalidData');
                
                % Take values from the input array rather than from the defaults.
                if pstruct.Format == 0, fmt = inData.fmt; end
                %
                %                 % Adjust for a new time zone.
                %                 thisData = timeZoneAdjustment(inData.data,inData.tz,tz);
                thisData = inData.data;
           
            end
            this.data = thisData;
            this.fmt = fmt;
            this.tz = tz;
        end
        
        function b = parenReference(a, varargin)
            b = matlab.internal.coder.datetime(matlab.internal.coder.datatypes.uninitialized);
            b.data = a.data(varargin{:});
            b.fmt = a.fmt;
            b.tz = a.tz;
        end
        
        function this = parenAssign(this, rhs, varargin)
            coder.internal.errorIf(isnumeric(rhs),'MATLAB:datetime:InvalidNumericAssignment',class(this));
            
            if isa(rhs,'datetime')
                % assignment from a datetime array into another
                coder.internal.assert(isa(this,'datetime'),'MATLAB:datetime:InvalidAssignmentLHS',class(rhs));
                
                if ~isempty(this.tz) && isempty(rhs.tz) && ~any(isfinite(rhs))
                    % Allow an unzoned NaT/Inf as the RHS even for assignment to zoned
                else
                    % Check that both datetimes either have or don't have timezones
                    checkCompatibleTZ(this.tz,rhs.tz);
                end
                rhs_data = rhs.data;
                this.data(varargin{:}) = rhs_data;

            else
                coder.internal.assert(false,'MATLAB:datetime:InvalidAssignment');
            end
            
        end
        
        function varargout = parenDelete(~, varargin) %#ok<STOUT>
            % dummy method to satisfy abstract superclass method
            coder.internal.assert(false, 'MATLAB:table:UnsupportedDelete');
        end
        
        %% Array methods
        function [varargout] = size(this,varargin)
            coder.internal.prefer_const(varargin);
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
        
        function d = repmat(this,varargin)
           d = matlab.internal.coder.datetime(matlab.internal.coder.datatypes.uninitialized);
           d.fmt = this.fmt;
           d.tz = this.tz;
           d.data = repmat(this.data,varargin{:});
        end
        
        function t = isempty(a),  t = isempty(a.data);  end
        function t = isscalar(a), t = isscalar(a.data); end
        function t = isvector(a), t = isvector(a.data); end
        function t = isrow(a),    t = isrow(a.data);    end
        function t = iscolumn(a), t = iscolumn(a.data); end
        function t = ismatrix(a), t = ismatrix(a.data); end
        
        function result = cat(dim,varargin)
            [argsData,prototype] = datetime.catUtil(varargin{:});
            result = matlab.internal.coder.datetime(matlab.internal.coder.datatypes.uninitialized);
            result.fmt = prototype.fmt;
            result.data = cat(dim,argsData{:}); % use fmt/tz from the first array
        end
        function result = horzcat(varargin)
            [argsData,prototype] = datetime.catUtil(varargin{:});
            result = matlab.internal.coder.datetime(matlab.internal.coder.datatypes.uninitialized);
            result.fmt = prototype.fmt;
            result.data = horzcat(argsData{:}); % use fmt/tz from the first array
        end
        function result = vertcat(varargin)
            [argsData,prototype] = datetime.catUtil(varargin{:});
            result = matlab.internal.coder.datetime(matlab.internal.coder.datatypes.uninitialized);
            result.fmt = prototype.fmt;
            result.data = vertcat(argsData{:}); % use fmt/tz from the first array
        end
        
        function that = ctranspose(this)
            that = matlab.internal.coder.datetime(matlab.internal.coder.datatypes.uninitialized);
            that.fmt = this.fmt;
            that.data = transpose(this.data); % NOT ctranspose
            
        end
        function that = transpose(this)
            that = matlab.internal.coder.datetime(matlab.internal.coder.datatypes.uninitialized);
            that.fmt = this.fmt;
            that.data = transpose(this.data);
        end
        
        
        function that = reshape(this,varargin)
            that = matlab.internal.coder.datetime(matlab.internal.coder.datatypes.uninitialized);
            that.fmt = this.fmt;
            that.data = reshape(this.data,varargin{:});
        end
        
        function that = permute(this,order)
            that = matlab.internal.coder.datetime(matlab.internal.coder.datatypes.uninitialized);
            that.fmt = this.fmt;
            that.data = permute(this.data,order);
        end
        
        %% Conversions to numeric types
        % No direct conversions, need to subtract a time origin
        %
    end

    methods(Static)
        function unsuppFcns = matlabCodegenUnsupportedMethods(~)
            unsuppFcns = {
                'discretize',...
                'char',...
                'cellstr',...
                'string',...
                'datenum',...
                'datestr',...
                'between',...
                'caldiff',...
                'convertTo',...
                'dateshift',...
                'day',...
                'exceltime',...
                'histcounts',...
                'isbetween',...
                'isdst',...
                'isweekend',...
                'juliandate',...
                'maxk',...
                'median',...
                'mink',...
                'mode',...
                'month',...
                'quarter',...
                'second',...
                'setDefaultFormats',...
                'std',...
                'timeofday',...
                'tzoffset',...
                'week',...
                'year',...
                'yyyymmdd'};
        end
    end
    
    %% Unsupported Methods
    methods(Hidden)
        function [bins,edges] = discretize(~,~,varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'discretize', 'datetime');
        end
                      
        function s = char(~,~,~) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'char', 'datetime');
        end
        
        function c = cellstr(~,~,~)%#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'cellstr', 'datetime');
        end
        
        function s = string(~,~,~)%#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'string', 'datetime');
        end
        
        function n = datenum(~) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'datenum', 'datetime');
        end
        
        function s = datestr(~,varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'datestr', 'datetime');
        end
        
        function d = between(~,~,~) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'between', 'datetime');
        end
        

        function d = caldiff(~,~,~) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'caldiff', 'datetime');
        end
        
        function n = convertTo(~,~,varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'convertTo', 'datetime');
        end
        
        function that = dateshift(~,~,~,~) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'dateshift', 'datetime');
        end
        
        function d = day(~,~) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'day', 'datetime');
        end
        
        function e = exceltime(~,~) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'exceltime', 'datetime');
        end
        
        function [n,edges,bin] = histcounts(~,varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'histcounts', 'datetime');
        end
        
        
        function tf = isbetween(~,~,~) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'isbetween', 'datetime');
        end
        
        function tf = isdst(~) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'isdst', 'datetime');
        end
        
        function tf = isweekend(~) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'isweekend', 'datetime');
        end
        
        function jd = juliandate(~,~) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'juliandate', 'datetime');
        end
        
        function [sortedk,ind] = maxk(~,~,varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'maxk', 'datetime');
        end
        
        function m = median(~,~,~) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'median', 'datetime');
        end
        
        function [sortedk,ind] = mink(~,~,varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'mink', 'datetime');
        end
        
        function [m,f,c] = mode(~,~) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'mode', 'datetime');
        end
        
        function m = month(~,~) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'month', 'datetime');
        end
        
        function q = quarter(~) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'quarter', 'datetime');
        end
        
        function s = second(~,~) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'second', 'datetime');
        end
        
        function setDefaultFormats(~,~) 
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'setDefaultFormats', 'datetime');
        end
        
        function b = std(~,~,~,~) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'std', 'datetime');
        end
        
        function d = timeofday(~) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'timeofday', 'datetime');
        end
        
        function [tz,dst] = tzoffset(~) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'tzoffset', 'datetime');
        end
        
        function w = week(~,~) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'week', 'datetime');
        end
        
        function y = year(~,~) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'year', 'datetime');
        end
        
        function pd = yyyymmdd(~) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'yyyymmdd', 'datetime');
        end
    end
       
    methods(Access='public')
        %% Conversions to the legacy types
        %
        function [yout,mo,d,h,m,s] = datevec(this)
            %DATEVEC Convert datetimes to date vectors.
            %   DV = DATEVEC(T) splits the datetime array T into separate column vectors for
            %   years, months, days, hours, minutes, and seconds, and returns one numeric
            %   matrix.
            %
            %   [Y,MO,D,H,MI,S] = DATEVEC(T) returns the components of T as individual
            %   variables.
            %
            %   See also YEAR, MONTH, DAY, HOUR, MINUTE, SECOND, YMD, HMS,
            %            TIMEOFDAY, DATENUM, DATESTR, DATETIME.
            
            % This preserves the zoned component values.
            [y,mo,d,h,m,s] = matlab.internal.coder.datetime.getDateVec(this.data);
            if nargout <= 1
                yout = [y(:),mo(:),d(:),h(:),m(:),s(:)];
            else
                yout = y;
            end
        end
        %
        %         %% Conversions to other time types
        %         function jd = juliandate(this,kind)
        %             %JULIANDATE Convert datetimes to Julian dates.
        %             %   JD = JULIANDATE(T) converts the datetimes in the array T to the equivalent Julian
        %             %   dates, i.e. the number of days and fractional days since noon on Nov 24, 4714 BCE
        %             %   in the proleptic Gregorian calendar (Jan 1, 4713 BCE in the proleptic Julian
        %             %   calendar). If T has a time zone, then JULIANDATE uses the offset for the time
        %             %   zone to compute JD with respect to UTC. If T is unzoned, then JULIANDATE treats T
        %             %   as though its time zone is UTC, and not your local time zone. JULIANDATE ignores
        %             %   leap seconds unless T's time zone is 'UTCLeapSeconds'. JD is a double array. To
        %             %   compute Julian dates with JULIANDATE, it is recommended that first you specify a
        %             %   time zone for T.
        %             %
        %             %   MJD = JULIANDATE(T,'modifiedjuliandate') converts the datetimes in the array
        %             %   T to the equivalent modified Julian date, i.e. the number of days and
        %             %   fractional days since Nov 17, 1858 00:00:00. JULIANDATE(T,'juliandate')
        %             %   returns Julian dates, the default behavior.
        %             %
        %             %   The modified Julian date is equal to the Julian date minus 2400000.5.
        %             %
        %             %   See also EXCELTIME, POSIXTIME, YYYYMMDD, DATENUM, DATETIME.
        %             import matlab.internal.datatypes.getChoice;
        %             if nargin == 1
        %                 kind = 1;
        %             else
        %                 kind = getChoice(kind,["juliandate" "jd" "modifiedjuliandate" "mjd"],[1 1 2 2], ...
        %                     "MATLAB:datetime:InvalidJulianDateType");
        %             end
        %             % This does not try to account for JD(UTC) vs. JD(UT1) vs. JD(TT), it simply
        %             % accepts the date/time components as is. The one exception is that for a
        %             % datetime set to 'UTCLeapSeconds', the fractional part of the JD on a day
        %             % with a leap second is normalized by 86401, not 86400. For JD, those are
        %             % [noon-noon) "days", for MJD they are [midnight-midnight) days.
        %             ucal = datetime.dateFields;
        %             if (kind == 1)
        %                 jd = matlab.internal.datetime.getDateFields(this.data,ucal.JULIAN_DATE,this.tz);
        %             else
        %                 jd = matlab.internal.datetime.getDateFields(this.data,ucal.MODIFIED_JULIAN_DATE,this.tz);
        %             end
        %         end
        %
        function p = posixtime(this)
            %POSIXTIME Convert datetimes to Posix times.
            %   P = POSIXTIME(T) converts the datetimes in the array T to the equivalent Posix
            %   time, i.e. the number of seconds (including fractional) that have elapsed since
            %   00:00:00 1-Jan-1970 UTC, ignoring leap seconds. P is a double array. If T has a
            %   time zone, then POSIXTIME uses the offset for the time zone to compute P with
            %   respect to UTC. If T is unzoned, then POSIXTIME treats T as though its time zone
            %   is UTC, and not your local time zone. To compute POSIX times with POSIXTIME, it
            %   it is recommended that first you specify a time zone for T.
            %
            %   See also EXCELTIME, JULIANDATE, YYYYMMDD, DATENUM, DATETIME.
            
            millisPerSec = 1000;
            thisData = this.data;
            p = real(thisData) / millisPerSec; % ms -> s
        end
        %
        %         function e = exceltime(this,timeSystem)
        %             %EXCELTIME Convert datetimes to Excel serial date numbers.
        %             %   E = EXCELTIME(T) converts the datetimes in the array T to the equivalent
        %             %   Excel serial date numbers, i.e. the number of days and fractional days since
        %             %   0-Jan-1900 00:00:00, ignoring time zone and leap seconds. D is a double
        %             %   array.
        %             %
        %             %   Excel serial date numbers treat 1900 as a leap year, therefore dates after
        %             %   28-Feb-1900 are off by 1 day relative to MATLAB serial date numbers, and
        %             %   there is a discontinuity of 1 day between 28-Feb-1900 and 1-Mar-1900.
        %             %
        %             %   E = EXCELTIME(T,'1904') converts the datetimes in the array T to the
        %             %   equivalent "1904-based" Excel serial date numbers, i.e. the number of days
        %             %   and fractional days since 1-Jan-1904 00:00:00, ignoring time zone.
        %             %   EXCELTIME(T,'1900') returns "1900-based" Excel serial date numbers, the
        %             %   default behavior.
        %             %
        %             %   EXCELTIME(T,'1904') is equal to EXCELTIME(T,'1900') - 1462.
        %             %
        %             %   NOTE: Excel serial date numbers are not defined prior to their epoch, i.e.
        %             %   prior to 0-Jan-1900 or 1-Jan-1904.
        %             %
        %             %   See also POSIXTIME, JULIANDATE, YYYYMMDD, DATENUM, DATETIME.
        %             thisData = timeZoneAdjustment(this.data,this.tz,'');
        %             millisPerDay = 86400*1000;
        %             excelOffset1900 = 25568 * millisPerDay;
        %             e = (real(thisData) + excelOffset1900) / millisPerDay; % consistent with datenum
        %             e = e + (e >= 60); % Correction for Excel's 1900 leap year bug
        %             if nargin > 1
        %                 if strcmp(timeSystem,'1904') || isequal(timeSystem,1904)
        %                     e = e - 1462; % "1904" epoch is 0-Jan-1904
        %                 elseif strcmp(timeSystem,'1900') || isequal(timeSystem,1900)
        %                     % OK
        %                 else
        %                     error(message('MATLAB:datetime:exceltime:InvalidTimeSystem'));
        %                 end
        %             end
        %             % There's no check here for out-of-range results, some find those useful.
        %         end
        %
        %         function pd = yyyymmdd(this)
        %             %YYYYMMDD Convert MATLAB datetimes to YYYYMMDD numeric values.
        %             %   D = YYYYMMDD(T) returns a double array containing integers whose digits
        %             %   represent the datetime values in T. For example, the date July 16, 2014
        %             %   is converted to the integer 20140716. The conversion is performed as
        %             %   D = 10000*YEAR(T) + 100*MONTH(T) + DAY(T).
        %             %
        %             %   See also EXCELTIME, POSIXTIME, JULIANDATE, DATENUM, DATETIME.
        %             ucal = datetime.dateFields;
        %             fieldIDs = [ucal.EXTENDED_YEAR ucal.MONTH ucal.DAY_OF_MONTH];
        %             [y,mo,d] = matlab.internal.datetime.getDateFields(this.data,fieldIDs,this.tz);
        %             if any(y < 1)
        %                 % Gregorian calendar has no year zero, and there's no non-confusing
        %                 % way to convert pre-01-Jan-0001 dates to yyyymmdd.
        %                 error(message('MATLAB:datetime:YYYYMMDDConversionOutOfRange',char(datetime(1,1,1))));
        %             end
        %             pd = y*10000 + mo*100 + d;
        %
        %             % Preserve Infs. These have become NaNs from NaNs in month/day
        %             % components. Use year, which will be the appropriate non-finite.
        %             nonfinites = ~isfinite(pd);
        %             pd(nonfinites) = y(nonfinites);
        %         end
        %
        %
        %         %% Date/time component methods
        %         % These return datetime components as integer values (and sometimes
        %         % names), except for seconds, which returns non-integer values
        %
        function [y,m,d] = ymd(this)
            %YMD Year, month, and day numbers of datetimes.
            %   [Y,M,D] = YMD(T) returns the year, month, and day numbers of the
            %   datetimes in T. Y, M, and D are numeric arrays the same size as
            %   T, containing integer values.
            %
            %   See also HMS, YEAR, QUARTER, MONTH, WEEK, DAY.
           [y,m,d] = matlab.internal.coder.datetime.getDateVec(this.data);
        end
        %
        function [h,m,s] = hms(this)
            %HMS Hour, minute, and second numbers of datetimes.
            %   [H,M,S] = HMS(T) returns the hour and minute numbers (as integer values) and
            %   the second values (including fractional part) of the datetimes in T. H, M,
            %   and S are numeric arrays the same size as T.
            %
            %   See also YMD, HOUR, MINUTE, SECOND.
            [~,~,~,h,m,s] = matlab.internal.coder.datetime.getDateVec(this.data);
        end
        %
        %         function y = year(this,kind)
        %             %YEAR Year numbers of datetimes.
        %             %   Y = YEAR(T) returns the year numbers of the datetimes in T. Y is an array
        %             %   the same size as T containing integer values.
        %             %
        %             %   Y = YEAR(T,KIND) returns the kind of year numbers specified by KIND. KIND
        %             %   is one of the following:
        %             %
        %             %      'iso'          - The ISO year number, which includes a year zero, and has
        %             %                       negative values for years BCE. This is the default.
        %             %      'gregorian'    - The Gregorian year number, which does not include a year
        %             %                       zero, and has positive values for years BCE.
        %             %
        %             % See also QUARTER, MONTH, WEEK, DAY, YMD.
        %             import matlab.internal.datatypes.getChoice;
        %             if nargin == 1
        %                 kind = 1;
        %             else
        %                 kind = getChoice(kind,["ISO" "Gregorian"],"MATLAB:datetime:InvalidYearType");
        %             end
        %             ucal = datetime.dateFields;
        %             fieldIDs = [ucal.EXTENDED_YEAR ucal.YEAR];
        %             y = matlab.internal.datetime.getDateFields(this.data,fieldIDs(kind),this.tz);
        %         end
        %
        %         function q = quarter(this)
        %             %QUARTER Quarter numbers of datetimes.
        %             %   Q = QUARTER(T) returns the quarter numbers of the datetimes in T. Q is an
        %             %   array the same size as T containing integer values from 1 to 4.
        %             %
        %             % See also YEAR, MONTH, WEEK, DAY, YMD.
        %             ucal = datetime.dateFields;
        %             q = matlab.internal.datetime.getDateFields(this.data,ucal.QUARTER,this.tz);
        %         end
        %
        %         function m = month(this,kind)
        %             %MONTH Month numbers or names of datetimes.
        %             %   M = MONTH(T) returns the month numbers of the datetimes in T. M is an array
        %             %   the same size as T containing integer values from 1 to 12.
        %             %
        %             %   M = MONTH(T,KIND) returns the kind of month values specified by KIND. KIND
        %             %   is one of the following:
        %             %
        %             %     'monthofyear'- The month of year number. This is the default
        %             %     'name'       - M is a cell array of character vectors the same size as T containing the
        %             %                    full month names. MONTH returns the empty character vector for NaT datetimes.
        %             %     'shortname'  - M is a cell array of character vectors the same size as T containing the
        %             %                    month name abbreviations. MONTH returns the empty character vector for NaT
        %             %                    datetimes.
        %             %
        %             % See also YEAR, QUARTER, WEEK, DAY, YMD.
        %             import matlab.internal.datetime.getMonthNames
        %             import matlab.internal.datatypes.getChoice;
        %
        %             ucal = datetime.dateFields;
        %             fieldIDs = ucal.MONTH;
        %             m = matlab.internal.datetime.getDateFields(this.data,fieldIDs,this.tz);
        %             if nargin > 1
        %                 kind = getChoice(kind,["MonthOfYear" "MoY" "Name" "LongName" "ShortName"],[1 1 2 2 3], ...
        %                     "MATLAB:datetime:InvalidMonthType");
        %                 if kind > 1
        %                     if kind == 2
        %                         names = matlab.internal.datetime.getMonthNames('long', getDatetimeSettings('locale'));
        %                     else % kind == 3
        %                         names = matlab.internal.datetime.getMonthNames('short', getDatetimeSettings('locale'));
        %                     end
        %                     names{end+1} = ''; % return empty character vector for NaT
        %                     m(isnan(m)) = length(names);
        %                     m = reshape(names(m),size(this));
        %                 end
        %             end
        %         end
        %
        %         function w = week(this,kind)
        %             %WEEK Week numbers of datetimes.
        %             %   W = WEEK(T) returns the week of year numbers of the datetimes in T. W is an
        %             %   array the same size as T containing integer values from 1 to 53.
        %             %
        %             %   W = WEEK(T,KIND) returns the kind of week numbers specified by KIND. KIND
        %             %   is one of the following:
        %             %
        %             %     'weekofyear' - The week of year number. Jan 1st is defined to be in week 1 of its
        %             %                    year, even if fewer than 4 days of that week fall in the same year.
        %             %                    This is the default.
        %             %     'weekofmonth'- The week of month number, from 1 to 5. The 1st of the month is
        %             %                    defined to be in week 1 of its month, even if fewer than 4 days of
        %             %                    that week fall in the same month.
        %             %
        %             % See also YEAR, QUARTER, MONTH, DAY, YMD.
        %             import matlab.internal.datatypes.getChoice;
        %             if nargin == 1
        %                 kind = 1;
        %             else
        %                 kind = getChoice(kind,["WeekOfYear" "WoY" "WeekOfMonth" "WoM"],[1 1 2 2], ...
        %                     "MATLAB:datetime:InvalidWeekType");
        %             end
        %             ucal = datetime.dateFields;
        %             fieldIDs = [ucal.WEEK_OF_YEAR ucal.WEEK_OF_MONTH];
        %             w = matlab.internal.datetime.getDateFields(this.data,fieldIDs(kind),this.tz);
        %         end
        %
        %         function d = day(this,kind) % DoM, DoY, DoW, ShortName, LongName
        %             %DAY Day numbers or names of datetimes.
        %             %   D = DAY(T) returns the day of month numbers of the datetimes in T. D is an
        %             %   array the same size as T containing integer values from 1 to 28, 29, 30, or
        %             %   31, depending on the month and year.
        %             %
        %             %   D = DAY(T,KIND) returns the kind of day values specified by KIND. KIND
        %             %   is one of the following:
        %             %
        %             %    'dayofmonth' - The day of month number. This is the default
        %             %    'dayofweek'  - The day of week number, from 1 to 7. Sunday is defined to be
        %             %                   day 1 of the week.
        %             %    'dayofyear'  - The day of year number, from 1 to 365 or 366, depending on the
        %             %                   year. This is sometimes incorrectly referred to as the "Julian
        %             %                   day".
        %             %    'name'       - D is a cell array of character vectors the same size as T containing the
        %             %                   full day names. DAY returns the empty character vector for NaT datetimes.
        %             %    'shortname'  - D is a cell array of character vectors the same size as T containing the
        %             %                   day name abbreviations. DAY returns the empty character vector for NaT
        %             %                   datetimes.
        %             %
        %             % See also YEAR, QUARTER, MONTH, WEEK, JULIANDATE, YMD.
        %             import matlab.internal.datetime.getDayNames
        %             import matlab.internal.datatypes.getChoice;
        %
        %             if nargin == 1
        %                 kind = 1;
        %             else
        %                 kind = getChoice(kind,["DayOfMonth" "DoM" "DayOfWeek" "DoW" "DayOfYear" "DoY" "Name" "LongName" "ShortName"], ...
        %                     [1 1 2 2 3 3 4 4 5],"MATLAB:datetime:InvalidDayType");
        %             end
        %             ucal = datetime.dateFields;
        %             fieldIDs = [ucal.DAY_OF_MONTH ucal.DAY_OF_WEEK ucal.DAY_OF_YEAR ucal.DAY_OF_WEEK ucal.DAY_OF_WEEK];
        %             d = matlab.internal.datetime.getDateFields(this.data,fieldIDs(kind),this.tz);
        %
        %             if kind > 3
        %                 if kind == 4
        %                     names = getDayNames('long', getDatetimeSettings('locale'));
        %                 else % kind == 5
        %                     names = getDayNames('short', getDatetimeSettings('locale'));
        %                 end
        %                 names{end+1} = ''; % return empty character vector for NaT
        %                 d(isnan(d)) = length(names);
        %                 d = reshape(names(d),size(this.data));
        %             end
        %         end
        %
                function h = hour(this)
                    %HOUR Hour numbers of datetimes.
                    %   H = HOUR(T) returns the hour numbers of the datetimes in T. H is an
                    %   array the same size as T containing integer values from 0 to 23.
                    %
                    % See also MINUTE, SECOND, TIMEOFDAY, HMS.
                    [~,~,~,h,~,~] = matlab.internal.coder.datetime.getDateVec(this.data);
                end
        
                function m = minute(this)
                    %MINUTE Minute numbers of datetimes.
                    %   M = MINUTE(T) returns the minute numbers of the datetimes in T. M is an
                    %   array the same size as T containing integer values from 0 to 23.
                    %
                    % See also HOUR, SECOND, TIMEOFDAY, HMS.
                    [~,~,~,~,m,~] = matlab.internal.coder.datetime.getDateVec(this.data);
                end
        %
        %         function s = second(this,kind)
        %             %SECOND Second numbers of datetimes.
        %             %   S = SECOND(T) returns the second values of the datetimes in T. S is an array
        %             %   the same size as T containing values (including a fractional part) from 0 to
        %             %   strictly less than 60.
        %             %
        %             %   For datetimes whose time zone is 'UTCLeapSeconds', SECOND returns a value
        %             %   from 60 to 61 for datetimes that are during a leap second occurrence.
        %             %
        %             %   S = SECOND(T,KIND) returns the kind of second values specified by KIND. KIND
        %             %   is one of the following:
        %             %
        %             %    'secondofminute' - The second of the minute. This is the default.
        %             %    'secondofday'    - The second of the day, from 0 to 86399.
        %             %
        %             % See also HOUR, MINUTE, TIMEOFDAY, HMS.
        %             import matlab.internal.datatypes.getChoice;
        %             if nargin == 1
        %                 kind = 1;
        %             else
        %                 kind = getChoice(kind,["SecondOfMinute" "SoM" "SecondOfDay" "SoD"],[1 1 2 2], ...
        %                     "MATLAB:datetime:InvalidSecondType");
        %             end
        %             ucal = datetime.dateFields;
        %             if kind == 1 % second+fraction within current minute
        %                 s = matlab.internal.datetime.getDateFields(this.data,ucal.SECOND,this.tz);
        %             else         % second+fraction within current day
        %                 s = matlab.internal.datetime.getDateFields(this.data,ucal.MILLISECOND_OF_DAY,this.tz) / 1000;
        %             end
        %         end
        %
        %         function d = timeofday(this)
        %             %TIMEOFDAY Elapsed time since midnight for datetimes.
        %             %   D = TIMEOFDAY(T) returns an array of durations equal to the elapsed time since
        %             %   midnight for each of the datetimes in T, i.e. T - DATESHIFT(T,'START','DAY').
        %             %
        %             %   For unzoned datetimes, and in most other cases, D is equal to
        %             %
        %             %      HOURS(T.Hour) + MINUTES(T.Minute) + SECONDS(T.Second)
        %             %
        %             %   However, for datetimes whose TimeZone property is set to a time zone that observes
        %             %   Daylight Saving Time, on days where a Daylight Saving Time shift occurs, for times
        %             %   after the shift occurs, D differs from that sum by the amount of the shift.
        %             %
        %             %   Examples:
        %             %
        %             %      Create an unzoned datetime array, get the hour, minute, and second
        %             %      properties, and compare to the elapsed time since midnight:
        %             %         t = datetime(2015,3,8) + hours(1:4)
        %             %         [hrs,mins,secs] = hms(t)
        %             %         d = timeofday(t)
        %             %
        %             %      Set the times of day in one unzoned datetime array according to the
        %             %      times of day in another unzoned datetime array:
        %             %         t1 = datetime(2015,3,7) + hours(1:4)
        %             %         t2 = datetime(2015,3,repmat(8,1,4))
        %             %         t2 = dateshift(t2,'start','day') + timeofday(t1)
        %             %
        %             %      Create a zoned datetime array, on a day with a Daylight Saving Time
        %             %      shift, get the hour, minute, and second properties, and compare to the
        %             %      elapsed time since midnight:
        %             %         tz = 'America/New_York';
        %             %         fmt = 'dd-MMM-yyyy HH:mm:ss z';
        %             %         t = datetime(2015,3,8,'TimeZone',tz,'Format',fmt) + hours(1:4)
        %             %         [hrs,mins,secs] = hms(t)
        %             %         d = timeofday(t)
        %             %
        %             %      Set the times of day in one datetime array according to the times of day in
        %             %      another datetime array. This method works regardless of the time zone or the
        %             %      day of year. In 'America/New_York', 2:00AM did not exist on 8-Mar-2015, and
        %             %      so that element becomes 3:00AM:
        %             %         t1 = datetime(2015,3,7) + hours(1:4)
        %             %         tz = 'America/New_York';
        %             %         fmt = 'dd-MMM-yyyy HH:mm:ss z';
        %             %         t2 = datetime(2015,3,repmat(8,1,4),'TimeZone',tz,'Format',fmt)
        %             %         t2.Hour = t1.Hour; t2.Minute = t1.Minute; t2.Second = t1.Second
        %             %
        %             %   See also HMS, HOUR, MINUTE, SECOND, DATESHIFT, DURATION.
        %             d = this - dateshift(this,'start','day');
        %         end
        %
        %         function [tz,dst] = tzoffset(this)
        %             %TZOFFSET Time zone offset of datetimes.
        %             %   DT = TZOFFSET(T) returns an array of durations equal to the time zone offset
        %             %   from UTC of the datetimes in T. For datetimes that occur in Daylight Saving
        %             %   Time, DT includes the time shift for DST. In other words, DT is the amount
        %             %   of time that each datetime in T differs from UTC.
        %             %
        %             %   The offset for unzoned datetimes is not defined.
        %             %
        %             %   [DT,DST] = TZOFFSET(T) also returns the time shift for Daylight Saving Time
        %             %   for each datetime in T.
        %             %
        %             %   See also TIMEZONE, ISDST.
        %             if isempty(this.tz)
        %                 tz = NaN(size(this.data));
        %                 dst = tz;
        %             else
        %                 ucal = datetime.dateFields;
        %                 [tz,dst] = matlab.internal.datetime.getDateFields(this.data,[ucal.ZONE_OFFSET ucal.DST_OFFSET],this.tz);
        %             end
        %             % Add the raw offset and the DST offset to get the total offset
        %             tz = duration.fromMillis(1000*(tz+dst),'hh:mm');
        %             if nargout > 1
        %                 dst = duration.fromMillis(1000*dst,'hh:mm');
        %             end
        %         end
        %
        %         % no need for eomday method, that's day(dateshift(t,'end','month'))
        %         % no need for weekday method, that's day(t,'dayofweek')
        %
        %         % These return logicals
        %
        %         function tf = isweekend(this)
        %             %ISWEEKEND True for datetimes occurring on a weekend.
        %             %   TF = ISWEEKEND(T) returns a logical vector the same size as the datetime
        %             %   array T, with logical 1 (true) in elements where the corresponding element
        %             %   of T is a datetime the occurs on a weekend day, and logical 0 (false)
        %             %   otherwise.
        %             %
        %             %   See also ISDST, DAY.
        %             ucal = datetime.dateFields;
        %             dow = matlab.internal.datetime.getDateFields(this.data,ucal.DAY_OF_WEEK,this.tz);
        %             tf = (dow == 1) | (dow == 7); % Sunday is always day 1, regardless of locale
        %         end
        %
        %         function tf = isdst(this)
        %             %ISDST True for datetimes occurring during Daylight Saving Time.
        %             %   TF = ISDST(T) returns a logical vector the same size as the datetime array
        %             %   T, with logical 1 (true) in elements where the corresponding element of T is
        %             %   a datetime the occurs during Daylight Saving Time, and logical 0 (false)
        %             %   otherwise.
        %             %
        %             %   ISDST returns false for datetimes in an "unzoned" array.
        %             %
        %             %   See also ISWEEKEND, TZOFFSET, TIMEZONE.
        %             ucal = datetime.dateFields;
        %             tf = matlab.internal.datetime.getDateFields(this.data,ucal.DST_OFFSET,this.tz) ~= 0;
        %             tf(isnan(this.data)) = false;
        %         end
        
        
        
                %% Relational operators
                function t = eq(a,b)
                    %EQ Equality comparison for datetimes.

                    coder.internal.implicitExpansionBuiltin;

                    [aData,bData] = datetime.compareUtil(a,b);
                    t = relopSign(aData,bData) == 0;
                end
        
                function t = ne(a,b)
                    %NE Not-equality comparison for datetimes.
                    coder.internal.implicitExpansionBuiltin;

                    [aData,bData] = datetime.compareUtil(a,b);
                    t = relopSign(aData,bData) ~= 0;
                end
        
                function t = lt(a,b)
                    %LT Less than or equal comparison for datetimes.

                    coder.internal.implicitExpansionBuiltin;

                    [aData,bData] = datetime.compareUtil(a,b);
                    t = relopSign(aData,bData) < 0;
                   end
        
                function t = le(a,b)
                    %LE Less than or equal comparison for datetimes.

                    coder.internal.implicitExpansionBuiltin;

                    [aData,bData] = datetime.compareUtil(a,b);
                    t = relopSign(aData,bData) <= 0;
                end
        
                function t = ge(a,b)
                    %GE Greater than or equal comparison for datetimes.

                    coder.internal.implicitExpansionBuiltin;

                    [aData,bData] = datetime.compareUtil(a,b);
                    t = relopSign(aData,bData) >= 0;
                end

                function t = gt(a,b)
                    %GT Greater than comparison for datetimes.

                    coder.internal.implicitExpansionBuiltin;

                    [aData,bData] = datetime.compareUtil(a,b);
                    t = relopSign(aData,bData) > 0;
                end
        
                function t = isequal(varargin)
                    %ISEQUAL True if datetime arrays are equal.
                    %   TF = ISEQUAL(A,B) returns logical 1 (true) if the datetime arrays A and B
                    %   are the same size and contain the same values, and logical 0 (false)
                    %   otherwise. Either A or B may also be a cell array of character vectors,
                    %   or a string scalar representing dates.
                    %
                    %   TF = ISEQUAL(A,B,C,...) returns logical 1 (true) if all the input arguments
                    %   are equal.
                    %
                    %   NaT elements are not considered equal to each other. Use ISEQUALN to treat
                    %   NaT elements as equal.
                    %
                    %   See also ISEQUALN, EQ.
                    narginchk(2,Inf);
                    [argsData,validComparison] = datetime.isequalUtil(varargin);
                    if ~validComparison
                         t = false;
                        
                    else
                       t = isequal(argsData{:});
                    end
                    
                end
        
                function tf = isnat(a)
                    tf = isnan(a.data);
                end
                
                function t = isequaln(varargin)
                    %ISEQUALN True if datetime arrays are equal, treating NaT elements as equal.
                    %   TF = ISEQUALN(A,B) returns logical 1 (true) if the datetime arrays A and B
                    %   are the same size and contain the same values or corresponding NaT elements,
                    %   and logical 0 (false) otherwise. Either A or B may also be a cell array of
                    %   character vectors, or a string scalar representing dates.
                    %
                    %   TF = ISEQUALN(A,B,C,...) returns logical 1 (true) if all the input arguments
                    %   are equal.
                    %
                    %   Use ISEQUAL to treat NaT elements as unequal.
                    %
                    %   See also ISEQUAL, EQ.
                    narginchk(2,Inf);    narginchk(2,Inf);
                    [argsData,validComparison] = datetime.isequalUtil(varargin);
                    if ~validComparison
                         t = false;
                        
                    else
                       t = isequaln(argsData{:});
                    end
                end
                
    end % public methods block
        %
        methods(Hidden = true)
            
            %% Arrayness
            function e = end(this,k,n)
                dims = ndims(this.data);
                if k == n && k <= dims
                    e = 1;
                    coder.unroll();
                    for i = k:dims
                        % Collapse the dimensions beyond N and return the end.
                        % Use an explicit for loop to look at the size of each
                        % dim individually to avoid issues for varsize inputs. 
                        e = e * size(this.data,i);
                    end
                else % k > n || k < n || k > ndims(a)
                    % for k > n or k > ndims(a), e is 1
                    e = size(this.data,k);
                end
            end

            %% Format
            function tf = hasDefaultFormat(this)
                % This function is for internal use only and will change in a
                % future release. Do not use this function.
                tf = isempty(this.fmt);
            end
            
            %% Error stubs
            %         % Methods to override functions and throw helpful errors
            function d = double(d), coder.internal.assert(false,'MATLAB:datetime:InvalidNumericConversion','double'); end 
            function d = single(d), coder.internal.assert(false,'MATLAB:datetime:InvalidNumericConversion','single'); end
            function d = months(d), coder.internal.assert(false,'MATLAB:datetime:NoMonthsMethod'); end
            function d = timezone(d),  coder.internal.assert(false,'MATLAB:datetime:NoTimeZoneMethod'); end
            function d = format(d),  coder.internal.assert(false,'MATLAB:datetime:NoFormatMethod'); end
            %         function d = floor(varargin), error(message('MATLAB:datetime:UseDateshiftMethod','floor')); end %#ok<STOUT>
            %         function d = ceil(varargin), error(message('MATLAB:datetime:UseDateshiftMethod','ceil')); end %#ok<STOUT>
            %         function d = round(varargin), error(message('MATLAB:datetime:UseDateshiftMethod','round')); end %#ok<STOUT>
        end % hidden public methods block
        %
        methods(Hidden = true, Static = true)
            function  b = matlabCodegenToRedirected(a)
                
                coder.internal.assert(isempty(a.TimeZone),'MATLAB:datetime:UnzonedCodegen');
                
                b = matlab.internal.coder.datetime(matlab.internal.coder.datatypes.uninitialized);
                [millis,fmt] = datetime.toMillis(a);
                b.data = complex(real(millis),imag(millis));
                if ~isempty(fmt)
                    b.fmt = fmt;
                end
            end
        
            function t = matlabCodegenTypeof(~)
                t = 'matlab.coder.type.DatetimeType';
            end
            
            
            function name = matlabCodegenUserReadableName
                % Make this look like a datetime (not the redirected datetime) in the codegen report
                name = 'datetime';
            end
        
            function b = matlabCodegenFromRedirected(a)
                b = datetime.codegenInit(a.data, a.fmt, a.tz);
            end
            
            function t = fromMillis(data,format,tz)
                % This function is for internal use only and will change in a
                % future release. Do not use this function.
                t = datetime(matlab.internal.coder.datatypes.uninitialized);
                
                processedData = complex(data);
                t.data = processedData;
                if nargin > 1
                    t.fmt = format;
                    if nargin > 2
                        t.tz = tz;
                    else
                        t.tz = '';
                    end
                else
                    t.fmt = '';
                    t.tz = '';
                end
            end
            
            function [t,fmt,tz] = toMillis(this,zeroLowPart)
                % This function is for internal use only and will change in a
                % future release. Do not use this function.
                fmt = this.fmt;
                tz = this.tz;
                if nargin == 2 && zeroLowPart
                    t = real(this.data);
                else
                    t = this.data;
                end
            end
        end
    %     methods(Hidden = true, Static = true)
    %         function d = empty(varargin)
    %         %EMPTY Create an empty datetime array.
    %         %   D = DATETIME.EMPTY() creates a 0x0 datetime array.
    %         %
    %         %   D = DATETIME.EMPTY(M,N,...) or D = DATETIME.EMPTY([N M ...]) creates
    %         %   an N-by-M-by-... datetime array. At least one of N,M,... must be zero.
    %         %
    %         %   See also DATETIME.
    %             d = datetime(); % fastest constructor call
    %             if nargin == 0
    %                 dData = [];
    %             else
    %                 dData = zeros(varargin{:});
    %                 if numel(dData) ~= 0
    %                     error(message('MATLAB:class:emptyMustBeZero'));
    %                 end
    %             end
    %             d.data = dData;
    %         end
    %
    %         function tzs = allTimeZones()
    %         % This function is for internal use only and will change in a
    %         % future release. Do not use this function.
    %         tzs = cell2table(matlab.internal.datetime.getDefaults('TimeZones'), ...
    %             'VariableNames',{'Name' 'CanonicalName' 'UTCOffset' 'DSTOffset'});
    %         end
    %
    %         function fmt = getDefaultFormatForLocale(locale)
    %         % This function is for internal use only and will change in a
    %         % future release. Do not use this function.
    %             if nargin == 0
    %                 locale = matlab.internal.datetime.getDefaults('locale');
    %             else
    %                 locale = matlab.internal.datetime.verifyLocale(locale);
    %             end
    %             fmt = matlab.internal.datetime.getDefaults('localeformat',locale,'uuuuMMdd');
    %         end
    %
    %         function setLocalTimeZone(tz)
    %         % This function is for internal use only and will change in a
    %         % future release. Do not use this function.
    %             if nargin == 0, tz = []; end
    %             datetime.getsetLocalTimeZone(tz);
    %         end
    %     end % hidden static public methods block
    %
    %     methods(Static, Access='public')
    %         setDefaultFormats(format,formatStr)
    %     end
    %

    methods(Access={?matlab.internal.coder.tabular.private.explicitRowTimesDim, ...
                    ?matlab.internal.coder.withtol})
        inds = timesubs2inds(subscripts,labels,tol)
    end

    methods(Static, Access='protected')
        
        [a,b,prototype] = compareUtil(a,b)
        [a,b] = arithUtil(a,b)
        [args,validComparison] = isequalUtil(args)
        [args,prototype] = catUtil(args)
        t = convertFrom(value,type,tz,epoch,ticksPerSec)
        %
        %
        %         function [tz,haveClientOverride] = getsetLocalTimeZone(tz)
        %             import matlab.internal.datetime.getDefaults
        %
        %             persistent clientOverride  % canonicalized client override, may be []
        %             persistent systemTZ % canonicalized system setting
        %             persistent rawTZ    % uncanonicalized system setting or client override
        %
        %             if isempty(systemTZ) % first time called
        %                 rawTZ = getDefaults('SystemTimeZone');
        %                 [systemTZ,rawTZ] = canonicalizeTZforLocal(rawTZ);
        %             end
        %
        %             if nargout > 0 % get syntax
        %                 if nargin == 0
        %                     % return the "current" value that should be used for 'local'
        %                     if isempty(clientOverride)
        %                         tz = systemTZ;
        %                     else
        %                         tz = clientOverride;
        %                     end
        %                 elseif strcmp(tz,'canonical')
        %                     % currentTime needs the actual system setting, avoiding warnings
        %                     tz = systemTZ;
        %                 elseif strcmp(tz,'uncanonical')
        %                     % verifyTimeZone needs the original value to possibly warn about it
        %                     tz = rawTZ;
        %                 else
        %                     assert(false);
        %                 end
        %             else % set syntax
        %                 if isequal(tz,[]) % remove the client override
        %                     clientOverride = [];
        %                     rawTZ = getDefaults('SystemTimeZone');
        %                     munlock % no longer strictly necessary
        %                 else % setting a client override
        %                     mlock % do this only when necessary to preserve the client override
        %                     [clientOverride,rawTZ] = canonicalizeTZforLocal(tz);
        %                 end
        %             end
        %
        %             if nargout > 1
        %                 haveClientOverride = ~isempty(clientOverride);
        %             end
        %         end
    end % static protected methods block
end % classdef
    %
    %
    % %%%%%%%%%%%%%%%%% Local functions %%%%%%%%%%%%%%%%%
    %
    % %-----------------------------------------------------------------------
    % function [canonicalTZ,tz] = canonicalizeTZforLocal(tz)
    % import matlab.internal.datetime.getCanonicalTZ
    %
    % try
    %     % Validate a time zone to use as the local setting. getCanonicalTZ will error if
    %     % it's invalid, and we fall back to UTC with a warning. Tell getCanonicalTZ to
    %     % not warn if it's just non-standard, because many places we just need the offset.
    %     % But use of 'local' later on (e.g. datetime('now','TimeZone','local') will still
    %     % lead (once) to a warning from verifyTimeZone if the tz is non-standard.
    %     canonicalTZ = getCanonicalTZ(tz,false);
    % catch ME
    %     if strcmp(ME.identifier,'MATLAB:datetime:UnknownTimeZone')
    %         warning(message('MATLAB:datetime:InvalidSystemTimeZone',tz));
    %         tz = datetime.UTCZoneID;
    %         canonicalTZ = tz;
    %     else
    %         throwAsCaller(ME);
    %     end
    % end
    % end
    %
    % %-----------------------------------------------------------------------
    % function tf = isDateOnlyFormat(fmt)
    % tf = isempty(regexp(fmt,'[hHkKmsSaA]','once'));
    % end
    %
    % %-----------------------------------------------------------------------
    function pivot = verifyPivot(pivot)
    coder.internal.assert(matlab.internal.datatypes.isScalarInt(pivot),'MATLAB:datetime:InvalidPivotYear');
    end
    %
    % %-----------------------------------------------------------------------
    function thisData = currentTime(yesterdayTodayTomorrow)
   
        % Get time components from the system clock and create an unzoned internal
        % value to match those components. clock returns seconds as d.p. rounded to
        % the nearest milli- (Windows) or micro-second (Linux/OSX). datetime counts
        % in ms, so (re)rounding 1000*sec to 3 digits (microsec) gets the first case
        % exactly right and more or less leaves the second case alone. For the second
        % case, could round in datetime's higher precision, but the cosmetic tweak
        % later on would break that anyway, so don't bother.
        
        c = coder.internal.time.getLocalTime();
        
        if yesterdayTodayTomorrow > 1
            offset = yesterdayTodayTomorrow - 3;
            thisData = matlab.internal.coder.datetime.createFromDateVec({c.tm_year c.tm_mon c.tm_mday+offset});
        else
            thisData = matlab.internal.coder.datetime.createFromDateVec({c.tm_year c.tm_mon c.tm_mday c.tm_hour c.tm_min c.tm_sec c.tm_nsec/1000000});
        end
        
        
    end
    
    %-----------------------------------------------------------------------
       
    

function expandedData = expandNumericInputs(inData)
% input to expandNumericInputs would always be either a non-complex double or a complex double with
% imag = 0

expandedData = cell(size(inData));
nonscalarfieldLoc = 0;
nonscalar = 0;
for i = 1:length(inData)
    field = inData{i};
    if ~isscalar(field)
        nonscalarfieldLoc = i;
        
        if  ~coder.internal.isConst(size(field))
            nonscalar = field;
        end
        
        break
    end
end

for i = 1:length(inData)
    
    field = inData{i};
    
    if isscalar(field) && nonscalarfieldLoc > 0
        if  ~coder.internal.isConst(size(nonscalar))
            expanded = nonscalar;
        else
            expanded = inData{nonscalarfieldLoc};
        end
        for j = 1:numel(expanded)
            expanded(j) = field;
        end
        expandedData{i} = expanded;
    else % let createFromDateVec check for size mismatchr
        expandedData{i} = field;
    end
end

end

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
