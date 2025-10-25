function n = convertTo(this,type,varargin)
%

%   Copyright 2017-2024 The MathWorks, Inc.

import matlab.internal.datatypes.isScalarText
import matlab.internal.datetime.removeLeapSeconds
import matlab.internal.datetime.datetimeSubtract

if ~isScalarText(type)
    error(message('MATLAB:datetime:InvalidConversionType'));
end

millisPerSec = 1000;

isUTCLeapSecs = (this.tz == datetime.UTCLeapSecsZoneID);
thisData = this.data;

switch lower(type)
case {'posix' 'posixtime'}
    n = posixtime(this);
case {'ntp' 'ntfs' '.net'}
    % NTP, .NET, and NTFS timestamps ignore leap seconds, remove them.
    if isUTCLeapSecs, thisData = removeLeapSeconds(thisData); end

    if matches(type,"ntp","IgnoreCase",true)
        % note to future self: NTP epoch changes to 2085978496000 on 07-Feb-2036 06:28:16
        ticksPerSec = 2^32;
        epochMillis = -2208988800000; % 1-Jan-1900
    elseif matches(type,"ntfs","IgnoreCase",true)
        ticksPerSec = 1e7;
        epochMillis = -11644473600000; % 1-Jan-1601
    else % '.net'
        ticksPerSec = 1e7;
        epochMillis = -62135596800000; % 1-Jan-0001
    end
    
    % Convert datetime values to whole and fractional seconds since the specified epoch
    [wholeSecs,fracSecMillis] = elapsedSinceEpoch(thisData,epochMillis);
    
    % Return ticks since epoch as an unsigned integer, rounding to nearest tick
    ticksPerMS = ticksPerSec/millisPerSec;
    n = uint64(wholeSecs)*ticksPerSec ... % scale after converting to avoid flint overflow
        + uint64(fracSecMillis*ticksPerMS); % scale before converting to preserve fractional millis
    
    % If any values are at uint64 extremes, check that those did not come from
    % integer saturation
    if any(n == 0) || any(n == intmax('uint64')) % NaT becomes 0, and is caught here
        checkUint64TimeLimits(thisData,epochMillis,ticksPerSec,type);
    end
    
case 'tt2000'
    if isUTCLeapSecs
        % For times prior to 1970, NASA's CDF conversion routines roughly account for
        % the fractional leap seconds and rubber seconds that were part of (proto-)UTC
        % from 1960-1970. Use those from cdflib instead of this MATLAB implementation.

%         ticksPerSec = 1e9; % 1ns ticks
%         epochMillis = 946727957816; % 1-Jan-2000 12:00:00 TT (a.k.a. 1-Jan-2000 11:58:55.816Z), including leap seconds
%         
%         % Convert datetime values to whole and fractional seconds since the specified epoch
%         [wholeSecs,fracSecMillis] = elapsedSinceEpoch(thisData,epochMillis);
%         
%         % Return ticks since epoch as an unsigned integer, rounding to nearest tick
%         ticksPerMS = ticksPerSec/millisPerSec;
%         n = int64(wholeSecs)*ticksPerSec ... % scale after converting to avoid flint overflow
%             + int64(fracSecMillis*ticksPerMS); % scale before converting to preserve fractional millis
%         
%         % If any values are at int64 extremes, check that those did not come from
%         % integer saturation
%         if any(n == intmin('int64')) || any(n == 0) || any(n == intmax('int64')) % NaT becomes 0, and is caught here
%             checkTT2000TimeLimits(thisData);
%         end

        % Split the datetime into y/m/d/h/m/s/ms/us/ns, then call computeTT2000 to convert to int64,
        % catching any out of range errors.
        [y,mo,d,h,m,secs] = matlab.internal.datetime.getDateVec(this.data,this.tz);      
        s = floor(secs);
        fracSecs = round(1e9*(secs - s)); % whole ns within second
        ms = floor(fracSecs/1e6);
        fracSecs = fracSecs - 1e6*ms;
        us = floor(fracSecs/1e3);
        ns = fracSecs - 1e3*us;
        try
            n = cdflib.computeTT2000([y(:) mo(:) d(:) h(:) m(:) s(:) ms(:) us(:) ns(:)]'); % computeTT2000 expects 9xM double array
            n = reshape(n,size(this.data));
        catch ME
            % The nine components came from splitting up a datetime, so never any illegal individual
            % component values. But computeTT2000 throws an illegal value for a NaN, i.e. from a NaT.
            % MATLAB:datetime:ConversionOutOfRange covers that.
            if strcmp(ME.identifier,'MATLAB:imagesci:cdflib:outOfRangeTT2000Value') ...
               || strcmp(ME.identifier,'MATLAB:imagesci:cdflib:illegalTT2000Value')
               checkTT2000TimeLimits(NaN);
            else
                rethrow(ME);
            end
        end
    else
        error(message('MATLAB:datetime:MustConvertFromUTCLeapSeconds'));
    end
    
case 'epochtime'
    [epochMillis,ticksPerSec] = validateEpochtimeInputs(varargin,this);
    ticksPerMS = ticksPerSec/millisPerSec;

    % Epoch times are defined as ignoring leap seconds, remove them.
    if isUTCLeapSecs, thisData = removeLeapSeconds(thisData); end
    
    % Convert datetime values to whole and fractional seconds since the specified epoch
    [wholeSecs,fracSecMillis,elapsed] = elapsedSinceEpoch(thisData,epochMillis);
    
    % Make sure elapsedSinceEpoch() stayed within flint range, about +/- 285Ky from the specified
    % epoch. datetimes corresponding to in-range NTP, NTFS, and .NET timestamps are well within
    % that, but here, for epochtime with arbitrary TicksPerSecond, more care needed.
    if all(abs(wholeSecs*millisPerSec) < flintmax)
        wholeSecsHi = 0; % don't need a high-order part
    elseif anynan(wholeSecs) % catch NaTs, there's no int64 NaN
        error(message('MATLAB:datetime:EpochTimeConversionOutOfRange'));
    else % any(abs(wholeSecs*millisPerSec) >= flintmax)
        % Extract whole multiples of 2^32 seconds from elapsed since epoch as a double. In-range
        % cases are at worst 2^63s == 2^31 of those chunks, which is within exact flint range.
        % Out-of-range cases exceed flintmax, but are caught below when they saturate int64.
        hi = fix(pow2(real(elapsed),-32) / millisPerSec);
        % Convert chunks back to whole seconds. At 2147483648, wholeSecsHi == 2^63, which is
        % exactly representable as double but would saturate in int64. Let the low-order piece
        % take that one 2^32s chunk.
        hi = min(hi,2147483647);
        wholeSecsHi = pow2(hi,32); % exact flint times 2^32, no roundoff
        % Use the high-order part of the elapsed time in millis to get the remaining low-order
        % part in millis as d-d.
        millisHi = pow2(hi*millisPerSec,32); % times 1000 stays exact less than flintmax, times 2^32 remains exact
        millisLo = datetimeSubtract(elapsed,millisHi,true); % full precision
        % Split the low-order part of the elapsed time into whole and fractional seconds.
        [wholeSecs,fracSecMillis] = elapsedSinceEpoch(millisLo,0);
    end

    % Return ticks before/after epoch as a signed integer, rounding to nearest tick. The highest order term
    % may saturate to int64 extremes.
    n = int64(wholeSecsHi)*ticksPerSec + int64(wholeSecs)*ticksPerSec + int64(fracSecMillis*ticksPerMS);
    
    % If any values are at int64 extremes, check that those did not come from integer saturation.
    if any(n == intmin('int64')) || any(n == intmax('int64'))
        checkEpochtimeLimits(thisData,epochMillis,ticksPerSec);
    end

% Delegate all these to the dedicated functions.
case {'excel' 'excel1900'}
    n = exceltime(this);
case 'excel1904'
    n = exceltime(this,'1904');
case 'juliandate'
    n = juliandate(this);
case 'modifiedjuliandate'
    n = juliandate(this,'mjd');
case 'yyyymmdd'
    n = yyyymmdd(this);
case 'datenum'
    n = datenum(this); %#ok<DATNM> 
otherwise
    error(message('MATLAB:datetime:UnrecognizedConversionType',convertStringsToChars(type)));
end


%-----------------------------------------------------------------------
function [epochMillis,ticksPerSec] = validateEpochtimeInputs(args,template)

import matlab.internal.datatypes.parseArgs
import matlab.internal.datatypes.isScalarText
import matlab.internal.datatypes.isScalarInt

try %#ok<ALIGN>

pnames = {'Epoch' 'TicksPerSecond'};
dflts =  { 0       1              };
[epoch,ticksPerSec] = parseArgs(pnames, dflts, args{:});
    
if isScalarText(epoch)
    % Create a datetime from the epoch string, in the source datetime's time
    % zone (if any) and leveraging its format for parsing. Zoned or unzoned,
    % the epoch's internal offset is comparable to the source datetime's,
    % and convertTo will subtract and scale suitably to get the desired
    % epochtime.
    epoch = autoConvertStrings(epoch,template);
    if isa(epoch,'duration')
       error(message('MATLAB:datetime:InvalidEpoch')); 
    end
    epochMillis = epoch.data;
elseif isa(epoch,'datetime')
    % If the epoch is a datetime, its time zone must be compatible with the
    % source datetime.
    tz = template.tz;
    if isempty(epoch.tz) ~= isempty(tz)
        error(message('MATLAB:datetime:IncompatibleEpochTZ'));
    elseif ~isempty(epoch.tz)
        if (epoch.tz == datetime.UTCLeapSecsZoneID) ~= (tz == datetime.UTCLeapSecsZoneID)
            error(message('MATLAB:datetime:IncompatibleEpochTZLeapSeconds'));
        end
    end
    % Zoned or unzoned, the epoch's internal offset is comparable to the
    % source datetime's, and convertTo will subtract and scale suitably to
    % get the desired epochtime.
    epochMillis = epoch.data;
elseif ~isnumeric(epoch) || ~isreal(epoch)
    error(message('MATLAB:datetime:InvalidEpoch'));
else
    epochMillis = double(epoch);
end
if ~isscalar(epochMillis)
    error(message('MATLAB:datetime:NonScalarEpoch'));
end

if ~isScalarInt(ticksPerSec,1,2^32) % not tested beyond that limit
    error(message('MATLAB:datetime:InvalidTicksPerSec'));
end

catch ME, throwAsCaller(ME), end


%-----------------------------------------------------------------------
function [wholeSecs,fracSecMillis,elapsed] = elapsedSinceEpoch(millis,epochMillis)
% Compute elapsed time since specified epoch, as whole seconds and fractional
% seconds (the latter in ms)
import matlab.internal.datetime.datetimeSubtract

millisPerSec = 1000;

% Compute millis since epoch using full precision, split into whole and fractional
% seconds pieces. Round towards zero (fix) to keep the whole seconds within the
% allowed range. 
elapsed = datetimeSubtract(millis,epochMillis,true); % preserve full precision
wholeSecMillis = millisFix(elapsed); % as millis, drop low order
fracSecMillis = datetimeSubtract(elapsed,wholeSecMillis,false); % as millis, drop low order
wholeSecs = wholeSecMillis / millisPerSec; % convert ms -> sec


%-----------------------------------------------------------------------
function millis = millisFix(millis)
% Round an elapsed millis value towards zero. This assumes that the input is
% less than flintmax ms, so keeping only the high order part is sufficient.
% Always true for NTP, NTFS, and .NET. For 'epochtime', it may not be true,
% but that's caught later
import matlab.internal.datetime.datetimeFloor

millisPerSec = 1000;
ucal = datetime.dateFields;
millis = real(datetimeFloor(millis,ucal.SECOND,'')); % drop low order
i = (millis < 0);
millis(i) = millis(i) + millisPerSec;


%-----------------------------------------------------------------------
function checkUint64TimeLimits(millis,epochMillis,ticksPerSec,type)
% Check that data is within limits to avoid integer saturation when converting to uint64 ticks
import matlab.internal.datetime.datetimeSubtract
import matlab.internal.datetime.getDatetimeSettings

millisPerSec = 1000;
millisPerTick = millisPerSec/ticksPerSec;

if matches(type,"ntp","IgnoreCase",true)
    % note to future self: NTP epoch changes to 2085978496000 on 07-Feb-2036 06:28:16
    maxMillis = 2085978496000; % 07-Feb-2036 06:28:16
elseif matches(type,"ntfs","IgnoreCase",true)
    maxMillis = complex(1833029933770955.25,-8.83999999999787178e-02); % 28-May-60056 05:36:10.9551616
else % '.net'
    maxMillis = complex(1782538810570955.25,-8.83999999999787178e-02); % 28-May-58456 05:36:10.9551616
end
maxMillis = datetimeSubtract(maxMillis,.5*millisPerTick,true);

% Verify that all elements are within [0, 2^64) ticks after the epoch
if ~all(datetimeSubtract(millis,epochMillis) >= 0) || ~all(datetimeSubtract(maxMillis,millis) > 0)
    ds1 = char(datetime.fromMillis(epochMillis,getDatetimeSettings('defaultformat')));
    ds2 = char(datetime.fromMillis(maxMillis,getDatetimeSettings('defaultformat')));
    error(message('MATLAB:datetime:ConversionOutOfRange',upper(type),ds1,ds2));
end


%-----------------------------------------------------------------------
function checkTT2000TimeLimits(millis)
% Check that data is within limits to avoid integer saturation when converting to int64 ticks

import matlab.internal.datetime.datetimeSubtract
import matlab.internal.datetime.getDatetimeSettings

minMillis = complex(-8276644069038.7753906,-4.1337499999372084858); % J2000-2^63ns+4ns (1707-09-22T12:12:10.961224196Z, or -9223372036854775804)
maxMillis = complex(10170099994670.775391,4.1737499998362181941e-04); % J2000+2^63ns (2292-04-11T11:46:07.670775808Z, or 9223372036854775808)

% Verify that all elements are within [-2^63+4, 2^63) ticks before/after the epoch
if ~all(datetimeSubtract(millis,minMillis) >= 0) ||  ~all(datetimeSubtract(maxMillis,millis) > 0)
    ds1 = char(datetime(1707,09,22,12,12,10,'Format',getDatetimeSettings('defaultformat'))); % more precisely, ...:10.961224196
    ds2 = char(datetime(2292,04,11,11,46,08,'Format',getDatetimeSettings('defaultformat'))); % more precisely, ...:07.670775808
    error(message('MATLAB:datetime:ConversionOutOfRange','tt2000',ds1,ds2));
end


%-----------------------------------------------------------------------
function checkEpochtimeLimits(millis,epochMillis,ticksPerSec)
% Check that data is within epoch -2^63/+(2^63-1) ticks, to avoid integer
% over/underflow when converting to int64 ticks
import matlab.internal.datetime.datetimeSubtract

% Use convertFrom to create the datetimes at the extremes of int64 for the specified
% epoch and ticksPerSec.
minMillis = datetime.convertFrom(intmin('int64'),'epochtime','',epochMillis,ticksPerSec);
maxMillis = datetime.convertFrom(intmax('int64'),'epochtime','',epochMillis,ticksPerSec);

% Verify that all elements are within [-2^63,2^63-1] ticks of the epoch
if ~all(datetimeSubtract(millis,minMillis) >= 0) || ~all(datetimeSubtract(maxMillis,millis) >= 0)
    error(message('MATLAB:datetime:EpochTimeConversionOutOfRange'));
end
