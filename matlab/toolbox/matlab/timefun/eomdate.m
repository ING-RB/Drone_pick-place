function d = eomdate(y,m,outType) 
%EOMDATE Last date of month. 
%   EOMDATE is not recommended. Use datetimes and call dateshift(dt,"end","month") or
%   dateshift(datetime(y,m,1),"end","month") instead.
%
%   D = EOMDATE(N) returns the last date of the month, given the date N.
%   N can be input as a serial date number date string or datetime array.
%   The date D is in serial date format (default) or datetime format (if N
%   is datetime format). 
%   
%
%   D = EOMDATE(Y,M, outType) returns the last date of the month, in serial
%   form, for the given year, Y, and month, M. D is in serial date format if 
%   outType is not specified, or set to 'datenum'. If outType is set to
%   'datetime' D will be in datetime format.
% 
%   For example, d = eomdate(1997,2) returns d = 729449 which is the serial
%   date corresponding to February 28, 1997.
%
%   See also DAY, EOMDAY, LBUSDATE, MONTH, YEAR. 
 
%   Copyright 1995-2021 The MathWorks, Inc.

% Check number of input arguments
if nargin > 0
    y = convertStringsToChars(y);
end

if nargin > 2
    outType = convertStringsToChars(outType);
end

if nargin < 1
  error(message('MATLAB:eomdate:missingInputs'))
end 

% Date input
if nargin == 1
  DateTimeFlag = isdatetime(y);  
  [yr,mt] = datevec(y);
  ld = eomday(yr,mt);
  d = datenum(yr,mt,ld); % always a pure date (no time)
  if DateTimeFlag
    d = matlab.datetime.compatibility.convertDatenum(d);
    d.TimeZone = y.TimeZone;
    d.Format = y.Format;
  end
  return
end

% Year and month input

if nargin <3 || isempty(outType)
    outType = 'datenum';
end

switch outType
    case 'datenum'
        DateTimeFlag = false;
    case 'datetime'
        DateTimeFlag = true;
    otherwise
        error(message('MATLAB:eomdate:invalidOutputType'));
end

if any(m < 1) || any(m > 12)
    error(message('MATLAB:eomdate:invalidMonth'))
end

if length(y)==1;y = y(ones(size(m)));end   % scalar expansion
if length(m)==1;m = m(ones(size(y)));end
if length(y)==1;y = y(ones(size(m)));end   
sizes = [size(y);size(m)];
if any(sizes(:,1)~=sizes(1,1)) || any(sizes(:,2)~=sizes(2,2))
  error(message('MATLAB:eomdate:invalidInputDims'))
end

ld = eomday(y,m);
d = datenum(y,m,ld); % always a pure date (no time)
if DateTimeFlag
    d = matlab.datetime.compatibility.convertDatenum(d);
end
