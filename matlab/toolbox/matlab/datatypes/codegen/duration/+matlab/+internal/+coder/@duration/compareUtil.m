function [amillis,bmillis,template] = compareUtil(a,b) %#codegen
%COMPAREUTIL Convert durations into values that can be compared directly.
%   [AMILLIS,BMILLIS,TEMPLATE] = COMPAREUTIL(A,B) returns the milliseconds
%   corresponding to A and B in AMILLIS and BMILLIS respectively and a
%   TEMPLATE duration, which has the same format property as the duration
%   object occuring first in the input arguments. If one of the inputs is
%   numeric or logical, it is converted into milliseconds by treating it as
%   a datenum. If one of the inputs is a string or char array, it is
%   converted into milliseconds by treating it as a text representation of
%   a duration.

%   Copyright 2014-2020 The MathWorks, Inc.

% Convert to seconds.  Numeric input interpreted as a number of days.
template = duration(matlab.internal.coder.datatypes.uninitialized);
if isa(a,'duration')
    template.fmt = a.fmt;
    amillis = a.millis;
    bmillis = convert(template,b);
else % b must have been a duration
    template.fmt = b.fmt;
    bmillis = b.millis;
    amillis = convert(template,a);
end
end

function bmillis = convert(template,b)
coder.internal.errorIf(matlab.internal.coder.datatypes.isText(b),'MATLAB:duration:TextConstructionCodegen');
if isa(b,'duration')
    bmillis = b.millis;
elseif isnumeric(b) || islogical(b)
    [bmillis, validConversion] = matlab.internal.coder.timefun.datenumToMillis(b);
    coder.internal.assert(validConversion,'MATLAB:duration:InvalidComparison',class(template),class(b));
else
    coder.internal.assert(false,'MATLAB:duration:InvalidComparison',class(template),class(b));
end
end

