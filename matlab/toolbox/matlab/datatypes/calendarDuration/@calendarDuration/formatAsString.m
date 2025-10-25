function s = formatAsString(components,fmt,missingAsNaN,~)
%

%FORMATASSTRING Convert calendar durations to string array.
%   S = FORMATASSTRING(COMPONENTS,FORMAT,MISSINGASNAN) returns a string
%   array representing the calendar durations in COMPONENTS, using the
%   specified calendar duration format. FMT is a string or character vector
%   containing the characters y,q,m,w,d,t to represent time units of the
%   calendar durations, for example 'ymd'. For the complete specification,
%   type "help calendarDuration.Format". If MISSINGASNAN is true, then
%   every NaN calendarDuration in COMPONENTS is represented as a "NaN".
%   Otherwise, every NaN calendarDuration is represented as a <missing>
%   string.
%
%   S = FORMATASSTRING(COMPONENTS,FORMAT,MISSINGASNAN,LOCALE) specifies the
%   locale (in particular, the language) used to create S. LOCALE must be a
%   string or character vector in the form xx_YY, where xx is a lowercase
%   ISO 639-1 two-letter language code and YY is an uppercase ISO 3166-1
%   alpha-2 country code, for example 'ja_JP'.
%
%   See also STRING, CELLSTR, CHAR, CALENDARDURATION.

%   Copyright 2014-2024 The MathWorks, Inc.

% Get the current output display format setting.
dblFmt = getFloatFormats();

outSz = calendarDuration.getFieldSize(components);

sz = calendarDuration.getFieldSize(components);
n = prod(sz);
mo = components.months(:);
if isscalar(mo), mo = repmat(mo,n,1); end
d = components.days(:);
if isscalar(d), d = repmat(d,n,1); end
s = components.millis(:) / 1000;  % ms -> s
if isscalar(s), s = repmat(s,n,1); end

% Find elements with non-finite values.
check = mo + d + s;
finiteElems = isfinite(check);
nonfiniteVals = check(~finiteElems);

units = ["y" "q" "mo" "w" "d" "h" "m" "s"];

% Create a cellstr column for each field in the format. The values
% are all signed.
fieldNum = 0;
zeroUnit = strings(0);
flen = strlength(fmt);

% Preallocating output array
strs = strings(n,flen);

for i = 1:flen
    switch fmt(i)
    case 'y'
        fieldNum = 1;
        y = fix(mo / 12);
        mo = rem(mo,12);
        field = y;
    case 'q'
        fieldNum = 2;
        q = fix(mo / 3);
        mo = rem(mo,3);
        field = q;
    case 'm'
        fieldNum = 3;
        field = mo;
    case 'w'
        fieldNum = 4;
        w = fix(d / 7);
        d = rem(d,7);
        field = w;
    case 'd'
        fieldNum = 5;
        field = d;
    case 't'
        fieldNum = 8;
        sgn = sign(s); s = abs(s);
        h = fix(s / 3600);
        s = rem(s,3600);
        m = fix(s / 60);
        s = rem(s,60);
        field = bsxfun(@times,sgn,[h m s]);
        % Prevent compose from displaying -0 in h/m/s instead of 0 if millis was negative.
        field(field == 0) = 0;
        % Use the current display format as specifier for seconds.
        strFmt = sprintf("%%g%s %%g%s %s%s",units(6),units(7),dblFmt,units(8));
        z = all(field == 0,2);
    end
    if fieldNum <= 5
        % Display with a fixed width.
        strFmt = sprintf("%%g%s ",units(fieldNum));
        z = (field == 0);
    end
    
    % Format the fields correctly and store them into a string array for concatenation later
    strs(:,i) = compose(strFmt,field);
    
    % Replace any 0 fields with empty
    strs(z,i) = "";

    % Track the lowest-order unit actually present.
    if ~all(z)
        zeroUnit = units(fieldNum);
    end
end

if isempty(zeroUnit)
    zeroUnit = units(5); % all elements are zero, use days
end

% Combine all fields into one character vector for each element.
strs = strip(join(strs,"")); % Already pre-padded

% Overwrite completely empty elements with an appropriate 0.
strs(strs == "") = "0" + zeroUnit;

% Overwrite non-finite elements.
if ~isempty(nonfiniteVals)
    strs(~finiteElems) = string(nonfiniteVals);
    
    % A NaN calendarDuration value will result in a <missing> string, because the string
    % method is "data copnversion", but display, char, and cellstr need NaN to show up as
    % "NaN", because they are "display"
    if missingAsNaN
        strs(ismissing(strs)) = "NaN";
    end
end

s = reshape(strs,outSz);

end

%-----------------------------------------------------------------------
function [dblFmt] = getFloatFormats()
% Display for double/single will follow 'format long/short g/e' from the
% command window. 'format long/short' (no 'g/e') is not supported
% because it often needs to print a leading scale factor.
switch lower(matlab.internal.display.format)
case {'short' 'shortg' 'shorteng'}
    dblFmt  = "%.5g";
case {'long' 'longg' 'longeng'}
    dblFmt  = "%.15g";
case 'shorte'
    dblFmt  = "%.4e";
case 'longe'
    dblFmt  = "%.14e";
otherwise % rat, hex, +, bank -- fall back to shortg
    dblFmt  = "%.5g";
end
end

