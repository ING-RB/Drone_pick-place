function n = weeknum(d,w,e)
%WEEKNUM Week in year.
%   WEEKNUM is not recommended. Use datetimes and call week(dt,"weekofyear") instead.
%
%   N = WEEKNUM(D) returns the week of the year given D, a serial date
%   number, date string, or a datetime. When D is a one dimensional 
% 	cell array of strings, weeknum returns a column vector of M week numbers, 
% 	where M is the number of strings in D. 
%
%   N = WEEKNUM(D,W) returns the week of the year given D, a serial date
%   number, date string or a datetime, and W, a numeric representation 
%   of the day a week begins.  The week start values and their corresponding 
%   day are:
%
%                       1     Sun   (default)
%                       2     Mon
%                       3     Tue
%                       4     Wed
%                       5     Thu
%                       6     Fri
%                       7     Sat
%
%   N = WEEKNUM(D,W,E) returns the week of the year given D, a serial date
%   number, date string or a datetime, and W, a numeric representation  
%   of the day a week begins. When E is set to 1, the week of the year is in 
%   the European standard. E by default is 0.
%
%   See also DATETIME, WEEK, WEEKDAY.

%   Copyright 1984-2022 The MathWorks, Inc.

%Check input size and type
%Do not use European standard
if nargin > 0
    d = convertStringsToChars(d);
end

if nargin < 3
    e = 0;
end

%Check e data type to be 0, 1, or logical
if ~iscell(e) && ~isstruct(e) && ~isempty(e) % e is an array
    if e(1)==0||e(1)==1||e(1)==true||e(1)==false
        % Correct data type. Proceed
    else
        error(message('MATLAB:weeknum:wrongTypeForE'));
    end
else
    error(message('MATLAB:weeknum:wrongTypeForE'));
end

%If no input or empty, week starts on Sunday
if nargin < 2
    w = 1;
end

%Check w data type to be a numeric integer
if isempty(w) || ~isnumeric(w(1))
    error(message('MATLAB:weeknum:wrongTypeForW'));
end

%Check w every element's value to be in range of [1:7]
[m, n] = size(w);
numberOfElements = m*n;
validWeekValues = 1:7;
for ii = 1:numberOfElements
    if isempty(find(validWeekValues == w(ii), 1))
        error(message('MATLAB:weeknum:checkRangeForW'));
    end
end

%Back up initial w and e values in case recursion is needed in the end
w0 = w; %#ok<NASGU>
e0 = e; %#ok<NASGU>

%Convert date to datenum if necessary    
if ~isnumeric(d)    
    try
        d = datenum(d);
    catch exception
        throw(MException('MATLAB:weeknum:ConvertDateString', '%s', exception.message));
    end
end

%Check dimensions of all inputs and expand scalars if necessary
isScalarD = isscalar(d);
isScalarW = isscalar(w);
isScalarE = isscalar(e);
result = [isScalarD, isScalarW, isScalarE];

switch sum(result == 1)
    case 0 % None is scalar - check dimension matches
        if isequal(size(w),size(d)) && isequal(size(d),size(e))
            % Proceed when all three matrices are the same size
        else
            error(message('MATLAB:weeknum:dimensionsMismatch'));
        end
    case 1 % If one input is scalar, the other two are matrices
        index = find(result, 1);
        switch index
            case 1    % d is scalar
                if size(w) == size(e)
                    d=repmat(d, size(w));
                else
                    error(message('MATLAB:weeknum:dimensionsMismatch'));
                end
            case 2    % w is scalar
                if size(d) == size(e)
                    w=repmat(w, size(d));
                else
                    error(message('MATLAB:weeknum:dimensionsMismatch'));
                end
            otherwise % e is scalar
                if size(w) == size(d)
                    e=repmat(e, size(d));
                else
                    error(message('MATLAB:weeknum:dimensionsMismatch'));
                end
        end
    case 2 % If two inputs are scalars, the other one is a matrix
        index = find(result==0, 1); 
        switch index
            case 1    % d is matrix
                w=repmat(w, size(d));
                e=repmat(e, size(w));
            case 2    % w is matrix
                d=repmat(d, size(w));
                e=repmat(e, size(w));
            otherwise % e is matrix
                d=repmat(d, size(e));
                w=repmat(w, size(e));
        end
    otherwise % All scalars
        % Do nothing
end


%Get year value from each date
yrs = year(d);

%Get date number of first day of year
dFirst = datenum(yrs,1,1);

%Get the difference between the first day and the user specified week start day

nDay = mod(fix(dFirst)-2,7)-(w-1);
    
%For Default Standard
n = zeros(size(d));

%When nDay<0 and user checks dates falling in any week after the first week
ii = (nDay<0 & (d-dFirst >= -nDay));
n(ii) = fix((d(ii) - dFirst(ii) + nDay(ii))./7)+2; 

%When
% 1)nDay>=0
% 2)nDay<0 but user happens to check dates in the first week of the year
n(~ii) = fix((d(~ii) - dFirst(~ii) + nDay(~ii))./7)+1;

%For European standard considers first week of year to be first week longer
%than 3 days, offset by given week start day
if any(any(e))
    isEuro = (e == 1);
    
    % Check whether the first week match the European standard
    ii = (nDay < 0);
    nDay(ii) = nDay(ii) + 7;
    
    ii = (nDay >= 4);
    n(ii & isEuro) = n(ii & isEuro)-1;
    
    % Check whether the dates should be counted as the first week of next year
    dFirstnew = datenum(yrs+1,1,1);
    nDaynew = mod(fix(dFirstnew)-2,7)-(w-1);
    
    ii = (nDaynew < 0);
    nDaynew(ii) = nDaynew(ii) + 7;
    
    ii = ((nDaynew < 4)&(dFirstnew - d <= nDaynew));
    n(ii & isEuro) = 1;
    
    % If n=0, we need to calculate the last week number of the previous year
    jj = (n==0 & isEuro);
    if any(any(jj))
        n(jj) = weeknum(dFirst(jj)-1,w(jj),e(jj));
    end
end
end


