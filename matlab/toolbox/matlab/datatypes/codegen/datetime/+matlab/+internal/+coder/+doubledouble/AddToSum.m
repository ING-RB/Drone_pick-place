function [c, b_was_nonnan] = AddToSum(a,b,omitnan) %#codegen
%ADDTOSUM Low-level helper for doubledouble math in codegen.

%   Copyright 2020 The MathWorks, Inc.

if omitnan    
    if isnan(b)
        c = a;
        b_was_nonnan = false;
    else
        c = matlab.internal.coder.doubledouble.plus(a,b);
        b_was_nonnan = true;
    end
    
else
    
    c = matlab.internal.coder.doubledouble.plus(a,b);
    b_was_nonnan = true;
end

end