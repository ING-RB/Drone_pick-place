function [c,b_is_max] = max(a,b,omitnan) %#codegen
%MAX Maximum elements of a doubledouble array.

%   Copyright 2020 The MathWorks, Inc.

ahi = real(a);
alo = imag(a);
bhi = real(b);
blo = imag(b);

if omitnan
    if (ahi > bhi || isnan(bhi))
        b_is_max = false;
    elseif (ahi < bhi || isnan(ahi))
        b_is_max = true;
    else
        %coder.internal.assert(alo == alo && blo == blo)
        b_is_max = (alo < blo);
    end
    
else
    if (ahi > bhi || isnan(ahi))
        b_is_max = false;
    elseif (ahi < bhi || isnan(bhi))
        b_is_max = true;
    else
        %coder.internal.assert(alo==alo && blo==blo)
        b_is_max = (alo<blo);
    end
end

if b_is_max
    c = b;
else
    c = a;
end

end
