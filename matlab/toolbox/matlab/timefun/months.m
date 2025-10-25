function mm = months(d1, d2, eom)
%MONTHS Number of whole months between dates.
%   MONTHS is not recommended. Use datetimes and call between(dt1,dt2,"months") instead.
%
%   Determine the number of whole months between dates.
%
%   MM = months(D1, D2)
%   MM = months(D1, D2, EOM)
%
%   Optional Inputs: EOM
%
%   Inputs:
%   D1  - Scalar, vector, or matrix of starting date(s).
%
%   D2  - Scalar, vector, or matrix of ending date(s).
%
%   Optional Inputs:
%   EOM - Determines if dates corresponding to the last day of the month are
%         treated as an additional whole month (EOM = 1, default) or not
%         (EOM = 0).
%
%   Outputs:
%   MM  - Scalar, vector, or matrix of the number of whole months between dates
%         D1 and D2.
%
%   Example:
%      mm = months('31-march-1997', '30-Jun-1997', 1)
%      mm =
%           3
%
%      mm = months('31-march-1997','30-Jun-1997', 0)
%      mm =
%           2
%
%   See also YEARFRAC.

%   Copyright 1995-2021 The MathWorks, Inc.

if nargin > 0
    d1 = convertStringsToChars(d1);
end

if nargin > 1
    d2 = convertStringsToChars(d2);
end

if nargin < 2
    if nargin == 1 && isnumeric(d1)
        error(message('MATLAB:months:oneInputSuggestCalMonths'))
    else
        error(message('MATLAB:months:tooFewInputs'))
    end
end

% Default EOM value is 1
if nargin < 3
    eom = 1;
end

if eom ~= 1 && eom ~= 0
    error(message('MATLAB:months:invalidEOM'))
end

% Convert date strings and datetime arrays if necessary

if ischar(d1) || ischar(d2) || isdatetime(d1) || isdatetime(d2)
    dat1 = datenum(d1);
    dat2 = datenum(d2);

elseif iscell(d1) || iscell(d2)
    try
        dat1 = datenum(d1);
        dat2 = datenum(d2);

    catch

        error(message('MATLAB:months:invalidDateType'))
    end

else
    dat1 = d1;
    dat2 = d2;
end

% Scalar expansion
if length(dat1) == 1,   dat1    = dat1(ones(size(eom))); end
if length(dat2) == 1,   dat2    = dat2(ones(size(dat1))); end
if length(eom)  == 1,   eom     = eom(ones(size(dat2))); end
if length(dat1) == 1,   dat1    = dat1(ones(size(eom))); end

sizes = [size(dat1); size(dat2); size(eom)];
if any(sizes(:,1)~=sizes(1,1)) || any(sizes(:,2)~=sizes(2,2))
    error(message('MATLAB:months:invalidInputDims'))
end

% Manipulate data for negative output
nindex = find(dat2 < dat1);
temp1 = dat1(nindex);
temp2 = dat2(nindex);
dat1(nindex) = temp2;
dat2(nindex) = temp1;

% Find the years and months between the specified dates
[year2, mont2, day2] = datevec(dat2);
[year1, mont1] = datevec(dat1);

yrs = (year2 - year1) * 12;
mts = mont2 - mont1;

% Find last day of month of D2
ld = eomday(year2, mont2);

% Do not subtract month if applicable
mincr = -ones(size(day2));
index = (day2 >= day(dat1) | (ld == day2 & eom == 1));
mincr(index) = 0;

% Months calculation
mm = mts + yrs + mincr;

% Make negative if D2 < D1
mm(nindex) = -mm(nindex) .* ones(size(nindex));


% [EOF]
