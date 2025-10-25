function c = plus(a,b) %#codegen
%PLUS Datetime addition.

%   Copyright 2019-2021 The MathWorks, Inc.

coder.internal.implicitExpansionBuiltin;

[a,b] = datetime.arithUtil(a,b); % durations become numeric, in days
c = matlab.internal.coder.datetime(matlab.internal.coder.datatypes.uninitialized);
if isa(a,'datetime')
    coder.internal.errorIf(isa(b,'datetime'),'MATLAB:datetime:DatetimeAdditionNotDefined');
    cdata = a.data;
    c.fmt = a.fmt;
    c.tz = a.tz;
    
    op = b;
else %isa(b,'datetime')
    cdata = b.data;
    c.fmt = b.fmt;
    c.tz = b.tz;
    op = a;
end

if isa(op,'duration')
    c.data = matlab.internal.coder.doubledouble.plus(cdata,milliseconds(op));
else
    [ms,validConversion] = matlab.internal.coder.timefun.datenumToMillis(op);
    coder.internal.assert(validConversion,'MATLAB:datetime:AdditionNotDefined',class(c),class(op))
    
    % Add a multiple of 24 hours
    c.data = matlab.internal.coder.doubledouble.plus(cdata,ms);
end
 