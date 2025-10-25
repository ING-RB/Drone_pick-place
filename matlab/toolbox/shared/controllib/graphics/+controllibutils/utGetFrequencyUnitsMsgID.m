function MsgID = utGetFrequencyUnitsMsgID(Str,Format)
% Helper function to get long/short string of property values for
% freqeuncies

% Format = Short or Long

%   Copyright 1986-2010 The MathWorks, Inc. 

if nargin == 1
    Format = 'short';
end

Data = {
    'auto', 'strAuto', 'strAuto';
    'Hz',  'strHz','strHz';
    'rad/s', 'strRadPerS','strRadPerSecond';
    'rpm', 'strRpm', 'strRpm';
    'kHz', 'strkHz', 'strkHz';
    'MHz', 'strMHz', 'strMHz';
    'GHz', 'strGHz', 'strGHz';
    'rad/nanosecond', 'strRadPerNanosecond', 'strRadPerNanosecond';
    'rad/microsecond', 'strRadPerMicrosecond', 'strRadPerMicrosecond';
    'rad/millisecond', 'strRadPerMillisecond', 'strRadPerMillisecond';
    'rad/minute', 'strRadPerMinute', 'strRadPerMinute';
    'rad/hour', 'strRadPerHour', 'strRadPerHour';
    'rad/day', 'strRadPerDay', 'strRadPerDay';
    'rad/week', 'strRadPerWeek', 'strRadPerWeek';
    'rad/month', 'strRadPerMonth', 'strRadPerMonth';
    'rad/year', 'strRadPerYear', 'strRadPerYear';
    'cycles/nanosecond', 'strCyclesPerNanosecond', 'strCyclesPerNanosecond';
    'cycles/microsecond', 'strCyclesPerMicrosecond', 'strCyclesPerMicrosecond';
    'cycles/millisecond', 'strCyclesPerMillisecond', 'strCyclesPerMillisecond';
    'cycles/hour', 'strCyclesPerHour', 'strCyclesPerHour';
    'cycles/day', 'strCyclesPerDay', 'strCyclesPerDay';
    'cycles/week', 'strCyclesPerWeek', 'strCyclesPerWeek';
    'cycles/month', 'strCyclesPerMonth', 'strCyclesPerMonth';
    'cycles/year', 'strCyclesPerYear', 'strCyclesPerYear'};

Idx = find(strcmpi(Str,Data(:,1)));

if strcmpi(Format,'short')
    ColIdx = 2;
else
    ColIdx = 3;
end

MsgID = sprintf('Controllib:gui:%s',Data{Idx,ColIdx});
