function t = today(outType) 
%TODAY Current date. 
%   TODAY is not recommended. Call datetime("today") instead.
%
%   T = TODAY returns the current date.
%
%   T = TODAY(OUTTYPE) returns the current date in the specified format
%   ('datenum' for serial date number, or 'datetime' for datetime).
%   The default value is 'datenum'.
%
%   See also DATETIME. 
 
%    Copyright 1995-2022 The MathWorks, Inc.  

if nargin > 0
    outType = convertStringsToChars(outType);
end

if nargin < 1 || isempty(outType)
    outType = 'datenum';
end

switch outType
    case 'datenum'
        DateTimeFlag = false;
    case 'datetime'
        DateTimeFlag = true;
    otherwise
        error(message('MATLAB:today:invalidOutputType'));
end
c = clock; 

if DateTimeFlag
    t = datetime('today');
else
    t = datenum(c(1),c(2),c(3));
end

