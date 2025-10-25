function d = nweekdate(n,wkd,y,m,g,outType)
%NWEEKDATE Date of specific occurrence of weekday in month.
%   Using MATLAB serial date numbers and date strings to represent dates and times is not
%   recommended. Return datetimes by calling NWEEKDATE with the 'datetime' flag.
%
%   D = NWEEKDATE(N,WKD,Y,M,G, OUTPUTTYPE) returns the serial date for a specific 
%   occurrence of a given weekday, in a given year and month.
%   N is the nth occurrence of the desired weekday, (an integer from 1 to 5),
%   WKD is the weekday, (1 through 7 equal Sunday through Saturday), Y is the
%   year, M is the month, and G is an optional specification of another weekday 
%   that must fall in the same week as WKD. The default value is G = 0. 
%   OUTTYPE, is a string which, if specified, determines if D is in serial 
%   date format ('datenum') or datetime format ('datetime'). The default 
%   behavior is 'datenum'.
%  
%   For example, to find the first Thursday in May 1997:
%
%   d = nweekdate(1,5,1997,5) returns d = 729511 which is
%       the serial date corresponding to May 01, 1997. 
%   
%   See also FBUSDATE, LBUSDATE, LWEEKDATE.

%   Copyright 1995-2021 The MathWorks, Inc.

if nargin < 4 
  error(message('MATLAB:nweekdate:missingInputs'))
end 

if nargin < 5 || isempty(g)
  g = 0;
end

if nargin < 6
    outType = 'datenum';
end

switch outType
    case 'datenum'
        DateTimeFlag = false;
    case 'datetime'
        DateTimeFlag = true;
    otherwise
        error(message('MATLAB:nweekdate:invalidOutputType'));
end

if any(any(n > 5 | n < 1)) 
  error(message('MATLAB:nweekdate:invalidOccurrence'))
end 

if any(any(m > 12 | m < 1)) 
  error(message('MATLAB:nweekdate:invalidMonth'))
end 

if any(any(wkd > 7 | wkd < 1))
  error(message('MATLAB:nweekdate:invalidWeekday'))
end 

if any(any(g > 7 | g < 0))
  error(message('MATLAB:nweekdate:invalidWeekdayConstraint'))
end 


% Scalar expansion
if length(n)==1, n = n(ones(size(g))); end
if length(wkd)==1, wkd = wkd(ones(size(n))); end
if length(y)==1, y = y(ones(size(wkd))); end
if length(m)==1, m = m(ones(size(y))); end
if length(g)==1, g = g(ones(size(m))); end
if length(n)==1, n = n(ones(size(g))); end
if length(wkd)==1, wkd = wkd(ones(size(n))); end
if length(y)==1, y = y(ones(size(wkd))); end
if length(m)==1, m = m(ones(size(y))); end
sizes = [size(n);size(wkd);size(y);size(m);size(g)];
if any(sizes(:,1)~=sizes(1,1)) || any(sizes(:,2)~=sizes(2,2))
  error(message('MATLAB:nweekdate:invalidInputDims'))
end
  
d = zeros(size(n));
firsd = convertTo(datetime(y,m,ones(size(y))),"datenum");
stard = weekday(firsd);
lastd = eomdate(y,m);
for i = 1:length(n(:))
  prelim1 = -ones(42,1);
  prelim2 = prelim1;
  numdays = length(firsd(i):lastd(i));
  prelim1(stard(i):numdays+stard(i)-1) = firsd(i):lastd(i); 
  prelim2(stard(i):numdays+stard(i)-1) = weekday(firsd(i):lastd(i));
  dayind = find(prelim2 == wkd(i));
  tind = ceil(dayind/7);
  mint = min(tind);
  if g(i) == 0 || wkd(i) < g(i)
    minat = mint;
  else
    adayind = find(prelim2 == g(i));
    atind = ceil(adayind/7);
    minat = min(atind);
  end
  if mint ~= minat
    if max(tind) < n(i)+1
      d(i) = 0;
    else
      d(i) = prelim1(dayind(n(i)+1));
    end
  else
    if max(tind) < n(i) || length(dayind) < n(i)
      d(i) = 0;
    else
      d(i) = prelim1(dayind(n(i)));
    end
  end
end

if DateTimeFlag
  d = datetime(d,"ConvertFrom","datenum");
end
