function dom = day(d,f) 
%DAY  Day of month. 
%   Using MATLAB serial date numbers and date strings to represent dates and times
%   is not recommended. Call DAY using a datetime value instead.
%
%   DOM = DAY(D) returns the day of the month given a serial date number 
%   or date string, D. 
% 
%	DOM = DAY(S,F) returns the day of one or more date strings S using 
%   format string F. S can be a character array where each
%	row corresponds to one date string, or one dimensional cell array of 
%	strings.  
%
%	All of the date strings in S must have the same format F, which must be
%	composed of date format symbols according to Table 2 in DATESTR help.
%	Formats with 'Q' are not accepted.  
%
%   For example, dom = day(728647) or dom = day('19-Dec-1994') 
%   returns dom = 19. 
%  
%   See also MONTH, YEAR.
 
%       Copyright 1995-2021 The MathWorks, Inc.
 
if nargin > 0
    if ~isa(d,"char") && ~isa(d,"string") && ~isa(d,"numeric") && ~isa(d,"cell")
      error(message('MATLAB:day:invalidInputClass'))
    end
    d = convertStringsToChars(d);
end

if nargin > 1
    f = convertStringsToChars(f);
end

if nargin < 1 
  error(message('MATLAB:day:missingInputs'))
end 
if nargin < 2
  f = '';
end

if any(strcmpi(f,{'dayofmonth','dayofweek','dayofyear','name','shortname'}))
    error(message('MATLAB:day:dayTypeNotRecognized'));
end

tFlag = false;   %Keep track if input was character array 
if ischar(d)
    d = datenum(d,f);
    tFlag = true;
end

% Generate date vectors
if nargin < 2  || tFlag
  c = datevec(d(:));
else
  c = datevec(d(:),f);
end

dom = c(:,3);            % Extract day of month 
if ~ischar(d) 
  dom = reshape(dom,size(d)); 
end
