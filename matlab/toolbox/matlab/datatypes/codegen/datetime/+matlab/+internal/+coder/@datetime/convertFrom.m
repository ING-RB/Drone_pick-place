function t_data = convertFrom(value,type,tz,epochMillis,ticksPerSec) %#codegen
%CONVERTFROM Convert numeric values to a datetime array.
%   T_DATA = CONVERTFROM(VALUE,TYPE,TZ,EPOCHMILLIS,TICKSPERSEC) returns a
%   datetime array T_DATA by converting numeric array VALUE, interpreted as
%   having type TYPE (e.g. 'datenum'), with the optional TZ, EPOCHMILLIS,
%   and TICKSPERSEC inputs to further specify VALUE.
%
% Refer to the documentation for the 'ConvertFrom', 'TimeZone', 'Epoch',
% and 'TicksPerSecond' name-value pairs for the datetime constructor for a
% complete description of the TYPE, TZ, EPOCHMILLIS, and TICKSPERSEC
% inputs.

%   Copyright 2019-2024 The MathWorks, Inc.
coder.internal.assert(matlab.internal.coder.datatypes.isScalarText(type),'MATLAB:datetime:InvalidConversionType');   
coder.internal.errorIf(isnumeric(value) && ~isreal(value),'MATLAB:datetime:InputMustBeReal');


value = full(value); % but preserve type, especially uint64

% datenum, excel, and yyyymmdd conversions are done in "local time", without
% accounting for tz and dst, i.e. treated as unzoned input values, and must be
% adjusted to UTC if the output is zoned. .NET, NTFS, NTP, julian date, and
% posix time are assumed measured with respect to UTC. epochtime values are
% assumed measured in "local time" if the epoch itself is char or an unzoned
% datetime, but measured w.r.t. the epoch's time zone if it is zoned.
unzonedInput = true;

isUTCLeapSecs = strcmp(tz,datetime.UTCLeapSecsZoneID);

millisPerDay = 86400 * 1000;
millisPerSec = 1000;

switch lower(type)
case {'ntp' 'ntfs' '.net'}
    coder.internal.assert(isa(value,'uint64'),'MATLAB:datetime:MustConvertFromInteger64',upper(type),'uint64');
    unzonedInput = false;
    if strcmpi(type,'ntp')
        epochMillis = -2208988800000; % 1-Jan-1900
        ticksPerSec = 2^32; % ~.2ns ticks
        % Split into two uint32's: seconds and (2^-32)s ticks, then convert latter to ms
        sz = size(value);
        value = reshape(typecast(value(:),'uint32'),2,[]);
        wholeSecs = zeros(sz);
        wholeSecs = double(reshape(value(2,:),sz));
        fracSecMillis = (double(reshape(value(1,:),sz))/ticksPerSec)*millisPerSec;
    else
        if strcmpi(type,'ntfs')
            epochMillis = -11644473600000; % 1-Jan-1601
            ticksPerSec = 1e7; % 100ns ticks
        else % '.net'
            epochMillis = -62135596800000; % 1-Jan-0001
            ticksPerSec = 1e7; % 100ns ticks
        end
        ticksPerMS = ticksPerSec/millisPerSec;
        % Convert the number of ticks to whole seconds, preserving as uint64. Flooring
        % keeps intermediate values in uint64 range for the fracSecMillis calculation
        wholeSecs = (value-.5*ticksPerSec)/ticksPerSec; % subtraction may saturate to 0, that's OK
        fracSecMillis = double(value - wholeSecs*ticksPerSec)/ticksPerMS; % convert to double to preserve fractional ms
    end
    
    % Convert whole seconds to ms and add to epoch (safe from uint64 saturation for
    % NTP, .NET, and NTFS), then add fractional seconds using full precision
    t_data = matlab.internal.coder.doubledouble.plus(epochMillis+double(wholeSecs*millisPerSec),fracSecMillis);

    % NTP, .NET, and NTFS timestamps ignore leap seconds, add them.
    if isUTCLeapSecs, t_data = addLeapSeconds(t_data); end

case 'epochtime'
    [epochMillis,ticksPerSec,unzonedInput] = validateEpochtimeInputs(epochMillis,ticksPerSec,tz);
    ticksPerMS = ticksPerSec/millisPerSec;
    if isa(value,'int64') || isa(value,'uint64')
        % Convert the number of ticks to whole seconds by rounding down, preserving as
        % [u]int64. Rounding down keeps the intermediate values in the fracSecMillis
        % calculation within integer limits for both int64 and uint64 ...
        half = floor(.5*ticksPerSec); % ticksPerSec==1 -> 0
        wholeSecs = (value-half)/ticksPerSec; % subtraction may saturate to 0 for uint64, that's harmless
        if isa(value,'int64')
            % ... except when rounding int64 down at the lower extreme, which saturates
            % to -2^63, in general not a whole number of seconds. Round those up.
            i = (value < intmin('int64')+half);
            wholeSecs(i) = (intmin('int64')+half)/ticksPerSec;
        end
        % Calculate fractional seconds as the remainder, converting to double to
        % preserve fractional ms
        fracSecMillis = double(value - wholeSecs*ticksPerSec)/ticksPerMS;
    else % double inputs, or integer types that can be safely cast to double
        value = double(value);
        % Convert the number of ticks to whole seconds by rounding, keeps fracSecMillis
        % smaller, more precision
        wholeSecs = round(value/ticksPerSec);
        fracSecMillis = (value - wholeSecs*ticksPerSec)/ticksPerMS; % preserve fractional ms
    end
    % Convert whole seconds to ms (checking for flint overflow) and add to epoch, then
    % add in fractional seconds, all using full precision
    wholeSecMillis = double(wholeSecs*millisPerSec);
    if any(abs(wholeSecMillis) >= flintmax) % doesn't catch NaNs from double input, they become NaTs
        % When ticks are larger than 100ns, [u]int64 values can exceed the equivalent of
        % 285Ky = 2^53ms, so wholeSecMillis as a double can overflow flint, more care needed.
        % Split wholeSecs into [u]int64 high and low parts, with the high part a multiple of
        % 2^32 so it converts to double millis exactly, and the low part less than 2^32.
        wholeSecsHi = bitshift(bitshift(wholeSecs,-32),32);
        wholeSecsLo = wholeSecs - wholeSecsHi;
        wholeSecMillisFullPrecision = matlab.internal.coder.doubledouble.plus(double(wholeSecsHi)*millisPerSec,double(wholeSecsLo)*millisPerSec);
        t_data = matlab.internal.coder.doubledouble.plus(matlab.internal.coder.doubledouble.plus(epochMillis,wholeSecMillisFullPrecision),fracSecMillis);
    else
        t_data = matlab.internal.coder.doubledouble.plus(matlab.internal.coder.doubledouble.plus(epochMillis,wholeSecMillis),fracSecMillis);
    end
    
    % Epoch times are defined as ignoring leap seconds, add them.
    if isUTCLeapSecs, t_data = matlab.internal.datetime.addLeapSeconds(t_data); end

otherwise
    value = double(value);

    switch lower(type)
    case {'posixtime' 'posix'}
        t_data = value*millisPerSec; % s -> ms
        if isUTCLeapSecs
            % POSIX time does not count leap seconds, add them.
            t_data = addLeapSeconds(t_data);
        end
        unzonedInput = false;

    case {'excel' 'excel1900'}
        coder.internal.errorIf(any(value(:) < 0),'MATLAB:datetime:ExcelTimeOutOfRange');
        
        % Day number (including fractional days) since 0-Jan-1900
        %
        % Round Excel day numbers to the nearest microsec, just above their
        % resolution for contemporary dates (about 6e-7s).
        excelOffset1900 = 25568;
        value = value - (value > 60); % Correction for Excel's 1900 leap year bug
        t_data = round2microsecs((value - excelOffset1900)*millisPerDay);

    case 'excel1904'
        coder.internal.errorIf(any(value(:) < 0),'MATLAB:datetime:ExcelTimeOutOfRange');
        % Day number (including fractional days) since 0-Jan-1904
        %
        % Round Excel day numbers to the nearest microsec, just above their
        % resolution for contemporary dates (about 6e-7s).
        excelOffset1904 = 24107;
        t_data = round2microsecs((value - excelOffset1904)*millisPerDay);

    case {'jd' 'juliandate'}
        JDoffset = 2440587.5; % the Julian date for 00:00:00 1-Jan-1970
        % Shift the origin to 1970, and scale from days to millis.
        if ~isUTCLeapSecs
            t_data = (value - JDoffset)*millisPerDay;
        else
            t_data = days2MillisWithLeapSecs(value - JDoffset,'jd');
        end
        unzonedInput = false;

    case {'mjd' 'modifiedjuliandate'}
        MJDoffset = 40587; % the modified Julian date for 00:00:00 1-Jan-1970
        % Shift the origin to 1970, and scale from days to millis.
        if ~isUTCLeapSecs
            t_data = (value - MJDoffset)*millisPerDay;
        else
            t_data = days2MillisWithLeapSecs(value - MJDoffset,'mjd');
        end
        unzonedInput = false;

    case 'yyyymmdd'
        coder.internal.errorIf(any(value(:) < 0),'MATLAB:datetime:YYYYMMDDOutOfRange');
        
        % Let the month and day numbers roll just as they would for datevecs
        year = round(value/10000);
        value = value - year*10000;
        month = round(value/100);
        day = value - month*100;
        t_data = matlab.internal.coder.datetime.createFromDateVec({year month day},'');

        % Handle NaT, Inf, or -Inf datetimes
        nonfinites = ~isfinite(value);
        t_data(nonfinites) = year(nonfinites);

    case 'datenum'
        % Because they count days, datenums can't represent whole hours, minutes, or
        % seconds exactly, "nice" times are represented with round-off (datenum's
        % resolution for contemporary dates is about 1.006e-5s). datetime _can_
        % represent such times exactly, but the original (rounded-off) datenum is also
        % representable. So the mathewmatically correct conversion often leads to a
        % datetime that differs by fractional seconds from the time that the datenum
        % was intended to represent. This is not helpful. Instead, find datenums
        % that correspond to exact milliseconds, and round to the exact ms. This is
        % less draconian than rounding everything to the nearest .1ms, and preserves
        % a round trip.
        t_data = (value - datetime.epochDN)*millisPerDay;
        t_dataRounded = round(t_data);
        i = (value == (t_dataRounded + datetime.epochDN*millisPerDay) / millisPerDay);
        t_data(i) = t_dataRounded(i);

    otherwise
        coder.internal.assert(false,'MATLAB:datetime:UnrecognizedConversionType',convertStringsToChars(type));
    end
end

if unzonedInput && ~isempty(tz)
    % For inputs that are treated as unzoned, adjust the internal value
    % if the output should be zoned. This preserves the clockface time
    % in the target time zone.
    t_data = timeZoneAdjustment(t_data,'',tz);
end



%-----------------------------------------------------------------------
function [epochMillis,ticksPerSec,unzonedInput] = validateEpochtimeInputs(epoch,ticksPerSec,tz)

unzonedInput = true;

if matlab.internal.coder.datatypes.isScalarText(epoch)
    % Create an unzoned datetime from the epoch string. convertFrom will add the
    % (suitably scaled) epochtime to the epoch's internal offset to create the
    % target datetime, unzoned, which can then be put into a specified time
    % zone if necessary.
    epoch = datetime(epoch);
    epochMillis = epoch.data;
elseif isa(epoch,'datetime')
    if isempty(epoch.tz)
        % When the epoch is unzoned, use its internal offset directly.
        % convertFrom will add the (suitably scaled) epochtime to create the
        % target datetime, unzoned, which can then be put into a specified
        % time zone if necessary.
        epochMillis = epoch.data;
    else % the epoch is a zoned datetime
        if isempty(tz)
            % When the epoch is zoned and the target datetime is unzoned, need
            % to adjust the epoch's internal offset to make it unzoned.
            % convertFrom will add the (suitably scaled) epochtime to create the
            % target datetime, unzoned.
            epochMillis = timeZoneAdjustment(epoch.data,epoch.tz,'');
        else
            % When both the epoch and the target datetime are zoned, the internal
            % offsets take care of themselves. convertFrom will add the (suitably
            % scaled) epochtime to create the target datetime, zoned.
            epochMillis = epoch.data;
            unzonedInput = false;
        end
    end
else
    coder.internal.assert(isnumeric(epoch) && isreal(epoch),'MATLAB:datetime:InvalidEpoch');
    epochMillis = double(epoch);
end

coder.internal.assert(isscalar(epochMillis),'MATLAB:datetime:NonScalarEpoch');


coder.internal.assert(matlab.internal.datatypes.isScalarInt(ticksPerSec,1,2^32),'MATLAB:datetime:InvalidTicksPerSec');


%-----------------------------------------------------------------------
function data = round2microsecs(millis)
% Round millisecs to nearest microsec for excel time calculations
wholeMillis = floor(millis);
fracMillis = round((millis - wholeMillis)*1000)/1000; % round to nearest to minimize rounding error
fracMillis(isinf(millis)) = 0; % preserve Infs
data = matlab.internal.coder.doubledouble.plus(wholeMillis,fracMillis);



%-----------------------------------------------------------------------
function data = days2MillisWithLeapSecs(day,type)
% Convert a day count from 1970 to an internal value, accounting for leap seconds,
% for julian date calculations
millisPerDay = 86400 * 1000;
millisPerSec = 1000;
dayAnchor = floor(day); % previous midnight
dayFrac = day - dayAnchor; % fraction of midnight-to-midnight day

% Julian date days are noon-to-noon.
if type == "jd"
    dayAnchor = dayAnchor + .5 - (dayFrac < .5); % previous noon
    dayFrac = day - dayAnchor; % fraction of noon-to-noon day
end

% Adjust the previous midnight (MJD) or noon (JD) to account for any preceeding leap
% seconds, and determine if it occurs during a calendar day that ends with a leap second.
% If it does, the midnight-to-midnight or noon-to-noon "day" is 86401s long.
[data,~,isLeapSecDay] = matlab.internal.datetime.addLeapSeconds(dayAnchor*millisPerDay);
% Add on the day fraction, normalized by the appropriate day length.
data = data + dayFrac.*(millisPerDay + millisPerSec*isLeapSecDay);
