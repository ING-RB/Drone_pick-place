function [new_x, eng_exp, units_x] = engunits(x, arg1, arg2)
% ENGUNITS Convert scalar input to engineering units.
%   [Y,E,U]=ENGUNITS(X) converts input value X into a new value Y,
%   with associated scale factor E, such that Y = X * E.  The
%   engineering unit prefix is returned as a character in U.  If X
%   is a matrix the largest value will be used to determine the scale.
%
%   [...]=ENGUNITS(X,'latex') returns engineering unit prefix
%   U in Latex format where appropriate, for use with the TEXT
%   command.  In particular, U='u' for micro, whereas U='\mu'
%   if the Latex flag is passed.
%
%   [...]=ENGUNITS(X,'unicode') returns engineering unit prefix U using
%   unicode where appropriate.  In particular, U='u' for micro, whereas
%   U=char(956) if the unicode flag is passed.
%
%   [...]=ENGUNITS(...,'time') will cause conversion from
%   seconds to mins/hrs/days/etc when appropriate, and the new
%   units in U.
% 
%   EXAMPLE:
%   [y,e,u] = engunits(1000);
%
%   See also CONVERT2ENGSTRS.

%   Copyright 1988-2014 The MathWorks, Inc.

if nargin==1
    % General engineering units conversion:
    [new_x, eng_exp, units_x] = getEngPrefix(x);
elseif nargin==2
  if strcmpi(arg1,'time')
    [new_x, eng_exp, units_x] = getTimeUnits(x);
  else
    [new_x, eng_exp, units_x] = getEngPrefix(x,arg1);
  end
else %nargin==3
  if strcmpi(arg2,'time')
    [new_x, eng_exp, units_x] = getTimeUnits(x,arg1);
  else
    [new_x, eng_exp, units_x] = getEngPrefix(x,arg1);
  end
end

%--------------------------------------------------------------
function [new_x, eng_exp, units_x] = getTimeUnits(x, latex)
% getTimeUnits Return new time-domain units from a seconds-based input

time_units = {'secs','mins','hrs','days','years'};
time_scale = [1,60,3600,86400,31536000];

% Use max to find the largest value to support matrices
i = find(max(x(:))>=time_scale, 1, 'last' );

if isempty(i),
   % No conversion to a higher unit - use general engineering prefix:
   if nargin==1
      [new_x,eng_exp,units_x] = getEngPrefix(x);
   else
      [new_x,eng_exp,units_x] = getEngPrefix(x, latex);
   end
   if eng_exp == 1,
      units_x = 'secs';
   else
      units_x = [units_x 's'];
   end
else
   new_x   = x./time_scale(i);
   eng_exp = 1./time_scale(i);
   units_x = time_units{i};
end


% --------------------------------------------------------------
function [new_x, eng_exp, units_x] = getEngPrefix(x, latex)
% getEngPrefix Return prefix for appropriate engineering units

eng_units = 'yzafpnum kMGTPEZY';
units_offset = 9; %find(eng_units==' ');
units_len = 17; %length(eng_units);
mu_offset = 7; %find(eng_units=='u');

% Normalize input such that
%    x = norm_x * 10^norm_exp
norm_exp = max(max(floor(log10(abs(x(x~=0)))))); % normalized exponent
if isempty(norm_exp)
    norm_exp = 0;
end

% Round to the nearest multiple of 3:
eng_exp    = 3.*floor(norm_exp./3);
scale_mant = x .* 10.^(-eng_exp);

% Select appropriate engineering units:
i = eng_exp./3 + units_offset;

% Update this section for vector inputs, if they
% become a required part of the spec:
%
if isnan(i) || i<1 || i>units_len || i==units_offset
   % Out of range or no offset required - return input unchanged:
   new_x   = x;
   units_x = '';
   eng_exp = 0;
else
   new_x = scale_mant;
   if nargin<2 || i~= mu_offset
     units_x = eng_units(i);
   elseif strcmp(latex,'unicode')
      units_x = char(956);
   else % latex
      units_x = '\mu';
   end
end

% Convert exponent to proper power of 10 for return:
eng_exp = 10 .^ (-eng_exp);

% [EOF]
