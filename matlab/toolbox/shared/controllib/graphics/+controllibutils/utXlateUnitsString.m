function [Str,MsgID] = utXlateUnitsString(Str,StringVersion)
% Helper function to get localized string of property values for
% units. When StringVersion is 'short', it returns the short versions of the
% units and their message IDs. If not, it returns long versions.

%   Copyright 1986-2017 The MathWorks, Inc. 

if nargin<2
    % default behavior
    StringVersion = 'long';
end

switch lower(StringVersion)
    case 'short'
        colIdx = 3;
    case 'long'
        colIdx = 2;
    otherwise
        colIdx = 2;
end

%   Unit                    ID for long                 ID for short
Data = {
    'dB',                   'strDB',                    'strDB';
    'rad',                  'strRad',                   'strRad';
    'deg',                  'strDeg',                   'strDeg';
    'Hz',                   'strHz',                    'strHz';
    'rad/s',                'strRadPerS',               'strRadPerS';
    'rad/second',           'strRadPerSecond',          'strRadPerS';
    'rpm',                  'strRpm',                   'strRpm';
    'kHz',                  'strkHz',                   'strkHz';
    'MHz',                  'strMHz',                   'strMHz';
    'GHz',                  'strGHz',                   'strGHz';
    'rad/nanosecond',       'strRadPerNanosecond',      'strRadPerNanosecond';
    'rad/microsecond',      'strRadPerMicrosecond',     'strRadPerMicrosecond';
    'rad/millisecond',      'strRadPerMillisecond',     'strRadPerMillisecond';
    'rad/minute',           'strRadPerMinute',          'strRadPerMinute';
    'rad/hour',             'strRadPerHour',            'strRadPerHour';
    'rad/day',              'strRadPerDay',             'strRadPerDay';
    'rad/week',             'strRadPerWeek',            'strRadPerWeek';
    'rad/month',            'strRadPerMonth',           'strRadPerMonth';
    'rad/year',             'strRadPerYear',            'strRadPerYear';
    'cycles/nanosecond',    'strCyclesPerNanosecond',   'strCyclesPerNanosecond';   
    'cycles/microsecond',   'strCyclesPerMicrosecond',  'strCyclesPerMicrosecond';
    'cycles/millisecond',   'strCyclesPerMillisecond',  'strCyclesPerMillisecond';
    'cycles/hour',          'strCyclesPerHour',         'strCyclesPerHour';
    'cycles/day',           'strCyclesPerDay',          'strCyclesPerDay';
    'cycles/week',          'strCyclesPerWeek',         'strCyclesPerWeek';
    'cycles/month',         'strCyclesPerMonth',        'strCyclesPerMonth';
    'cycles/year',          'strCyclesPerYear',         'strCyclesPerYear';
    'yoctoseconds',         'strYoctoseconds',          'strYoctosecondsShort';
    'zeptoseconds',         'strZeptoseconds',          'strZeptosecondsShort';
    'attoseconds',          'strAttoseconds',           'strAttosecondsShort';
    'femtoseconds',         'strFemtoseconds',          'strFemtosecondsShort';
    'picoseconds',          'strPicoseconds',           'strPicosecondsShort';
    'nanoseconds',          'strNanoseconds',           'strNanosecondsShort';
    'microseconds',         'strMicroseconds',          'strMicrosecondsShort';
    'milliseconds',         'strMilliseconds',          'strMillisecondsShort';
    'seconds',              'strSeconds',               'strSecondsShort';
    'minutes',              'strMinutes',               'strMinutesShort';
    'hours',                'strHours',                 'strHoursShort';
    'days',                 'strDays',                  'strDays';
    'weeks',                'strWeeks',                 'strWeeks';
    'months',               'strMonths',                'strMonths';
    'years',                'strYears',                 'strYears'};

Idx = find(strcmpi(Str,Data(:,1)));

if isempty(Idx)
    MsgID = '';
else
    MsgID = sprintf('Controllib:gui:%s',Data{Idx,colIdx});
    Str = getString(message(MsgID));
end
