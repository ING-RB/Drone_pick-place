function c = minus(a,b) %#codegen
%MINUS Datetime subtraction.

%   Copyright 2019-2021 The MathWorks, Inc.

coder.internal.implicitExpansionBuiltin;


[a,b] = datetime.arithUtil(a,b);


coder.internal.errorIf(isa(b,'datetime') && ~isa(a,'datetime'),'MATLAB:datetime:SubtractionNotDefined',class(b),class(a));
if isa(a,'datetime')
    if isa(b,'datetime')
        % Return the duration between two datetimes
        ms = matlab.internal.coder.doubledouble.minus(a.data,b.data,false);
        c = duration.fromMillis(ms);
    else
        cdata = a.data;
        c = matlab.internal.coder.datetime(matlab.internal.coder.datatypes.uninitialized);
        c.fmt = a.fmt;
        c.tz = a.tz;
        if isa(b,'duration')
            c.data = matlab.internal.coder.doubledouble.minus(cdata,milliseconds(b),true);            
        else
            [ms,validConversion] = matlab.internal.coder.timefun.datenumToMillis(b);
            
            coder.internal.assert(validConversion,'MATLAB:datetime:SubtractionNotDefined',class(b),class(a))
            
            % Subtract a multiple of 24 hours
            c.data = matlab.internal.coder.doubledouble.minus(cdata,ms,true);
        end
        
    end
end

