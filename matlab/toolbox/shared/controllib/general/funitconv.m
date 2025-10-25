function cf = funitconv(OldUnit,NewUnit,TimeUnit)
%FUNITCONV  Computes conversion factor between frequency units.
%
%   CF = FUNITCONV(OLDUNITS,NEWUNITS,TIMEUNITS)
%
%   Supported frequency units include:
%     1) 'rad/s', 'Hz', 'kHz', 'MHz', 'GHz', and 'rpm'
%     2) 'rad/TimeUnit' and 'cycles/TimeUnit' (time-relative units)
%     3) Units obtained by replacing "TimeUnit" above by one of the following
%        time units: nanoseconds, microseconds, milliseconds, seconds, minutes,
%        hours, days, weeks, months, years.
%
%   The third input TIMEUNITS is required when the old or new units are
%   'rad/TimeUnit' or 'cycles/TimeUnit'.

%   Copyright 1986-2010 The MathWorks, Inc.

%#codegen

if strcmp(OldUnit,NewUnit)
    cf = 1;  return
end

OldUnit = char(OldUnit);
NewUnit = char(NewUnit);

% Conversion factor for time units
if nargin>2
    TimeUnit = char(TimeUnit);
    f_time = tunitconv('seconds',TimeUnit);
else
    f_time = 1;
end

% Compute factor OldUnit -> rad/s
switch OldUnit
    case 'rad/TimeUnit'
        f_old = f_time;
    case 'rad/s'
        f_old = 1;
    case 'cycles/TimeUnit'
        f_old = 2*pi*f_time;
    case 'Hz'
        f_old = 2*pi;
    case 'kHz'
        f_old = 2e3*pi;
    case 'MHz'
        f_old = 2e6*pi;
    case 'GHz'
        f_old = 2e9*pi;
    case 'rpm'
        f_old = pi/30;
    otherwise
        if OldUnit(end)~='s'
            % Accept both rad/second and rad/seconds
            OldUnit_ = [OldUnit 's'];
        else
            OldUnit_ = OldUnit;
        end
        if strncmp(OldUnit_,'rad/',4)
            f_old = tunitconv('seconds',OldUnit_(5:end));
        elseif strncmp(OldUnit_,'cycles/',7)
            f_old = (2*pi)*tunitconv('seconds',OldUnit_(8:end));
        end
end

% Compute factor NewUnit -> rad/s
switch NewUnit
    case 'rad/TimeUnit'
        f_new = f_time;
    case 'rad/s'
        f_new = 1;
    case 'cycles/TimeUnit'
        f_new = 2*pi*f_time;
    case 'Hz'
        f_new = 2*pi;
    case 'kHz'
        f_new = 2e3*pi;
    case 'MHz'
        f_new = 2e6*pi;
    case 'GHz'
        f_new = 2e9*pi;
    case 'rpm'
        f_new = pi/30;
    otherwise
        if NewUnit(end)~='s'
            NewUnit_ = [NewUnit 's'];
        else
            NewUnit_ = NewUnit;
        end
        if strncmp(NewUnit_,'rad/',4)
            f_new = tunitconv('seconds',NewUnit_(5:end));
        elseif strncmp(NewUnit_,'cycles/',7)
            f_new = (2*pi)*tunitconv('seconds',NewUnit_(8:end));
        end
end

cf = f_old/f_new;