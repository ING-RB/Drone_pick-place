function fact = tunitconv(OldUnit,NewUnit)
%TUNITCONV  Computes conversion factor between time units.
%
%   Supported units include 'yoctoseconds','zeptoseconds','attoseconds',
%   'femtoseconds', 'picoseconds', 'nanoseconds', 'microseconds',
%   'milliseconds', 'seconds', 'minutes', 'hours', 'days', 'weeks',
%   'months', 'years' 

%   Copyright 1986-2017 The MathWorks, Inc.

%#codegen

% Compute factor OldUnit -> seconds
switch OldUnit
   case 'yoctoseconds'
      f_old = 1e-24;
   case 'zeptoseconds'
      f_old = 1e-21;
   case 'attoseconds'
      f_old = 1e-18;
   case 'femtoseconds'
      f_old = 1e-15;
   case 'picoseconds'
      f_old = 1e-12;
   case 'nanoseconds'
      f_old = 1e-9;
   case 'microseconds'
      f_old = 1e-6;
   case 'milliseconds'
      f_old = 1e-3;
   case 'seconds'
      f_old = 1;
   case 'minutes'
      f_old = 60;
   case 'hours'
      f_old = 3600;
   case 'days'
      f_old = 86400;
   case 'weeks'
      f_old = 604800;
   case 'months'
      f_old = 2629800;
   case 'years'
      f_old = 31557600;
   otherwise
      f_old = 1;
end

% Compute factor NewUnit -> rad/s
switch NewUnit
   case 'yoctoseconds'
      f_new = 1e-24;
   case 'zeptoseconds'
      f_new = 1e-21;
   case 'attoseconds'
      f_new = 1e-18;
   case 'femtoseconds'
      f_new = 1e-15;
   case 'picoseconds'
      f_new = 1e-12;
   case 'nanoseconds'
      f_new = 1e-9;
   case 'microseconds'
      f_new = 1e-6;
   case 'milliseconds'
      f_new = 1e-3;
   case 'seconds'
      f_new = 1;
   case 'minutes'
      f_new = 60;
   case 'hours'
      f_new = 3600;
   case 'days'
      f_new = 86400;
   case 'weeks'
      f_new = 604800;
   case 'months'
      f_new = 2629800;
   case 'years'
      f_new = 31557600;
   otherwise
      f_new = 1;
end

fact = f_old/f_new;
